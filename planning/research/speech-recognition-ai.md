# Speech Recognition and AI Integration Research

## Overview
Voice notes allow users to quickly capture interactions by speaking, with automatic transcription and AI summarization using iOS Speech Framework and Gemini AI.

## iOS Speech Recognition

### Framework: Speech
```swift
import Speech
import AVFoundation
```

### Capabilities
- **Real-time transcription**: Live speech-to-text
- **Recorded audio transcription**: Process audio files
- **Multi-language support**: 50+ languages
- **On-device processing**: iOS 13+ (limited)
- **Server-based**: More accurate, requires internet

### Permission Requirements
```xml
<!-- Info.plist -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>Circles needs speech recognition to transcribe your voice notes about contacts</string>

<key>NSMicrophoneUsageDescription</key>
<string>Circles needs microphone access to record voice notes</string>
```

## Implementation

### 1. Request Authorization
```swift
func requestSpeechAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status == .authorized)
        }
    }
}
```

### 2. Real-Time Transcription
```swift
class VoiceNoteRecorder: ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    @Published var transcribedText = ""
    @Published var isRecording = false
    
    func startRecording() throws {
        // Reset previous state
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw RecordingError.recognitionUnavailable
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Set up audio engine
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                self?.transcribedText = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                self?.stopRecording()
            }
        }
        
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
```

### 3. Time Limit Handling (3 minutes)
```swift
class VoiceNoteRecorder: ObservableObject {
    private var recordingTimer: Timer?
    private let maxRecordingTime: TimeInterval = 180 // 3 minutes
    
    @Published var remainingTime: TimeInterval = 180
    
    func startRecording() throws {
        try startAudioRecording()
        
        // Start timer
        remainingTime = maxRecordingTime
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.remainingTime -= 1
            
            if self.remainingTime <= 0 {
                self.stopRecording()
                self.showMaxTimeReachedAlert()
            }
        }
    }
    
    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        // ... rest of stop logic
    }
}
```

### 4. UI Component
```swift
struct VoiceNoteView: View {
    @StateObject private var recorder = VoiceNoteRecorder()
    @State private var showingSummary = false
    @State private var aiSummary = ""
    
    var body: Some View {
        VStack(spacing: 24) {
            // Waveform visualization
            WaveformView(isRecording: recorder.isRecording)
            
            // Transcribed text
            ScrollView {
                Text(recorder.transcribedText)
                    .font(.body)
                    .padding()
            }
            .frame(maxHeight: 200)
            
            // Time remaining
            Text(formatTime(recorder.remainingTime))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Record button
            Button(action: {
                if recorder.isRecording {
                    recorder.stopRecording()
                    Task {
                        await summarizeWithAI()
                    }
                } else {
                    try? recorder.startRecording()
                }
            }) {
                Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(recorder.isRecording ? .red : .blue)
            }
        }
        .sheet(isPresented: $showingSummary) {
            SummaryEditView(
                summary: $aiSummary,
                onSave: { summary in
                    saveInteraction(summary)
                }
            )
        }
    }
    
    func summarizeWithAI() async {
        let summary = try? await AIService.shared.summarizeVoiceNote(
            recorder.transcribedText
        )
        aiSummary = summary ?? recorder.transcribedText
        showingSummary = true
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

## AI Summarization with Gemini

### API Integration
```swift
class AIService {
    static let shared = AIService()
    private let apiKey = "YOUR_GEMINI_API_KEY"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    func summarizeVoiceNote(_ transcription: String) async throws -> Summary {
        let prompt = """
Summarize this voice note about a conversation with someone.

Extract:
1. A brief summary (2-3 sentences)
2. Interests or hobbies mentioned
3. Topics discussed
4. Events or plans mentioned
5. Important dates

Transcription: \(transcription)

Respond in JSON format:
{
  "summary": "brief summary",
  "interests": ["interest1", "interest2"],
  "topics": ["topic1", "topic2"],
  "events": ["event1"],
  "dates": ["2024-01-15"]
}
"""
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [["text": prompt]]
            ]],
            "generationConfig": [
                "temperature": 0.3,
                "topP": 0.8,
                "topK": 40
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.requestFailed
        }
        
        let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let jsonText = result.candidates.first?.content.parts.first?.text ?? ""
        
        return try JSONDecoder().decode(Summary.self, from: jsonText.data(using: .utf8)!)
    }
}

struct Summary: Codable {
    let summary: String
    let interests: [String]
    let topics: [String]
    let events: [String]
    let dates: [String]
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
}
```

### Alternative: Cloudflare Worker Endpoint
```typescript
// Use same backend as screenshot processing
POST /api/summarize-voice-note

Body:
{
  "transcription": "...",
  "contactId": "uuid"
}

Response:
{
  "summary": "...",
  "extractedInfo": {...}
}
```

## Waveform Visualization

### Simple Audio Level Meter
```swift
struct WaveformView: View {
    let isRecording: Bool
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.3, count: 50)
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<audioLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 3, height: audioLevels[index] * 60)
            }
        }
        .frame(height: 80)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if isRecording {
                updateLevels()
            }
        }
    }
    
    func updateLevels() {
        audioLevels.removeFirst()
        audioLevels.append(CGFloat.random(in: 0.3...1.0))
    }
}
```

### Advanced: Real Audio Level Monitoring
```swift
extension VoiceNoteRecorder {
    func setupAudioLevelMonitoring() {
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            // Append buffer for recognition
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level
            let level = self?.calculateAudioLevel(buffer: buffer) ?? 0
            DispatchQueue.main.async {
                self?.audioLevel = level
            }
        }
    }
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frames = buffer.frameLength
        
        var sum: Float = 0
        for i in 0..<Int(frames) {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frames)
        return min(average * 10, 1.0) // Normalize to 0-1
    }
}
```

## Error Handling

### Common Errors
```swift
enum VoiceNoteError: Error, LocalizedError {
    case recognitionNotAuthorized
    case recognitionNotAvailable
    case audioSessionFailed
    case recordingFailed
    case aiSummarizationFailed
    
