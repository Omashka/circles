# Research Summary

## Overview
This document summarizes the research conducted for the Circles relationship management iOS app.

## Research Topics Covered

### 1. StoreKit 2 and Monetization
**File**: `storekit-monetization.md`

**Key Findings:**
- StoreKit 2 provides modern Swift-native APIs for in-app purchases
- Recommended freemium model: free for 20-30 contacts, premium for unlimited
- Suggested pricing: $4.99/month or $39.99/year
- Built-in security with JWS-signed transactions
- SwiftUI views (ProductView, SubscriptionStoreView) simplify implementation

**Implementation Approach:**
- Use StoreKit 2 directly (no third-party needed for MVP)
- Feature gate: graph visualization, AI features, unlimited contacts as premium
- 7-day free trial to increase conversions

### 2. Force-Directed Graph Visualization
**File**: `graph-visualization.md`

**Key Findings:**
- SpriteKit is best choice for iOS graph visualization
- No perfect third-party library exists; custom implementation needed
- Force-directed algorithm using repulsion and attraction forces
- Barnes-Hut optimization for 100+ nodes
- Touch interactions: tap, drag, pinch-zoom, pan

**Implementation Approach:**
- Each contact as SKSpriteNode with profile photo texture
- Connections as SKShapeNode lines (solid/dashed/arrowed)
- Custom force simulation with tunable parameters
- Spatial hashing for performance
- Estimated timeline: 4-6 weeks for full implementation

### 3. CloudKit Implementation
**File**: `cloudkit-implementation.md`

**Key Findings:**
- NSPersistentCloudKitContainer simplifies Core Data + CloudKit sync
- Private database only for maximum privacy
- Automatic encryption and sync across devices
- Core Data provides local cache for offline support
- CKAssets for efficient photo storage

**Implementation Approach:**
- Use NSPersistentCloudKitContainer for MVP
- App Groups for widget data sharing
- Graceful error handling for network issues
- Change tokens for efficient delta sync
- "Soft offline" mode with local cache

### 4. Apple Shortcuts Integration
**File**: `apple-shortcuts-integration.md`

**Key Findings:**
- Back Tap + Shortcuts = frictionless screenshot import
- Built-in OCR in Shortcuts extracts text accurately
- URL scheme simplest integration method for MVP
- Cloudflare Workers for backend processing
- Gemini AI detects contacts and summarizes

**Implementation Approach:**
- Define custom URL scheme: `circles://import`
- Distribute pre-configured shortcut via iCloud link
- Backend API processes text with Gemini
- Inbox for unmatched notes (AI confidence < 0.7)
- Onboarding teaches Back Tap setup

### 5. Speech Recognition and AI
**File**: `speech-recognition-ai.md`

**Key Findings:**
- iOS Speech framework provides real-time transcription
- 3-minute recording limit enforced by timer
- Gemini AI summarizes and extracts key information
- Raw audio discarded after transcription (privacy)
- User can edit AI summary before saving

**Implementation Approach:**
- Real-time waveform visualization during recording
- iOS Speech Recognition for transcription (free, accurate)
- Gemini API for summarization and extraction
- Graceful degradation: save raw transcription if AI fails
- Available only from contact profile page

### 6. WidgetKit Implementation
**File**: `widgetkit-implementation.md`

**Key Findings:**
- Three widget sizes: small (2 contacts), medium (4), large (8)
- Show contacts needing attention with color-coded urgency
- iOS 17+ supports interactive widgets with buttons
- App Groups required for data sharing
- 4-6 hour refresh interval recommended

**Implementation Approach:**
- Timeline-based updates via TimelineProvider
- Share data through UserDefaults in app group
- Color-coded urgency: green → yellow → orange → red
- Quick check-in button (iOS 17+) via App Intents
- Profile photos with fallback to initials

### 7. Glass UI Design
**File**: `glass-ui-design.md`

**Key Findings:**
- SwiftUI materials (`.ultraThinMaterial`) provide native glass effect
- Key elements: translucent background, subtle border, soft shadow
- Continuous corner radius for premium feel
- Performance considerations with materials
- Must support dark mode and accessibility

