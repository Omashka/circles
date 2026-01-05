//
//  DebugHelpers.swift
//  Circles
//

import SwiftUI
import CoreData

/// Debug helpers for development and testing
#if DEBUG
struct DebugHelpers {
    /// Add sample contacts for testing
    @MainActor
    static func addSampleContactsIfNeeded() async {
        let context = PersistenceController.shared.viewContext
        
        // Check if we already have contacts
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        let count = (try? context.count(for: fetchRequest)) ?? 0
        
        if count == 0 {
            do {
                try await SampleDataGenerator.generateSampleContacts(count: 15, in: context)
                print("✅ Generated 15 sample contacts")
            } catch {
                print("❌ Failed to generate sample contacts: \(error)")
            }
        }
    }
}
#endif

