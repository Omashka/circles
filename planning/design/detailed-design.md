# Circles - Detailed Design Document

## Overview

Circles is an iOS relationship management app that helps users maintain meaningful connections with friends and family. The app provides a people-first interface, visual relationship mapping, AI-powered insights, and gentle reminders to stay in touch.

### Vision
Transform relationship management from a chore into a natural, low-friction activity that helps users maintain meaningful connections without guilt or pressure.

### Target Users
- Social butterflies managing large friend networks
- People who struggle to keep in touch with distant friends and family
- (Future) Professionals managing business relationships

### Platform
- **Primary**: iOS 16+
- **Technology**: Swift, SwiftUI
- **Design Language**: Glassmorphism (Apple's glass UI)

## Requirements Summary

### Core Features (MVP)

#### 1. Contact Management
- **People List**: Scrollable list showing all contacts with relationship indicators
- **Contact Profiles**: Detailed "cheat sheet" for each person
- **Search**: Find contacts quickly by name
- **Relationship Types**: Predefined categories (Family, Friend, Partner, Colleague, Acquaintance) + custom

#### 2. Relationship Visualization
- **Web View**: Force-directed graph showing connections between contacts
- **Connection Types**: Visual representation of relationships (sibling, friend, colleague, etc.)
- **Interactive**: Zoom, pan, drag nodes, tap connections for details

#### 3. Interaction Tracking
- **Voice Notes**: Record and transcribe notes about interactions (3-min limit)
- **AI Summarization**: Automatic extraction of interests, events, dates
- **Shortcuts Integration**: Import message screenshots via Back Tap
- **Timeline**: Chronological log of interactions per contact

#### 4. Reminders & Notifications
- **Check-in Reminders**: Automatic reminders after 1 month (configurable)
- **Relationship Meter**: Visual indicator of connection health (color-coded progress bar)
- **Birthday Alerts**: Upcoming important dates

#### 5. Widgets
- **Home Screen Widgets**: Show contacts needing attention
- **Quick Check-in**: Mark interaction from widget (iOS 17+)
- **Three Sizes**: Small (2 contacts), Medium (4), Large (8)

#### 6. AI Features
- **Gift Suggestions**: AI-powered gift ideas based on interests and context
- **Contact Detection**: Auto-identify contacts from imported messages
- **Information Extraction**: Parse dates, events, interests from conversations

### Premium Features (Monetization)
- **Unlimited Contacts**: Free tier limited to 20-30 contacts
- **Full Graph Visualization**: Premium-only feature
- **Advanced AI Features**: Gift suggestions, enhanced summarization
- **Priority Support**: Faster response times

### Deferred to Future Versions
- Calendar integration
- Photo timeline/gallery
- Data export
- Siri Shortcuts
- Backdating interactions
- Archive/hide contacts
- Shared contacts (collaboration)

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App                             │
│  ┌────────────┬────────────┬────────────┬──────────────┐  │
│  │  SwiftUI   │ SpriteKit  │  Speech    │  StoreKit 2  │  │
│  │    Views   │   Graph    │ Recognition│     IAP      │  │
│  └────────────┴────────────┴────────────┴──────────────┘  │
│  ┌────────────────────────────────────────────────────┐   │
│  │              View Models (ObservableObject)        │   │
│  └────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────┐   │
│  │                  Data Manager                      │   │
│  │         (Core Data + CloudKit Coordinator)         │   │
│  └────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────┐   │
│  │        NSPersistentCloudKitContainer               │   │
│  │  ┌──────────────┬──────────────┐                   │   │
│  │  │  Core Data   │   CloudKit   │                   │   │
│  │  │ (Local Cache)│ (Private DB) │                   │   │
│  │  └──────────────┴──────────────┘                   │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Cloudflare Workers (Backend)                   │
│  ┌────────────────────┬────────────────────────────────┐   │
│  │ /process-screenshot│  /summarize-voice-note         │   │
│  │ /generate-gifts    │  /detect-contact               │   │
│  └────────────────────┴────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│                    Gemini 2.5 API                           │
└─────────────────────────────────────────────────────────────┘
                           │
                           │
┌─────────────────────────────────────────────────────────────┐
│                Widget Extension (WidgetKit)                 │
│  ┌────────────────────────────────────────────────────┐   │
│  │          Timeline Provider                         │   │
│  │     (Reads from App Group Container)               │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Navigation Structure

```
TabView (Bottom Navigation)
├── People Tab (Default)
│   ├── NavigationStack
│   │   ├── Home Screen (List)
│   │   │   ├── Navigation Bar (Title + Settings)
│   │   │   ├── Search Bar
│   │   │   └── Contact List (LazyVStack)
│   │   │       └── ContactCard (tap → Detail)
│   │   └── Contact Detail
│   │       ├── Profile Section
│   │       ├── Relationship Meter
│   │       ├── Voice Note Button
│   │       ├── Gift Ideas Button
│   │       ├── Interaction Timeline
│   │       └── Edit Button
│   └── Floating Action Button (+)
│       └── Add Contact Sheet
│
├── Web Tab
│   ├── Graph View (SpriteKit)
│   │   ├── Contact Nodes
│   │   ├── Connection Edges
│   │   └── Zoom/Pan Controls
│   └── Tap Interactions
│       ├── Node → Contact Detail
│       └── Edge → Connection Sheet
│
└── Reminders Tab
    ├── Upcoming Reminders
    ├── Check-in Suggestions
    └── Birthday Alerts
```

### Data Flow

#### Voice Note Flow
```
User Records → Speech Recognition → Transcription
    → Cloudflare Worker → Gemini API → Summary + Extracted Info
    → User Edits → Save to Core Data → Sync to CloudKit
```

#### Screenshot Import Flow
```
User Takes Screenshot → Double Tap Back → Shortcut Runs
    → OCR Text Extraction → circles://import?text=...
    → App Receives URL → Send to Backend → Gemini Detects Contact
    → If Matched: Add to Contact Timeline
    → If Unmatched: Add to Inbox
    → Sync to CloudKit
```

#### CloudKit Sync Flow
```
User Creates/Edits Contact → Save to Core Data
    → NSPersistentCloudKitContainer → Automatic CloudKit Upload
    → Syncs to Other Devices → Updates Local Core Data
```

## Data Models

### Core Data Entities

#### Contact
```swift
@Entity
class Contact: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var relationshipType: String
    @NSManaged var profilePhotoData: Data?
    @NSManaged var birthday: Date?
    @NSManaged var familyDetails: String?
    @NSManaged var interests: [String]?
    @NSManaged var jobInfo: String?
    @NSManaged var religiousEvents: [String]?
    @NSManaged var travelNotes: String?
    @NSManaged var topicsToAvoid: [String]?
    @NSManaged var lastConnectedDate: Date
    @NSManaged var createdAt: Date
    @NSManaged var modifiedAt: Date
    
    // Relationships
    @NSManaged var interactions: Set<Interaction>
    @NSManaged var connectionsFrom: Set<Connection>
    @NSManaged var connectionsTo: Set<Connection>
    
    // Computed
    var daysSinceLastContact: Int {
        Calendar.current.dateComponents(
            [.day],
            from: lastConnectedDate,
            to: Date()
        ).day ?? 0
    }
    
    var relationshipScore: Double {
        // 0.0 to 1.0 based on recency and frequency
        let days = Double(daysSinceLastContact)
        let interactionCount = Double(interactions.count)
        
        let recencyScore = max(0, 1.0 - (days / 90.0))
        let frequencyScore = min(1.0, interactionCount / 50.0)
        
        return (recencyScore * 0.7) + (frequencyScore * 0.3)
    }
    
    var urgencyLevel: UrgencyLevel {
        switch daysSinceLastContact {
        case 0..<7: return .low
        case 7..<30: return .medium
        case 30..<60: return .high
        default: return .critical
        }
    }
}

enum UrgencyLevel: String {
    case low, medium, high, critical
}
```

#### Interaction
```swift
@Entity
class Interaction: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var content: String // AI summary
    @NSManaged var interactionDate: Date
    @NSManaged var source: String // "voice_note", "shortcut_import", "manual"
    @NSManaged var rawTranscription: String? // Original voice/text
    @NSManaged var extractedInterests: [String]?
    @NSManaged var extractedEvents: [String]?
    @NSManaged var extractedDates: [Date]?
    @NSManaged var createdAt: Date
    
    // Relationship
    @NSManaged var contact: Contact
}
```

#### Connection
```swift
@Entity
class Connection: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var connectionType: String // "sibling", "friend", "colleague", etc.
    @NSManaged var context: String? // "met through Sarah, 2019"
    @NSManaged var dateEstablished: Date?
    @NSManaged var createdAt: Date
    
    // Relationships
    @NSManaged var fromContact: Contact
    @NSManaged var toContact: Contact
    @NSManaged var introducedBy: Contact? // Optional reference
}
```

#### UnassignedNote
```swift
@Entity
class UnassignedNote: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var content: String
    @NSManaged var rawText: String
    @NSManaged var source: String
    @NSManaged var aiSuggestions: [String]? // Suggested contact matches
    @NSManaged var createdAt: Date
}
```

#### UserSettings
```swift
@Entity
class UserSettings: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var defaultReminderDays: Int
    @NSManaged var relationshipTypeReminders: [String: Int] // JSON encoded
    @NSManaged var notificationsEnabled: Bool
    @NSManaged var isPremium: Bool
    @NSManaged var lastSyncDate: Date?
}
```

### CloudKit Schema

All Core Data entities automatically sync to CloudKit via `NSPersistentCloudKitContainer`.

**Custom Zone**: `CirclesZone` (for atomic operations and efficient sync)

**Record Types**: Automatically generated from Core Data entities
- `CD_Contact`
- `CD_Interaction`
- `CD_Connection`
- `CD_UnassignedNote`
- `CD_UserSettings`

### View Models

#### ContactsViewModel
```swift
@MainActor
class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let dataManager: DataManager
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var contactsNeedingAttention: [Contact] {
        contacts
            .filter { $0.daysSinceLastContact >= 30 }
            .sorted { $0.daysSinceLastContact > $1.daysSinceLastContact }
    }
    
    func fetchContacts() async {
        contacts = await dataManager.fetchAllContacts()
    }
    
    func createContact(_ contact: Contact) async throws {
        try await dataManager.saveContact(contact)
        await fetchContacts()
    }
    
    func deleteContact(_ contact: Contact) async throws {
        try await dataManager.deleteContact(contact)
        await fetchContacts()
    }
}
```

#### GraphViewModel
```swift
@MainActor
class GraphViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var connections: [Connection] = []
    @Published var selectedContact: Contact?
    @Published var selectedConnection: Connection?
    
    private let dataManager: DataManager
    
    func fetchGraphData() async {
        contacts = await dataManager.fetchAllContacts()
        connections = await dataManager.fetchAllConnections()
    }
    
    func createConnection(
        from: Contact,
        to: Contact,
        type: String,
        context: String?
    ) async throws {
        let connection = Connection(/* ... */)
        try await dataManager.saveConnection(connection)
        await fetchGraphData()
    }
}
```

#### VoiceNoteViewModel
```swift
@MainActor
class VoiceNoteViewModel: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var aiSummary: String = ""
    @Published var isRecording: Bool = false
    @Published var remainingTime: TimeInterval = 180
    @Published var isProcessing: Bool = false
    @Published var error: VoiceNoteError?
    
    private let recorder: VoiceNoteRecorder
    private let aiService: AIService
    
    func startRecording() throws {
        try recorder.startRecording()
        isRecording = true
    }
    
    func stopRecording() {
        recorder.stopRecording()
        isRecording = false
        Task {
            await summarize()
        }
    }
    
    private func summarize() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let summary = try await aiService.summarizeVoiceNote(transcribedText)
            aiSummary = summary.summary
        } catch {
            // Fallback: use raw transcription
            aiSummary = transcribedText
            self.error = .aiSummarizationFailed
        }
    }
}
```

## Components and Interfaces

### UI Components

#### GlassCard
```swift
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content)
    
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
```

#### ContactCard
```swift
struct ContactCard: View {
    let contact: Contact
    var onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ProfilePhoto(contact: contact)
            ContactInfo(contact: contact)
            Spacer()
            LastContactedIndicator(contact: contact)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)
    }
}
```

#### RelationshipMeter
```swift
struct RelationshipMeter: View {
    let score: Double // 0.0 to 1.0
    
    var color: Color {
        switch score {
        case 0.75...: return .green
        case 0.5..<0.75: return .yellow
        case 0.25..<0.5: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * score)
            }
        }
        .frame(height: 6)
    }
}
```

### Service Interfaces

#### DataManager
```swift
protocol DataManagerProtocol {
    func fetchAllContacts() async -> [Contact]
    func fetchContact(id: UUID) async -> Contact?
    func saveContact(_ contact: Contact) async throws
    func deleteContact(_ contact: Contact) async throws
    
    func fetchAllConnections() async -> [Connection]
    func saveConnection(_ connection: Connection) async throws
    func deleteConnection(_ connection: Connection) async throws
    
    func fetchInteractions(for contact: Contact) async -> [Interaction]
    func saveInteraction(_ interaction: Interaction) async throws
    
    func fetchUnassignedNotes() async -> [UnassignedNote]
    func assignNote(_ note: UnassignedNote, to contact: Contact) async throws
    
    func syncWithCloud() async throws
}
```

#### AIService
```swift
protocol AIServiceProtocol {
    func summarizeVoiceNote(_ transcription: String) async throws -> VoiceNoteSummary
    func processScreenshot(_ text: String) async throws -> ScreenshotResult
    func generateGiftIdeas(for contact: Contact) async throws -> [GiftIdea]
}

struct VoiceNoteSummary: Codable {
    let summary: String
    let interests: [String]
    let topics: [String]
    let events: [String]
    let dates: [String]
}

struct ScreenshotResult: Codable {
    let detectedContact: String?
    let confidence: Double
    let summary: String
    let extractedInfo: ExtractedInfo
}

struct GiftIdea: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let priceRange: String
    let reasoning: String
}
```

#### StoreManager
```swift
protocol StoreManagerProtocol {
    var isPremium: Bool { get }
    var products: [Product] { get async }
    
    func fetchProducts() async throws
    func purchase(_ product: Product) async throws -> Transaction
    func restorePurchases() async throws
    func checkSubscriptionStatus() async -> SubscriptionStatus
}
```

### Graph Components (SpriteKit)

#### GraphScene
```swift
class GraphScene: SKScene {
    var contacts: [Contact] = []
    var connections: [Connection] = []
    
    private var contactNodes: [UUID: ContactNode] = [:]
    private var connectionEdges: [Connection: ConnectionEdge] = [:]
    private var forceSimulation: ForceSimulation!
    
    func setupGraph(contacts: [Contact], connections: [Connection])
    func updateLayout()
    func handleNodeTap(_ node: ContactNode)
    func handleEdgeTap(_ edge: ConnectionEdge)
}
```

#### ContactNode
```swift
class ContactNode: SKSpriteNode {
    let contact: Contact
    var velocity: CGVector = .zero
    var force: CGVector = .zero
    
    init(contact: Contact, size: CGSize)
    func applyForce(_ force: CGVector)
    func updatePosition(deltaTime: TimeInterval)
}
```

#### ConnectionEdge
```swift
class ConnectionEdge: SKShapeNode {
    let connection: Connection
    let fromNode: ContactNode
    let toNode: ContactNode
    
    init(connection: Connection, from: ContactNode, to: ContactNode)
    func updatePath()
    func setStyle(for type: String)
}
```

#### ForceSimulation
```swift
class ForceSimulation {
    var nodes: [ContactNode]
    var edges: [ConnectionEdge]
    
    var repulsionStrength: CGFloat = 3000
    var attractionStrength: CGFloat = 0.3
    var damping: CGFloat = 0.9
    
    func step(deltaTime: TimeInterval)
    func calculateRepulsion(node1: ContactNode, node2: ContactNode) -> CGVector
    func calculateAttraction(edge: ConnectionEdge) -> CGVector
}
```

## API Specifications

### Backend API (Cloudflare Workers)

#### POST /api/process-screenshot
Process screenshot text and detect contact.

**Request:**
```json
{
  "text": "extracted text from screenshot",
  "userId": "apple-sign-in-user-id",
  "timestamp": "2024-01-04T10:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "detectedContact": {
    "name": "Mom",
    "confidence": 0.95
  },
  "summary": "Discussed upcoming birthday plans",
  "extractedInfo": {
    "interests": ["cooking", "gardening"],
    "events": ["Birthday dinner on Jan 15"],
    "dates": ["2024-01-15"]
  }
}
```

#### POST /api/summarize-voice-note
Summarize voice note transcription.

**Request:**
```json
{
  "transcription": "voice note text",
  "contactId": "uuid",
  "userId": "user-id"
}
```

**Response:**
```json
{
  "summary": "Brief summary of conversation",
  "interests": ["hiking", "photography"],
  "topics": ["vacation plans", "work project"],
  "events": ["Trip to mountains next month"],
  "dates": ["2024-02-15"]
}
```

#### POST /api/generate-gift-ideas
Generate gift suggestions for a contact.

**Request:**
```json
{
  "contactId": "uuid",
  "occasion": "birthday",
  "priceRange": "50-100",
  "userId": "user-id"
}
```

**Response:**
```json
{
  "ideas": [
    {
      "name": "Personalized Photo Book",
      "description": "A collection of your shared memories",
      "priceRange": "$30-60",
      "reasoning": "Based on their interest in photography and your shared travel experiences"
    }
  ]
}
```

### Authentication
All API requests require Apple Sign-In token in header:
```
Authorization: Bearer <apple-id-token>
```

## Error Handling

### Error Types

```swift
enum CirclesError: Error, LocalizedError {
    // Data errors
    case contactNotFound
    case invalidData
    case syncFailed(underlying: Error)
    
    // Network errors
    case networkUnavailable
    case apiRequestFailed(statusCode: Int)
    case requestTimeout
    
    // CloudKit errors
    case cloudKitNotAvailable
    case notAuthenticated
    case quotaExceeded
    
    // Voice note errors
    case recognitionNotAuthorized
    case recordingFailed
    case aiSummarizationFailed
    
    // IAP errors
    case purchaseFailed
    case productNotFound
    case restoreFailed
    
    var errorDescription: String? {
        // User-friendly messages
    }
    
    var recoverySuggestion: String? {
        // Actionable guidance
    }
}
```

### Error Handling Strategy

#### 1. CloudKit Sync Errors
```swift
func handleCloudKitError(_ error: Error) {
    switch (error as NSError).code {
    case CKError.notAuthenticated.rawValue:
        showBanner("Sign in to iCloud to sync your data")
        
    case CKError.networkUnavailable.rawValue:
        // Queue changes locally, retry later
        queueForRetry()
        showBanner("Sync paused. Retrying...")
        
    case CKError.quotaExceeded.rawValue:
        showAlert("iCloud storage full. Free up space to continue syncing.")
        
    default:
        // Generic error with retry
        showBanner("Sync issue. Retrying in background.")
    }
}
```

#### 2. AI Processing Errors
```swift
func handleAIError(_ error: Error) async {
    // Always save raw data first
    await saveRawData()
    
    // Then attempt recovery
    switch error {
    case .networkUnavailable:
        queueForProcessing()
        showToast("Will process when online")
        
    case .apiRequestFailed:
        // Use fallback summary
        await saveFallbackSummary()
        showToast("Saved without AI enhancement")
        
    default:
        showAlert("Processing failed. Raw data saved.")
    }
}
```

#### 3. Voice Note Errors
```swift
func handleVoiceNoteError(_ error: VoiceNoteError) {
    switch error {
    case .recognitionNotAuthorized:
        showSettingsAlert("Enable speech recognition in Settings")
        
    case .recordingFailed:
        showAlert("Recording failed. Please try again.")
        
    case .aiSummarizationFailed:
        // Save transcription without AI
        saveTranscriptionOnly()
        showToast("Note saved without AI summary")
    }
}
```

### Offline Handling

```swift
class OfflineManager {
    @Published var isOnline: Bool = true
    private var pendingOperations: [PendingOperation] = []
    
    func queueOperation(_ operation: PendingOperation) {
        pendingOperations.append(operation)
        saveQueue()
    }
    
    func processPendingOperations() async {
        guard isOnline else { return }
        
        for operation in pendingOperations {
            do {
                try await process(operation)
                pendingOperations.removeFirst()
            } catch {
                // Retry later
                break
            }
        }
        
        saveQueue()
    }
}

enum PendingOperation: Codable {
    case voiceNoteSummary(transcription: String, contactId: UUID)
    case screenshotProcessing(text: String)
    case giftIdeasGeneration(contactId: UUID)
}
```

## Testing Strategy

### Unit Tests

#### Data Models
```swift
class ContactTests: XCTestCase {
    func testDaysSinceLastContact() {
        let contact = Contact(/* ... */)
        contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        XCTAssertEqual(contact.daysSinceLastContact, 15)
    }
    
    func testRelationshipScore() {
        let contact = Contact(/* ... */)
        contact.lastConnectedDate = Date()
        XCTAssertGreaterThan(contact.relationshipScore, 0.8)
    }
}
```

#### Force Simulation
```swift
class ForceSimulationTests: XCTestCase {
    func testRepulsionForce() {
        let node1 = ContactNode(/* ... */)
        let node2 = ContactNode(/* ... */)
        let simulation = ForceSimulation(/* ... */)
        
        let force = simulation.calculateRepulsion(node1: node1, node2: node2)
        XCTAssertGreaterThan(force.dx, 0)
    }
    
    func testStabilization() {
        let simulation = ForceSimulation(/* ... */)
        for _ in 0..<1000 {
            simulation.step(deltaTime: 1.0/60.0)
        }
        // Assert nodes have stabilized
    }
}
```

### Integration Tests

#### CloudKit Sync
```swift
class CloudKitSyncTests: XCTestCase {
    func testContactSync() async throws {
        let dataManager = DataManager(/* test configuration */)
        
        // Create contact
        let contact = Contact(/* ... */)
        try await dataManager.saveContact(contact)
        
        // Wait for sync
        try await Task.sleep(for: .seconds(2))
        
        // Verify sync
        let synced = await dataManager.fetchContact(id: contact.id)
        XCTAssertNotNil(synced)
    }
}
```

#### Widget Data Sharing
```swift
class WidgetDataSharingTests: XCTestCase {
    func testSharedDataAccess() async {
        let dataManager = SharedDataManager(appGroup: "group.test")
        
        // Write from app
        let contacts = [ContactSummary(/* ... */)]
        dataManager.updateContactsForWidget(contacts)
        
        // Read from widget extension
        let retrieved = dataManager.getContactsNeedingAttention(limit: 5)
        XCTAssertEqual(retrieved.count, min(5, contacts.count))
    }
}
```

### UI Tests

#### Contact Creation Flow
```swift
class ContactCreationUITests: XCTestCase {
    func testCreateContact() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Tap add button
        app.buttons["Add Contact"].tap()
        
        // Fill form
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("John Doe")
        
        // Select relationship type
        app.buttons["Friend"].tap()
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify contact appears
        XCTAssertTrue(app.staticTexts["John Doe"].exists)
    }
}
```

### Performance Tests

```swift
class PerformanceTests: XCTestCase {
    func testGraphPerformance() {
        let contacts = (0..<500).map { Contact(/* ... */) }
        let connections = generateConnections(contacts)
        
        measure {
            let scene = GraphScene(size: CGSize(width: 1000, height: 1000))
            scene.setupGraph(contacts: contacts, connections: connections)
            
            for _ in 0..<60 {
                scene.updateLayout()
            }
        }
    }
    
    func testContactListScrolling() {
        let app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
        
        // Generate 1000 contacts
        // ...
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            let scrollView = app.scrollViews.firstMatch
            scrollView.swipeUp(velocity: .fast)
        }
    }
}
```

## Design Decisions & Rationales

### 1. SpriteKit for Graph
**Decision**: Use SpriteKit instead of SwiftUI Canvas or web view
**Rationale**: 
- Better performance with many nodes
- Native touch handling
- Physics simulation support
- Proven for interactive graphics

**Trade-offs**: More code, custom algorithm implementation

### 2. NSPersistentCloudKitContainer
**Decision**: Use Apple's integrated solution instead of custom CloudKit
**Rationale**:
- Automatic sync, conflict resolution
- Less boilerplate code
- Well-tested, supported by Apple
- Core Data query performance

**Trade-offs**: Less control over sync timing

### 3. Cloudflare Workers
**Decision**: Serverless edge computing instead of traditional server
**Rationale**:
- Low latency (global edge network)
- Cost-effective (pay per request)
- Auto-scaling
- Simple deployment

**Trade-offs**: Cold starts, vendor lock-in

### 4. Gemini 2.5 (Free Tier)
**Decision**: Google's Gemini instead of ChatGPT or Claude
**Rationale**:
- Free tier sufficient for MVP
- Good quality summaries
- Fast response times
- Simple API

**Trade-offs**: Rate limits, privacy considerations

### 5. URL Scheme for Shortcuts
**Decision**: URL scheme instead of App Intents
**Rationale**:
- Simpler implementation
- Works on iOS 15+
- Proven pattern
- Faster to market

**Trade-offs**: Less elegant, manual URL parsing

## Security & Privacy

### Data Encryption
- **At Rest**: CloudKit encrypts all data
- **In Transit**: HTTPS for all network requests
- **Local**: Core Data uses iOS data protection

### Privacy Principles
1. **User Control**: Users own all data, can delete anytime
2. **Transparency**: Clear about AI processing
3. **Minimal Collection**: Only what's needed
4. **No Third-Party Sharing**: Data not sold or shared

### Authentication
- **Apple Sign-In**: Primary authentication method
- **Token-Based**: JWT tokens for API requests
- **Per-Device**: CloudKit handles device auth

### Compliance
- **Privacy Policy**: Disclose AI processing, data storage
- **Terms of Service**: User agreement for service use
- **GDPR**: Right to access, delete data (export feature future)

## Deployment & Operations

### Development Environment
- Xcode 15+
- iOS 16+ Simulator
- CloudKit Development Container
- Cloudflare Workers dev environment

### CI/CD Pipeline
1. **Code Push** → GitHub
2. **Tests Run** → GitHub Actions
3. **Build** → Xcode Cloud or Fastlane
4. **TestFlight** → Beta distribution
5. **App Store** → Production release

### Monitoring
- **Crashes**: Xcode Organizer / Sentry
- **Analytics**: Apple Analytics (privacy-focused)
- **API**: Cloudflare Workers analytics
- **CloudKit**: CloudKit Dashboard metrics

### Versioning Strategy
- **Semantic Versioning**: MAJOR.MINOR.PATCH
- **1.0.0**: Initial MVP release
- **1.x.x**: Bug fixes, minor features
- **2.0.0**: Major feature additions

## Success Metrics

### Key Performance Indicators (KPIs)

#### Engagement
- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- Average session duration
- Contacts added per user
- Interactions logged per week

#### Retention
- Day 1, 7, 30 retention rates
- Churn rate
- Time to first interaction log

#### Monetization
- Conversion rate (free → premium)
- Monthly Recurring Revenue (MRR)
- Average Revenue Per User (ARPU)
- Trial conversion rate

#### Technical
- App launch time (<2s)
- CloudKit sync success rate (>99%)
- API response time (<2s p95)
- Crash-free rate (>99.5%)

## Future Enhancements

### Phase 2 Features
- Calendar integration (detect meetings)
- Photo timeline for relationships
- Data export (JSON/CSV)
- Shared contacts (collaboration)

### Phase 3 Features
- AI relationship insights
- Automated connection detection
- Voice commands (Siri)
- Apple Watch companion

### Platform Expansion
- iPad optimization (split view)
- Mac Catalyst app
- visionOS (spatial graph)

## Conclusion

This design provides a comprehensive blueprint for building Circles, covering architecture, data models, user flows, technical decisions, and testing strategies. The design balances ambition with pragmatism, leveraging native iOS technologies for a premium, private, and performant relationship management experience.

**Next Step**: Develop Implementation Plan with concrete, testable prompts for building the application.
