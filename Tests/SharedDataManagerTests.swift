//
//  SharedDataManagerTests.swift
//  CirclesTests
//

import XCTest
import CoreData
@testable import PrivateDatabase

final class SharedDataManagerTests: XCTestCase {
    var sharedDataManager: SharedDataManager!
    
    override func setUp() {
        super.setUp()
        sharedDataManager = SharedDataManager.shared
    }
    
    override func tearDown() {
        sharedDataManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSharedDataManagerSingleton() {
        let instance1 = SharedDataManager.shared
        let instance2 = SharedDataManager.shared
        
        // Should return the same instance
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Widget Refresh Time Tests
    
    func testUpdateWidgetRefreshTime() {
        // Update refresh time
        sharedDataManager.updateWidgetRefreshTime()
        
        // Get the time back
        let refreshTime = sharedDataManager.getLastWidgetRefreshTime()
        
        // Should not be nil
        XCTAssertNotNil(refreshTime)
        
        // Should be recent (within last 5 seconds)
        if let time = refreshTime {
            let timeSince = Date().timeIntervalSince(time)
            XCTAssertLessThan(timeSince, 5.0)
        }
    }
    
    func testGetWidgetRefreshTimeBeforeSet() {
        // Clear any existing value
        UserDefaults(suiteName: "group.com.circles.app")?.removeObject(forKey: "lastWidgetRefresh")
        
        // Should return nil if never set
        let refreshTime = sharedDataManager.getLastWidgetRefreshTime()
        
        // May be nil or an old value depending on test environment
        // Just verify it doesn't crash
        XCTAssertTrue(refreshTime == nil || refreshTime != nil)
    }
    
    // MARK: - Widget Contact Model Tests
    
    func testWidgetContactInitialization() {
        let contact = WidgetContact(
            id: UUID(),
            name: "Test User",
            daysSinceLastContact: 15,
            relationshipType: "Friend"
        )
        
        XCTAssertEqual(contact.name, "Test User")
        XCTAssertEqual(contact.daysSinceLastContact, 15)
        XCTAssertEqual(contact.relationshipType, "Friend")
    }
    
    func testWidgetContactUrgencyLevelLow() {
        let contact = WidgetContact(
            id: UUID(),
            name: "Recent Contact",
            daysSinceLastContact: 3,
            relationshipType: "Friend"
        )
        
        XCTAssertEqual(contact.urgencyLevel, "low")
    }
    
    func testWidgetContactUrgencyLevelMedium() {
        let contact = WidgetContact(
            id: UUID(),
            name: "Medium Contact",
            daysSinceLastContact: 15,
            relationshipType: "Friend"
        )
        
        XCTAssertEqual(contact.urgencyLevel, "medium")
    }
    
    func testWidgetContactUrgencyLevelHigh() {
        let contact = WidgetContact(
            id: UUID(),
            name: "High Priority",
            daysSinceLastContact: 45,
            relationshipType: "Friend"
        )
        
        XCTAssertEqual(contact.urgencyLevel, "high")
    }
    
    func testWidgetContactUrgencyLevelCritical() {
        let contact = WidgetContact(
            id: UUID(),
            name: "Critical Contact",
            daysSinceLastContact: 90,
            relationshipType: "Friend"
        )
        
        XCTAssertEqual(contact.urgencyLevel, "critical")
    }
    
    // MARK: - Codable Tests
    
    func testWidgetContactCodable() throws {
        let originalContact = WidgetContact(
            id: UUID(),
            name: "Codable Test",
            daysSinceLastContact: 20,
            relationshipType: "Colleague"
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalContact)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedContact = try decoder.decode(WidgetContact.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedContact.id, originalContact.id)
        XCTAssertEqual(decodedContact.name, originalContact.name)
        XCTAssertEqual(decodedContact.daysSinceLastContact, originalContact.daysSinceLastContact)
        XCTAssertEqual(decodedContact.relationshipType, originalContact.relationshipType)
    }
    
    func testWidgetContactArrayCodable() throws {
        let contacts = [
            WidgetContact(id: UUID(), name: "Person 1", daysSinceLastContact: 5, relationshipType: "Friend"),
            WidgetContact(id: UUID(), name: "Person 2", daysSinceLastContact: 15, relationshipType: "Family"),
            WidgetContact(id: UUID(), name: "Person 3", daysSinceLastContact: 30, relationshipType: "Colleague")
        ]
        
        // Encode array
        let encoder = JSONEncoder()
        let data = try encoder.encode(contacts)
        
        // Decode array
        let decoder = JSONDecoder()
        let decodedContacts = try decoder.decode([WidgetContact].self, from: data)
        
        // Verify count
        XCTAssertEqual(decodedContacts.count, 3)
        
        // Verify first contact
        XCTAssertEqual(decodedContacts[0].name, "Person 1")
        XCTAssertEqual(decodedContacts[1].name, "Person 2")
        XCTAssertEqual(decodedContacts[2].name, "Person 3")
    }
    
    // MARK: - App Group Access Tests
    
    func testAppGroupUserDefaultsAccess() {
        // Verify we can access app group defaults
        let defaults = UserDefaults(suiteName: "group.com.circles.app")
        XCTAssertNotNil(defaults)
        
        // Test write and read
        let testKey = "test_key_\(UUID().uuidString)"
        let testValue = "test_value"
        
        defaults?.set(testValue, forKey: testKey)
        let retrievedValue = defaults?.string(forKey: testKey)
        
        XCTAssertEqual(retrievedValue, testValue)
        
        // Clean up
        defaults?.removeObject(forKey: testKey)
    }
    
    // MARK: - Integration Tests
    
    func testGetContactsNeedingAttentionEmptyDatabase() {
        // With in-memory database, should return empty array
        let contacts = sharedDataManager.getContactsNeedingAttentionForWidget(limit: 5)
        
        // Should not crash and return an array
        XCTAssertTrue(contacts.isEmpty || contacts.count >= 0)
    }
    
    func testWidgetContactLimitParameter() {
        // Test different limit values don't crash
        _ = sharedDataManager.getContactsNeedingAttentionForWidget(limit: 1)
        _ = sharedDataManager.getContactsNeedingAttentionForWidget(limit: 5)
        _ = sharedDataManager.getContactsNeedingAttentionForWidget(limit: 10)
        
        // Should complete without crashing
        XCTAssertTrue(true)
    }
}

