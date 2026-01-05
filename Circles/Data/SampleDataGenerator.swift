//
//  SampleDataGenerator.swift
//  Circles
//

import Foundation
import CoreData

/// Generates sample contact data for testing and development
struct SampleDataGenerator {
    
    /// Generate sample contacts for testing
    static func generateSampleContacts(count: Int = 10, in context: NSManagedObjectContext) async throws {
        let sampleNames = [
            ("Sarah", "Chen", "Friend"),
            ("Michael", "Rodriguez", "Colleague"),
            ("Emily", "Johnson", "Family"),
            ("David", "Kim", "Friend"),
            ("Jessica", "Martinez", "Colleague"),
            ("James", "Anderson", "Friend"),
            ("Lisa", "Taylor", "Family"),
            ("Robert", "Brown", "Colleague"),
            ("Jennifer", "Wilson", "Friend"),
            ("William", "Lee", "Acquaintance"),
            ("Maria", "Garcia", "Friend"),
            ("Daniel", "Davis", "Colleague"),
            ("Laura", "Thompson", "Family"),
            ("Christopher", "White", "Friend"),
            ("Amanda", "Harris", "Colleague")
        ]
        
        let interests = [
            ["hiking", "photography", "cooking"],
            ["gaming", "music", "tech"],
            ["reading", "yoga", "travel"],
            ["sports", "movies", "gardening"],
            ["art", "coffee", "cycling"]
        ]
        
        for i in 0..<min(count, sampleNames.count) {
            let (firstName, lastName, relationshipType) = sampleNames[i]
            let name = "\(firstName) \(lastName)"
            
            let contact = Contact(context: context)
            contact.id = UUID()
            contact.name = name
            contact.relationshipType = relationshipType
            
            // Vary last connected dates for testing
            let daysAgo = [2, 5, 15, 25, 35, 50, 75, 100, 120][i % 9]
            contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())
            
            // Add some interests
            contact.interests = interests[i % interests.count] as NSArray
            
            // Add birthday for some contacts
            if i % 3 == 0 {
                let birthday = Calendar.current.date(byAdding: .year, value: -25 - i, to: Date())
                contact.birthday = birthday
            }
            
            // Note: Additional fields like notes, jobTitle, company will be added in Prompt 5
        }
        
        try context.save()
    }
    
    /// Clear all sample data
    static func clearAllContacts(in context: NSManagedObjectContext) async throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Contact.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()
    }
}

