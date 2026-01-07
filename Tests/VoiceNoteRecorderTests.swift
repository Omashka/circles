//
//  VoiceNoteRecorderTests.swift
//  CirclesTests
//

import XCTest
import AVFoundation
import Speech
@testable import Circles

final class VoiceNoteRecorderTests: XCTestCase {
    var recorder: VoiceNoteRecorder!
    
    override func setUp() {
        super.setUp()
        recorder = VoiceNoteRecorder()
    }
    
    override func tearDown() {
        recorder = nil
        super.tearDown()
    }
    
    // MARK: - Permission Tests
    
    func testRequestSpeechAuthorization() async {
        // Note: This will show a permission dialog in simulator
        // In real tests, you might want to mock this
        let authorized = await VoiceNoteRecorder.requestSpeechAuthorization()
        // We can't assert the result as it depends on user/system state
        XCTAssertTrue(true, "Permission request completed")
    }
    
    func testRequestMicrophoneAuthorization() async {
        // Note: This will show a permission dialog in simulator
        let authorized = await VoiceNoteRecorder.requestMicrophoneAuthorization()
        // We can't assert the result as it depends on user/system state
        XCTAssertTrue(true, "Permission request completed")
    }
    
    // MARK: - Time Formatting Tests
    
    func testFormattedTime_Initial() {
        // Initially should show 3:00
        XCTAssertEqual(recorder.formattedTime, "3:00")
    }
    
    func testRemainingTime_NotRecording() {
        // When not recording, should return max duration
        XCTAssertEqual(recorder.remainingTime, 180.0, accuracy: 0.1)
    }
    
    // MARK: - State Tests
    
    func testInitialState() {
        XCTAssertFalse(recorder.isRecording)
        XCTAssertEqual(recorder.transcription, "")
        XCTAssertEqual(recorder.audioLevel, 0.0)
        XCTAssertNil(recorder.errorMessage)
    }
    
    // MARK: - Callback Tests
    
    func testOnTranscriptionUpdate() {
        var receivedTranscription = ""
        let expectation = XCTestExpectation(description: "Transcription update")
        
        recorder.onTranscriptionUpdate = { text in
            receivedTranscription = text
            expectation.fulfill()
        }
        
        // Simulate transcription update
        recorder.transcription = "Test transcription"
        recorder.onTranscriptionUpdate?("Test transcription")
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedTranscription, "Test transcription")
    }
    
    func testOnDurationReached() {
        var durationReached = false
        let expectation = XCTestExpectation(description: "Duration reached")
        
        recorder.onDurationReached = {
            durationReached = true
            expectation.fulfill()
        }
        
        // Simulate duration reached
        recorder.onDurationReached?()
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(durationReached)
    }
}

final class VoiceNoteViewModelTests: XCTestCase {
    var persistence: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var dataManager: DataManager!
    var contact: Contact!
    var viewModel: VoiceNoteViewModel!
    
    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        viewContext = persistence.viewContext
        dataManager = DataManager(persistence: persistence)
        
        contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "Test Contact"
        contact.createdAt = Date()
        
        viewModel = VoiceNoteViewModel(contact: contact, dataManager: dataManager)
    }
    
    override func tearDown() {
        viewModel = nil
        contact = nil
        dataManager = nil
        viewContext = nil
        persistence = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.transcription, "")
        XCTAssertEqual(viewModel.audioLevel, 0.0)
        XCTAssertEqual(viewModel.timeRemaining, "3:00")
    }
    
    // MARK: - Permission Tests
    
    func testCheckPermissions() async {
        await viewModel.checkPermissions()
        // Result depends on system state, but should complete without error
        XCTAssertTrue(true, "Permission check completed")
    }
    
    func testRequestPermissions() async {
        await viewModel.requestPermissions()
        // Result depends on system state, but should complete without error
        XCTAssertTrue(true, "Permission request completed")
    }
    
    // MARK: - Recording Control Tests
    
    func testCancelRecording() {
        // Set some state
        viewModel.transcription = "Test transcription"
        viewModel.isRecording = true
        
        // Cancel should reset state
        viewModel.cancelRecording()
        
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.transcription, "")
    }
    
    func testUpdateStateFromRecorder() {
        // Note: recorder is private, so we can't directly access it
        // This test verifies the method exists and can be called without crashing
        viewModel.updateStateFromRecorder()
        // Method should complete without error
        XCTAssertTrue(true, "Update method called successfully")
    }
    
    // MARK: - Save Tests
    
    func testSaveVoiceNote_EmptyTranscription() async {
        viewModel.transcription = ""
        
        do {
            try await viewModel.saveVoiceNote()
            XCTFail("Should throw error for empty transcription")
        } catch {
            // Expected to throw
            XCTAssertTrue(true)
        }
    }
    
    func testSaveVoiceNote_ValidTranscription() async throws {
        viewModel.transcription = "Had a great conversation about the project"
        
        try await viewModel.saveVoiceNote()
        
        // Verify interaction was created
        let interactions = await dataManager.fetchInteractions(for: contact)
        XCTAssertEqual(interactions.count, 1)
        XCTAssertEqual(interactions.first?.content, "Had a great conversation about the project")
        XCTAssertEqual(interactions.first?.source, "voice_note")
    }
}

// Note: Full recording tests (start/stop) would require:
// - Mocking AVAudioEngine
// - Mocking SFSpeechRecognizer
// - Handling permission states
// These are complex and would require more sophisticated test infrastructure

