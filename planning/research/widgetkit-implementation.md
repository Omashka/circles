# WidgetKit Implementation Research

## Overview
iOS widgets provide at-a-glance information on the home screen, showing contacts that need attention and quick check-in functionality.

## WidgetKit Basics

### Widget Sizes
- **Small**: 2x2 grid cells (155x155 pts on iPhone 13)
- **Medium**: 4x2 grid cells (329x155 pts)
- **Large**: 4x4 grid cells (329x345 pts)

### Widget Types
- **Static**: Fixed content, updated on timeline
- **Interactive** (iOS 17+): Buttons, toggles within widget
- **App Intents**: Actions triggered from widget

### Timeline Updates
Widgets use a timeline-based system:
- App provides entries with dates
- System displays appropriate entry
- Timeline reload policies control updates

## For Circles App

### Widget Purpose
Show contacts the user hasn't connected with recently, with quick check-in actions.

### Recommended Sizes
- **Small**: 1-2 contacts
- **Medium**: 3-4 contacts
- **Large**: 6-8 contacts

## Implementation

### 1. Create Widget Extension
```swift
// File: CirclesWidget/CirclesWidget.swift
import WidgetKit
import SwiftUI

@main
struct CirclesWidgetBundle: WidgetBundle {
    var body: some Widget {
        CirclesWidget()
    }
}

struct CirclesWidget: Widget {
    let kind: String = "CirclesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CirclesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Reconnect")
        .description("See who you haven't connected with recently")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

### 2. Timeline Provider
```swift
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ContactEntry {
        ContactEntry(date: Date(), contacts: Contact.placeholders)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ContactEntry) -> Void) {
        let entry = ContactEntry(date: Date(), contacts: fetchRecentContacts())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ContactEntry>) -> Void) {
        // Fetch contacts that need attention
        let contacts = fetchContactsNeedingAttention(limit: context.family.maxContacts)
        
        let currentDate = Date()
        let entry = ContactEntry(date: currentDate, contacts: contacts)
        
        // Update every 4 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    func fetchContactsNeedingAttention(limit: Int) -> [ContactSummary] {
        // Access shared data container
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.circles") else {
            return []
        }
        
        // Fetch from shared container
        // Or use Core Data with app groups
        let dataManager = SharedDataManager(appGroup: "group.com.yourapp.circles")
        return dataManager.getContactsNeedingAttention(limit: limit)
    }
}

extension WidgetFamily {
    var maxContacts: Int {
        switch self {
        case .systemSmall: return 2
        case .systemMedium: return 4
        case .systemLarge: return 8
        default: return 4
        }
    }
}
```

### 3. Entry Model
```swift
struct ContactEntry: TimelineEntry {
    let date: Date
    let contacts: [ContactSummary]
}

struct ContactSummary: Identifiable, Codable {
    let id: String
    let name: String
    let relationshipType: String
    let daysSinceLastContact: Int
    let profilePhotoData: Data?
    
    var urgencyLevel: UrgencyLevel {
        switch daysSinceLastContact {
        case 0..<7: return .low
        case 7..<30: return .medium
        case 30..<60: return .high
        default: return .critical
        }
    }
}

enum UrgencyLevel {
    case low, medium, high, critical
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}
```

### 4. Widget UI - Small
```swift
struct CirclesWidgetSmallView: View {
    let contacts: [ContactSummary]
    