**Implementation Approach:**
- Use `.ultraThinMaterial` for card backgrounds
- `.stroke(.white.opacity(0.2))` for borders
- Subtle shadows for depth
- GlassCard, GlassButton, GlassBottomSheet components
- Test with Reduce Transparency accessibility setting

## Technical Stack Summary

### Frontend
- **Platform**: iOS 16+
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Graph**: SpriteKit
- **Data**: Core Data + CloudKit (NSPersistentCloudKitContainer)
- **Speech**: iOS Speech Recognition Framework
- **Widgets**: WidgetKit
- **IAP**: StoreKit 2

### Backend
- **Hosting**: Cloudflare Workers (serverless)
- **AI**: Gemini 2.5 API (free tier)
- **Authentication**: Apple Sign-In
- **Language**: TypeScript/JavaScript

### Services
- **Cloud Storage**: CloudKit (Private Database)
- **Photos**: CKAssets
- **Sync**: Automatic via NSPersistentCloudKitContainer
- **Shortcuts**: Apple Shortcuts with URL scheme

## Architecture Overview

```
iOS App (SwiftUI)
├── Home (List View)
│   ├── Contact Cards (Glass UI)
│   ├── Search Bar
│   └── Floating Action Button
├── Web (Graph View)
│   ├── SpriteKit Scene
│   ├── Force-Directed Layout
│   └── Connection Details
├── Reminders
│   ├── Upcoming Reminders
│   └── Birthday Alerts
├── Contact Detail
│   ├── Profile Info
│   ├── Interaction Timeline
│   ├── Voice Note Recording
│   ├── Gift Suggestions (AI)
│   └── Relationship Meter
└── Settings
    ├── Reminder Intervals
    └── Notifications

Widget Extension (WidgetKit)
├── Small Widget (2 contacts)
├── Medium Widget (4 contacts)
└── Large Widget (8 contacts)

Apple Shortcuts
└── Import Message (OCR + API)

Backend (Cloudflare Workers)
├── /api/process-screenshot
├── /api/summarize-voice-note
└── /api/generate-gift-ideas

Data Layer
├── CloudKit (Private Database)
└── Core Data (Local Cache)
```

## Key Technical Decisions

### 1. SpriteKit for Graph
**Decision**: Use SpriteKit with custom force-directed algorithm
**Rationale**: No suitable third-party library, SpriteKit provides excellent performance and touch handling
**Trade-off**: More development time, but full control and optimization

### 2. NSPersistentCloudKitContainer
**Decision**: Use Apple's integrated Core Data + CloudKit solution
**Rationale**: Automatic sync, conflict resolution, proven technology
**Trade-off**: Less sync control, but much faster development

### 3. Cloudflare Workers
**Decision**: Serverless backend on Cloudflare's edge network
**Rationale**: Fast, cheap, scales automatically, easy deployment
**Trade-off**: Cold starts, but minimal for API endpoints

### 4. Gemini 2.5 (Free)
**Decision**: Use Google's Gemini API for AI processing
**Rationale**: Free tier sufficient for MVP, good quality, fast responses
**Trade-off**: Vendor lock-in, but easy to swap later

### 5. StoreKit 2 (Native)
**Decision**: Use StoreKit 2 directly without third-party SDK
**Rationale**: Simple subscription model, reduced dependencies
**Trade-off**: More code, but full control and no recurring costs

### 6. URL Scheme (Not App Intents)
**Decision**: Start with URL scheme for Shortcuts integration
**Rationale**: Simpler, works on iOS 15+, proven approach
**Trade-off**: Less elegant than App Intents, but faster to implement

## Implementation Priorities

### Phase 1: Core Functionality (MVP)
1. Basic UI with Glass design
2. Contact management (CRUD)
3. CloudKit sync
4. Relationship meter
5. Reminders (basic)

### Phase 2: Differentiation Features
1. Force-directed graph visualization
2. Voice notes with AI summarization
3. Apple Shortcuts integration
4. Widgets

### Phase 3: Monetization
1. StoreKit 2 integration
2. Feature gating
3. Paywall design
4. Free trial implementation

