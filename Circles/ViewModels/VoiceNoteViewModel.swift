//
//  VoiceNoteViewModel.swift
//  Circles
//

import SwiftUI
import AVFoundation
import Speech

/// ViewModel managing voice note recording state and operations
@MainActor
class VoiceNoteViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var transcription = ""
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?
    @Published var timeRemaining: String = "3:00"
    @Published var hasPermissions = false
    
    // MARK: - Private Properties
    
    private let recorder = VoiceNoteRecorder()
    private let contact: Contact
    private let dataManager: DataManager
    
    // MARK: - Initialization
    
    init(contact: Contact, dataManager: DataManager) {
        self.contact = contact
        self.dataManager = dataManager
        
        // Setup recorder callbacks
        recorder.onTranscriptionUpdate = { [weak self] text in
            Task { @MainActor in
                self?.transcription = text
            }
        }
        
        recorder.onDurationReached = { [weak self] in
            Task { @MainActor in
                self?.stopRecording()
            }
        }
    }
    
    // MARK: - Permission Management
    
    /// Check and request permissions
    func checkPermissions() async {
        hasPermissions = await VoiceNoteRecorder.hasRequiredPermissions()
    }
    
    /// Request permissions explicitly
    func requestPermissions() async {
        let speechAuth = await VoiceNoteRecorder.requestSpeechAuthorization()
        let micAuth = await VoiceNoteRecorder.requestMicrophoneAuthorization()
        hasPermissions = speechAuth && micAuth
    }
    
    // MARK: - Recording Control
    
    /// Start recording
    func startRecording() async {
        guard hasPermissions else {
            errorMessage = "Permissions are required to record voice notes."
            return
        }
        
        do {
            try await recorder.startRecording()
            // Update state from recorder
            updateStateFromRecorder()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Stop recording and save
    func stopRecording() {
        recorder.stopRecording()
        updateStateFromRecorder()
    }
    
    /// Cancel recording (discard)
    func cancelRecording() {
        recorder.cancelRecording()
        updateStateFromRecorder()
        transcription = ""
    }
    
    /// Update published properties from recorder (call this periodically during recording)
    func updateStateFromRecorder() {
        isRecording = recorder.isRecording
        transcription = recorder.transcription
        audioLevel = recorder.audioLevel
        errorMessage = recorder.errorMessage
        timeRemaining = recorder.formattedTime
    }
    
    /// Save the voice note as an interaction
    func saveVoiceNote() async throws {
        let trimmed = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "VoiceNoteError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Transcription is empty"])
        }
        
        // Create interaction with voice note transcription
        _ = try await dataManager.createInteraction(
            for: contact,
            content: trimmed,
            source: .voiceNote,
            rawTranscription: trimmed,
            extractedInterests: nil,
            extractedEvents: nil,
            extractedDates: nil
        )
        
        // Reset state
        transcription = ""
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func observeRecorder() {
        // Observe recorder's published properties
        // Note: Since VoiceNoteRecorder is @MainActor, we can directly access its properties
        // The view will update when we call start/stop recording which updates our @Published properties
    }
}