    var body: some View {
        if let contact = contacts.first {
            VStack(alignment: .leading, spacing: 8) {
                // Profile photo
                if let photoData = contact.profilePhotoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(contact.name.prefix(1))
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
                
                // Name and type
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(contact.relationshipType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time indicator
                HStack {
                    Circle()
                        .fill(contact.urgencyLevel.color)
                        .frame(width: 8, height: 8)
                    
                    Text("\(contact.daysSinceLastContact)d ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        } else {
            Text("All caught up! 🎉")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
```

### 5. Widget UI - Medium
```swift
struct CirclesWidgetMediumView: View {
    let contacts: [ContactSummary]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(contacts.prefix(4)) { contact in
                VStack(spacing: 6) {
                    // Profile photo
                    profilePhoto(for: contact)
                        .frame(width: 50, height: 50)
                    
                    // Name
                    Text(contact.name)
                        .font(.caption)
                        .lineLimit(1)
                    
                    // Days ago with indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(contact.urgencyLevel.color)
                            .frame(width: 6, height: 6)
                        Text("\(contact.daysSinceLastContact)d")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func profilePhoto(for contact: ContactSummary) -> some View {
        if let photoData = contact.profilePhotoData,
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text(contact.name.prefix(1))
                        .font(.title3)
                        .foregroundColor(.white)
                )
        }
    }
}
```

### 6. Widget UI - Large
```swift
struct CirclesWidgetLargeView: View {
    let contacts: [ContactSummary]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Reconnect")
                    .font(.headline)
                Spacer()
                Text("\(contacts.count) contacts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Contact list
            ForEach(contacts.prefix(8)) { contact in
                HStack(spacing: 12) {
                    // Profile photo
                    profilePhoto(for: contact)
                        .frame(width: 40, height: 40)
                    
                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(contact.relationshipType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Days with urgency indicator
                    HStack(spacing: 6) {
                        Text("\(contact.daysSinceLastContact)d")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(contact.urgencyLevel.color)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            if contacts.isEmpty {
                Spacer()
                Text("All caught up! 🎉")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func profilePhoto(for contact: ContactSummary) -> some View {
        // Same as medium widget
    }
}
```

### 7. Interactive Widgets (iOS 17+)
```swift
// Add quick check-in button
struct CirclesWidgetEntryView: View {
    let entry: ContactEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetWithAction(contacts: entry.contacts)
        case .systemMedium:
            mediumWidgetWithActions(contacts: entry.contacts)
        case .systemLarge:
            largeWidgetWithActions(contacts: entry.contacts)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    func smallWidgetWithAction(contacts: [ContactSummary]) -> some View {
        if let contact = contacts.first {
            VStack {
                // ... existing UI ...
                
                // Quick check-in button (iOS 17+)
                if #available(iOS 17.0, *) {
                    Button(intent: CheckInIntent(contactId: contact.id)) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Check In")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

### 8. App Intent for Check-In
```swift
import AppIntents

@available(iOS 17.0, *)
struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In"
    static var description = IntentDescription("Mark that you've connected with this contact")
    
    @Parameter(title: "Contact ID")
    var contactId: String
    
    func perform() async throws -> some IntentResult {
        // Log interaction
        let dataManager = SharedDataManager(appGroup: "group.com.yourapp.circles")
        try await dataManager.logCheckIn(contactId: contactId)
        
        // Refresh widget
        WidgetCenter.shared.reloadTimelines(ofKind: "CirclesWidget")
        
        return .result(
            dialog: "Checked in!"
        )
    }
}
```

## Data Sharing with App

### App Groups
```swift
// Xcode: Capabilities → App Groups
// Enable for both main app and widget extension
// Group ID: group.com.yourapp.circles
```

### Shared Data Container
```swift
class SharedDataManager {
    let appGroupId: String
    let sharedDefaults: UserDefaults?
    let sharedContainer: URL?
    
    init(appGroup: String) {
        self.appGroupId = appGroup
        self.sharedDefaults = UserDefaults(suiteName: appGroup)
        self.sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
    }
    
    func getContactsNeedingAttention(limit: Int) -> [ContactSummary] {
        // Option 1: UserDefaults (for small data)
        if let data = sharedDefaults?.data(forKey: "contactsNeedingAttention"),
           let contacts = try? JSONDecoder().decode([ContactSummary].self, from: data) {
            return Array(contacts.prefix(limit))
        }
        
        // Option 2: Core Data with shared store
        // See Core Data + App Groups section
        
        return []
    }
    
    func updateContactsForWidget(_ contacts: [ContactSummary]) {
        if let data = try? JSONEncoder().encode(contacts) {
            sharedDefaults?.set(data, forKey: "contactsNeedingAttention")
        }
        
        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "CirclesWidget")
    }
}
```

### Core Data + App Groups
```swift
// In shared Core Data setup
lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "Circles")
    
    // Use app group container
    let storeURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.yourapp.circles"
    )!.appendingPathComponent("Circles.sqlite")
    
    let description = NSPersistentStoreDescription(url: storeURL)
    container.persistentStoreDescriptions = [description]
    
    container.loadPersistentStores { description, error in
        if let error = error {
            fatalError("Core Data failed: \(error)")
        }
    }
    
    return container
}()
```

## Widget Refresh Strategies

### 1. Periodic Refresh (Recommended)
```swift
// In TimelineProvider
let timeline = Timeline(
    entries: [entry],
    policy: .after(nextUpdateDate)
)

// Update every 4-6 hours
let nextUpdateDate = Calendar.current.date(
    byAdding: .hour,
    value: 4,
    to: Date()
)!
```

### 2. App-Triggered Refresh
```swift
// In main app after data changes
WidgetCenter.shared.reloadTimelines(ofKind: "CirclesWidget")

// Or reload all widgets
WidgetCenter.shared.reloadAllTimelines()
```

### 3. Background Refresh
```swift
// After CloudKit sync
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any]
) async -> UIBackgroundFetchResult {
    // Sync data
    try? await dataManager.syncWithCloud()
    
    // Update widget
    WidgetCenter.shared.reloadAllTimelines()
    
    return .newData
}
```

## Design Considerations

### Glass UI Styling
```swift
struct CirclesWidgetEntryView: View {
    var body: some View {
        ZStack {
            // Background
            ContainerRelativeShape()
                .fill(.ultraThinMaterial)
            
            // Content
            content
                .foregroundStyle(.primary)
        }
    }
}
```

### Dark Mode Support
```swift
// Colors adapt automatically with system colors
Text(contact.name)
    .foregroundColor(.primary)

Circle()
    .fill(Color.accentColor)
```

### Accessibility
```swift
// Widget accessibility
.accessibilityLabel("""
\(contact.name), \(contact.relationshipType). 
Last contact \(contact.daysSinceLastContact) days ago.
""")
```

## Testing

### Widget Preview
```swift
struct CirclesWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small widget
            CirclesWidgetEntryView(entry: ContactEntry(
                date: Date(),
                contacts: ContactSummary.sampleData
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            // Medium widget
            CirclesWidgetEntryView(entry: ContactEntry(
                date: Date(),
                contacts: ContactSummary.sampleData
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            // Large widget
            CirclesWidgetEntryView(entry: ContactEntry(
                date: Date(),
                contacts: ContactSummary.sampleData
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
```

### Test Scenarios
- [ ] Empty state (no contacts needing attention)
- [ ] 1 contact
- [ ] Full widget (max contacts)
- [ ] Long names (truncation)
- [ ] Missing profile photos
- [ ] Different urgency levels
- [ ] Dark mode
- [ ] Different device sizes
- [ ] Widget refresh after app update

## Performance

### Optimization Tips
1. **Limit Photo Size**: Compress/resize profile photos
2. **Efficient Data Fetch**: Query only needed fields
3. **Cache Results**: Don't recompute on every timeline request
4. **Async Loading**: Use async/await for data fetching

### Memory Budget
- Widgets have strict memory limits (~50MB)
- Exceeded limits = widget crashes
- Compress images aggressively
- Limit cached data

## Troubleshooting

### Widget Not Updating
1. Check timeline policy
2. Verify app group configuration
3. Check if data is being written to shared container
4. Call `WidgetCenter.shared.reloadTimelines()`

### Data Not Syncing
1. Verify app group ID matches
2. Check UserDefaults suite name
3. Ensure Core Data store URL correct
4. Test with simple data first

## Best Practices

1. **Keep It Simple**: Widgets are glanceable, not interactive dashboards
2. **Update Regularly**: But not too frequently (4-6 hours)
3. **Handle Empty State**: Show encouraging message
4. **Urgency Colors**: Visual hierarchy helps users prioritize
5. **Profile Photos**: Make contacts recognizable
6. **Test All Sizes**: Design for small, medium, large
7. **Accessibility**: VoiceOver support important
8. **App Group Required**: Essential for data sharing

## Key Takeaways

1. **WidgetKit is Straightforward**: Timeline-based, declarative UI
2. **App Groups Essential**: For sharing data between app and widget
3. **Interactive Widgets**: iOS 17+ allows buttons
4. **Show Who Needs Attention**: Core value proposition
5. **Color-Coded Urgency**: Green→Yellow→Orange→Red
6. **4-6 Hour Updates**: Balance freshness with battery
7. **Memory Limits**: Compress photos, limit data

## Implementation Checklist

- [ ] Create widget extension target
- [ ] Enable app groups capability
- [ ] Implement TimelineProvider
- [ ] Design widget UI (small, medium, large)
- [ ] Share data via app group
- [ ] Implement check-in intent (iOS 17+)
- [ ] Add widget refresh in app
- [ ] Test all widget sizes
- [ ] Test dark mode
- [ ] Optimize memory usage
- [ ] Add accessibility labels

## Resources

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [WWDC WidgetKit Sessions](https://developer.apple.com/videos/play/wwdc2022/10051/)
- [App Groups Guide](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW19)
- [Interactive Widgets (iOS 17)](https://developer.apple.com/documentation/widgetkit/making-widgets-interactive)
