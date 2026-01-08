# AI Profile Update Plan

## Overview
Plan for automatically updating contact profile fields (Key Facts section) based on AI-extracted information from voice notes.

## Current State

### What's Already Implemented
- ✅ AI extracts: summary, interests, events, dates from voice notes
- ✅ Interests are merged into contact's interests array (basic implementation)
- ✅ User can review/edit AI summary before saving
- ✅ Extracted data is stored in Interaction entity

### What's Missing
- ❌ Work/job information extraction and merging
- ❌ Topics to avoid extraction and merging
- ❌ Family details extraction
- ❌ Travel notes extraction
- ❌ Religious events extraction
- ❌ Birthday/important dates extraction
- ❌ User confirmation for profile updates
- ❌ Conflict resolution (AI vs existing data)
- ❌ Confidence scoring for extracted data

## Data Mapping

### AI Extraction → Contact Fields

| AI Extracted Data | Contact Field | Update Strategy | Priority |
|------------------|---------------|-----------------|----------|
| **Interests** | `interests` (array) | Merge (add new, keep existing) | High |
| **Work/Job mentions** | `jobInfo` (string) | Replace if more specific, merge if partial | High |
| **Topics to avoid** | `topicsToAvoid` (array) | Merge (add new, keep existing) | Medium |
| **Family details** | `familyDetails` (string) | Append new info, don't overwrite | Medium |
| **Travel preferences** | `travelNotes` (string) | Append new info, don't overwrite | Low |
| **Religious events** | `religiousEvents` (array) | Merge (add new, keep existing) | Medium |
| **Birthday/Important dates** | `birthday` (date) | Replace only if more specific | High |
| **Events** | Store in Interaction only | Not merged to profile | N/A |

## Implementation Plan

### Phase 1: Enhanced AI Extraction

#### 1.1 Update AI Prompt
**File**: `Circles/Services/AIService.swift`

**Changes**:
- Enhance `buildSummarizationPrompt()` to extract:
  - Job/work information (company, role, industry)
  - Topics to avoid (sensitive subjects, preferences)
  - Family details (children, spouse, family structure)
  - Travel preferences (destinations, travel style)
  - Religious/cultural events (holidays, observances)
  - Birthday (if mentioned with context)

**New JSON Structure**:
```json
{
  "summary": "...",
  "interests": ["..."],
  "events": ["..."],
  "dates": ["2024-12-25"],
  "workInfo": "Software Engineer at Apple",
  "topicsToAvoid": ["Politics", "Religion"],
  "familyDetails": "Has two children, married",
  "travelNotes": "Loves visiting Japan",
  "religiousEvents": ["Christmas", "Eid"],
  "birthday": "1990-05-15"
}
```

#### 1.2 Update VoiceNoteSummary Model
**File**: `Circles/Services/AIService.swift`

**Changes**:
- Extend `VoiceNoteSummary` struct:
```swift
struct VoiceNoteSummary {
    let summary: String
    let interests: [String]
    let events: [String]
    let dates: [Date]
    let workInfo: String?        // NEW
    let topicsToAvoid: [String]? // NEW
    let familyDetails: String?   // NEW
    let travelNotes: String?     // NEW
    let religiousEvents: [String]? // NEW
    let birthday: Date?          // NEW
}
```

### Phase 2: Profile Update Logic

#### 2.1 Create ProfileUpdateService
**New File**: `Circles/Services/ProfileUpdateService.swift`

**Purpose**: Centralized service for merging AI-extracted data into contact profile

**Key Methods**:
```swift
@MainActor
class ProfileUpdateService {
    /// Merge AI-extracted data into contact profile
    func mergeAIExtractedData(
        into contact: Contact,
        from summary: VoiceNoteSummary,
        context: DataManager
    ) async throws -> ProfileUpdateResult
    
    /// Check for conflicts between AI data and existing profile
    func detectConflicts(
        contact: Contact,
        summary: VoiceNoteSummary
    ) -> [ProfileConflict]
    
    /// Apply updates with conflict resolution
    func applyUpdates(
        to contact: Contact,
        from summary: VoiceNoteSummary,
        resolving conflicts: [ProfileConflict: ConflictResolution],
        context: DataManager
    ) async throws
}
```

