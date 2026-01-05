# Apple Shortcuts Integration Research

## Overview
Integrating Apple Shortcuts allows users to capture iMessage/WhatsApp screenshots and import them into Circles app using iOS Back Tap accessibility feature.

## Architecture

### Data Flow
```
1. User takes screenshot
2. Double-tap back of phone (Back Tap trigger)
3. Shortcut executes automatically
4. OCR extracts text from screenshot
5. Text sent to Circles app
6. Cloudflare Worker processes with Gemini AI
7. AI detects contact and creates summary
8. Updates stored in CloudKit
```

## Shortcuts Implementation

### 1. Creating the Shortcut

**Shortcut Actions:**
1. Get Latest Screenshots (1 photo)
2. Extract Text from Image (OCR)
3. Send to App (via URL Scheme or App Intent)

### 2. Back Tap Configuration
```
Settings → Accessibility → Touch → Back Tap → Double Tap
Select: Your Shortcut
```

**User Experience:**
- Take screenshot of message
- Double tap back of phone
- Shortcut runs automatically
- Data imported to app seamlessly

## Integration Methods

### Method 1: URL Scheme (Simple, Recommended for MVP)

#### Define URL Scheme
```xml
<!-- Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>circles</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourapp.circles</string>
    </dict>
</array>
```

#### Shortcut Configuration
```
Open URL: circles://import?text=[encoded_text]
```

#### Handle in App
```swift
// SwiftUI App
.onOpenURL { url in
    guard url.scheme == "circles",
          url.host == "import",
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let textItem = components.queryItems?.first(where: { $0.name == "text" }),
          let text = textItem.value else {
        return
    }
    
    // Send to backend for processing
    Task {
        await processImportedText(text)
    }
}

func processImportedText(_ text: String) async {
    // 1. Send to Cloudflare Worker
    let summary = try await apiClient.processScreenshot(text)
    
    // 2. If contact detected, update interaction
    // 3. If no contact detected, add to inbox
}
```

### Method 2: App Intents (iOS 16+, More Powerful)

#### Define App Intent
```swift
import AppIntents

struct ImportMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Message"
    static var description = IntentDescription("Import message text to Circles")
    
    @Parameter(title: "Message Text")
    var messageText: String
    
    func perform() async throws -> some IntentResult {
        // Process the text
        await DataManager.shared.processImport(messageText)
        
        return .result(
            dialog: "Message imported successfully"
        )
    }
}
```

#### Shortcut Configuration
```
Run "Import Message" with messageText=[text]
```

#### Benefits
- Native iOS 16+ integration
- Better parameter handling
- Siri integration possible
- More type-safe

### Method 3: Share Extension (Alternative)

#### Create Share Extension Target
```swift
// ShareViewController.swift
class ShareViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool {
        return true
    }
    
    override func didSelectPost() {
        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
           let attachment = item.attachments?.first {
            
            // Handle image or text
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                // Process image
            }
        }
        
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
```

#### User Flow
- Take screenshot
- Share → Circles
- Extension processes image

**Pros:** Native iOS sharing
**Cons:** Extra tap required (not as seamless as Back Tap)

## OCR Text Extraction in Shortcuts

### Built-In OCR Action
```
Extract Text from Images
Input: Latest Screenshot
```

**Features:**
- Free, built into iOS
- Supports multiple languages
- Good accuracy for messaging apps
- Preserves formatting

###Extraction Quality
- **High accuracy** for printed text
- **Good accuracy** for messaging apps (iMessage, WhatsApp)
- May struggle with:
  - Handwriting
  - Stylized fonts
  - Low contrast images
  - Small text

### Optimization Tips
- Screenshot at actual size (not scaled)
- Good lighting in photos
- Clear text, minimal background

## Backend Processing (Cloudflare Worker)

### Worker Architecture
```typescript
// cloudflare-worker/src/index.ts

export default {
    async fetch(request: Request): Promise<Response> {
        if (request.method !== 'POST') {
            return new Response('Method not allowed', { status: 405 });
        }
        
        const { text, userId } = await request.json();
        
        // 1. Authenticate user (Apple Sign-In token)
        const user = await authenticateUser(userId);
        
        // 2. Process with Gemini AI
        const result = await processWithGemini(text, user);
        
        // 3. Return detected contact and summary
        return Response.json(result);
    }
};

async function processWithGemini(text: string, user: User) {
    const prompt = `
