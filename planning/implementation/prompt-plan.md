# Circles - Implementation Prompt Plan

## Implementation Checklist

- [x] Prompt 1: Project setup and Core Data models
- [x] Prompt 2: CloudKit configuration and data manager
- [x] Prompt 3: Basic UI structure and navigation
- [ ] Prompt 4: Contact list view with glass UI
- [ ] Prompt 5: Contact detail view and editing
- [ ] Prompt 6: Relationship meter and interaction logging
- [ ] Prompt 7: Voice notes with speech recognition
- [ ] Prompt 8: AI service integration (Gemini API)
- [ ] Prompt 9: Apple Shortcuts integration (URL scheme)
- [ ] Prompt 10: Cloudflare Workers backend
- [ ] Prompt 11: Force-directed graph foundation (SpriteKit)
- [ ] Prompt 12: Graph interactions and connection management
- [ ] Prompt 13: Widget extension implementation
- [ ] Prompt 14: StoreKit 2 integration and paywalls
- [ ] Prompt 15: Reminders and notifications
- [ ] Prompt 16: Settings and user preferences
- [ ] Prompt 17: Onboarding flow
- [ ] Prompt 18: Error handling and offline support
- [ ] Prompt 19: Testing and polish
- [ ] Prompt 20: App Store preparation

---

## Git Checkpointing

### Git Checkpointing Instructions

After completing each prompt, create a git commit with all source and test code changes:

**Constraints:**
- You MUST add and commit all changes in the project directories (excluding planning/)
- You MUST NOT commit files in planning/ directory or build artifacts
- You MUST use descriptive commit messages following this format:
  ```
  feat: implement [brief description of completed work]

  - [Key achievement 1]
  - [Key achievement 2]
  - [Key achievement 3]

  Completes Prompt N of implementation plan
  ```
- You MUST verify the git status before committing
- You MUST assume the user has properly set up their git environment and branch

**Git Commands:**
```bash
# Add source files only (exclude planning/)
git add PrivateDatabase/ Tests/ PrivateDatabase.xcodeproj/

# Commit with descriptive message
git commit -m "feat: implement [description]

- [achievement 1]
- [achievement 2]
- [achievement 3]

Completes Prompt N of implementation plan"
```

---

## Implementation Prompts

### Prompt 1: Project setup and Core Data models

Set up the Xcode project structure and implement the Core Data models for contacts, interactions, connections, and settings.

**Objectives:**
1. Configure the existing Xcode project for the Circles app
2. Create Core Data model file with all entities (Contact, Interaction, Connection, UnassignedNote, UserSettings)
3. Define entity relationships and attributes as specified in the design document
4. Set up NSPersistentCloudKitContainer for CloudKit integration
5. Create Core Data stack with proper error handling
6. Write unit tests for Core Data models

**Implementation Guidance:**
- Use the existing `PrivateDatabase` project structure
- Create `CirclesDataModel.xcdatamodeld` with all entities
- Configure CloudKit container identifier in entitlements
- Implement computed properties for Contact (daysSinceLastContact, relationshipScore, urgencyLevel)
- Test Core Data CRUD operations

**Testing:**
- Test entity creation and relationships
- Verify computed properties calculate correctly
- Test Core Data fetch requests
- Ensure CloudKit container initializes properly

**Integration:**
- Sets foundation for all data operations in subsequent prompts
- Data models will be used by all view models and services

---

### Prompt 2: CloudKit configuration and data manager

Configure CloudKit with proper entitlements and implement the DataManager service for handling all data operations.

**Objectives:**
1. Enable CloudKit capability in Xcode project
2. Configure CloudKit container and private database
3. Create App Groups capability for widget data sharing
4. Implement DataManager class with all CRUD operations
5. Set up NSPersistentCloudKitContainer with custom zone
6. Implement sync status monitoring and error handling
7. Write integration tests for CloudKit sync

**Implementation Guidance:**
- Add iCloud capability with CloudKit services
- Create app group: `group.com.yourapp.circles`
- Implement DataManager conforming to DataManagerProtocol from design
- Handle common CloudKit errors (not authenticated, network unavailable, quota exceeded)
- Implement retry logic for failed sync operations
- Create SharedDataManager for widget data sharing

**Testing:**
- Test CRUD operations save to Core Data
- Verify CloudKit sync triggers automatically
- Test error handling for offline scenarios
- Test app group data sharing

