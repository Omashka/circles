//
//  VoiceNoteRecorder.swift
//  Circles
//

import Foundation
import AVFoundation
import Speech

/// Handles audio recording and real-time speech recognition
@MainActor
class VoiceNoteRecorder: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var transcription = ""
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    private let maxDuration: TimeInterval = 180 // 3 minutes
    private var startTime: Date?
    private var timer: Timer?
    
    // Callbacks
    var onDurationReached: (() -> Void)?
    var onTranscriptionUpdate: ((String) -> Void)?
    var onRecordingStopped: ((String) -> Void)? // Called when recording stops with final transcription
    
    // MARK: - Initialization
    
    override init() {
        // Initialize speech recognizer with user's locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        super.init()
    }
    
    // MARK: - Permission Management
    
    /// Request speech recognition authorization
    static func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    /// Request microphone authorization
    static func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Check if all required permissions are granted
    static func hasRequiredPermissions() async -> Bool {
        let speechAuth = await requestSpeechAuthorization()
        let micAuth = await requestMicrophoneAuthorization()
        return speechAuth && micAuth
    }
    
    // MARK: - Recording Control
    
    /// Start recording with speech recognition
    func startRecording() async throws {
        // Check permissions
        guard await Self.hasRequiredPermissions() else {
            throw VoiceNoteError.permissionsDenied
        }
        
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceNoteError.speechRecognizerUnavailable
        }
        
        // Reset state
        transcription = ""
        errorMessage = nil
        startTime = Date()
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create audio engine
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine
        
        // Create recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true
        
        // Get input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap to get audio buffer
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            
            // Calculate audio level for waveform visualization
            let channelData = buffer.floatChannelData?[0]
            let channelDataValue = channelData?.pointee ?? 0
            let level = abs(channelDataValue) * 10 // Amplify for visualization
            
            Task { @MainActor in
                self.audioLevel = min(level, 1.0)
            }
        }
        
        // Prepare and start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                    // Call completion with current transcription even on error
                    let finalTranscription = self.transcription
                    self.stopRecordingInternal()
                    self.onRecordingStopped?(finalTranscription)
                }
                return
            }
            
            if let result = result {
                let newTranscription = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcription = newTranscription
                    self.onTranscriptionUpdate?(newTranscription)
                }
                
                // If final result, stop recording and call completion
                if result.isFinal {
                    Task { @MainActor in
                        let finalTranscription = result.bestTranscription.formattedString
                        self.transcription = finalTranscription
                        self.stopRecordingInternal()
                        self.onRecordingStopped?(finalTranscription)
                    }
                }
            }
        }
        
        isRecording = true
        
        // Start timer for 3-minute limit
        startTimer()
    }
    
    /// Stop recording (public method - triggers final result callback)
    func stopRecording() {
        // End recognition request to trigger final result
        recognitionRequest?.endAudio()
        // Don't cancel task yet - wait for final result in callback
        // The recognition task callback will call stopRecordingInternal() when final result arrives
    }
    
    /// Internal method to actually stop recording and clean up
    private func stopRecordingInternal() {
        // Stop timer
        timer?.invalidate()
        timer = nil
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Clean up recognition request
        recognitionRequest = nil
        
        // Cancel recognition task (now safe to cancel since we have final result)
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isRecording = false
        audioLevel = 0.0
    }
    
    /// Cancel recording (discard all data)
    func cancelRecording() {
        stopRecordingInternal()
        transcription = ""
        errorMessage = nil
        onRecordingStopped?("") // Call with empty string to indicate cancellation
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = self.maxDuration - elapsed
            
            if remaining <= 0 {
                self.timer?.invalidate()
                self.onDurationReached?()
                self.stopRecording()
            }
        }
    }
    
    /// Get remaining time in seconds
    var remainingTime: TimeInterval {
        guard let startTime = startTime, isRecording else { return maxDuration }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, maxDuration - elapsed)
    }
    
    /// Get formatted time string (MM:SS)
    var formattedTime: String {
        let time = isRecording ? remainingTime : maxDuration
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Errors

enum VoiceNoteError: LocalizedError {
    case permissionsDenied
    case speechRecognizerUnavailable
    case audioEngineError(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionsDenied:
            return "Microphone and speech recognition permissions are required to record voice notes."
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available. Please check your internet connection."
        case .audioEngineError(let message):
            return "Audio engine error: \(message)"
        }
    }
}

