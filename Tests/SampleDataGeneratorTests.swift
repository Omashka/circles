//
//  SampleDataGeneratorTests.swift
//  PrivateDatabaseTests
//

import XCTest
import CoreData
@testable import Circles

final class SampleDataGeneratorTests: XCTestCase {
    var persistence: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        context = persistence.viewContext
    }
    
    override func tearDown() {
        context = nil
        persistence = nil
        super.tearDown()
    }
    
    // MARK: - Generation Tests
    
    func testGenerateSampleContacts() async throws {
        // Generate sample contacts
        try await SampleDataGenerator.generateSampleContacts(count: 10, in: context)
        
        // Verify contacts were created
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        XCTAssertEqual(contacts.count, 10)
    }
    
    func testGeneratedContactsHaveRequiredFields() async throws {
        try await SampleDataGenerator.generateSampleContacts(count: 5, in: context)
        
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        for contact in contacts {
            XCTAssertNotNil(contact.id)
            XCTAssertNotNil(contact.name)
            XCTAssertFalse(contact.name!.isEmpty)
            XCTAssertNotNil(contact.relationshipType)
            XCTAssertNotNil(contact.lastConnectedDate)
        }
    }
    
    func testGeneratedContactsHaveVariedUrgency() async throws {
        try await SampleDataGenerator.generateSampleContacts(count: 15, in: context)
        
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        // Check that we have varied days since last contact
        let daysSinceLastContact = contacts.map { $0.daysSinceLastContact }
        let uniqueDays = Set(daysSinceLastContact)
        
        // Should have multiple different urgency levels
        XCTAssertGreaterThan(uniqueDays.count, 5)
    }
    
    func testGeneratedContactsHaveInterests() async throws {
        try await SampleDataGenerator.generateSampleContacts(count: 5, in: context)
        
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        for contact in contacts {
            let interests = contact.interestsArray
            XCTAssertFalse(interests.isEmpty, "Contact should have interests")
        }
    }
    
    func testGeneratedContactsHaveVariedRelationshipTypes() async throws {
        try await SampleDataGenerator.generateSampleContacts(count: 15, in: context)
        
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        let relationshipTypes = Set(contacts.compactMap { $0.relationshipType })
        
        // Should have multiple relationship types
        XCTAssertGreaterThan(relationshipTypes.count, 1)
        XCTAssertTrue(relationshipTypes.contains("Friend"))
        XCTAssertTrue(relationshipTypes.contains("Family") || relationshipTypes.contains("Colleague"))
    }
    
    func testGenerateLimitedCount() async throws {
        // Request more than available
        try await SampleDataGenerator.generateSampleContacts(count: 100, in: context)
        
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        // Should be limited to available sample names (15)
        XCTAssertLessThanOrEqual(contacts.count, 15)
    }
    
    func testSomeBirthdaysSet() async throws {
        try await SampleDataGenerator.generateSampleContacts(count: 15, in: context)
        
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        let contactsWithBirthdays = contacts.filter { $0.birthday != nil }
        
        // Not all should have birthdays (i % 3 == 0 in generator)
        XCTAssertGreaterThan(contactsWithBirthdays.count, 0)
        XCTAssertLessThan(contactsWithBirthdays.count, contacts.count)
    }
    
    // MARK: - Clear Tests
    
    func testClearAllContacts() async throws {
        // Generate contacts
        try await SampleDataGenerator.generateSampleContacts(count: 10, in: context)
        
        var fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        var contacts = try context.fetch(fetchRequest)
        XCTAssertEqual(contacts.count, 10)
        
        // Clear all
        try await SampleDataGenerator.clearAllContacts(in: context)
        
        fetchRequest = Contact.fetchRequest()
        contacts = try context.fetch(fetchRequest)
        XCTAssertEqual(contacts.count, 0)
    }
    
    func testRegenerateAfterClear() async throws {
        // Generate, clear, regenerate
        try await SampleDataGenerator.generateSampleContacts(count: 5, in: context)
        try await SampleDataGenerator.clearAllContacts(in: context)
        try await SampleDataGenerator.generateSampleContacts(count: 8, in: context)
        
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let contacts = try context.fetch(fetchRequest)
        
        XCTAssertEqual(contacts.count, 8)
    }
}