**Integration:**
- DataManager will be dependency-injected into all view models
- SharedDataManager used by widget extension
- Builds on Core Data models from Prompt 1

---

### Prompt 3: Basic UI structure and navigation

Create the main app structure with SwiftUI, including tab navigation, basic screens, and glass UI foundation.

**Objectives:**
1. Implement App structure with SwiftUI lifecycle
2. Create TabView with three tabs (People, Web, Reminders)
3. Set up NavigationStack for each tab
4. Create glass UI components (GlassCard, GlassButton, etc.)
5. Implement GlassBackground with gradient
6. Set up basic routing and navigation
7. Add settings navigation in top bar

**Implementation Guidance:**
- Update App.swift with proper SwiftUI App structure
- Create reusable glass UI components as specified in design
- Implement color extensions for glass palette
- Set up environment objects for data manager
- Create placeholder views for each tab
- Follow Apple Human Interface Guidelines

**Testing:**
- Test tab switching
- Verify navigation flows work correctly
- Test glass UI components in light and dark mode
- Verify accessibility with VoiceOver

**Integration:**
- Navigation structure will host all feature screens
- Glass UI components will be reused throughout app
- Builds foundation for Prompts 4-7

---

### Prompt 4: Contact list view with glass UI

Implement the People tab's home screen with scrollable contact list, search, and premium glass UI design.

**Objectives:**
1. Create ContactsViewModel with observable state
2. Implement HomeScreen with contact list
3. Create ContactCard component with glass styling
4. Add search bar with filtering
5. Implement profile photo display with fallback initials
6. Add relationship meter visualization
7. Create floating action button for adding contacts
8. Write UI tests for contact list

**Implementation Guidance:**
- Use LazyVStack for performance with many contacts
- Implement async data loading in viewModel
- Show loading states and empty states
- Apply glass UI styling from Prompt 3
- Sort contacts by last connected date
- Implement pull-to-refresh

**Testing:**
- Test contact list displays correctly
- Verify search filtering works
- Test empty state when no contacts
- Verify performance with 100+ contacts
- Test pull-to-refresh functionality

**Integration:**
- Uses DataManager from Prompt 2
- Uses glass UI components from Prompt 3
- Clicking contact will navigate to detail view (Prompt 5)

---

### Prompt 5: Contact detail view and editing

Create the detailed contact profile view with all information fields, editing capability, and interaction timeline.

**Objectives:**
1. Implement ContactDetailView with all profile sections
2. Create ContactEditView for adding/editing contacts
3. Display interaction timeline chronologically
4. Show relationship meter prominently
5. Add voice note button (placeholder for Prompt 7)
6. Add gift ideas button (placeholder for Prompt 8)
7. Implement delete contact functionality
8. Write UI tests for contact detail and editing

**Implementation Guidance:**
- Use Form or ScrollView for profile layout
- Implement all fields from Contact entity (birthday, interests, job, etc.)
- Create date pickers for birthday and important dates
- Show read-only timeline initially (full implementation in Prompt 6)
- Apply glass UI styling consistently
- Handle photo selection from camera/library

**Testing:**
- Test creating new contact
- Test editing existing contact
- Test all form fields save correctly
- Verify photo upload works
- Test delete confirmation flow

**Integration:**
- Uses DataManager from Prompt 2
- Uses glass UI from Prompt 3
- Navigated from contact list in Prompt 4
- Interaction logging added in Prompt 6
- Voice notes added in Prompt 7

---

### Prompt 6: Relationship meter and interaction logging

Implement the relationship health tracking system with visual meter, interaction logging, and timeline display.

**Objectives:**
1. Create InteractionViewModel for managing interactions
2. Implement manual interaction logging with notes
3. Display interaction timeline in contact detail
4. Calculate and display relationship score
5. Implement color-coded relationship meter
6. Add "last connected" date tracking
7. Update relationship meter after logging interaction
8. Write unit tests for relationship scoring algorithm

**Implementation Guidance:**
- Implement relationship score calculation as specified in design
- Create interaction cards for timeline display
- Allow editing/deleting interactions
- Update contact's lastConnectedDate when interaction logged
- Show most recent interactions first
- Apply glass UI to interaction cards

