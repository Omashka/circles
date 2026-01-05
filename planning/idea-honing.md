# Requirements Clarification

This document captures the interactive Q&A process to refine and clarify the requirements for the relationship management app.

---

## Question 1: Target Platform and Primary Use Case

What is the primary platform for this app (iOS, Android, web, or cross-platform), and who is the target user? Are you envisioning this for:
- Professionals managing business relationships?
- Social butterflies maintaining large friend networks?
- People who struggle to keep in touch with distant friends/family?
- A specific demographic or use case?

Understanding the platform and target audience will help shape decisions about features, UI complexity, and technical approach.

**Answer:**
- **Primary Platform**: iOS
- **Technology Stack**: Swift with Apple's glass UI (for premium look and feel)
- **Target Users**: 
  - Social butterflies maintaining large friend networks
  - People who struggle to keep in touch with distant friends and family
- **Future Expansion**: Eventually target professionals managing business relationships

---

## Question 2: Data Storage and Privacy

Given the highly personal nature of relationship data (notes about people, interactions, photos), how should the app handle data storage and privacy?

Options to consider:
- **Local-only storage**: All data stays on the device (maximum privacy, no sync)
- **iCloud Private Database**: Apple's encrypted cloud storage (privacy + sync across user's devices)
- **Custom backend with end-to-end encryption**: More flexibility but more complex
- **Hybrid approach**: Local storage with optional cloud backup

Also, what's your vision for data portability? Should users be able to export their relationship data, or is it primarily meant to stay within the app ecosystem?

