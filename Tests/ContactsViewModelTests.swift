//
//  ContactsViewModelTests.swift
//  PrivateDatabaseTests
//

import XCTest
import CoreData
@testable import Circles

final class ContactsViewModelTests: XCTestCase {
    var viewModel: ContactsViewModel!
    var persistence: PersistenceController!
    var dataManager: DataManager!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        persistence = PersistenceController(inMemory: true)
        dataManager = DataManager(persistence: persistence)
        viewModel = ContactsViewModel(dataManager: dataManager, persistence: persistence)
    }
    
    override func tearDown() {
        viewModel = nil
        dataManager = nil
        persistence = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    @MainActor
    func testInitialState() {
        XCTAssertTrue(viewModel.contacts.isEmpty)
        XCTAssertTrue(viewModel.filteredContacts.isEmpty)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Load Contacts Tests
    
    @MainActor
    func testLoadContactsEmpty() async throws {
        await viewModel.loadContacts()
        
        XCTAssertTrue(viewModel.contacts.isEmpty)
        XCTAssertTrue(viewModel.filteredContacts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testLoadContactsWithData() async throws {
        // Create sample contacts
        let contact1 = try await dataManager.createContact(name: "Alice Smith", relationshipType: "Friend")
        contact1.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        try await dataManager.saveContact(contact1)
        
        let contact2 = try await dataManager.createContact(name: "Bob Jones", relationshipType: "Family")
        contact2.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())
        try await dataManager.saveContact(contact2)
        
        await viewModel.loadContacts()
        
        XCTAssertEqual(viewModel.contacts.count, 2)
        XCTAssertEqual(viewModel.filteredContacts.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Sorting Tests
    
    @MainActor
    func testContactsSortedByUrgency() async throws {
        // Create contacts with different urgency levels
        let recentContact = try await dataManager.createContact(name: "Recent Contact", relationshipType: "Friend")
        recentContact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        try await dataManager.saveContact(recentContact)
        
        let urgentContact = try await dataManager.createContact(name: "Urgent Contact", relationshipType: "Friend")
        urgentContact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -50, to: Date())
        try await dataManager.saveContact(urgentContact)
        
        let mediumContact = try await dataManager.createContact(name: "Medium Contact", relationshipType: "Friend")
        mediumContact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -20, to: Date())
        try await dataManager.saveContact(mediumContact)
        
        await viewModel.loadContacts()
        
        // Should be sorted by most urgent first (most days = most urgent)
        XCTAssertEqual(viewModel.filteredContacts.count, 3)
        XCTAssertEqual(viewModel.filteredContacts[0].name, "Urgent Contact")
        XCTAssertEqual(viewModel.filteredContacts[1].name, "Medium Contact")
        XCTAssertEqual(viewModel.filteredContacts[2].name, "Recent Contact")
    }
    
    // MARK: - Search Tests
    
    @MainActor
    func testSearchByName() async throws {
        // Create test contacts
        let alice = try await dataManager.createContact(name: "Alice Smith", relationshipType: "Friend")
        try await dataManager.saveContact(alice)
        
        let bob = try await dataManager.createContact(name: "Bob Jones", relationshipType: "Family")
        try await dataManager.saveContact(bob)
        
        let charlie = try await dataManager.createContact(name: "Charlie Brown", relationshipType: "Friend")
        try await dataManager.saveContact(charlie)
        
        await viewModel.loadContacts()
        
        // Search for "Bob"
        viewModel.searchTextChanged("Bob")
        
        XCTAssertEqual(viewModel.filteredContacts.count, 1)
        XCTAssertEqual(viewModel.filteredContacts.first?.name, "Bob Jones")
    }
    
    @MainActor
    func testSearchByRelationshipType() async throws {
        let friend1 = try await dataManager.createContact(name: "Alice", relationshipType: "Friend")
        try await dataManager.saveContact(friend1)
        
        let family1 = try await dataManager.createContact(name: "Bob", relationshipType: "Family")
        try await dataManager.saveContact(family1)
        
        let friend2 = try await dataManager.createContact(name: "Charlie", relationshipType: "Friend")
        try await dataManager.saveContact(friend2)
        
        await viewModel.loadContacts()
        
        // Search for "Friend"
        viewModel.searchTextChanged("Friend")
        
        XCTAssertEqual(viewModel.filteredContacts.count, 2)
    }
    
    @MainActor
    func testSearchCaseInsensitive() async throws {
        let contact = try await dataManager.createContact(name: "Alice Smith", relationshipType: "Friend")
        try await dataManager.saveContact(contact)
        
        await viewModel.loadContacts()
        
        // Search with different case
        viewModel.searchTextChanged("alice")
        XCTAssertEqual(viewModel.filteredContacts.count, 1)
        
        viewModel.searchTextChanged("ALICE")
        XCTAssertEqual(viewModel.filteredContacts.count, 1)
        
        viewModel.searchTextChanged("AlIcE")
        XCTAssertEqual(viewModel.filteredContacts.count, 1)
    }
    
    @MainActor
    func testSearchEmptyString() async throws {
        let contact1 = try await dataManager.createContact(name: "Alice", relationshipType: "Friend")
        try await dataManager.saveContact(contact1)
        
        let contact2 = try await dataManager.createContact(name: "Bob", relationshipType: "Family")
        try await dataManager.saveContact(contact2)
        
        await viewModel.loadContacts()
        
        // Empty search should show all contacts
        viewModel.searchTextChanged("")
        XCTAssertEqual(viewModel.filteredContacts.count, 2)
    }
    
    // MARK: - Refresh Tests
    
    @MainActor
    func testRefreshContacts() async throws {
        // Initial load
        let contact = try await dataManager.createContact(name: "Alice", relationshipType: "Friend")
        try await dataManager.saveContact(contact)
        
        await viewModel.loadContacts()
        XCTAssertEqual(viewModel.contacts.count, 1)
        
        // Add another contact
        let contact2 = try await dataManager.createContact(name: "Bob", relationshipType: "Family")
        try await dataManager.saveContact(contact2)
        
        // Refresh should pick up new contact
        await viewModel.refreshContacts()
        XCTAssertEqual(viewModel.contacts.count, 2)
    }
    
    // MARK: - Computed Properties Tests
    
    @MainActor
    func testContactsNeedingAttention() async throws {
        // Create contact needing attention (35+ days)
        let needsAttention = try await dataManager.createContact(name: "Needs Attention", relationshipType: "Friend")
        needsAttention.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())
        try await dataManager.saveContact(needsAttention)
        
        // Create recent contact
        let recent = try await dataManager.createContact(name: "Recent", relationshipType: "Friend")
        recent.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        try await dataManager.saveContact(recent)
        
        await viewModel.loadContacts()
        
        let needingAttention = viewModel.contactsNeedingAttention
        XCTAssertEqual(needingAttention.count, 1)
        XCTAssertEqual(needingAttention.first?.name, "Needs Attention")
    }
    
    @MainActor
    func testRecentlyContacted() async throws {
        // Create recently contacted (< 7 days)
        let recent = try await dataManager.createContact(name: "Recent", relationshipType: "Friend")
        recent.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        try await dataManager.saveContact(recent)
        
        // Create old contact
        let old = try await dataManager.createContact(name: "Old", relationshipType: "Friend")
        old.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        try await dataManager.saveContact(old)
        
        await viewModel.loadContacts()
        
        let recentContacts = viewModel.recentlyContacted
        XCTAssertEqual(recentContacts.count, 1)
        XCTAssertEqual(recentContacts.first?.name, "Recent")
    }
    
    // MARK: - Delete Tests
    
    @MainActor
    func testDeleteContact() async throws {
        let contact = try await dataManager.createContact(name: "To Delete", relationshipType: "Friend")
        try await dataManager.saveContact(contact)
        
        await viewModel.loadContacts()
        XCTAssertEqual(viewModel.contacts.count, 1)
        
        await viewModel.deleteContact(contact)
        
        XCTAssertEqual(viewModel.contacts.count, 0)
    }
}

