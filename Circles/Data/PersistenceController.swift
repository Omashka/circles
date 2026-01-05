//
//  PersistenceController.swift
//  Circles
//

import CoreData
import CloudKit
import os.log

/// Manages Core Data stack with CloudKit synchronization
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    private let logger = Logger(subsystem: "com.circles.app", category: "Persistence")
    
    // MARK: - Initialization
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "CirclesDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure for CloudKit sync
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description")
            }
            
            // Enable persistent history tracking for CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // CloudKit container options
            let cloudKitOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: Config.containerIdentifier
            )
            description.cloudKitContainerOptions = cloudKitOptions
        }
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                self?.logger.error("Failed to load persistent store: \(error.localizedDescription)")
                // In production, handle this more gracefully
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            self?.logger.info("Persistent store loaded successfully")
        }
        
        // Set up automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Observe remote change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }
    
    // MARK: - Context Management
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    // MARK: - Save Operations
    
    func save(context: NSManagedObjectContext? = nil) throws {
        let contextToSave = context ?? viewContext
        
        if contextToSave.hasChanges {
            do {
                try contextToSave.save()
                logger.info("Context saved successfully")
            } catch {
                logger.error("Failed to save context: \(error.localizedDescription)")
                throw PersistenceError.saveFailed(error)
            }
        }
    }
    
    // MARK: - CloudKit Sync Notifications
    
    @objc private func storeRemoteChange(_ notification: Notification) {
        logger.info("Remote change detected, refreshing view context")
        viewContext.perform {
            self.viewContext.refreshAllObjects()
        }
    }
    
    // MARK: - Preview Support
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample data for previews
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "John Doe"
        contact.relationshipType = "Friend"
        contact.lastConnectedDate = Date()
        contact.createdAt = Date()
        contact.modifiedAt = Date()
        
        let interaction = Interaction(context: viewContext)
        interaction.id = UUID()
        interaction.content = "Had coffee and caught up"
        interaction.interactionDate = Date()
        interaction.source = "manual"
        interaction.createdAt = Date()
        interaction.contact = contact
        
        do {
            try viewContext.save()
        } catch {
            fatalError("Failed to create preview data: \(error.localizedDescription)")
        }
        
        return controller
    }()
}

// MARK: - Persistence Errors

enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        }
    }
}
