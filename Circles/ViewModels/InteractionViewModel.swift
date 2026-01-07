//
//  InteractionViewModel.swift
//  Circles
//

import SwiftUI
import CoreData

/// ViewModel managing interactions for a contact
@MainActor
class InteractionViewModel: ObservableObject {
    @Published var interactions: [Interaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let contact: Contact
    var dataManager: DataManager
    
    init(contact: Contact, dataManager: DataManager) {
        self.contact = contact
        self.dataManager = dataManager
    }
    
    // MARK: - Data Loading
    
    /// Load all interactions for the contact
    func loadInteractions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Refresh the contact object to ensure we have latest relationships
            dataManager.viewContext.refresh(contact, mergeChanges: true)
            
            interactions = await dataManager.fetchInteractions(for: contact)
            // Sort by date (most recent first)
            interactions.sort { interaction1, interaction2 in
                let date1 = interaction1.interactionDate ?? Date.distantPast
                let date2 = interaction2.interactionDate ?? Date.distantPast
                return date1 > date2
            }
            isLoading = false
        } catch {
            errorMessage = "Failed to load interactions: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Refresh interactions
    func refreshInteractions() async {
        await loadInteractions()
    }
    
    // MARK: - Interaction Operations
    
    /// Create a new interaction
    func createInteraction(
        content: String,
        source: InteractionSource = .manual,
        interactionDate: Date = Date(),
        rawTranscription: String? = nil,
        extractedInterests: [String]? = nil,
        extractedEvents: [String]? = nil,
        extractedDates: [Date]? = nil
    ) async throws {
        do {
            _ = try await dataManager.createInteraction(
                for: contact,
                content: content,
                source: source,
                rawTranscription: rawTranscription,
                extractedInterests: extractedInterests,
                extractedEvents: extractedEvents,
                extractedDates: extractedDates
            )
            await loadInteractions()
        } catch {
            errorMessage = "Failed to create interaction: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Update an existing interaction
    func updateInteraction(
        _ interaction: Interaction,
        content: String? = nil,
        interactionDate: Date? = nil
    ) async throws {
        if let content = content {
            interaction.content = content
        }
        if let interactionDate = interactionDate {
            interaction.interactionDate = interactionDate
        }
        
        do {
            try await dataManager.saveInteraction(interaction)
            await loadInteractions()
        } catch {
            errorMessage = "Failed to update interaction: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Delete an interaction
    func deleteInteraction(_ interaction: Interaction) async throws {
        do {
            try await dataManager.deleteInteraction(interaction)
            await loadInteractions()
        } catch {
            errorMessage = "Failed to delete interaction: \(error.localizedDescription)"
            throw error
        }
    }
}