**Testing:**
- Test relationship score calculation
- Verify interaction logging updates last connected date
- Test relationship meter color changes appropriately
- Verify timeline displays chronologically
- Test interaction editing and deletion

**Integration:**
- Uses DataManager from Prompt 2
- Integrates into ContactDetailView from Prompt 5
- Foundation for voice notes (Prompt 7) and shortcuts (Prompt 9)

---

### Prompt 7: Voice notes with speech recognition

Implement voice note recording with real-time transcription, waveform visualization, and 3-minute time limit.

**Objectives:**
1. Create VoiceNoteViewModel and VoiceNoteRecorder classes
2. Implement real-time speech recognition
3. Create voice note recording UI with waveform
4. Add 3-minute timer with countdown
5. Show transcription in real-time
6. Implement stop/cancel functionality
7. Request microphone and speech recognition permissions
8. Write tests for recording flow

**Implementation Guidance:**
- Use iOS Speech Recognition framework
- Implement AVAudioEngine for audio capture
- Create simple waveform visualization (animated bars)
- Show timer counting down from 3:00
- Handle permission requests gracefully
- Save raw transcription (AI summary added in Prompt 8)

**Testing:**
- Test recording starts/stops correctly
- Verify 3-minute limit enforced
- Test transcription accuracy
- Verify permission handling
- Test cancel preserves no data

**Integration:**
- Accessible from ContactDetailView (Prompt 5)
- Transcription will be sent to AI service (Prompt 8)
- Creates Interaction entities via DataManager (Prompt 2)

---

### Prompt 8: AI service integration (Gemini API)

Integrate Gemini AI for voice note summarization, screenshot processing, and gift idea generation.

**Objectives:**
1. Create AIService class with Gemini API integration
2. Implement voice note summarization endpoint
3. Extract interests, events, dates from transcriptions
4. Create summary edit view for user review
5. Implement gift idea generation
6. Handle AI API errors gracefully
7. Add offline queueing for pending AI operations
8. Write integration tests for AI service

**Implementation Guidance:**
- Store Gemini API key securely (consider environment variable)
- Implement proper error handling and retries
- Allow users to edit AI-generated summaries before saving
- Extract structured data (interests, events, dates) from responses
- Queue operations when offline, process when online
- Show loading states during AI processing

**Testing:**
- Test API request/response format
- Verify error handling for API failures
- Test offline queueing and retry
- Verify data extraction from AI responses
- Test user can edit summaries

**Integration:**
- Called from VoiceNoteViewModel (Prompt 7)
- Will be used by Shortcuts integration (Prompt 9)
- Will be used by gift ideas feature
- Creates/updates Interaction entities via DataManager (Prompt 2)

---

### Prompt 9: Apple Shortcuts integration (URL scheme)

Implement URL scheme handling for importing screenshots via Apple Shortcuts, with Back Tap integration guide.

**Objectives:**
1. Define custom URL scheme `circles://import`
2. Implement URL handling in App structure
3. Create shortcut import flow (parse text, call AI service)
4. Implement inbox for unassigned notes
5. Create InboxView to review and assign notes
6. Add ability to manually assign notes to contacts
7. Handle contact detection with confidence threshold
8. Create onboarding instructions for Back Tap setup

**Implementation Guidance:**
- Add URL scheme to Info.plist
- Parse URL parameters safely
- Send extracted text to backend API (Prompt 10) or AI service (Prompt 8)
- If confidence < 0.7, add to inbox (UnassignedNote entity)
- Create inbox view showing unassigned notes
- Allow user to select contact for assignment
- Provide clear onboarding for setting up Back Tap + Shortcut

**Testing:**
- Test URL handling with various payloads
- Verify contact detection accuracy
- Test inbox workflow
- Verify manual assignment works
- Test error handling for malformed URLs

**Integration:**
- Uses AIService from Prompt 8
- Uses DataManager from Prompt 2
- Creates Interaction or UnassignedNote entities
- Inbox accessible from main navigation

---

### Prompt 10: Cloudflare Workers backend

Create Cloudflare Workers serverless functions for processing screenshots and AI operations with Gemini API.

**Objectives:**
1. Set up Cloudflare Workers project structure
2. Implement `/api/process-screenshot` endpoint
3. Implement `/api/summarize-voice-note` endpoint  
4. Implement `/api/generate-gift-ideas` endpoint
5. Integrate Gemini 2.5 API calls
6. Add authentication with Apple Sign-In tokens
7. Implement rate limiting and error handling
8. Write tests for API endpoints