    var errorDescription: String? {
        switch self {
        case .recognitionNotAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .recognitionNotAvailable:
            return "Speech recognition is not available on this device."
        case .audioSessionFailed:
            return "Couldn't access microphone. Please check permissions."
        case .recordingFailed:
            return "Recording failed. Please try again."
        case .aiSummarizationFailed:
            return "Couldn't summarize note. The transcription has been saved."
        }
    }
}
```

### Graceful Degradation
```swift
func saveVoiceNote() async {
    do {
        // Try to summarize with AI
        let summary = try await AIService.shared.summarizeVoiceNote(transcribedText)
        await dataManager.saveInteraction(summary: summary.summary, extractedInfo: summary)
    } catch {
        // Fallback: Save raw transcription
        await dataManager.saveInteraction(summary: transcribedText, extractedInfo: nil)
        showAlert("Note saved without AI summary")
    }
}
```

## Offline Handling

### Strategy
1. **Transcription**: Requires internet for accurate results
2. **AI Summary**: Requires internet for Gemini API
3. **Offline Mode**: 
   - Still allow recording
   - Queue for processing when online
   - Show "Processing when online" indicator

```swift
func handleOfflineVoiceNote(_ transcription: String) {
    let pendingNote = PendingVoiceNote(
        transcription: transcription,
        timestamp: Date()
    )
    
    // Save locally
    dataManager.queuePendingNote(pendingNote)
    
    // Show feedback
    showToast("Note saved. Will process when online.")
}
```

## Performance Optimization

### 1. Avoid Memory Leaks
```swift
deinit {
    stopRecording()
    audioEngine = nil
    recognitionTask?.cancel()
}
```

### 2. Throttle UI Updates
```swift
private var transcriptionDebouncer: Timer?

func updateTranscription(_ text: String) {
    transcriptionDebouncer?.invalidate()
    transcriptionDebouncer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
        self?.transcribedText = text
    }
}
```

### 3. Background Processing
```swift
func summarizeInBackground() {
    Task.detached(priority: .userInitiated) {
        let summary = try await AIService.shared.summarizeVoiceNote(text)
        
        await MainActor.run {
            self.aiSummary = summary
        }
    }
}
```

## Testing

### Test Scenarios
- [ ] Clear speech, quiet environment
- [ ] Noisy background
- [ ] Different accents
- [ ] Multiple speakers
- [ ] Long pauses
- [ ] Maximum duration (3 minutes)
- [ ] Permission denied handling
- [ ] Network failure during AI summary
- [ ] Interruptions (phone call, notification)

### Test Data
Create sample voice notes covering:
- Simple conversation recap
- Multiple topics
- Dates and events
- Names mentioned
- Interests discussed

## Accessibility

### VoiceOver Support
```swift
.accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
.accessibilityHint(isRecording ? "Double tap to stop and save note" : "Double tap to start recording")
```

### Alternative Input
- Support text input as alternative
- Paste from clipboard
- Import from Files app

## Privacy Considerations

### Data Handling
1. **Audio**: Not stored, discarded after transcription
2. **Transcription**: Processed by Apple servers (Speech Recognition)
3. **AI Summary**: Sent to Gemini API
4. **Final Storage**: Only summary in CloudKit

### User Transparency
```swift
// Show privacy info before first use
.sheet(isPresented: $showingPrivacyInfo) {
    VStack {
        Text("Voice Notes Privacy")
            .font(.title2)
        
        Text("""
        • Audio recorded on your device
        • Sent to Apple for transcription
        • Summarized using AI (Gemini)
        • Original audio not stored
        • Only summary saved
        """)
        .padding()
        
        Button("Got it") {
            showingPrivacyInfo = false
            UserDefaults.standard.set(true, forKey: "voiceNotePrivacyAcknowledged")
        }
    }
}
```

## Best Practices

1. **Clear Feedback**: Show transcription in real-time
2. **Time Indicator**: Display remaining time prominently
3. **Easy Cancel**: Allow canceling without saving
4. **Review Before Save**: Let user edit AI summary
5. **Visual Cues**: Waveform shows recording is active
6. **Error Recovery**: Gracefully handle all failures
7. **Offline Support**: Queue for later processing

## Key Takeaways

1. **iOS Speech Framework**: Powerful, built-in, free
2. **Real-Time Transcription**: Great UX, shows progress
3. **3-Minute Limit**: Enforced by timer
4. **AI Summary Essential**: Makes notes useful
5. **Discard Audio**: Privacy and storage
6. **Gemini via Backend**: Keep API key secure
7. **Graceful Degradation**: Save transcription if AI fails
8. **User Can Edit**: Don't force AI output

## Implementation Checklist

- [ ] Request Speech Recognition permission
- [ ] Request Microphone permission
- [ ] Implement VoiceNoteRecorder class
- [ ] Create recording UI with waveform
- [ ] Add 3-minute timer
- [ ] Integrate AI summarization
- [ ] Implement summary editing
- [ ] Add error handling
- [ ] Test on real devices
- [ ] Handle background interruptions
- [ ] Add accessibility support
- [ ] Update privacy policy

## Resources

- [Apple Speech Framework Documentation](https://developer.apple.com/documentation/speech)
- [AVAudioEngine Guide](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [WWDC Speech Recognition Videos](https://developer.apple.com/videos/play/wwdc2019/256/)
