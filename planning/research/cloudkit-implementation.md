# CloudKit Implementation for Relationship Management App

## Overview
CloudKit provides encrypted cloud storage with automatic sync across Apple devices, making it ideal for the Circles app's privacy-focused relationship data.

## CloudKit Architecture

### Container Types
- **Private Database**: User's personal data (contacts, notes, interactions)
- **Public Database**: Not needed for this app
- **Shared Database**: Future feature for sharing specific contacts

### For Circles App
Use **Private Database exclusively** for MVP:
- Maximum privacy
- Automatic encryption
- Per-user data isolation
- No server-side code required

## Data Model Design

### Core Entities

#### 1. Contact (CKRecord)
```swift
recordType: "Contact"
fields:
- name: String
- relationshipType: String  
- profilePhotoAsset: CKAsset?
- birthday: Date?
- familyDetails: String?
- interests: [String]?
- jobInfo: String?
- religiousEvents: [String]?
- travelNotes: String?
- topicsToAvoid: [String]?
- lastConnected: Date
- createdAt: Date
- modifiedAt: Date
```

#### 2. Interaction (CKRecord)
```swift
recordType: "Interaction"
fields:
- contactReference: CKRecord.Reference (to Contact)
- content: String (AI summary)
- interactionDate: Date
- source: String ("voice_note", "shortcut_import", "manual")
- createdAt: Date
```

#### 3. Connection (CKRecord)
```swift
recordType: "Connection"
fields:
- fromContact: CKRecord.Reference (to Contact)
- toContact: CKRecord.Reference (to Contact)
- connectionType: String ("sibling", "friend", "colleague", etc.)
- context: String ("met through Sarah, 2019")
- introducedBy: CKRecord.Reference? (to Contact)
- dateEstablished: Date?
- createdAt: Date
```

#### 4. UnassignedNote (CKRecord)
```swift
recordType: "UnassignedNote"
fields:
- content: String
- source: String
- createdAt: Date
```

#### 5. UserSettings (CKRecord)
```swift
recordType: "UserSettings"
fields:
- defaultReminderInterval: Int (days)
- relationshipTypeReminders: [String: Int] // type: days
- notificationsEnabled: Bool
- lastSyncDate: Date
```

## CloudKit Best Practices

### 1. Record Zones
```swift
// Create custom zone for atomic commits
let zone = CKRecordZone(zoneName: "CirclesZone")
let zoneID = zone.zoneID

// Allows for:
// - Batch operations
// - Change tracking
// - Better sync performance
```

### 2. References and Relationships
```swift
// Forward reference (Contact → Interactions)
let contactRef = CKRecord.Reference(
    recordID: contact.recordID,
    action: .deleteSelf  // Cascade delete
)
interaction["contactReference"] = contactRef

// Query interactions for a contact
let predicate = NSPredicate(
    format: "contactReference == %@",
    contactRef
)
```

### 3. Assets for Photos
```swift
// Store profile photos as CKAssets
let imageURL = // local file URL
let asset = CKAsset(fileURL: imageURL)
contact["profilePhotoAsset"] = asset

// CloudKit handles upload/download automatically
// Caches locally for performance
```

### 4. Change Tracking
```swift
// Use CKFetchRecordZoneChangesOperation
// for efficient delta sync
let operation = CKFetchRecordZoneChangesOperation(
    recordZoneIDs: [zoneID],
    configurationsByRecordZoneID: [zoneID: config]
)

// Provides:
// - Only changed records since last sync
// - Deleted record IDs  
// - Server change token for next fetch
```

## Sync Strategy

### Initial Sync
1. Check if CloudKit account available
2. Create custom zone if doesn't exist
3. Fetch all records from server
4. Store locally in Core Data (cache)
5. Save server change token

### Ongoing Sync
```swift
// On app launch
func syncWithCloud() async throws {
    // 1. Push local changes to CloudKit
    try await pushLocalChanges()
    
    // 2. Fetch changes from CloudKit
    try await fetchRemoteChanges()
    
    // 3. Resolve conflicts if any
    try await resolveConflicts()
}
```

### Conflict Resolution
```swift
// CloudKit provides both versions
switch conflict.resolution {
case .keepServer:
    // Server wins
case .keepClient:
    // Client wins
case .custom(let record):
    // Merge manually based on timestamps
    let merged = mergeRecords(
        server: conflict.serverRecord,
        client: conflict.clientRecord
    )
}
```

### Offline Support ("Soft Offline")
```swift
// Local Core Data cache
class DataManager {
    let container: NSPersistentContainer
    let cloudContainer: CKContainer
    
    // All reads from Core Data
    func fetchContacts() -> [Contact] {
        // Return local cache immediately
    }
    
    // Writes go to both
    func saveContact(_ contact: Contact) {
        // 1. Save to Core Data
        // 2. Queue for CloudKit upload
        // 3. Upload when network available
    }
}
```

## Error Handling

### Common CloudKit Errors
```swift
switch error.code {
case .notAuthenticated:
    // User not signed into iCloud
    // Show banner: "Sign in to iCloud to sync"
    
case .networkUnavailable:
    // No internet connection
    // Queue changes locally, retry later
    
case .quotaExceeded:
    // User's iCloud storage full
    // Show alert with suggestions
    
case .serverRejectedRequest:
    // Rate limited or server issue
    // Exponential backoff retry
    
case .zoneNotFound:
    // Create zone
    try await createCustomZone()
}
```

### Retry Strategy
```swift
func uploadWithRetry(
    _ record: CKRecord,
    maxRetries: Int = 3
) async throws {
    var retries = 0
    var delay: TimeInterval = 1.0
    
    while retries < maxRetries {
        do {
            return try await database.save(record)
        } catch {
            retries += 1
            try await Task.sleep(for: .seconds(delay))
            delay *= 2  // Exponential backoff
        }
    }
    throw CloudKitError.maxRetriesExceeded
}
```