**Implementation Guidance:**
- Use TypeScript for Workers
- Validate Apple ID tokens for authentication
- Implement contact matching algorithm with fuzzy matching
- Parse Gemini responses and structure data
- Add comprehensive error handling
- Use Cloudflare KV for caching contact lists
- Deploy to Cloudflare Workers

**Testing:**
- Test each endpoint with sample requests
- Verify authentication works
- Test Gemini API integration
- Verify error responses formatted correctly
- Test rate limiting

**Integration:**
- Called from iOS app (Prompts 8, 9)
- Processes data and returns to app
- Independent service, can be tested separately
- API URLs configured in iOS app

---

### Prompt 11: Force-directed graph foundation (SpriteKit)

Create the SpriteKit scene for relationship graph with force-directed layout algorithm and basic rendering.

**Objectives:**
1. Create GraphScene (SKScene subclass)
2. Implement ContactNode (SKSpriteNode) for contacts
3. Implement ConnectionEdge (SKShapeNode) for relationships
4. Create ForceSimulation class with physics algorithm
5. Implement repulsion and attraction forces
6. Add touch handling for pan and zoom
7. Render nodes with profile photos
8. Write unit tests for force calculations

**Implementation Guidance:**
- Use Barnes-Hut optimization for large graphs
- Tune force constants for stable layout
- Implement spatial hashing for performance
- Use SKTexture for profile photos
- Add pinch gesture for zoom, pan gesture for movement
- Implement damping for stabilization
- Start with smaller networks (< 100 nodes) for testing

**Testing:**
- Test force calculations produce expected vectors
- Verify nodes stabilize over time
- Test touch gestures work correctly
- Verify performance with 100 nodes
- Test photo loading and display

**Integration:**
- Uses Contact and Connection entities from DataManager (Prompt 2)
- Displayed in Web tab navigation (Prompt 3)
- Full interactions added in Prompt 12

---

### Prompt 12: Graph interactions and connection management

Add drag-and-drop connection creation, connection detail sheets, and full graph interactivity.

**Objectives:**
1. Create GraphViewModel for managing graph state
2. Implement node tap to open contact detail
3. Implement edge tap to show connection details
4. Add drag-and-drop to create connections
5. Create connection edit sheet with type selection
6. Implement connection deletion
7. Add "Why do I know this person?" details display
8. Style edges based on connection type (solid/dashed/arrowed)
9. Write UI tests for graph interactions

**Implementation Guidance:**
- Detect long press + drag for connection creation
- Show sheet to select connection type after drag
- Display connection metadata (context, date, introducer)
- Update edge rendering based on connection type
- Allow manual node repositioning
- Implement connection search/filter
- Add accessibility labels for VoiceOver

**Testing:**
- Test drag-and-drop connection creation
- Verify edge tap shows details
- Test connection type changes styling
- Verify node repositioning works
- Test accessibility with VoiceOver

**Integration:**
- Uses GraphScene from Prompt 11
- Uses DataManager from Prompt 2
- Opens ContactDetailView from Prompt 5
- Full graph feature now complete

---

### Prompt 13: Widget extension implementation

Create WidgetKit extension showing contacts needing attention with quick check-in functionality.

**Objectives:**
1. Create widget extension target in Xcode
2. Implement TimelineProvider for widget updates
3. Create widget UI for small, medium, large sizes
4. Display contacts needing attention with urgency colors
5. Implement quick check-in button (iOS 17+)
6. Set up app group for data sharing
7. Update SharedDataManager for widget access
8. Write tests for widget timeline generation

**Implementation Guidance:**
- Use app group `group.com.yourapp.circles` for data sharing
- Fetch contacts from SharedDataManager
- Sort by days since last contact (most urgent first)
- Apply color coding: green/yellow/orange/red
- Implement CheckInIntent for button actions (iOS 17+)
- Update timeline every 4-6 hours
- Show "All caught up!" when no contacts need attention

**Testing:**
- Test widget displays correctly in all sizes
- Verify data sharing via app group works
- Test check-in button updates data
- Verify timeline updates appropriately
- Test in both light and dark mode

**Integration:**
- Reads data via SharedDataManager (Prompt 2)
- Check-in updates logged via DataManager
- Widget refreshed when app updates data
- Provides home screen quick access

