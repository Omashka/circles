//
//  CloudKitSyncMonitor.swift
//  Circles
//

import Foundation
import CoreData
import Combine
import os.log

/// Monitors CloudKit sync status and provides error handling
@MainActor
class CloudKitSyncMonitor: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var lastError: Error?
    
    private let persistence: PersistenceController
    private let logger = Logger(subsystem: "com.circles.app", category: "CloudKitSync")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        setupNotificationObservers()
    }
    
    // MARK: - Sync Monitoring
    
    private func setupNotificationObservers() {
        // Observe CloudKit import notifications
        NotificationCenter.default
            .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
        
        // Observe store remote change notifications
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.lastSyncTime = Date()
                    self.logger.info("Remote changes detected")
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        Task { @MainActor in
            switch event.type {
            case .setup:
                self.logger.info("CloudKit setup event")
                
            case .import:
                self.syncStatus = .syncing
                self.logger.info("CloudKit import started")
                
            case .export:
                self.syncStatus = .syncing
                self.logger.info("CloudKit export started")
                
            @unknown default:
                break
            }
            
            // Check for errors
            if let error = event.error {
                self.handleSyncError(error)
            } else if event.endDate != nil {
                self.syncStatus = .success
                self.lastSyncTime = event.endDate
                self.logger.info("CloudKit sync completed successfully")
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleSyncError(_ error: Error) {
        self.syncStatus = .error
        self.lastError = error
        
        let nsError = error as NSError
        
        switch nsError.code {
        case 134400: // CKAccountStatusNoAccount
            logger.error("CloudKit error: No iCloud account signed in")
            
        case 134410: // CKAccountStatusRestricted
            logger.error("CloudKit error: iCloud account restricted")
            
        case 134401: // Network unavailable
            logger.error("CloudKit error: Network unavailable")
            
        case 134409: // Quota exceeded
            logger.error("CloudKit error: iCloud storage quota exceeded")
            
        default:
            logger.error("CloudKit sync error: \(error.localizedDescription)")
        }
    }
    
    /// Manually trigger sync (for testing or user-initiated sync)
    func triggerSync() {
        logger.info("Manual sync triggered")
        syncStatus = .syncing
        
        // Force CloudKit to check for changes
        persistence.viewContext.refreshAllObjects()
    }
    
    /// Check if CloudKit is available and account is signed in
    func checkCloudKitStatus() async -> CloudKitAccountStatus {
        // This would normally use CKContainer.accountStatus()
        // For now, we'll check based on recent errors
        if let error = lastError as? NSError {
            if error.code == 134400 {
                return .noAccount
            } else if error.code == 134410 {
                return .restricted
            }
        }
        
        return .available
    }
}

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error
    
    var description: String {
        switch self {
        case .idle: return "Idle"
        case .syncing: return "Syncing..."
        case .success: return "Synced"
        case .error: return "Sync Error"
        }
    }
    
    var systemImage: String {
        switch self {
        case .idle: return "icloud"
        case .syncing: return "icloud.and.arrow.up.fill"
        case .success: return "icloud.fill"
        case .error: return "icloud.slash"
        }
    }
}

enum CloudKitAccountStatus {
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    
    var message: String {
        switch self {
        case .available:
            return "iCloud available"
        case .noAccount:
            return "No iCloud account. Sign in to Settings to enable sync."
        case .restricted:
            return "iCloud access restricted."
        case .couldNotDetermine:
            return "Could not determine iCloud status."
        }
    }
}