You are analyzing a message conversation screenshot.
Identify:
1. Who the conversation is with (name/contact)
2. Key topics discussed
3. Important dates or events mentioned
4. Interests or preferences mentioned

Text: ${text}

Respond in JSON:
{
  "detectedContact": "Name or null",
  "confidence": 0-1,
  "summary": "Brief summary",
  "extractedInfo": {
    "interests": [],
    "events": [],
    "dates": []
  }
}
    `;
    
    const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': GEMINI_API_KEY
        },
        body: JSON.stringify({
            contents: [{
                parts: [{ text: prompt }]
            }]
        })
    });
    
    const data = await response.json();
    return JSON.parse(data.candidates[0].content.parts[0].text);
}
```

### API Endpoint Design
```
POST /api/process-screenshot
Headers:
  Authorization: Bearer [Apple ID token]
  Content-Type: application/json

Body:
{
  "text": "extracted text from screenshot",
  "timestamp": "2024-01-04T10:30:00Z"
}

Response:
{
  "success": true,
  "detectedContact": {
    "id": "contact-uuid",
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

## Contact Detection Logic

### AI Prompt Engineering
```typescript
const systemPrompt = `
You are analyzing a conversation screenshot. The user has ${contacts.length} saved contacts:
${contacts.map(c => `- ${c.name}`).join('\n')}

Instructions:
1. Identify who the conversation is with
2. Match to one of the saved contacts if possible
3. Extract key information
4. Be conservative - only match if confident

Return JSON with:
- matchedContact: name or null
- confidence: 0.0-1.0
- reasoning: brief explanation
- summary: 2-3 sentence summary
- extractedInfo: interests, dates, events
`;
```

### Matching Algorithm
```typescript
function matchContact(
    detectedName: string,
    contacts: Contact[]
): Contact | null {
    // 1. Exact name match
    let match = contacts.find(c => 
        c.name.toLowerCase() === detectedName.toLowerCase()
    );
    
    if (match) return match;
    
    // 2. Fuzzy match (handle nicknames)
    match = contacts.find(c => {
        const similarity = stringSimilarity(
            c.name.toLowerCase(),
            detectedName.toLowerCase()
        );
        return similarity > 0.8;
    });
    
    if (match) return match;
    
    // 3. Check aliases/nicknames if stored
    match = contacts.find(c => 
        c.nicknames?.some(nick => 
            nick.toLowerCase() === detectedName.toLowerCase()
        )
    );
    
    return match || null;
}
```

### Inbox for Unmatched
```swift
// If no contact matched
if result.detectedContact == nil || result.confidence < 0.7 {
    // Save to inbox
    let unassignedNote = UnassignedNote(
        content: result.summary,
        extractedText: originalText,
        timestamp: Date()
    )
    await dataManager.saveToInbox(unassignedNote)
    
    // User can manually assign later
}
```

## Onboarding Setup

### Teach Users to Set Up Shortcut

**Onboarding Flow:**
1. **Introduction Screen**
   - "Import messages with a double-tap"
   - Benefits explanation
   
2. **Shortcut Installation**
   - "Add to Shortcuts" button
   - Opens Shortcuts app with pre-configured shortcut
   
3. **Back Tap Configuration**
   - Step-by-step guide:
     1. Open Settings
     2. Go to Accessibility
     3. Tap Touch
     4. Tap Back Tap
     5. Select Double Tap
     6. Choose "Circles Import" shortcut
   
4. **Test It**
   - "Try it now! Take a screenshot and double-tap"
   - Success confirmation

### Pre-Configured Shortcut Distribution
```swift
// Generate shortcut URL
let shortcutURL = URL(string: "https://www.icloud.com/shortcuts/YOUR_SHORTCUT_ID")!

