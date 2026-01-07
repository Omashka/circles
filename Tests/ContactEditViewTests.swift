//
//  ContactEditViewTests.swift
//  CirclesTests
//

import XCTest
@testable import Circles

@MainActor
final class ContactEditViewTests: XCTestCase {
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
    
    func testCreateNewContact() async throws {
        let contact = try await dataManager.createContact(
            name: "New Contact",
            relationshipType: "Friend",
            birthday: Calendar.current.date(byAdding: .year, value: -25, to: Date()),
            interests: ["Music", "Sports"]
        )
        
        XCTAssertNotNil(contact.id)
        XCTAssertEqual(contact.name, "New Contact")
        XCTAssertEqual(contact.relationshipType, "Friend")
        XCTAssertNotNil(contact.birthday)
        XCTAssertEqual(contact.interestsArray.count, 2)
        XCTAssertEqual(contact.interestsArray, ["Music", "Sports"])
    }
    
    func testEditExistingContact() async throws {
        // Create contact
        var contact = try await dataManager.createContact(
            name: "Original Name",
            relationshipType: "Colleague"
        )
        
        // Update contact
        contact.name = "Updated Name"
        contact.relationshipType = "Friend"
        contact.jobInfo = "Software Engineer"
        contact.interestsArray = ["Reading", "Coding"]
        
        try await dataManager.saveContact(contact)
        
        // Verify updates
        XCTAssertEqual(contact.name, "Updated Name")
        XCTAssertEqual(contact.relationshipType, "Friend")
        XCTAssertEqual(contact.jobInfo, "Software Engineer")
        XCTAssertEqual(contact.interestsArray.count, 2)
    }
    
    func testContactFieldsSaveCorrectly() async throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.relationshipType = "Family"
        contact.birthday = Calendar.current.date(byAdding: .year, value: -40, to: Date())
        contact.jobInfo = "Doctor"
        contact.familyDetails = "Has two children"
        contact.travelNotes = "Loves to travel"
        contact.interestsArray = ["Photography", "Travel"]
        contact.religiousEventsArray = ["Christmas", "Easter"]
        contact.topicsToAvoidArray = ["Politics"]
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        try await dataManager.saveContact(contact)
        
        // Verify all fields
        XCTAssertEqual(contact.name, "Test Contact")
        XCTAssertEqual(contact.relationshipType, "Family")
        XCTAssertNotNil(contact.birthday)
        XCTAssertEqual(contact.jobInfo, "Doctor")
        XCTAssertEqual(contact.familyDetails, "Has two children")
        XCTAssertEqual(contact.travelNotes, "Loves to travel")
        XCTAssertEqual(contact.interestsArray.count, 2)
        XCTAssertEqual(contact.religiousEventsArray.count, 2)
        XCTAssertEqual(contact.topicsToAvoidArray.count, 1)
    }
    
    func testContactPhotoData() async throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // Create sample image data
        let imageData = Data("fake image data".utf8)
        contact.profilePhotoData = imageData
        
        try await dataManager.saveContact(contact)
        
        XCTAssertNotNil(contact.profilePhotoData)
        XCTAssertEqual(contact.profilePhotoData, imageData)
    }
    
    func testContactArrayFields() async throws {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        // Test interests array
        contact.interestsArray = ["Interest1", "Interest2", "Interest3"]
        XCTAssertEqual(contact.interestsArray.count, 3)
        XCTAssertTrue(contact.interestsArray.contains("Interest1"))
        
        // Test religious events array
        contact.religiousEventsArray = ["Event1", "Event2"]
        XCTAssertEqual(contact.religiousEventsArray.count, 2)
        
        // Test topics to avoid array
        contact.topicsToAvoidArray = ["Topic1"]
        XCTAssertEqual(contact.topicsToAvoidArray.count, 1)
        
        try await dataManager.saveContact(contact)
        
        // Verify arrays persist
        XCTAssertEqual(contact.interestsArray.count, 3)
        XCTAssertEqual(contact.religiousEventsArray.count, 2)
        XCTAssertEqual(contact.topicsToAvoidArray.count, 1)
    }
}

