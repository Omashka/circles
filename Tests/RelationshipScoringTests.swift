//
//  RelationshipScoringTests.swift
//  CirclesTests
//

import XCTest
import CoreData
@testable import Circles

final class RelationshipScoringTests: XCTestCase {
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
    
    // MARK: - Relationship Score Tests
    
    func testRelationshipScore_RecentContact_HighScore() {
        // Given: Contact connected today
        let contact = createContact(name: "Recent Friend")
        contact.lastConnectedDate = Date()
        
        // When: Calculate relationship score
        let score = contact.relationshipScore
        
        // Then: Score should be high (close to 1.0)
        XCTAssertGreaterThan(score, 0.9, "Recent contact should have high relationship score")
    }
    
    func testRelationshipScore_OldContact_LowScore() {
        // Given: Contact connected 100 days ago
        let contact = createContact(name: "Old Friend")
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())
        
        // When: Calculate relationship score
        let score = contact.relationshipScore
        
        // Then: Score should be low
        XCTAssertLessThan(score, 0.3, "Old contact should have low relationship score")
    }
    
    func testRelationshipScore_ManyInteractions_HigherScore() {
        // Given: Contact with many interactions
        let contact = createContact(name: "Frequent Contact")
        contact.lastConnectedDate = Date()
        
        // Add 30 interactions
        for i in 0..<30 {
            let interaction = Interaction(context: viewContext)
            interaction.id = UUID()
            interaction.contact = contact
            interaction.interactionDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            interaction.content = "Interaction \(i)"
        }
        
        // When: Calculate relationship score
        let score = contact.relationshipScore
        
        // Then: Score should be higher than contact with few interactions
        XCTAssertGreaterThan(score, 0.5, "Contact with many interactions should have higher score")
    }
    
    func testRelationshipScore_RecencyWeighted() {
        // Given: Two contacts - one recent with few interactions, one old with many interactions
        let recentContact = createContact(name: "Recent")
        recentContact.lastConnectedDate = Date()
        addInteractions(to: recentContact, count: 5)
        
        let oldContact = createContact(name: "Old")
        oldContact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())
        addInteractions(to: oldContact, count: 30)
        
        // When: Calculate relationship scores
        let recentScore = recentContact.relationshipScore
        let oldScore = oldContact.relationshipScore
        
        // Then: Recent contact should have higher score (recency weighted 70%)
        XCTAssertGreaterThan(recentScore, oldScore, "Recent contact should score higher due to recency weighting")
    }
    
    func testRelationshipScore_ZeroInteractions_StillHasScore() {
        // Given: Contact with no interactions but recent connection
        let contact = createContact(name: "New Contact")
        contact.lastConnectedDate = Date()
        
        // When: Calculate relationship score
        let score = contact.relationshipScore
        
        // Then: Should still have a score based on recency
        XCTAssertGreaterThan(score, 0.0, "Contact should have score even with no interactions")
        XCTAssertLessThan(score, 1.0, "Score should be less than 1.0 without interactions")
    }
    
    func testRelationshipScore_90DaysAgo_ZeroRecencyScore() {
        // Given: Contact connected exactly 90 days ago
        let contact = createContact(name: "90 Days")
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        
        // When: Calculate relationship score
        let score = contact.relationshipScore
        
        // Then: Recency component should be 0, but frequency component may contribute
        // Score should be low but not necessarily zero if there are interactions
        XCTAssertLessThan(score, 0.5, "Contact 90 days ago should have low score")
    }
    
    func testRelationshipScore_50Interactions_MaxFrequencyScore() {
        // Given: Contact with exactly 50 interactions
        let contact = createContact(name: "50 Interactions")
        contact.lastConnectedDate = Date()
        addInteractions(to: contact, count: 50)
        
        // When: Calculate relationship score
        let score = contact.relationshipScore
        
        // Then: Frequency component should be 1.0, combined with recency should be high
        XCTAssertGreaterThan(score, 0.9, "Contact with 50 interactions should have very high score")
    }
    
    // MARK: - Urgency Level Tests
    
    func testUrgencyLevel_Recent_Low() {
        let contact = createContact(name: "Recent")
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        
        XCTAssertEqual(contact.urgencyLevel, .low)
    }
    
    func testUrgencyLevel_Medium() {
        let contact = createContact(name: "Medium")
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        
        XCTAssertEqual(contact.urgencyLevel, .medium)
    }
    
    func testUrgencyLevel_High() {
        let contact = createContact(name: "High")
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())
        
        XCTAssertEqual(contact.urgencyLevel, .high)
    }
    
    func testUrgencyLevel_Critical() {
        let contact = createContact(name: "Critical")
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        
        XCTAssertEqual(contact.urgencyLevel, .critical)
    }
    
    // MARK: - Helper Methods
    
    private func createContact(name: String) -> Contact {
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = name
        contact.createdAt = Date()
        contact.lastConnectedDate = Date()
        return contact
    }
    
    private func addInteractions(to contact: Contact, count: Int) {
        for i in 0..<count {
            let interaction = Interaction(context: viewContext)
            interaction.id = UUID()
            interaction.contact = contact
            interaction.interactionDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            interaction.content = "Interaction \(i)"
            interaction.source = "manual"
        }
    }
}

