//
//  ContactTests.swift
//  CirclesTests
//

import XCTest
import CoreData
@testable import PrivateDatabase

final class ContactTests: XCTestCase {
    var persistence: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        viewContext = persistence.viewContext
    }
    
    override func tearDown() {
        persistence = nil
        viewContext = nil
        super.tearDown()
    }
    
    // MARK: - Contact Creation Tests
    
    func testContactCreation() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        XCTAssertNotNil(contact.id)
        XCTAssertEqual(contact.name, "Test User")
        XCTAssertEqual(contact.relationshipType, "Friend")
    }
    
    // MARK: - Computed Property Tests
    
    func testDaysSinceLastContact() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // Set last contact to 15 days ago
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        
        XCTAssertEqual(contact.daysSinceLastContact, 15)
    }
    
    func testRelationshipScoreRecent() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Date() // Connected today
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // Recent contact should have high score
        XCTAssertGreaterThan(contact.relationshipScore, 0.6)
    }
    
    func testRelationshipScoreOld() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // Set last contact to 90 days ago
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        
        // Old contact should have low score
        XCTAssertLessThan(contact.relationshipScore, 0.4)
    }
    
    func testUrgencyLevelLow() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        XCTAssertEqual(contact.urgencyLevel, .low)
    }
    
    func testUrgencyLevelMedium() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        XCTAssertEqual(contact.urgencyLevel, .medium)
    }
    
    func testUrgencyLevelHigh() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        XCTAssertEqual(contact.urgencyLevel, .high)
    }
    
    func testUrgencyLevelCritical() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        XCTAssertEqual(contact.urgencyLevel, .critical)
    }
    
    // MARK: - Array Accessor Tests
    
    func testInterestsArrayAccessor() {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        let interests = ["hiking", "photography", "cooking"]
        contact.interestsArray = interests
        
        XCTAssertEqual(contact.interestsArray, interests)
    }
    
    // MARK: - Relationship Tests
    
    func testContactInteractionRelationship() throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test User"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        let interaction = Interaction(context: viewContext)
        interaction.id = UUID()
        interaction.content = "Had coffee"
        interaction.source = "manual"
        interaction.interactionDate = Date()
        interaction.createdAt = Date()
        interaction.contact = contact
        
        try viewContext.save()
        
        XCTAssertEqual(contact.interactions?.count, 1)
        XCTAssertEqual(interaction.contact, contact)
    }
}
