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
            ["Passionate about women in tech mentorship", "loves reading biographies"],
            ["Gaming", "music", "tech"],
            ["Reading", "yoga", "travel"],
            ["Sports", "movies", "gardening"],
            ["Art", "coffee", "cycling"]
        ]
        
        let jobInfo = [
            "Former VP at Google, now angel investor",
            "Senior Software Engineer at Apple",
            "Marketing Director at Nike",
            "Product Manager at Microsoft",
            "Design Lead at Airbnb",
            "Data Scientist at Netflix",
            "Engineering Manager at Meta",
            "Business Development at Stripe"
        ]
        
        let preferences = [
            "Prefers early morning meetings, before 9am. Tea over coffee.",
            "Likes to be contacted via email, not text.",
            "Prefers video calls over phone calls.",
            "Available for meetings after 2pm only.",
            "Prefers in-person meetings when possible.",
            "Likes to schedule meetings at least a week in advance.",
            "Prefers coffee meetings over lunch.",
            "Available mornings only, before noon."
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
            contact.createdAt = Date()
            contact.modifiedAt = Date()
            
            // Add interests
            contact.interests = interests[i % interests.count] as NSArray
            
            // Add job info
            contact.jobInfo = jobInfo[i % jobInfo.count]
            
            // Add preferences (using topicsToAvoid field)
            contact.topicsToAvoid = [preferences[i % preferences.count]] as NSArray
            
            // Add birthday for some contacts
            if i % 3 == 0 {
                let birthday = Calendar.current.date(byAdding: .year, value: -25 - i, to: Date())
                contact.birthday = birthday
            }
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