**Answer:**
- **Storage Solution**: CloudKit (Apple's iCloud infrastructure)
- This provides encrypted cloud storage with automatic sync across the user's Apple devices
- Maintains strong privacy while enabling seamless multi-device experience

---

## Question 3: Smart Prompts and User Activity Triggers

You mentioned the app should prompt users to save notes after calendar events or phone calls end. How should these prompts work in practice?

Specifically:
- Should the app integrate with iOS Calendar and Phone apps directly, or rely on user initiation?
- For calendar events, should it prompt for ALL events, or only those with specific people from the contacts list?
- How intrusive should the prompts be? (notification, in-app banner, widget prompt, etc.)
- Should there be a time delay after an event ends before prompting?
- What about other trigger points like after sending messages, visiting locations, or other activities?

Understanding the prompt mechanism will help define the technical approach and user experience flow.

**Answer:**
- **Calendar Integration**: Not implementing for now (deferred to future version)
- Focus on manual, user-initiated note-taking rather than automated triggers
- Users will proactively add notes and interactions when they choose

---

## Question 4: Relationship Graph Visualization

You described a visual relationship web with different line styles (solid/dashed/arrowed) and thickness to show connections. This is a core feature. 

Questions about the graph:
- Should this be a 2D force-directed graph (nodes repel/attract), a hierarchical layout, or something else?
- How many contacts should be displayable at once? (What scale are we designing for - dozens, hundreds, thousands?)
- Should users be able to manually position/arrange contacts in the graph, or should it be automatic?
- When you tap a connection line, should it show connection details in a modal/popup, or expand inline?
- Should the graph be navigable/zoomable for large networks?

**Answer:**
- **Graph Type**: 2D force-directed graph (nodes repel/attract automatically)
- **Scale**: Design for dozens to hundreds of contacts initially, with performance optimization for larger networks
- **Layout**: Automatic force-directed positioning with ability to manually rearrange if needed
- **Connection Details**: Show in a popup/sheet (following Apple HIG - likely bottom sheet or popover)
- **Navigation**: Fully zoomable and pannable for exploring large networks
- **Priority**: Maintain excellent user experience as network grows

---

## Question 5: Relationship Types and Categories

You mentioned relationship types displayed on the home screen and different line styles for different relationship strengths (family, partner, acquaintance, etc.).

Questions:
- Should relationship types be predefined categories (Family, Friend, Partner, Colleague, Acquaintance) or fully customizable?
- Can a contact have multiple types? (e.g., Friend + Colleague)
- Who defines the relationship strength for the line style - user explicitly, or automatically based on interaction frequency?
- Should there be relationship subcategories? (e.g., Family > Sibling, Family > Parent, Friend > College Friend, Friend > Childhood Friend)

**Answer:**
- **Relationship Types**: Predefined categories (Family, Friend, Partner, Colleague, Acquaintance) with ability to add custom categories
- **Multiple Types**: No - each contact has one primary relationship type
- **Line Style/Thickness**: Automatically determined by interaction frequency (more interactions = thicker/stronger lines)
- **Subcategories**: Not implementing subcategories for simplicity

**Additional Feature - Apple Shortcuts Integration:**
- Integrate with Apple Shortcuts to allow users to screenshot iMessages and import message content
- This will help build out connections and capture important events/reminders from conversations
- Makes it easy to save contextual information without manual typing

---

## Question 6: Relationship Meter and Check-in Reminders

You mentioned a relationship meter showing how recently/consistently users have interacted, and reminders when it's been more than a month since last contact.

Questions:
- How should the relationship meter be visualized? (progress bar, color indicator, days/weeks counter, etc.)
- Should reminder notifications be automatic after 1 month, or should users set custom reminder intervals per contact?
- Can users disable reminders for specific contacts? (e.g., distant relatives you're not close with)
- Should there be different reminder thresholds for different relationship types? (e.g., check in with close friends every 2 weeks vs acquaintances every 3 months)
- How should reminders appear? (iOS notification, in-app badge, home screen indicator?)

**Answer:**
- **Visualization**: Progress bar with color coding (green = recent contact, transitioning to yellow/orange as time passes)
- **Default Reminder**: Automatic reminder after 1 month of no contact
- **Customization**: Users can change reminder intervals in settings
- **Per-Contact Control**: Cannot disable reminders for specific contacts (all contacts get reminders)
- **Relationship-Based Thresholds**: Yes - different reminder intervals can be set for different relationship types
- **Notification Method**: Standard iOS notifications

---

## Question 7: AI-Powered Gift Suggestions

You mentioned AI suggestions for gift ideas based on birthdays and what people have mentioned/their likes.

Questions:
- Should this integrate with an AI service (ChatGPT, Claude, etc.) or use local on-device intelligence?
- What information should the AI use to make suggestions? (notes from interactions, interests field, past gifts given, price range preferences?)
- When should gift suggestions appear? (Only when birthday is approaching, or available anytime from the profile?)
- Should users be able to save/bookmark gift ideas for later?
- Do you want integration with shopping services, or just text-based suggestions?

**Answer:**
- **AI Service**: Gemini 2.5 (free tier)
- **Data Sources for Suggestions**: 
  - Messages/notes from interactions (imported via Shortcuts or manually entered)
  - Profile information (interests, hobbies, job, etc.)
  - Any other relevant context stored in the profile
- **Timing**: (To be clarified - when should suggestions appear?)
- **Bookmarking**: (To be clarified - can users save gift ideas?)
- **Shopping Integration**: (To be clarified - text only or links to products?)

---

## Question 7b: Gift Suggestion Details

Just to complete the gift suggestion feature - a few quick clarifications:

- When should gift suggestions be available? (Always accessible from profile, or only when birthday is approaching?)
- Should users be able to save/bookmark specific gift ideas for later reference?
- Text-based suggestions only, or should it include product links/shopping integration?

**Answer:**
- **Availability**: Accessible anytime from the contact's profile (not just near birthdays)
- **Bookmarking**: Not implementing for now
- **Format**: Text-based suggestions with:
  - Gift name/title
  - Price range estimate
  - Brief description
  - "Based on what you know" section showing the interests/context used
  - Event context (Birthday, Holiday, etc.)
- **Shopping Integration**: No direct product links for now - just suggestions

---

## Question 8: Photo Management and Display

You mentioned users can upload photos with automatic date/time stamps, creating a private diary for each relationship. You also mentioned "fake photos for each contact."

Questions:
- Should each contact have a profile photo separate from the timeline photos?
- What did you mean by "fake photos" - placeholder avatars/images, or AI-generated photos?
- Should photos be organized chronologically, by event, or both?
- Can users add captions or notes to photos?
- Should photos appear in the relationship timeline along with other interactions, or in a separate gallery?
- Any limits on number of photos per contact?

**Answer:**
- **Profile Photo**: Yes - each contact has one profile photo
- **Placeholder Avatars**: Use placeholder/default avatars if user hasn't added a photo
- **Photo Gallery/Timeline**: NOT implementing for now - only profile photos
- **Future Consideration**: Photo timeline and shared memories deferred to later version

---

## Question 9: Contact Profile Information

The profile acts as a relationship "cheat sheet" with key facts. What specific fields/sections should each contact profile include?

Based on your initial idea, I'm seeing:
- Name (required)
- Relationship type (required)
- Profile photo
- Birthday
- Family details
- Interests/hobbies
- Job/career info
- Religious/cultural events
- Recent travel
- Topics to avoid
- Important dates (beyond birthday)
- Interaction timeline/notes

Should all these be included? Any additions or removals? Should any fields be required vs optional?

**Answer:**
All fields confirmed. Complete profile structure:

**Required Fields:**
- Name
- Relationship type

**Optional Fields:**
- Profile photo (with placeholder if not set)
- Birthday
- Family details
- Interests/hobbies
- Job/career info
- Religious/cultural events
- Recent travel
- Topics to avoid
- Important dates (beyond birthday)
- Interaction timeline/notes (chronological log)

**Automatically Tracked:**
- Last connected (date of last interaction)
- Relationship meter (visual indicator based on interaction frequency)

---

## Question 10: Interaction Logging

How should users log interactions with contacts to update the "last connected" date and relationship meter?

Options:
- Manual "Log Interaction" button with optional notes
- Quick-log from home screen (tap to mark "connected today")
- Only counts when user adds a note/memory to the timeline
- Integration with message imports from Apple Shortcuts (automatically updates when importing messages)
- Combination of the above?

Also, should users be able to backdate interactions? (e.g., "We had coffee yesterday but I forgot to log it")

**Answer:**
Interactions are logged when:
- User adds voice notes (speech-to-text, then AI summarized and added to timeline)
- User imports iMessage screenshot via Apple Shortcuts (automatically logged)

**Additional Features Included:**
- iOS widgets for quick access and logging

**Deferred/Not Including:**
- Siri Shortcuts integration (not for MVP)
- Backdating interactions (not for MVP)
- Quick clipboard paste (covered by Shortcuts integration)

---

## Question 11: Widget Design and Functionality

iOS supports multiple widget sizes (small, medium, large). What should the widget(s) display and do?

Options to consider:
- Show contacts you haven't connected with recently (with quick check-in button)
- Show upcoming birthdays/important dates
- Quick access to add note for specific contacts
- Relationship meter summary (who needs attention)
- Display different content based on widget size

What would be most useful for users to see/do from their home screen?

**Answer:**
- **Primary Widget Function**: Show contacts you haven't connected with recently
- Include quick check-in button for each contact displayed
- Widget provides at-a-glance view of relationships that need attention
- Different widget sizes can show different numbers of contacts

---

## Question 12: App Navigation and Structure

You've described two main views: a people-first list (home screen) and a visual relationship graph. How should users navigate between these views and access other features?

Questions:
- Should there be a tab bar at the bottom? (e.g., List, Graph, Settings)
- Or a navigation bar with view toggles?
- Where does "Add New Contact" live?
- Should there be a search/filter feature? If so, where is it accessed?
- Any other top-level screens needed? (Settings, Reminders, etc.)

**Answer:**
**Navigation Structure:**
- **Bottom Tab Bar** with 3 tabs:
  - "People" (list view - default home screen)
  - "Web" (relationship graph visualization)
  - "Reminders" (notifications and check-in reminders)
- **Top Bar Elements**:
  - App name/title with connection count
  - Settings icon (top right)
  - Search bar below header for finding contacts
- **People List View** shows:
  - Profile photo
  - Name
  - Relationship type
  - Time since last interaction ("X days ago")
- **Add New Contact**: Likely via + button (standard iOS pattern in top right or floating action button)

---

## Question 13: Drag-and-Drop Connection Creation

You mentioned drag-and-drop to connect contacts (e.g., marking them as siblings or friends of friends). How should this work?

Questions:
- Where does drag-and-drop happen? (Only in the Web/graph view, or also from the People list?)
- What's the interaction flow? (Drag person A onto person B, then select connection type?)
- Should there be an alternative method for creating connections for accessibility? (e.g., tap person, select "Add Connection", choose another person)
- Can one person have multiple connections? (e.g., Sarah is connected to both Mike and Lisa)
- Should connection types be predefined? (Sibling, Parent, Friend, Introduced by, Colleague, etc.)

**Answer (Best Practice Recommendations):**
- **Location**: Primarily in the Web/graph view where connections are visualized
  - Also available from contact profile (button to "Add Connection to Another Contact")
- **Interaction Flow**: 
  - Drag person A onto person B in graph view
  - Sheet appears to select connection type and add context
  - Connection line appears with appropriate styling
- **Accessibility Alternative**: 
  - Tap contact → "Add Connection" button
  - Search/select another contact from list
  - Choose connection type
- **Multiple Connections**: Yes - each person can be connected to many others
- **Connection Types**: Predefined with custom option
  - Family (Sibling, Parent, Child, Spouse/Partner, Extended Family)
  - Social (Friend, Best Friend, Acquaintance)
  - Professional (Colleague, Mentor, Client)
  - Introducer (Introduced you to others, Was introduced by)
  - Custom (user can add their own)
- **Connection Metadata**: Optional fields for context
  - "How you met" / "Shared context" (e.g., "college roommates", "met through Sarah, 2019")
  - Date connection was established

---

## Question 14: Voice Notes and AI Processing

You mentioned users can speak into notes which are then summarized via AI. How should this work?

Questions:
- Should voice recording be available from multiple places? (contact profile, widget, quick-add from home screen?)
- What happens to the raw audio? (Kept for reference, or discarded after transcription?)
- Should the AI summary be editable by the user?
- What should the AI extract/highlight from voice notes? (Important dates, interests, topics, events?)
- Should voice notes have a length limit?
- Which AI service for transcription? (iOS built-in speech recognition, or Gemini API?)

**Answer:**
- **Availability**: Voice recording only from contact profile detail page
- **Audio Storage**: Raw audio discarded after transcription (not kept)
- **AI Summary**: Editable by user after generation
- **AI Extraction**: Should identify and highlight:
  - Interests and hobbies
  - Topics discussed
  - Events and activities
  - Important dates mentioned
- **Length Limit**: 3 minutes maximum
- **User Experience**: Seamless behind-the-scenes processing
  - User speaks into microphone
  - System automatically transcribes (iOS Speech Recognition)
  - Gemini AI summarizes and extracts key information
  - Summary added to interaction timeline
  - User can edit summary before saving

---

## Question 15: Apple Shortcuts Integration Details

You mentioned users can screenshot iMessages and import them via Apple Shortcuts. How should this work technically?

Questions:
- Should the shortcut extract text from the screenshot using OCR?
- How does the user specify which contact the message is about? (Manual selection, or AI detects names?)
- Should it also extract dates/times from the screenshot?
- What information gets saved? (Full message text, or just AI summary?)
- Should this work for other apps too? (WhatsApp, Instagram DMs, etc.)?

**Answer:**
- **Trigger**: iOS Back Tap accessibility feature (double tap back of phone) launches the shortcut
- **Text Extraction**: Apple Shortcuts OCR capability extracts text from screenshot
- **Processing Flow**:
  - User takes screenshot of message (iMessage, WhatsApp, etc.)
  - Double tap back of phone triggers shortcut
  - Shortcut extracts text using OCR
  - Sends text content to app/server
  - AI (Gemini) automatically detects which contact the message is about
  - AI generates summary of the conversation
  - Interaction logged automatically for that contact
- **Data Saved**: AI-generated summary (not full message text)
- **Supported Apps**: iMessage and WhatsApp (MVP), potentially others in future
- **Server Component**: Backend service needed to receive screenshot text, process with AI, and update contact data

---

## Question 16: Settings and Preferences

What configuration options should users have access to in Settings?

Potential settings to consider:
- Reminder intervals (default and per-relationship-type)
- Notification preferences
- AI/privacy settings (data usage, AI service toggle)
- Widget configuration
- Data export/import
- Account/sync settings
- Theme/appearance options
- Default relationship type for new contacts
- Any others?

Which settings are most important for the MVP?

**Answer:**
**MVP Settings (Keep it Light):**
- **Reminder Intervals**: Configure default reminder period and per-relationship-type thresholds
- **Notification Preferences**: Control when and how reminders are sent

**Deferred to Future Versions:**
- AI/privacy settings
- Widget configuration
- Data export/import
- Account/sync settings (CloudKit handles this automatically)
- Theme/appearance options
- Default relationship type for new contacts

---

## Question 17: 'Why Do I Know This Person?' Feature

You mentioned adding a 'Why do I know this person?' button. This sounds like a helpful memory aid.

Questions:
- Where does this button appear? (In the contact profile, on the graph when viewing a contact node, both?)
- What information should it display?
  - How you met / shared context
  - Who introduced you (if applicable)
  - Timeline of your relationship (first met, key moments)
  - Connection path in the network (e.g., 'Friend of Sarah, met at college')
- Should this be auto-generated by AI based on available data, or manually filled in by the user, or both?

**Answer:**
- **Location**: In the Web/graph view when tapping on connection lines between contacts
- **Display**: Shows in the modal/sheet that appears when user taps a connection
- **Information Displayed**:
  - How you met / shared context
  - Who introduced them (if applicable)
  - Connection relationship type
  - Date/timeline information (e.g., 'met through Sarah, 2019')
- **Data Source**: Populated from connection metadata that user enters when creating connections

---

## Question 18: Backend/Server Requirements

Based on our discussion, you'll need a server component for:
- Receiving screenshot text from Apple Shortcuts
- Processing with Gemini AI
- Gift suggestion generation
- Voice note summarization

Questions:
- Should this be a simple serverless function (AWS Lambda, Cloud Functions) or a dedicated server?
- Do you have a preference for backend technology? (Node.js, Python, Swift Vapor, etc.)
- Should user authentication be handled through Apple Sign-In only, or support other methods?
- Any specific hosting preferences or constraints?

**Answer:**
- **Backend Architecture**: Serverless using Cloudflare Workers
- **Benefits**: Fast edge computing, cost-effective, scales automatically
- **Authentication**: Use Apple Sign-In (integrates naturally with iOS and CloudKit)
- **API Endpoints Needed**:
  - POST /process-screenshot - receives text from Shortcuts, processes with Gemini, returns summary
  - POST /generate-gift-ideas - generates gift suggestions for a contact
  - POST /summarize-voice-note - processes transcribed voice notes with AI
- **Technology Stack**: Cloudflare Workers (JavaScript/TypeScript) with Gemini API integration

---

## Question 19: Onboarding and First-Time Experience

What should happen when a user first opens the app?

Questions:
- Should there be an onboarding tutorial/walkthrough?
- How do users add their first contacts? (Import from iOS Contacts, manual entry, both?)
- Should the app request permissions upfront (notifications, speech recognition)?
- Any initial setup steps? (Set default reminder intervals, relationship types to use, etc.)
- Should there be sample/demo data to show what a populated app looks like?

**Answer:**
- **Onboarding Tutorial**: Yes - walkthrough showing:
  - How to set up the Apple Shortcuts Back Tap integration
  - How the app works (core features overview)
  - Brief introduction to key features (voice notes, graph, reminders)
- **Adding First Contacts**:
  - Option to import from iOS Contacts (user selects which contacts to add)
  - Option for manual entry
  - Both methods available
- **Permissions**: Request upfront during onboarding:
  - Notifications (for reminders)
  - Speech Recognition (for voice notes)
  - Contacts access (for importing)
  - CloudKit/iCloud (for sync)
- **Initial Setup**: Minimal - just permissions and contact import
- **Demo Data**: (Not specified - likely not needed if import is easy)

---

## Question 20: Edge Cases and Error Handling

A few edge cases to consider:

**Connection Scenarios:**
- What happens if AI can't detect which contact a screenshot is about?
- What if a contact has no interactions logged yet? (Should relationship meter show differently?)
- Can contacts be archived/hidden without deleting them?

**Graph Scenarios:**
- What if a contact has no connections to others? (Isolated node in graph)
- Should there be a limit on how many connections one person can have?

**Data Scenarios:**
- What happens if CloudKit sync fails?
- Should there be offline mode functionality?

Which of these are important to address in MVP vs future versions?

**Answer:**

**Connection Scenarios (MVP):**
- **AI Can't Detect Contact**: Create an 'Inbox' for unassigned notes
  - User can manually assign them to contacts later
  - Prevents data loss while maintaining flexibility
- **No Interactions Yet**: Show neutral state
  - Display: 'No history yet' message
  - Include 'Add first note' CTA button
  - Relationship meter shows empty/neutral state
- **Archive/Hidden Contacts**: NOT in MVP (deferred to future version)

**Graph Scenarios (MVP):**
- **Isolated Nodes**: Display normally on the graph
  - Position at edge area or as 'floating' nodes
  - Still visible and accessible
  - No special treatment needed
- **Connection Limits**: No hard limit on connections per person

**Data Scenarios (MVP):**
- **CloudKit Sync Fails**: Non-blocking error handling
  - Show banner: 'Sync paused. Retrying...'
  - Keep edits locally in memory and retry automatically
  - User can continue working without interruption
- **Offline Mode**: 'Soft offline' functionality
  - App still opens normally
  - Shows last loaded/cached data if available
  - Edits queued locally and sync when connection restored
  - No hard block on app usage

---

## Requirements Clarification Summary

We've covered:
1. Platform and target users
2. Data storage and privacy
3. Smart prompts and triggers
4. Relationship graph visualization
5. Relationship types and categories
6. Relationship meter and reminders
7. AI-powered gift suggestions
8. Photo management
9. Contact profile structure
10. Interaction logging
11. Widget functionality
12. App navigation and structure
13. Connection creation (drag-drop)
14. Voice notes and AI processing
15. Apple Shortcuts integration
16. Settings and preferences
17. 'Why do I know this person?' feature
18. Backend architecture
19. Onboarding experience
20. Edge cases and error handling


**Status**: Requirements clarification complete. Moving to research phase.
