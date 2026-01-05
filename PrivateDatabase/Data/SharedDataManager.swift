//
//  SharedDataManager.swift
//  Circles
//

import Foundation
import CoreData

/// Manages shared data access for widgets and app extensions
/// Uses App Groups to share data between main app and extensions
class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let appGroupIdentifier = "group.com.circles.app"
    private let userDefaults: UserDefaults?
    
    // MARK: - Initialization
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Widget Data
    
    /// Fetches contacts that need attention for widget display
    func getContactsNeedingAttentionForWidget(limit: Int = 5) -> [WidgetContact] {
        guard let url = getSharedContainerURL() else { return [] }
        
        // Create a separate persistent container for shared access
        let container = NSPersistentCloudKitContainer(name: "CirclesDataModel")
        
        let storeDescription = NSPersistentStoreDescription(url: url)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        var contacts: [WidgetContact] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Failed to load shared store: \(error)")
                semaphore.signal()
                return
            }
            
            let context = container.viewContext
            let request = Contact.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.lastConnectedDate, ascending: true)]
            request.fetchLimit = limit
            
            do {
                let results = try context.fetch(request)
                contacts = results.compactMap { contact in
                    guard let name = contact.name,
                          let id = contact.id else { return nil }
                    
                    let daysSince = Calendar.current.dateComponents(
                        [.day],
                        from: contact.lastConnectedDate ?? Date(),
                        to: Date()
                    ).day ?? 0
                    
                    return WidgetContact(
                        id: id,
                        name: name,
                        daysSinceLastContact: daysSince,
                        relationshipType: contact.relationshipType ?? "Contact"
                    )
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        return contacts
    }
    
    /// Saves widget refresh timestamp
    func updateWidgetRefreshTime() {
        userDefaults?.set(Date(), forKey: "lastWidgetRefresh")
    }
    
    /// Gets last widget refresh time
    func getLastWidgetRefreshTime() -> Date? {
        userDefaults?.object(forKey: "lastWidgetRefresh") as? Date
    }
    
    // MARK: - Helpers
    
    private func getSharedContainerURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("Failed to get shared container URL")
            return nil
        }
        
        return containerURL.appendingPathComponent("CirclesDataModel.sqlite")
    }
}

// MARK: - Widget Contact Model

struct WidgetContact: Codable, Identifiable {
    let id: UUID
    let name: String
    let daysSinceLastContact: Int
    let relationshipType: String
    
    var urgencyLevel: String {
        switch daysSinceLastContact {
        case 0..<7: return "low"
        case 7..<30: return "medium"
        case 30..<60: return "high"
        default: return "critical"
        }
    }
}