---

### Prompt 14: StoreKit 2 integration and paywalls

Implement in-app purchases with StoreKit 2, feature gating, and premium subscription management.

**Objectives:**
1. Create StoreManager class with StoreKit 2 APIs
2. Configure subscription products in App Store Connect
3. Create StoreKit configuration file for testing
4. Implement purchase flow with async/await
5. Create paywall view with premium benefits
6. Implement feature gating (check isPremium)
7. Add subscription management view
8. Handle transaction verification and restore
9. Write integration tests for purchase flow

**Implementation Guidance:**
- Offer monthly ($4.99) and annual ($39.99) subscriptions
- Include 7-day free trial
- Feature gate: unlimited contacts, graph view, AI features
- Use StoreView or SubscriptionStoreView for UI
- Verify transactions using StoreKit 2 automatic verification
- Handle purchase errors gracefully
- Implement restore purchases functionality

**Testing:**
- Test purchase flow end-to-end
- Verify free trial works correctly
- Test feature gating blocks/allows features
- Test restore purchases
- Verify subscription status updates

**Integration:**
- StoreManager injected into app environment
- Paywall shown when accessing premium features
- Premium status checked before graph view, AI features
- Settings includes subscription management

---

### Prompt 15: Reminders and notifications

Implement reminder system with configurable intervals, notifications, and birthday alerts.

**Objectives:**
1. Create ReminderManager for scheduling notifications
2. Implement check-in reminders based on last contact date
3. Create birthday reminder system
4. Build Reminders tab view listing upcoming reminders
5. Implement relationship-type-specific intervals
6. Add notification permission requests
7. Handle notification taps to open contact
8. Write tests for reminder scheduling logic

**Implementation Guidance:**
- Use UNUserNotificationCenter for local notifications
- Schedule reminders when lastConnectedDate + interval reached
- Show birthday reminders 1 week and 1 day before
- List upcoming reminders in Reminders tab, sorted by date
- Allow dismissing/snoozing reminders
- Handle timezone changes appropriately
- Update reminders when contact is interacted with

**Testing:**
- Test reminder scheduling logic
- Verify notifications appear at correct times
- Test notification tap opens correct contact
- Verify birthday reminders schedule correctly
- Test reminder updates after interaction

**Integration:**
- Uses DataManager to read contacts (Prompt 2)
- Opens ContactDetailView when notification tapped (Prompt 5)
- Reminders tab in main navigation (Prompt 3)
- Settings for configuring intervals (Prompt 16)

---

### Prompt 16: Settings and user preferences

Create settings screen with reminder configuration, notification preferences, and app information.

**Objectives:**
1. Create SettingsView with navigation
2. Implement default reminder interval setting
3. Add relationship-type-specific interval customization
4. Create notification enable/disable toggle
5. Add subscription management section (if premium)
6. Include about, privacy policy, terms of service links
7. Add version information
8. Write UI tests for settings

**Implementation Guidance:**
- Use Form or List for settings layout
- Store settings in UserSettings Core Data entity
- Sync settings via CloudKit
- Link to subscription management (Prompt 14)
- Provide sensible defaults (30 days default)
- Update ReminderManager when settings change
- Apply glass UI styling to settings

**Testing:**
- Test setting changes save correctly
- Verify reminder intervals update
- Test notification toggle works
- Verify settings sync across devices
- Test all links open correctly

**Integration:**
- Accessible from top navigation bar (Prompt 3)
- Uses DataManager for UserSettings (Prompt 2)
- Updates ReminderManager from Prompt 15
- Links to StoreManager from Prompt 14

---

### Prompt 17: Onboarding flow

Create first-run onboarding experience teaching key features and guiding Shortcuts setup.

**Objectives:**
1. Create OnboardingView with page navigation
2. Design welcome screen explaining app value
3. Create permissions request screens (notifications, speech, contacts)
4. Add Shortcuts setup tutorial with step-by-step guide
5. Create Back Tap configuration walkthrough
6. Add iOS Contacts import option
7. Implement onboarding completion tracking
8. Write UI tests for onboarding flow

**Implementation Guidance:**
- Show onboarding only on first launch
- Use TabView with PageTabViewStyle for pages
- Request permissions at appropriate moments
- Provide visual guide for Back Tap setup with screenshots
- Allow skipping optional steps
- Store onboarding completion in UserDefaults
- Make onboarding accessible from settings (replay)

