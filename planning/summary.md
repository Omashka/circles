# Circles - Project Summary

## Overview

**Circles** is a relationship management iOS app that helps users maintain meaningful connections through visual relationship mapping, AI-powered insights, and gentle reminders—all with a premium glass UI aesthetic and privacy-first architecture.

**Date**: January 4, 2026
**Status**: Design and planning complete, ready for implementation

---

## What Was Created

### 1. Requirements Clarification (`planning/idea-honing.md`)
Comprehensive Q&A session covering 20 key decision points:
- Platform: iOS with Swift and Apple's glass UI
- Target users: Social butterflies and people maintaining distant relationships
- Data storage: CloudKit with NSPersistentCloudKitContainer
- Core features: People list, relationship graph, voice notes, shortcuts integration, widgets
- Monetization: Freemium model with premium subscription
- Edge cases and error handling strategies

### 2. Research Documents (`planning/research/`)
Seven comprehensive research documents:

- **storekit-monetization.md**: StoreKit 2 implementation, pricing strategy ($4.99/month), feature gating
- **graph-visualization.md**: SpriteKit force-directed graphs, performance optimization, touch interactions
- **cloudkit-implementation.md**: Data models, sync strategies, offline support, NSPersistentCloudKitContainer
- **apple-shortcuts-integration.md**: Back Tap + OCR workflow, URL scheme handling, contact detection
- **speech-recognition-ai.md**: iOS Speech Framework, Gemini AI integration, 3-minute voice notes
- **widgetkit-implementation.md**: Home screen widgets, timeline updates, app group data sharing
- **glass-ui-design.md**: Glassmorphism patterns, SwiftUI materials, component library
- **research-summary.md**: Comprehensive overview tying everything together

### 3. Detailed Design (`planning/design/detailed-design.md`)
Complete technical design including:
- System architecture diagram
- Navigation structure
- Core Data entities (Contact, Interaction, Connection, UnassignedNote, UserSettings)
- View models and data flow
- SpriteKit graph components
- API specifications (Cloudflare Workers endpoints)
- Error handling strategies
- Testing approach
- Security and privacy considerations

### 4. Implementation Plan (`planning/implementation/prompt-plan.md`)
20 sequential, testable prompts for building the app:
1. Project setup and Core Data models
2. CloudKit configuration and data manager
3. Basic UI structure and navigation
4. Contact list view with glass UI
5. Contact detail view and editing
6. Relationship meter and interaction logging
7. Voice notes with speech recognition
8. AI service integration (Gemini API)
9. Apple Shortcuts integration (URL scheme)
10. Cloudflare Workers backend
11. Force-directed graph foundation (SpriteKit)
12. Graph interactions and connection management
13. Widget extension implementation
14. StoreKit 2 integration and paywalls
15. Reminders and notifications
16. Settings and user preferences
17. Onboarding flow
18. Error handling and offline support
19. Testing and polish
20. App Store preparation

---

## Key Features

### Core Functionality (MVP)

#### 1. Contact Management
- **People-First List**: Scrollable list with profile photos, relationship types, and last contact indicators
- **Detailed Profiles**: Comprehensive "cheat sheet" for each person (interests, family, job, important dates)
- **Search & Filter**: Quick contact lookup
- **Relationship Types**: Predefined + custom categories

#### 2. Relationship Visualization
- **Interactive Graph**: Force-directed 2D graph showing connections between contacts
- **Visual Connections**: Different line styles (solid/dashed/arrowed) for relationship types
- **Zoom & Pan**: Navigate large networks smoothly
- **Connection Details**: Tap lines to see "how you know them"

#### 3. Smart Tracking
- **Voice Notes**: 3-minute recordings with automatic transcription and AI summarization
- **Screenshot Import**: Double-tap phone back → import messages via Apple Shortcuts
- **Interaction Timeline**: Chronological log of all interactions per contact
- **Relationship Meter**: Color-coded health indicator (green → yellow → orange → red)

#### 4. Reminders & Notifications
- **Check-in Reminders**: Automatic alerts after 30 days (configurable)
- **Birthday Alerts**: Never forget important dates
- **Widget Support**: Home screen glanceable info (small/medium/large sizes)
- **Custom Intervals**: Different reminder periods per relationship type

