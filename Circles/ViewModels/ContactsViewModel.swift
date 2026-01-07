//
//  ContactsViewModel.swift
//  Circles
//

import SwiftUI
import CoreData

/// ViewModel managing the contact list state and operations
@MainActor
class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var filteredContacts: [Contact] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    private let persistence: PersistenceController
    
    init(dataManager: DataManager? = nil, persistence: PersistenceController = .shared) {
        self.persistence = persistence
        self.dataManager = dataManager ?? DataManager(persistence: persistence)
    }
    
    // MARK: - Data Loading
    
    /// Load all contacts from the data manager
    func loadContacts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            contacts = try await dataManager.fetchAllContacts()
            updateFilteredContacts()
            isLoading = false
        } catch {
            errorMessage = "Failed to load contacts: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Refresh contacts (pull-to-refresh)
    func refreshContacts() async {
        await loadContacts()
    }
    
    // MARK: - Search & Filter
    
    /// Update filtered contacts based on search text
    private func updateFilteredContacts() {
        if searchText.isEmpty {
            filteredContacts = sortedContacts(contacts)
        } else {
            filteredContacts = sortedContacts(
                contacts.filter { contact in
                    let name = contact.name ?? ""
                    let relationshipType = contact.relationshipType ?? ""
                    return name.localizedCaseInsensitiveContains(searchText) ||
                           relationshipType.localizedCaseInsensitiveContains(searchText)
                }
            )
        }
    }
    
    /// Sort contacts by last connected date (most recent first)
    private func sortedContacts(_ contacts: [Contact]) -> [Contact] {
        contacts.sorted { contact1, contact2 in
            let days1 = contact1.daysSinceLastContact
            let days2 = contact2.daysSinceLastContact
            
            // Sort by most recent first (fewer days = more recent = higher priority)
            if days1 != days2 {
                return days1 < days2
            }
            
            // If same recency, sort by name
            let name1 = contact1.name ?? ""
            let name2 = contact2.name ?? ""
            return name1 < name2
        }
    }
    
    /// Handle search text changes
    func searchTextChanged(_ newText: String) {
        searchText = newText
        updateFilteredContacts()
    }
    
    // MARK: - Contact Operations
    
    /// Delete a contact
    func deleteContact(_ contact: Contact) async {
        do {
            try await dataManager.deleteContact(contact)
            await loadContacts() // Reload after deletion
        } catch {
            errorMessage = "Failed to delete contact: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    /// Contacts needing attention (30+ days since last contact)
    var contactsNeedingAttention: [Contact] {
        contacts.filter { $0.daysSinceLastContact >= 30 }
    }
    
    /// Recently contacted (within last 7 days)
    var recentlyContacted: [Contact] {
        contacts.filter { $0.daysSinceLastContact < 7 }
    }
}

