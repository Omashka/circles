//
//  VoiceNoteViewModel.swift
//  Circles
//

import SwiftUI
import AVFoundation
import Speech
import os.log
import Foundation

extension Notification.Name {
    static let recordingStopped = Notification.Name("recordingStopped")
}

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
    @Published var isProcessingAI = false
    @Published var aiSummary: VoiceNoteSummary?
    @Published var showingSummaryEdit = false
    
    // MARK: - Private Properties
    
    let recorder = VoiceNoteRecorder()
    let contact: Contact
    let dataManager: DataManager
    private let aiService = AIService.shared
    private let offlineQueue = OfflineQueueManager.shared
    private let logger = Logger(subsystem: "com.circles.app", category: "VoiceNoteViewModel")
    
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
        
        // Setup callback for when recording stops with final transcription
        recorder.onRecordingStopped = { [weak self] finalTranscription in
            Task { @MainActor in
                self?.transcription = finalTranscription
                self?.isRecording = false
                // Notify that recording has stopped with final transcription
                NotificationCenter.default.post(name: .recordingStopped, object: nil, userInfo: ["transcription": finalTranscription])
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
        // State will be updated via onRecordingStopped callback
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
    
    /// Process voice note with AI and show summary edit view
    func processWithAI(transcriptionOverride: String? = nil) async {
        // Ensure we have the latest transcription from the recorder
        updateStateFromRecorder()
        
        // Use provided transcription or get from recorder/view model
        let transcriptionToUse: String
        if let override = transcriptionOverride, !override.isEmpty {
            transcriptionToUse = override
        } else {
            // Try recorder first (most up-to-date), then fallback to view model
            transcriptionToUse = recorder.transcription.isEmpty ? transcription : recorder.transcription
        }
        
        let trimmed = transcriptionToUse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            errorMessage = "Transcription is empty. Please record a voice note first."
            logger.error("Transcription is empty")
            return
        }
        
        logger.info("Starting AI processing with transcription length: \(trimmed.count)")
        isProcessingAI = true
        errorMessage = nil
        
        do {
            // Try to get AI summary
            logger.info("Calling AIService.summarizeVoiceNote...")
            let summary = try await aiService.summarizeVoiceNote(
                transcription: trimmed,
                contactName: contact.name
            )
            
            logger.info("AI summary received - Summary: \(summary.summary), Work Info: \(summary.workInfo ?? "nil"), Interests: \(summary.interests)")
            
            aiSummary = summary
            showingSummaryEdit = true
            isProcessingAI = false
            logger.info("Summary edit view should now be showing")
        } catch {
            logger.error("AI processing failed: \(error.localizedDescription, privacy: .public)")
            
            // If offline or API fails, queue the operation
            if let aiError = error as? AIError {
                logger.error("AIError type: \(String(describing: aiError), privacy: .public)")
                if aiError == .apiKeyMissing {
                    errorMessage = "AI service is not configured. Saving without AI processing."
                    logger.warning("API key is missing")
                    // Save directly without AI
                    await saveVoiceNoteDirectly(trimmed: trimmed)
                } else {
                    logger.warning("Other AI error, queueing for offline processing")
                    // Queue for offline processing
                    let operation = QueuedAIOperation(
                        id: UUID(),
                        type: .voiceNoteSummarization,
                        transcription: trimmed,
                        contactId: contact.id,
                        createdAt: Date()
                    )
                    offlineQueue.enqueue(operation)
                    
                    errorMessage = "Offline or AI service unavailable. Saved to queue for processing later."
                    // Save with raw transcription for now
                    await saveVoiceNoteDirectly(trimmed: trimmed)
                }
            } else {
                logger.warning("Non-AIError, queueing for offline processing: \(error.localizedDescription, privacy: .public)")
                // Other errors - queue for offline processing
                let operation = QueuedAIOperation(
                    id: UUID(),
                    type: .voiceNoteSummarization,
                    transcription: trimmed,
                    contactId: contact.id,
                    createdAt: Date()
                )
                offlineQueue.enqueue(operation)
                
                errorMessage = "AI service error: \(error.localizedDescription). Saved to queue for processing later."
                // Save with raw transcription for now
                await saveVoiceNoteDirectly(trimmed: trimmed)
            }
            isProcessingAI = false
        }
    }
    
    /// Save the voice note with AI summary
    func saveVoiceNote(with summary: VoiceNoteSummary) async throws {
        let trimmed = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "VoiceNoteError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Transcription is empty"])
        }
        
        // Create interaction with AI summary and extracted data
        _ = try await dataManager.createInteraction(
            for: contact,
            content: summary.summary,
            source: .voiceNote,
            rawTranscription: trimmed,
            extractedInterests: summary.interests.isEmpty ? nil : summary.interests,
            extractedEvents: summary.events.isEmpty ? nil : summary.events,
            extractedDates: summary.dates.isEmpty ? nil : summary.dates
        )
        
        // Update contact profile with AI-extracted data
        try await ProfileUpdateService.shared.updateContactProfile(
            contact,
            with: summary,
            dataManager: dataManager
        )
        
        // Reset state
        transcription = ""
        errorMessage = nil
        aiSummary = nil
    }
    
    /// Save voice note directly without AI processing (fallback)
    func saveVoiceNoteDirectly(trimmed: String) async {
        do {
            _ = try await dataManager.createInteraction(
                for: contact,
                content: trimmed,
                source: .voiceNote,
                rawTranscription: trimmed,
                extractedInterests: nil,
                extractedEvents: nil,
                extractedDates: nil
            )
            transcription = ""
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save voice note: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    private func observeRecorder() {
        // Observe recorder's published properties
        // Note: Since VoiceNoteRecorder is @MainActor, we can directly access its properties
        // The view will update when we call start/stop recording which updates our @Published properties
    }
}