#### 5. AI-Powered Insights
- **Gift Suggestions**: Context-aware gift ideas based on interests and conversations
- **Information Extraction**: Automatically parse dates, events, interests from notes
- **Contact Detection**: AI identifies contacts from imported messages
- **Smart Summarization**: Turn lengthy conversations into actionable insights

### Premium Features

**Free Tier**:
- Up to 20-30 contacts
- Basic people list
- Manual notes
- Limited reminders

**Premium ($4.99/month or $39.99/year)**:
- Unlimited contacts
- Full relationship graph visualization
- AI gift suggestions
- Voice note transcription & summarization
- Advanced widgets
- Priority support
- 7-day free trial

---

## Technical Architecture

### Technology Stack

**Frontend (iOS App)**:
- **Platform**: iOS 16+
- **Language**: Swift
- **UI Framework**: SwiftUI with glassmorphism design
- **Graph**: SpriteKit (custom force-directed algorithm)
- **Data**: Core Data + CloudKit (NSPersistentCloudKitContainer)
- **Speech**: iOS Speech Recognition Framework
- **Widgets**: WidgetKit
- **IAP**: StoreKit 2

**Backend (Serverless)**:
- **Platform**: Cloudflare Workers
- **Language**: TypeScript/JavaScript
- **AI**: Gemini 2.5 API (free tier)
- **Auth**: Apple Sign-In tokens

**Data Layer**:
- **Cloud**: CloudKit Private Database (encrypted, auto-sync)
- **Local**: Core Data (offline cache)
- **Photos**: CKAssets (efficient binary storage)
- **Widgets**: App Groups for data sharing

### Architecture Highlights

1. **Privacy-First**: All data in user's iCloud, end-to-end encrypted
2. **Offline-First**: Core Data cache, queue operations when offline
3. **Serverless**: Cloudflare Workers for scalable, low-cost AI processing
4. **Native iOS**: Leverage Apple frameworks for best performance and integration

---

## Design Highlights

### Glassmorphism UI
- **Translucent Cards**: `.ultraThinMaterial` backgrounds
- **Subtle Borders**: `.white.opacity(0.2)` strokes
- **Soft Shadows**: Depth without overwhelming
- **Premium Feel**: Modern, Apple-style aesthetic
- **Dark Mode**: Full support with adaptive colors

### User Experience
- **Low Friction**: Double-tap back to import messages
- **Voice First**: Speak notes instead of typing
- **Visual Context**: See relationship network at a glance
- **Gentle Nudges**: Reminders without guilt or pressure
- **Privacy Control**: User owns all data, can delete anytime

---

## Implementation Approach

### Phased Development

**Phase 1: Foundation (Prompts 1-6)** - 2-3 weeks
- Core Data models and CloudKit sync
- Basic UI with glass design
- Contact management CRUD
- Relationship meter and manual interaction logging

**Phase 2: Differentiation (Prompts 7-12)** - 3-4 weeks
- Voice notes with AI summarization
- Apple Shortcuts integration
- Force-directed graph visualization
- Connection management

**Phase 3: Polish (Prompts 13-20)** - 2-3 weeks
- Widgets
- StoreKit 2 monetization
- Reminders system
- Settings, onboarding, error handling
- Testing and App Store preparation

**Total Timeline**: 7-10 weeks for MVP

### Testing Strategy
- **Unit Tests**: Data models, algorithms, business logic
- **Integration Tests**: CloudKit sync, API calls, IAP flow
- **UI Tests**: User flows, navigation, accessibility
- **Performance Tests**: Graph with 500+ nodes, scroll performance

---

## Key Innovations

1. **Force-Directed Relationship Graph**: Unique visualization of social networks
2. **Back Tap Import**: Frictionless message screenshot capture
3. **AI-Powered Insights**: Gift suggestions and smart summarization
4. **Privacy-First Architecture**: No backend database, CloudKit only
5. **Premium Glass UI**: Modern, beautiful design language

---

## Risk Mitigation

