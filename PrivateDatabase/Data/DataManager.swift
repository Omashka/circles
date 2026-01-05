//
//  DataManager.swift
//  Circles
//

import Foundation
import CoreData
import os.log

/// Main data manager for all CRUD operations
@MainActor
class DataManager: ObservableObject {
    private let persistence: PersistenceController
    private let logger = Logger(subsystem: "com.circles.app", category: "DataManager")
    
    var viewContext: NSManagedObjectContext {
        persistence.viewContext
    }
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }
    
    // MARK: - Contact Operations
    
    func fetchAllContacts() async -> [Contact] {
        let request = Contact.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Failed to fetch contacts: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchContact(id: UUID) async -> Contact? {
        let request = Contact.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            logger.error("Failed to fetch contact: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveContact(_ contact: Contact) async throws {
        contact.modifiedAt = Date()
        try persistence.save()
        logger.info("Contact saved: \(contact.name ?? "Unknown")")
    }
    
    func createContact(
        name: String,
        relationshipType: String,
        birthday: Date? = nil,
        interests: [String]? = nil
    ) async throws -> Contact {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = name
        contact.relationshipType = relationshipType
        contact.birthday = birthday
        contact.interests = interests as NSObject?
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        try await saveContact(contact)
        return contact
    }
    
    func deleteContact(_ contact: Contact) async throws {
        viewContext.delete(contact)
        try persistence.save()
        logger.info("Contact deleted: \(contact.name ?? "Unknown")")
    }
    
    // MARK: - Interaction Operations
    
    func fetchInteractions(for contact: Contact) async -> [Interaction] {
        let request = Interaction.fetchRequest()
        request.predicate = NSPredicate(format: "contact == %@", contact)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Interaction.interactionDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Failed to fetch interactions: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveInteraction(_ interaction: Interaction) async throws {
        try persistence.save()
        
        // Update contact's last connected date
        if let contact = interaction.contact {
            contact.lastConnectedDate = interaction.interactionDate
            contact.modifiedAt = Date()
            try persistence.save()
        }
        
        logger.info("Interaction saved")
    }
    
    func createInteraction(
        for contact: Contact,
        content: String,
        source: InteractionSource,
        rawTranscription: String? = nil,
        extractedInterests: [String]? = nil,
        extractedEvents: [String]? = nil,
        extractedDates: [Date]? = nil
    ) async throws -> Interaction {
        let interaction = Interaction(context: viewContext)
        interaction.id = UUID()
        interaction.content = content
        interaction.source = source.rawValue
        interaction.rawTranscription = rawTranscription
        interaction.interactionDate = Date()
        interaction.createdAt = Date()
        interaction.contact = contact
        
        if let interests = extractedInterests {
            interaction.extractedInterests = interests as NSArray
        }
        if let events = extractedEvents {
            interaction.extractedEvents = events as NSArray
        }
        if let dates = extractedDates {
            interaction.extractedDates = dates as NSArray
        }
        
        try await saveInteraction(interaction)
        return interaction
    }
    
    // MARK: - Connection Operations
    
    func fetchAllConnections() async -> [Connection] {
        let request = Connection.fetchRequest()
        
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Failed to fetch connections: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveConnection(_ connection: Connection) async throws {
        try persistence.save()
        logger.info("Connection saved")
    }
    
    func createConnection(
        from: Contact,
        to: Contact,
        type: String,
        context: String? = nil,
        introducedBy: Contact? = nil
    ) async throws -> Connection {
        let connection = Connection(context: viewContext)
        connection.id = UUID()
        connection.connectionType = type
        connection.context = context
        connection.fromContact = from
        connection.toContact = to
        connection.introducedBy = introducedBy
        connection.createdAt = Date()
        
        try await saveConnection(connection)
        return connection
    }
    
    func deleteConnection(_ connection: Connection) async throws {
        viewContext.delete(connection)
        try persistence.save()
        logger.info("Connection deleted")
    }
    
    // MARK: - Unassigned Notes Operations
    
    func fetchUnassignedNotes() async -> [UnassignedNote] {
        let request = UnassignedNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UnassignedNote.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Failed to fetch unassigned notes: \(error.localizedDescription)")
            return []
        }
    }
    
    func createUnassignedNote(
        content: String,
        rawText: String,
        source: String
    ) async throws -> UnassignedNote {
        let note = UnassignedNote(context: viewContext)
        note.id = UUID()
        note.content = content
        note.rawText = rawText
        note.source = source
        note.createdAt = Date()
        
        try persistence.save()
        return note
    }
    
    func assignNote(_ note: UnassignedNote, to contact: Contact) async throws {
        // Create interaction from note
        _ = try await createInteraction(
            for: contact,
            content: note.content ?? "",
            source: .shortcutImport,
            rawTranscription: note.rawText
        )
        
        // Delete the unassigned note
        viewContext.delete(note)
        try persistence.save()
        
        logger.info("Note assigned to contact: \(contact.name ?? "Unknown")")
    }
    
    // MARK: - User Settings Operations
    
    func fetchUserSettings() async -> UserSettings {
        let request = UserSettings.fetchRequest()
        request.fetchLimit = 1
        
        do {
            if let settings = try viewContext.fetch(request).first {
                return settings
            } else {
                // Create default settings
                return try await createDefaultSettings()
            }
        } catch {
            logger.error("Failed to fetch user settings: \(error.localizedDescription)")
            // Return default settings on error
            return try! await createDefaultSettings()
        }
    }
    
    private func createDefaultSettings() async throws -> UserSettings {
        let settings = UserSettings(context: viewContext)
        settings.id = UUID()
        settings.defaultReminderDays = 30
        settings.notificationsEnabled = true
        settings.isPremium = false
        
        try persistence.save()
        return settings
    }
    
    func saveUserSettings(_ settings: UserSettings) async throws {
        try persistence.save()
        logger.info("User settings saved")
    }
    
    // MARK: - Utility Operations
    
    func getContactsNeedingAttention(limit: Int = 10) async -> [Contact] {
        let allContacts = await fetchAllContacts()
        return Array(allContacts
            .filter { $0.daysSinceLastContact >= 30 }
            .sorted { $0.daysSinceLastContact > $1.daysSinceLastContact }
            .prefix(limit))
    }
}