### Phase 4: Polish
1. Gift suggestions (AI)
2. Advanced reminders
3. Performance optimization
4. Accessibility improvements

## Risk Assessment

### High Risk
1. **Graph Performance**: Complex force-directed layout with many nodes
   - **Mitigation**: Barnes-Hut algorithm, LOD, spatial hashing
2. **CloudKit Sync Conflicts**: Multi-device editing
   - **Mitigation**: Use NSPersistentCloudKitContainer's built-in resolution

### Medium Risk
1. **AI Quality**: Gemini might misidentify contacts or provide poor summaries
   - **Mitigation**: Confidence thresholds, inbox for unmatched, user editing
2. **Shortcut Adoption**: Users may not set up Back Tap integration
   - **Mitigation**: Excellent onboarding, clear value proposition

### Low Risk
1. **StoreKit Implementation**: Well-documented, standard approach
   - **Mitigation**: Follow Apple guidelines, test thoroughly
2. **Speech Recognition**: Mature iOS framework
   - **Mitigation**: Handle errors gracefully, allow text input alternative

## Performance Targets

- **App Launch**: <2s cold start
- **Contact List**: 60 FPS scrolling with 500+ contacts
- **Graph Rendering**: 60 FPS with 100 nodes, 30 FPS with 500 nodes
- **Voice Note**: <3s from stop to AI summary
- **CloudKit Sync**: <5s for typical sync
- **Screenshot Import**: <5s end-to-end

## Accessibility Requirements

- [ ] VoiceOver support for all screens
- [ ] Dynamic Type support
- [ ] Reduce Transparency support (glass UI fallback)
- [ ] High Contrast mode
- [ ] Voice Control compatibility
- [ ] Alternative to voice notes (text input)

## Privacy Considerations

### Data Collection
- Contact information (names, relationships, notes)
- Interaction timestamps
- Voice transcriptions (not audio)
- Profile photos

### Data Processing
- iOS Speech Recognition (Apple servers)
- Gemini AI (Google servers)
- CloudKit storage (Apple servers)

### User Control
- All data synced via CloudKit (user's iCloud)
- Can delete individual contacts/interactions
- Can disable AI features
- Export capability (future)

## Testing Strategy

### Unit Tests
- Data models
- Force-directed algorithm
- AI response parsing
- Date calculations

### Integration Tests
- CloudKit sync
- Widget data sharing
- Shortcut URL handling
- StoreKit purchases

### UI Tests
- Contact creation flow
- Graph interactions
- Voice note recording
- Onboarding

### Performance Tests
- Graph with 100, 500, 1000 nodes
- CloudKit sync with large dataset
- Widget refresh performance
- Memory usage

### Manual Tests
- Multi-device sync
- Offline functionality
- Error recovery
- Accessibility features

## Next Steps

1. **Review Requirements**: Ensure all needs captured
2. **Create Detailed Design**: Architecture, data models, UI flows
3. **Develop Implementation Plan**: Break into concrete, testable prompts
4. **Begin Development**: Start with core functionality

## Key Takeaways

1. **Solid Foundation**: Native iOS technologies provide everything needed
2. **Custom Graph**: Most complex component, requires custom implementation
3. **AI is Differentiator**: Voice notes and screenshot import set app apart
4. **Privacy First**: CloudKit ensures user data stays private
5. **Premium Feel**: Glass UI creates high-quality aesthetic
6. **Freemium Model**: Clear path to monetization with premium features
7. **Achievable MVP**: All components have clear implementation paths

## Resources Directory

- `storekit-monetization.md`: In-app purchase implementation
- `graph-visualization.md`: Force-directed graph with SpriteKit
- `cloudkit-implementation.md`: Data storage and sync
- `apple-shortcuts-integration.md`: Screenshot import workflow
- `speech-recognition-ai.md`: Voice notes and AI summarization
- `widgetkit-implementation.md`: Home screen widgets
- `glass-ui-design.md`: Glassmorphism UI patterns

## Research Complete

All necessary research has been conducted to proceed with detailed design and implementation planning. The technical approaches are validated, libraries and frameworks identified, and implementation strategies defined.