### High-Risk Areas
| Risk | Mitigation |
|------|-----------|
| Graph performance with many nodes | Barnes-Hut algorithm, LOD, spatial hashing |
| CloudKit sync conflicts | Use NSPersistentCloudKitContainer's built-in resolution |
| AI quality (contact detection) | Confidence thresholds, inbox for unmatched, user editing |
| User adoption of shortcuts | Excellent onboarding, clear value proposition |

### Testing & Quality
- Comprehensive test suite (unit, integration, UI)
- Performance profiling with Instruments
- Accessibility audit with VoiceOver
- Multi-device sync testing
- Beta testing via TestFlight

---

## Success Metrics

### Engagement
- Contacts added per user
- Interactions logged per week
- Widget placement rate
- Voice notes recorded per week

### Retention
- Day 1, 7, 30 retention rates
- Weekly Active Users (WAU)
- Average session duration

### Monetization
- Free → Premium conversion rate
- Trial → Paid conversion rate
- Monthly Recurring Revenue (MRR)
- Average Revenue Per User (ARPU)

### Technical
- App launch time: <2s
- CloudKit sync success: >99%
- API response time: <2s (p95)
- Crash-free rate: >99.5%

---

## Next Steps

### Immediate (Week 1)
1. ✅ Review detailed design document
2. ✅ Understand implementation plan structure
3. 🔄 Begin **Prompt 1**: Project setup and Core Data models
4. 🔄 Set up development environment (Xcode, CloudKit Dashboard)

### Short-term (Weeks 2-4)
- Complete Prompts 2-6 (foundation features)
- Set up CloudKit container
- Build basic UI with glass design
- Implement contact management

### Mid-term (Weeks 5-8)
- Complete Prompts 7-12 (differentiation features)
- Add voice notes and AI integration
- Build relationship graph
- Integrate Apple Shortcuts

### Long-term (Weeks 9-10)
- Complete Prompts 13-20 (polish and launch)
- Add widgets and monetization
- Comprehensive testing
- App Store submission

---

## Resources

### Documentation
- `planning/rough-idea.md`: Original concept
- `planning/idea-honing.md`: Requirements clarification (20 Q&As)
- `planning/research/`: 7 technical research documents
- `planning/design/detailed-design.md`: Complete technical design
- `planning/implementation/prompt-plan.md`: 20 implementation prompts

### External Links
- [Apple CloudKit Documentation](https://developer.apple.com/icloud/cloudkit/)
- [StoreKit 2 Guide](https://developer.apple.com/storekit/)
- [SwiftUI Materials](https://developer.apple.com/documentation/swiftui/material)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## Project Statistics

- **Requirements Questions**: 20 answered
- **Research Documents**: 7 comprehensive guides
- **Design Pages**: 100+ pages of detailed specification
- **Implementation Prompts**: 20 sequential, testable steps
- **Estimated Lines of Code**: ~15,000-20,000 (Swift + TypeScript)
- **Estimated Development Time**: 7-10 weeks for MVP

---

## Conclusion

The Circles app has been meticulously designed with a clear vision, comprehensive technical specification, and actionable implementation plan. The architecture leverages native iOS technologies for a premium, privacy-focused experience while incorporating cutting-edge AI features for differentiation.

**The foundation is set. Time to build.** 🚀

### How to Continue

1. **Start Implementation**: Begin with Prompt 1 in `planning/implementation/prompt-plan.md`
2. **Reference Design**: Consult `planning/design/detailed-design.md` for technical details
3. **Check Research**: Review relevant research documents as needed
4. **Commit Progress**: Create git commits after each prompt completion
5. **Test Thoroughly**: Run tests after each major feature

### Getting Help

- **Design Questions**: Reference `detailed-design.md`
- **Technical Questions**: Check research documents in `planning/research/`
- **Requirements Questions**: Review `idea-honing.md`
- **Implementation Questions**: Follow prompts in `prompt-plan.md`

---

**Project Start Date**: January 4, 2026  
**Planning Status**: ✅ Complete  
**Ready for**: Implementation Phase  
**Next Action**: Execute Prompt 1 - Project setup and Core Data models

---

*Built with Prompt-Driven Development methodology*
