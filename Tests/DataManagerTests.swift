//
//  DataManagerTests.swift
//  CirclesTests
//

import XCTest
import CoreData
@testable import Circles

@MainActor
final class DataManagerTests: XCTestCase {
    var persistence: PersistenceController!
    var dataManager: DataManager!
    
    override func setUp() async throws {
        try await super.setUp()
        persistence = PersistenceController(inMemory: true)
        dataManager = DataManager(persistence: persistence)
    }
    
    override func tearDown() {
        dataManager = nil
        persistence = nil
        super.tearDown()
    }
    
    // MARK: - Contact CRUD Tests
    
    func testCreateContact() async throws {
        let contact = try await dataManager.createContact(
            name: "Jane Doe",
            relationshipType: "Friend",
            interests: ["reading", "travel"]
        )
        
        XCTAssertEqual(contact.name, "Jane Doe")
        XCTAssertEqual(contact.relationshipType, "Friend")
        XCTAssertEqual(contact.interestsArray, ["reading", "travel"])
        XCTAssertNotNil(contact.id)
    }
    
    func testFetchAllContacts() async throws {
        // Create test contacts
        _ = try await dataManager.createContact(name: "Alice", relationshipType: "Friend")
        _ = try await dataManager.createContact(name: "Bob", relationshipType: "Family")
        
        let contacts = await dataManager.fetchAllContacts()
        
        XCTAssertEqual(contacts.count, 2)
        XCTAssertTrue(contacts.contains { $0.name == "Alice" })
        XCTAssertTrue(contacts.contains { $0.name == "Bob" })
    }
    
    func testFetchContactById() async throws {
        let created = try await dataManager.createContact(name: "Charlie", relationshipType: "Colleague")
        
        let fetched = await dataManager.fetchContact(id: created.id!)
        
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Charlie")
        XCTAssertEqual(fetched?.id, created.id)
    }
    
    func testDeleteContact() async throws {
        let contact = try await dataManager.createContact(name: "David", relationshipType: "Acquaintance")
        guard let contactId = contact.id else {
            XCTFail("Created contact should have an ID")
            return
        }
        
        try await dataManager.deleteContact(contact)
        
        let fetched = await dataManager.fetchContact(id: contactId)
        XCTAssertNil(fetched)
    }
    
    // MARK: - Interaction Tests
    
    func testCreateInteraction() async throws {
        let contact = try await dataManager.createContact(name: "Eve", relationshipType: "Friend")
        
        let interaction = try await dataManager.createInteraction(
            for: contact,
            content: "Had lunch together",
            source: .manual,
            extractedInterests: ["food", "restaurants"]
        )
        
        XCTAssertEqual(interaction.content, "Had lunch together")
        XCTAssertEqual(interaction.sourceType, .manual)
        XCTAssertEqual(interaction.extractedInterestsArray, ["food", "restaurants"])
        XCTAssertEqual(interaction.contact, contact)
    }
    
    func testInteractionUpdatesLastConnected() async throws {
        let contact = try await dataManager.createContact(name: "Frank", relationshipType: "Friend")
        let originalDate = contact.lastConnectedDate
        
        // Wait a moment to ensure different timestamp
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        _ = try await dataManager.createInteraction(
            for: contact,
            content: "Caught up",
            source: .manual
        )
        
        // Refetch contact to get updated data
        let updated = await dataManager.fetchContact(id: contact.id!)
        
        XCTAssertNotNil(updated?.lastConnectedDate)
        XCTAssertNotEqual(updated?.lastConnectedDate, originalDate)
    }
    
    // MARK: - Connection Tests
    
    func testCreateConnection() async throws {
        let contact1 = try await dataManager.createContact(name: "Grace", relationshipType: "Friend")
        let contact2 = try await dataManager.createContact(name: "Henry", relationshipType: "Friend")
        
        let connection = try await dataManager.createConnection(
            from: contact1,
            to: contact2,
            type: "friend",
            context: "Met at college"
        )
        
        XCTAssertEqual(connection.connectionType, "friend")
        XCTAssertEqual(connection.context, "Met at college")
        XCTAssertEqual(connection.fromContact, contact1)
        XCTAssertEqual(connection.toContact, contact2)
    }
    
    // MARK: - Unassigned Notes Tests
    
    func testCreateUnassignedNote() async throws {
        let note = try await dataManager.createUnassignedNote(
            content: "Summary of conversation",
            rawText: "Full text here",
            source: "shortcut_import"
        )
        
        XCTAssertEqual(note.content, "Summary of conversation")
        XCTAssertEqual(note.rawText, "Full text here")
        XCTAssertEqual(note.source, "shortcut_import")
    }
    
    func testAssignNoteToContact() async throws {
        let contact = try await dataManager.createContact(name: "Iris", relationshipType: "Friend")
        let note = try await dataManager.createUnassignedNote(
            content: "Note content",
            rawText: "Raw text",
            source: "shortcut_import"
        )
        
        try await dataManager.assignNote(note, to: contact)
        
        // Note should be deleted
        let notes = await dataManager.fetchUnassignedNotes()
        XCTAssertFalse(notes.contains { $0.id == note.id })
        
        // Interaction should be created
        let interactions = await dataManager.fetchInteractions(for: contact)
        XCTAssertEqual(interactions.count, 1)
        XCTAssertEqual(interactions.first?.content, "Note content")
    }
    
    // MARK: - Utility Tests
    
    func testGetContactsNeedingAttention() async throws {
        // Create contacts with different last contact dates
        let recent = try await dataManager.createContact(name: "Recent", relationshipType: "Friend")
        recent.lastConnectedDate = Date()
        
        let needsAttention = try await dataManager.createContact(name: "NeedsAttention", relationshipType: "Friend")
        needsAttention.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())
        
        try await dataManager.saveContact(recent)
        try await dataManager.saveContact(needsAttention)
        
        let contacts = await dataManager.getContactsNeedingAttention(limit: 10)
        
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts.first?.name, "NeedsAttention")
    }
}