## Privacy and Security

### Data Encryption
- CloudKit encrypts data at rest
- Encrypted in transit (HTTPS)
- Private database only accessible by user
- Apple cannot read user data

### Photo Privacy
```swift
// Photos stored as CKAssets
// Encrypted by CloudKit
// Only accessible with user's iCloud account
// Automatically synced but private
```

### Access Control
```swift
// Private database - no sharing needed for MVP
// User must be signed into iCloud
// Automatic authentication via device

// Future: CKShare for sharing specific contacts
```

## Performance Optimization

### 1. Batch Operations
```swift
// Save multiple records in one operation
let operation = CKModifyRecordsOperation(
    recordsToSave: contacts,
    recordIDsToDelete: nil
)

// More efficient than individual saves
// Atomic - all succeed or all fail
```

### 2. Selective Fetching
```swift
// Only fetch needed fields
let query = CKQuery(
    recordType: "Contact",
    predicate: predicate
)
query.desiredKeys = ["name", "relationshipType"]
// Don't fetch large assets if not needed
```

### 3. Query Pagination
```swift
// Limit results for large datasets
let query = CKQuery(/* ... */)
let operation = CKQueryOperation(query: query)
operation.resultsLimit = 50

// Fetch more with cursor
operation.recordFetchedBlock = { record in
    // Process record
}
operation.cursor = cursor  // For next page
```

### 4. Local Caching
```swift
// Core Data as local cache
// Fast reads, no network needed
// Sync in background

// Relationship handling
@Published var contacts: [Contact] = []

// Load from Core Data immediately
func loadCachedContacts() {
    contacts = fetchFromCoreData()
}

// Sync with CloudKit in background
Task {
    try await syncWithCloudKit()
}
```

## Subscription and Push Notifications

### Database Subscriptions
```swift
// Get notified of remote changes
let subscription = CKQuerySubscription(
    recordType: "Contact",
    predicate: NSPredicate(value: true),
    subscriptionID: "contact-changes"
)

// Silent push notifications
subscription.notificationInfo = CKSubscription.NotificationInfo()
subscription.notificationInfo?.shouldSendContentAvailable = true

// App refreshes data in background
```

### Implementation
```swift
// AppDelegate
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any]
) async -> UIBackgroundFetchResult {
    // CloudKit notified of changes
    try? await dataManager.syncWithCloud()
    return .newData
}
```

## Testing Strategy

### 1. Development Environment
```swift
// Use development container for testing
let container = CKContainer(
    identifier: "iCloud.com.yourapp.circles"
)
let database = container.privateCloudDatabase

// Separate from production data
```

### 2. Simulator Testing
- CloudKit works in simulator
- Sign in with test Apple ID
- Data separate from production

### 3. Test Scenarios
- [ ] Create contact with photo
- [ ] Sync across two devices
- [ ] Offline edits, then sync
- [ ] Conflict resolution
- [ ] Account not available handling
- [ ] Network failure recovery
- [ ] Large dataset performance (500+ contacts)

## CloudKit Entitlements

### Xcode Configuration
```xml
<!-- Circles.entitlements -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.yourapp.circles</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### CloudKit Dashboard
1. Navigate to CloudKit Dashboard
2. Create schema for record types
3. Add indexes for queries
4. Configure security roles
5. Enable development/production environments

## Core Data + CloudKit Integration

### NSPersistentCloudKitContainer
```swift
// Simplified approach - automatic sync
let container = NSPersistentCloudKitContainer(name: "Circles")
container.loadPersistentStores { description, error in
    if let error = error {
        fatalError("Core Data failed: \(error)")
    }
}

// Automatically syncs Core Data with CloudKit
// Handles conflicts, push/pull
// Minimal code required
```

### Pros of NSPersistentCloudKitContainer
- Automatic CloudKit sync
- Built-in conflict resolution
- Less boilerplate code
- Core Data query performance
- Offline-first by design

### Cons
- Less control over sync
- Harder to debug sync issues
- Schema changes can be tricky

### Recommendation
**Use NSPersistentCloudKitContainer** for MVP:
- Faster development
- Proven solution
- Apple-supported
- Handles edge cases

## Implementation Checklist

- [ ] Enable CloudKit capability in Xcode
- [ ] Create CloudKit container in dashboard
- [ ] Define Core Data model
- [ ] Set up NSPersistentCloudKitContainer
- [ ] Implement error handling
- [ ] Add iCloud account check
- [ ] Test multi-device sync
- [ ] Handle photo assets
- [ ] Implement offline queueing
- [ ] Add sync status UI
- [ ] Test conflict scenarios

## Key Takeaways

1. **Use NSPersistentCloudKitContainer**: Simplifies everything
2. **Private Database Only**: Maximum privacy, no backend
3. **Core Data Cache**: Fast reads, offline support
4. **Handle Errors Gracefully**: Network issues common
5. **Test Multi-Device**: Sync is the hard part
6. **Assets for Photos**: Efficient binary storage
7. **Custom Zone**: Better sync performance
8. **Background Sync**: Silent push notifications

## Resources

- [Apple CloudKit Documentation](https://developer.apple.com/icloud/cloudkit/)
- [NSPersistentCloudKitContainer Guide](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [CloudKit Best Practices WWDC](https://developer.apple.com/videos/play/wwdc2021/10086/)
- [Core Data with CloudKit Tutorial](https://www.raywenderlich.com/4878052-cloudkit-tutorial-getting-started)
