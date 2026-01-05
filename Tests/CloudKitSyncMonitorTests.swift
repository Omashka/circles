//
//  CloudKitSyncMonitorTests.swift
//  CirclesTests
//

import XCTest
import CoreData
import Combine
@testable import PrivateDatabase

@MainActor
final class CloudKitSyncMonitorTests: XCTestCase {
    var persistence: PersistenceController!
    var syncMonitor: CloudKitSyncMonitor!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        persistence = PersistenceController(inMemory: true)
        syncMonitor = CloudKitSyncMonitor(persistence: persistence)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        syncMonitor = nil
        persistence = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialSyncStatus() {
        XCTAssertEqual(syncMonitor.syncStatus, .idle)
        XCTAssertNil(syncMonitor.lastSyncTime)
        XCTAssertNil(syncMonitor.lastError)
    }
    
    // MARK: - Sync Status Tests
    
    func testSyncStatusDescriptions() {
        XCTAssertEqual(SyncStatus.idle.description, "Idle")
        XCTAssertEqual(SyncStatus.syncing.description, "Syncing...")
        XCTAssertEqual(SyncStatus.success.description, "Synced")
        XCTAssertEqual(SyncStatus.error.description, "Sync Error")
    }
    
    func testSyncStatusSystemImages() {
        XCTAssertEqual(SyncStatus.idle.systemImage, "icloud")
        XCTAssertEqual(SyncStatus.syncing.systemImage, "icloud.and.arrow.up.fill")
        XCTAssertEqual(SyncStatus.success.systemImage, "icloud.fill")
        XCTAssertEqual(SyncStatus.error.systemImage, "icloud.slash")
    }
    
    // MARK: - Trigger Sync Tests
    
    func testTriggerSync() async {
        // Initially idle
        XCTAssertEqual(syncMonitor.syncStatus, .idle)
        
        // Trigger sync
        syncMonitor.triggerSync()
        
        // Should be syncing
        XCTAssertEqual(syncMonitor.syncStatus, .syncing)
    }
    
    // MARK: - CloudKit Account Status Tests
    
    func testCloudKitAccountStatusAvailable() async {
        let status = await syncMonitor.checkCloudKitStatus()
        
        // In test environment with in-memory store, should be available
        XCTAssertEqual(status, .available)
    }
    
    func testCloudKitAccountStatusMessages() {
        XCTAssertEqual(CloudKitAccountStatus.available.message, "iCloud available")
        XCTAssertTrue(CloudKitAccountStatus.noAccount.message.contains("No iCloud account"))
        XCTAssertTrue(CloudKitAccountStatus.restricted.message.contains("restricted"))
        XCTAssertTrue(CloudKitAccountStatus.couldNotDetermine.message.contains("Could not determine"))
    }
    
    // MARK: - Published Property Tests
    
    func testSyncStatusPublisher() {
        let expectation = XCTestExpectation(description: "Sync status changes")
        var receivedStatuses: [SyncStatus] = []
        
        syncMonitor.$syncStatus
            .sink { status in
                receivedStatuses.append(status)
                if receivedStatuses.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger a status change
        syncMonitor.triggerSync()
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(receivedStatuses.count, 2)
        XCTAssertEqual(receivedStatuses[0], .idle) // Initial value
        XCTAssertEqual(receivedStatuses[1], .syncing) // After trigger
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingNoAccount() async {
        // Create a mock error for no account
        let error = NSError(domain: NSCocoaErrorDomain, code: 134400, userInfo: [
            NSLocalizedFailureReasonErrorKey: "No iCloud account"
        ])
        
        // Simulate error by setting it
        syncMonitor.lastError = error
        
        let status = await syncMonitor.checkCloudKitStatus()
        XCTAssertEqual(status, .noAccount)
    }
    
    func testErrorHandlingRestricted() async {
        // Create a mock error for restricted account
        let error = NSError(domain: NSCocoaErrorDomain, code: 134410, userInfo: [
            NSLocalizedFailureReasonErrorKey: "Account restricted"
        ])
        
        syncMonitor.lastError = error
        
        let status = await syncMonitor.checkCloudKitStatus()
        XCTAssertEqual(status, .restricted)
    }
    
    // MARK: - Integration Tests
    
    func testSyncMonitorWithPersistenceController() {
        // Verify sync monitor has access to persistence controller
        XCTAssertNotNil(syncMonitor)
        
        // Trigger sync shouldn't crash
        syncMonitor.triggerSync()
        
        // Status should update
        XCTAssertEqual(syncMonitor.syncStatus, .syncing)
    }
    
    func testMultipleSyncTriggers() {
        // Trigger multiple syncs in succession
        syncMonitor.triggerSync()
        XCTAssertEqual(syncMonitor.syncStatus, .syncing)
        
        syncMonitor.triggerSync()
        XCTAssertEqual(syncMonitor.syncStatus, .syncing)
        
        // Should still be syncing (idempotent)
        XCTAssertEqual(syncMonitor.syncStatus, .syncing)
    }
}