**Update Strategies**:

1. **Interests** (Array Merge)
   - Add new interests not already present
   - Use case-insensitive matching to avoid duplicates
   - Keep existing interests
   - Example: Existing ["Music", "Sports"] + AI ["Music", "Reading"] → ["Music", "Sports", "Reading"]

2. **Work Info** (Smart Replace/Merge)
   - If existing is empty → Replace with AI
   - If AI is more specific (longer, contains company name) → Replace
   - If existing is more specific → Keep existing
   - If both are similar → Keep existing
   - Example: Existing "Engineer" + AI "Software Engineer at Apple" → "Software Engineer at Apple"

3. **Topics to Avoid** (Array Merge)
   - Same as interests: add new, keep existing
   - Case-insensitive duplicate detection

4. **Family Details** (Append)
   - If existing is empty → Replace with AI
   - If existing has content → Append new info with separator
   - Example: Existing "Has one child" + AI "Married to Sarah" → "Has one child. Married to Sarah"

5. **Travel Notes** (Append)
   - Same strategy as family details
   - Append new travel preferences

6. **Religious Events** (Array Merge)
   - Same as interests: merge arrays

7. **Birthday** (Replace if Better)
   - Only replace if:
     - Existing is nil, OR
     - AI date is more specific (includes year when existing doesn't)
   - Never replace if existing has year and AI doesn't

#### 2.2 Conflict Detection
**Types of Conflicts**:

1. **Data Mismatch**: AI suggests different value than existing
   - Example: Existing job "Teacher" vs AI "Engineer"
   
2. **Data Quality**: AI data is less specific than existing
   - Example: Existing "Software Engineer at Apple" vs AI "Engineer"

3. **Duplicate Detection**: AI suggests something already present (but different wording)
   - Example: Existing "Photography" vs AI "Taking photos"

**Conflict Resolution Options**:
- Keep existing
- Replace with AI
- Merge both
- Ask user (default for high-confidence conflicts)

### Phase 3: User Experience

#### 3.1 Update Summary Edit View
**File**: `Circles/UI/Screens/VoiceNoteSummaryEditView.swift`

**Changes**:
- Add sections for all extracted fields:
  - Work Info (text field)
  - Topics to Avoid (editable list)
  - Family Details (text field)
  - Travel Notes (text field)
  - Religious Events (editable list)
  - Birthday (date picker)

- Add "Profile Updates" section showing:
  - What will be updated in contact profile
  - Conflicts detected (if any)
  - Toggle to enable/disable auto-update

**New UI Sections**:
```
┌─────────────────────────────────┐
│ Summary                         │
│ [Text editor]                   │
├─────────────────────────────────┤
│ Extracted Interests             │
│ [Editable list]                 │
├─────────────────────────────────┤
│ Profile Updates                 │
│ ☑ Update interests              │
│ ☑ Update work info              │
│ ⚠ Conflict: Job title differs   │
│   [Keep existing] [Use AI]      │
│ ☐ Update topics to avoid        │
├─────────────────────────────────┤
│ [Save] [Cancel]                 │
└─────────────────────────────────┘
```

#### 3.2 Conflict Resolution Dialog
**New Component**: `ProfileConflictResolutionView`

**Purpose**: Show conflicts and let user resolve them before saving

**Features**:
- List all detected conflicts
- Show existing vs AI value side-by-side
- Radio buttons for resolution (Keep existing / Use AI / Merge)
- Preview of final result

### Phase 4: Integration Points

#### 4.1 Update DataManager
**File**: `Circles/Data/DataManager.swift`

**Changes**:
- Replace current simple interest merging with `ProfileUpdateService`
- Call service in `createInteraction()` when `extractedInterests` or other fields are present
- Add method: `updateContactFromAIExtraction(contact:summary:resolving:)`

#### 4.2 Update VoiceNoteViewModel
**File**: `Circles/ViewModels/VoiceNoteViewModel.swift`

**Changes**:
- Pass full `VoiceNoteSummary` to save method (not just interests)
- Include conflict resolution in save flow

#### 4.3 Update ContactDetailView
**File**: `Circles/UI/Screens/ContactDetailView.swift`

**Changes**:
- Ensure view refreshes when profile is updated
- Show visual indicator when profile was recently updated from AI
- Add "Last updated from voice note" timestamp

### Phase 5: Confidence & Quality

#### 5.1 Confidence Scoring
**Purpose**: Only auto-update high-confidence extractions

**Scoring Factors**:
- **Specificity**: More specific = higher confidence
  - "Software Engineer at Apple" > "Engineer" > "Works in tech"
- **Context**: Mentioned with context = higher confidence
  - "She works as a doctor" > "doctor"
- **Frequency**: Mentioned multiple times = higher confidence
- **Date proximity**: Recent mentions = higher confidence

**Confidence Levels**:
- **High** (≥0.8): Auto-update without asking
- **Medium** (0.5-0.8): Show in summary edit, user can approve
- **Low** (<0.5): Only show, don't auto-update

#### 5.2 Data Quality Checks
- Validate extracted dates (reasonable range)
- Validate job titles (common patterns)
- Check for duplicates with fuzzy matching
- Sanitize text (trim, remove extra spaces)

### Phase 6: User Preferences

#### 6.1 Settings
**New Settings Options**:
- "Auto-update profile from voice notes" (toggle)
- "Ask before updating profile" (toggle)
- "Minimum confidence for auto-update" (slider: 0.5-1.0)
- "Update fields" (multi-select):
  - ☑ Interests
  - ☑ Work info
  - ☑ Topics to avoid
  - ☑ Family details
  - ☑ Travel notes
  - ☑ Religious events
  - ☑ Birthday

#### 6.2 Per-Contact Override
- Allow user to disable auto-updates for specific contacts
- Store in UserSettings or Contact entity

## Implementation Order

### Priority 1 (Core Functionality)
1. ✅ Enhanced AI extraction (all fields)
2. ✅ Update VoiceNoteSummary model
3. ✅ Create ProfileUpdateService with merge logic
4. ✅ Update summary edit view to show all fields
5. ✅ Integrate into save flow

### Priority 2 (User Control)
6. ✅ Conflict detection
7. ✅ Conflict resolution UI
8. ✅ User preferences/settings

### Priority 3 (Polish)
9. ✅ Confidence scoring
10. ✅ Data quality validation
11. ✅ Visual indicators for AI updates
12. ✅ Analytics/logging

## Testing Strategy

### Unit Tests
- ProfileUpdateService merge logic for each field type
- Conflict detection accuracy
- Confidence scoring calculations
- Data quality validation

### Integration Tests
- End-to-end: Voice note → AI extraction → Profile update
- Conflict resolution flow
- Settings/preferences application

### Manual Testing
- Test with various voice note content
- Test conflict scenarios
- Test user preference combinations
- Test edge cases (empty fields, duplicates, etc.)

## Edge Cases & Considerations

### Edge Cases
1. **Empty existing data**: Always use AI if existing is empty
2. **AI extraction fails**: Fall back to current behavior (save interaction only)
3. **Multiple voice notes**: Later notes should update, not overwrite
4. **Conflicting information**: User must resolve
5. **Partial extraction**: Update only what's extracted, leave rest unchanged

### Privacy Considerations
- User always has final say (can edit/reject)
- All updates are logged in interaction history
- User can see what was updated and when

### Performance
- Profile updates should be fast (<100ms)
- Batch updates if multiple fields change
- Use background context for saves

## Success Metrics

- **Accuracy**: % of AI extractions that are correct
- **Adoption**: % of users who enable auto-update
- **Conflict rate**: % of voice notes that trigger conflicts
- **User satisfaction**: Feedback on profile update quality

## Future Enhancements

1. **Learning from corrections**: If user frequently corrects AI, learn patterns
2. **Multi-language support**: Extract in user's language
3. **Temporal updates**: Update profile based on time (e.g., job changes)
4. **Relationship insights**: Suggest relationship improvements based on profile
5. **Smart reminders**: Use updated profile for better gift ideas, conversation starters