// Open in Safari to install
UIApplication.shared.open(shortcutURL)
```

**Alternative: Deep Link**
```
shortcuts://import-shortcut?url=[encoded_shortcut_url]&name=Circles%20Import
```

## Privacy and Security

### Data Handling
1. **Text Extraction**: Happens on-device (Shortcuts OCR)
2. **Transmission**: HTTPS to Cloudflare Worker
3. **Processing**: Gemini API (Google Cloud)
4. **Storage**: CloudKit (Apple's servers)

### Privacy Considerations
- **User Consent**: Required for sending data to backend
- **Data Retention**: Don't store raw screenshot images
- **Encryption**: All network requests over HTTPS
- **Authentication**: Apple Sign-In tokens

### Privacy Policy Updates
Must disclose:
- OCR text extraction
- Sending to external AI service (Gemini)
- Data processing and storage

## Testing Strategy

### 1. Shortcut Testing
- [ ] OCR accuracy on various message apps
- [ ] URL scheme handling
- [ ] Error cases (no text extracted)
- [ ] Back Tap trigger reliability

### 2. Backend Testing
- [ ] Contact detection accuracy
- [ ] Summary quality
- [ ] Performance (response time)
- [ ] Error handling
- [ ] Rate limiting

### 3. End-to-End Testing
- [ ] Screenshot → Double Tap → Import flow
- [ ] Matched contact updates
- [ ] Unmatched → Inbox flow
- [ ] Multi-device sync

## Performance Optimization

### Response Time Target
- **OCR**: <1s (on-device)
- **Network**: <500ms
- **AI Processing**: <2s
- **Total**: <3.5s

### Caching Strategy
```typescript
// Cache user's contact list
const cache = await caches.open('user-contacts');
const cacheKey = `contacts-${userId}`;

// Refresh every 5 minutes
const cachedContacts = await cache.match(cacheKey);
if (cachedContacts && !isStale(cachedContacts)) {
    contacts = await cachedContacts.json();
} else {
    contacts = await fetchContactsFromCloudKit(userId);
    await cache.put(cacheKey, Response.json(contacts));
}
```

## Error Handling

### Common Errors
```swift
enum ShortcutImportError: Error {
    case ocrFailed
    case networkError
    case authenticationFailed
    case aiProcessingFailed
    case invalidResponse
}

func handleImportError(_ error: ShortcutImportError) {
    switch error {
    case .ocrFailed:
        showAlert("Couldn't extract text from screenshot")
    case .networkError:
        // Queue for retry
        queueForRetry(text)
    case .aiProcessingFailed:
        // Save to inbox without AI processing
        saveRawToInbox(text)
    default:
        showGenericError()
    }
}
```

## Alternative Apps Support

### WhatsApp
- OCR works similarly
- May need different AI prompt for formatting
- Test extraction quality

### Instagram DMs
- Similar approach
- May have different text layouts

### Signal
- Encrypted messages
- OCR still works on screenshots

## Future Enhancements

1. **Batch Import**: Multiple screenshots at once
2. **Automatic Trigger**: On screenshot (without Back Tap)
3. **Contact Suggestions**: AI suggests new contacts to add
4. **Relationship Detection**: AI infers relationships from messages
5. **Siri Integration**: "Hey Siri, import last screenshot"

## Key Takeaways

1. **URL Scheme Simplest**: Start with URL scheme for MVP
2. **Back Tap is Genius**: Frictionless UX
3. **OCR Built-In**: No additional libraries needed
4. **AI Detection**: Gemini handles contact matching
5. **Inbox Safety Net**: Don't lose unmatched data
6. **Onboarding Critical**: Must teach setup process
7. **Privacy First**: Be transparent about data flow

## Implementation Checklist

- [ ] Define URL scheme in Info.plist
- [ ] Create shortcut (distribute via iCloud link)
- [ ] Implement URL handler in app
- [ ] Build Cloudflare Worker API
- [ ] Integrate Gemini API
- [ ] Create inbox for unassigned notes
- [ ] Design onboarding flow
- [ ] Test with real screenshots
- [ ] Add error handling
- [ ] Update privacy policy

## Resources

- [Apple Shortcuts User Guide](https://support.apple.com/guide/shortcuts/)
- [URL Schemes Documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [App Intents Framework](https://developer.apple.com/documentation/appintents)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Gemini API Documentation](https://ai.google.dev/docs)
