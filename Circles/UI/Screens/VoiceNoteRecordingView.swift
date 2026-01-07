//
//  VoiceNoteRecordingView.swift
//  Circles
//

import SwiftUI
import Combine

/// View for recording voice notes with real-time transcription
struct VoiceNoteRecordingView: View {
    @ObservedObject var viewModel: VoiceNoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSaveConfirmation = false
    @State private var updateTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                VStack(spacing: 32) {
                    // Timer display
                    timerDisplay
                    
                    // Waveform visualization
                    waveformView
                    
                    // Transcription display
                    transcriptionView
                    
                    // Control buttons
                    controlButtons
                }
                .padding()
            }
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.isRecording {
                            viewModel.cancelRecording()
                        }
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.checkPermissions()
            }
            .onChange(of: viewModel.isRecording) { isRecording in
                if isRecording {
                    // Start timer to update state
                    updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        viewModel.updateStateFromRecorder()
                    }
                } else {
                    // Stop timer
                    updateTimer?.invalidate()
                    updateTimer = nil
                }
            }
            .onDisappear {
                updateTimer?.invalidate()
            }
            .alert("Save Voice Note", isPresented: $showingSaveConfirmation) {
                Button("Save") {
                    Task {
                        do {
                            try await viewModel.saveVoiceNote()
                            dismiss()
                        } catch {
                            // Error is shown in viewModel.errorMessage
                            showingSaveConfirmation = false
                        }
                    }
                }
                Button("Discard", role: .destructive) {
                    viewModel.cancelRecording()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Save this voice note as an interaction?")
            }
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(viewModel.timeRemaining)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(viewModel.isRecording ? .primary : .secondary)
            
            if viewModel.isRecording {
                Text("Recording...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ready to record")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Waveform View
    
    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(waveformColor(for: index))
                    .frame(width: 4)
                    .frame(height: waveformHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.1)
                        .repeatForever(autoreverses: true),
                        value: viewModel.audioLevel
                    )
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }
    
    private func waveformColor(for index: Int) -> Color {
        if viewModel.isRecording {
            let normalizedIndex = Double(index) / 19.0
            let distance = abs(normalizedIndex - 0.5) * 2 // 0 to 1, center is 0
            let intensity = 1.0 - distance
            let level = Double(viewModel.audioLevel) * intensity
            
            return Color.glassBlue.opacity(0.3 + level * 0.7)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        if viewModel.isRecording {
            let normalizedIndex = Double(index) / 19.0
            let distance = abs(normalizedIndex - 0.5) * 2 // 0 to 1, center is 0
            let intensity = 1.0 - distance
            let baseHeight: CGFloat = 8
            let maxHeight: CGFloat = 60
            let level = CGFloat(viewModel.audioLevel) * intensity
            
            return baseHeight + (maxHeight - baseHeight) * level
        } else {
            return 8
        }
    }
    
    // MARK: - Transcription View
    
    private var transcriptionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.transcription.isEmpty {
                    Text("Your transcription will appear here as you speak...")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Text(viewModel.transcription)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .frame(maxHeight: 200)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        VStack(spacing: 16) {
            if !viewModel.hasPermissions {
                // Permission request
                VStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    
                    Text("Microphone and speech recognition permissions are required")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        Task {
                            await viewModel.requestPermissions()
                        }
                    } label: {
                        Text("Grant Permissions")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.glassBlue)
                            .clipShape(Capsule())
                    }
                }
                .padding()
            } else if viewModel.isRecording {
                // Stop button
                Button {
                    viewModel.stopRecording()
                    if !viewModel.transcription.isEmpty {
                        showingSaveConfirmation = true
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                        Text("Stop Recording")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .clipShape(Capsule())
                }
            } else {
                // Start button
                Button {
                    Task {
                        await viewModel.startRecording()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                        Text("Start Recording")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.glassBlue)
                    .clipShape(Capsule())
                }
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.viewContext
    let contact = Contact(context: context)
    contact.id = UUID()
    contact.name = "Sarah Chen"
    
    return VoiceNoteRecordingView(
        viewModel: VoiceNoteViewModel(
            contact: contact,
            dataManager: DataManager(persistence: PersistenceController.preview)
        )
    )
}