**Testing:**
- Test onboarding shows on first launch only
- Verify permission requests work correctly
- Test contact import functionality
- Verify onboarding can be replayed from settings
- Test skip functionality

**Integration:**
- Shown before main app interface (Prompt 3)
- Requests permissions for various features
- Guides Shortcuts setup for Prompt 9
- Can import contacts into DataManager (Prompt 2)

---

### Prompt 18: Error handling and offline support

Implement comprehensive error handling, offline queueing, and sync status indicators throughout the app.

**Objectives:**
1. Create centralized ErrorHandler utility
2. Implement offline detection and status indicator
3. Create OfflineManager for queueing operations
4. Add retry logic for failed operations
5. Implement sync status banner (syncing/error/paused)
6. Handle all CloudKit errors gracefully
7. Add error recovery suggestions to users
8. Write tests for error scenarios

**Implementation Guidance:**
- Monitor network reachability continuously
- Queue AI operations when offline (voice notes, screenshots)
- Show non-blocking banners for sync status
- Provide actionable error messages
- Implement exponential backoff for retries
- Handle iCloud sign-out gracefully
- Show last sync time in settings

**Testing:**
- Test offline operation queueing
- Verify operations process when back online
- Test CloudKit error handling (not authenticated, quota exceeded)
- Verify sync status indicators appear correctly
- Test error recovery suggestions

**Integration:**
- Used throughout all features
- Wraps DataManager operations (Prompt 2)
- Handles AIService failures (Prompt 8)
- Displays status in navigation bar (Prompt 3)

---

### Prompt 19: Testing and polish

Comprehensive testing pass, performance optimization, accessibility improvements, and UI polish.

**Objectives:**
1. Run full test suite and fix failures
2. Optimize graph performance for 500+ nodes
3. Improve accessibility with VoiceOver
4. Add loading skeletons for async operations
5. Optimize image loading and caching
6. Test on multiple device sizes (iPhone SE to Pro Max)
7. Verify dark mode throughout app
8. Test with Reduce Transparency accessibility setting
9. Performance profiling and optimization
10. Fix any remaining bugs

**Implementation Guidance:**
- Use Instruments to profile performance bottlenecks
- Implement image caching for profile photos
- Add skeleton loaders during data fetching
- Ensure all interactive elements have accessibility labels
- Test VoiceOver navigation flows
- Verify Dynamic Type support
- Polish animations and transitions
- Test edge cases (empty states, max data)

**Testing:**
- Run full unit, integration, and UI test suites
- Manual testing on physical devices
- Accessibility audit with VoiceOver
- Performance testing with large datasets
- Test all user flows end-to-end

**Integration:**
- Touches all features from previous prompts
- Ensures production-ready quality
- Prepares for App Store submission

---

### Prompt 20: App Store preparation

Prepare app for App Store submission including assets, metadata, privacy details, and final build.

**Objectives:**
1. Create app icon in all required sizes
2. Design App Store screenshots for all device sizes
3. Write App Store description and keywords
4. Create privacy policy and terms of service
5. Fill out App Privacy details in App Store Connect
6. Configure In-App Purchase products
7. Add promotional text and what's new
8. Create final production build
9. Submit for App Store review

**Implementation Guidance:**
- Design app icon following Apple guidelines
- Create compelling screenshots showing key features
- Write clear, benefit-focused description
- Highlight unique features (graph, voice notes, AI)
- Be transparent about data usage in privacy details
- Set up subscription products with correct pricing
- Use TestFlight for final testing
- Prepare for review questions

**Deliverables:**
- App icon asset catalog
- Screenshots (6.7", 6.5", 5.5" displays)
- App Store metadata
- Privacy policy hosted online
- Terms of service
- Configured IAP products
- Signed production build
- Submission ready

**Integration:**
- Final step completing entire implementation
- App ready for public release
- Marketing materials prepared

---

## Implementation Complete

Following these 20 prompts in sequence will result in a fully functional, tested, and polished Circles iOS app ready for App Store submission. Each prompt builds incrementally on previous work, ensuring no orphaned code and smooth integration.

**Remember**: After each prompt, create a git commit following the checkpointing instructions at the top of this document.
