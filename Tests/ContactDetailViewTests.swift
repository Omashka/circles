//
//  ContactDetailViewTests.swift
//  CirclesTests
//

import XCTest
import SwiftUI
@testable import Circles

@MainActor
final class ContactDetailViewTests: XCTestCase {
    var dataManager: DataManager!
    var viewContext: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        let persistence = PersistenceController.preview
        dataManager = DataManager(persistence: persistence)
        viewContext = persistence.viewContext
    }
    
    override func tearDown() async throws {
        dataManager = nil
        viewContext = nil
        try await super.tearDown()
    }
    
    func testContactDetailViewDisplaysContactInfo() async throws {
        // Create a test contact
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.relationshipType = "Friend"
        contact.birthday = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        contact.jobInfo = "Engineer"
        contact.interestsArray = ["Reading", "Hiking"]
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        try viewContext.save()
        
        // Verify contact properties are accessible
        XCTAssertEqual(contact.name, "Test Contact")
        XCTAssertEqual(contact.relationshipType, "Friend")
        XCTAssertNotNil(contact.birthday)
        XCTAssertEqual(contact.jobInfo, "Engineer")
        XCTAssertEqual(contact.interestsArray.count, 2)
    }
    
    func testContactDetailViewShowsRelationshipMeter() async throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.lastConnectedDate = Date() // Recent contact
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // Recent contact should have high relationship score
        let score = contact.relationshipScore
        XCTAssertGreaterThan(score, 0.7, "Recent contact should have high relationship score")
    }
    
    func testContactDetailViewShowsEmptyInteractions() async throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // New contact should have no interactions
        let interactions = contact.sortedInteractions
        XCTAssertTrue(interactions.isEmpty, "New contact should have no interactions")
    }
    
    func testContactDetailViewShowsInteractions() async throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // Add an interaction
        let interaction = Interaction(context: viewContext)
        interaction.id = UUID()
        interaction.contact = contact
        interaction.content = "Had coffee together"
        interaction.interactionDate = Date()
        interaction.createdAt = Date()
        
        try viewContext.save()
        
        let interactions = contact.sortedInteractions
        XCTAssertEqual(interactions.count, 1, "Contact should have one interaction")
        XCTAssertEqual(interactions.first?.content, "Had coffee together")
    }
    
    func testContactDeleteFunctionality() async throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        try viewContext.save()
        
        // Verify contact exists
        let fetchRequest = Contact.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", contact.id! as CVarArg)
        var contacts = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(contacts.count, 1)
        
        // Delete contact
        try await dataManager.deleteContact(contact)
        
        // Verify contact is deleted
        contacts = try viewContext.fetch(fetchRequest)
        XCTAssertTrue(contacts.isEmpty, "Contact should be deleted")
    }
}

