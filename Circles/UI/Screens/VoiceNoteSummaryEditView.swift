//
//  VoiceNoteSummaryEditView.swift
//  Circles
//
//  View for editing AI-generated voice note summary

import SwiftUI

struct VoiceNoteSummaryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VoiceNoteSummaryEditViewModel
    
    init(
        summary: VoiceNoteSummary,
        rawTranscription: String,
        contact: Contact,
        dataManager: DataManager,
        onSave: @escaping (VoiceNoteSummary) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: VoiceNoteSummaryEditViewModel(
            summary: summary,
            rawTranscription: rawTranscription,
            contact: contact,
            dataManager: dataManager,
            onSave: onSave
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Review and edit the AI-generated summary")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Summary") {
                    TextEditor(text: $viewModel.editedSummary)
                        .frame(minHeight: 100)
                }
                
                Section("Extracted Interests") {
                    if viewModel.editedInterests.isEmpty {
                        Text("No interests extracted")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.editedInterests.enumerated()), id: \.offset) { index, interest in
                            HStack {
                                TextField("Interest", text: Binding(
                                    get: { viewModel.editedInterests[index] },
                                    set: { viewModel.editedInterests[index] = $0 }
                                ))
                                Button {
                                    viewModel.editedInterests.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Button {
                            viewModel.editedInterests.append("")
                        } label: {
                            Label("Add Interest", systemImage: "plus.circle")
                        }
                    }
                }
                
                Section("Extracted Events") {
                    if viewModel.editedEvents.isEmpty {
                        Text("No events extracted")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.editedEvents.enumerated()), id: \.offset) { index, event in
                            HStack {
                                TextField("Event", text: Binding(
                                    get: { viewModel.editedEvents[index] },
                                    set: { viewModel.editedEvents[index] = $0 }
                                ))
                                Button {
                                    viewModel.editedEvents.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Button {
                            viewModel.editedEvents.append("")
                        } label: {
                            Label("Add Event", systemImage: "plus.circle")
                        }
                    }
                }
                
                Section("Extracted Dates") {
                    if viewModel.editedDates.isEmpty {
                        Text("No dates extracted")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.editedDates.enumerated()), id: \.offset) { index, date in
                            HStack {
                                DatePicker("Date", selection: Binding(
                                    get: { viewModel.editedDates[index] },
                                    set: { viewModel.editedDates[index] = $0 }
                                ), displayedComponents: .date)
                                Button {
                                    viewModel.editedDates.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Button {
                            viewModel.editedDates.append(Date())
                        } label: {
                            Label("Add Date", systemImage: "plus.circle")
                        }
                    }
                }
                
                Section("Work Information") {
                    TextField("Job title and company", text: $viewModel.editedWorkInfo)
                }
                
                Section("Topics to Avoid") {
                    if viewModel.editedTopicsToAvoid.isEmpty {
                        Text("No topics to avoid extracted")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.editedTopicsToAvoid.enumerated()), id: \.offset) { index, topic in
                            HStack {
                                TextField("Topic", text: Binding(
                                    get: { viewModel.editedTopicsToAvoid[index] },
                                    set: { viewModel.editedTopicsToAvoid[index] = $0 }
                                ))
                                Button {
                                    viewModel.editedTopicsToAvoid.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Button {
                            viewModel.editedTopicsToAvoid.append("")
                        } label: {
                            Label("Add Topic", systemImage: "plus.circle")
                        }
                    }
                }
                
                Section("Family Details") {
                    TextEditor(text: $viewModel.editedFamilyDetails)
                        .frame(minHeight: 60)
                }
                
                Section("Travel Notes") {
                    TextEditor(text: $viewModel.editedTravelNotes)
                        .frame(minHeight: 60)
                }
                
                Section("Religious Events") {
                    if viewModel.editedReligiousEvents.isEmpty {
                        Text("No religious events extracted")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.editedReligiousEvents.enumerated()), id: \.offset) { index, event in
                            HStack {
                                TextField("Event", text: Binding(
                                    get: { viewModel.editedReligiousEvents[index] },
                                    set: { viewModel.editedReligiousEvents[index] = $0 }
                                ))
                                Button {
                                    viewModel.editedReligiousEvents.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Button {
                            viewModel.editedReligiousEvents.append("")
                        } label: {
                            Label("Add Event", systemImage: "plus.circle")
                        }
                    }
                }
                
                Section("Birthday") {
                    if let birthday = viewModel.editedBirthday {
                        DatePicker("Birthday", selection: Binding(
                            get: { birthday },
                            set: { viewModel.editedBirthday = $0 }
                        ), displayedComponents: .date)
                        Button("Clear Birthday") {
                            viewModel.editedBirthday = nil
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button {
                            viewModel.editedBirthday = Date()
                        } label: {
                            Label("Set Birthday", systemImage: "calendar")
                        }
                    }
                }
                
                Section("Original Transcription") {
                    ScrollView {
                        Text(viewModel.rawTranscription)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(maxHeight: 200)
                }
            }
            .navigationTitle("Edit Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(viewModel.editedSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}

@MainActor
class VoiceNoteSummaryEditViewModel: ObservableObject {
    @Published var editedSummary: String
    @Published var editedInterests: [String]
    @Published var editedEvents: [String]
    @Published var editedDates: [Date]
    @Published var editedWorkInfo: String
    @Published var editedTopicsToAvoid: [String]
    @Published var editedFamilyDetails: String
    @Published var editedTravelNotes: String
    @Published var editedReligiousEvents: [String]
    @Published var editedBirthday: Date?
    @Published var showingError = false
    @Published var errorMessage: String?
    
    let rawTranscription: String
    private let contact: Contact
    private let dataManager: DataManager
    private let onSave: (VoiceNoteSummary) -> Void
    
    init(
        summary: VoiceNoteSummary,
        rawTranscription: String,
        contact: Contact,
        dataManager: DataManager,
        onSave: @escaping (VoiceNoteSummary) -> Void
    ) {
        self.editedSummary = summary.summary
        self.editedInterests = summary.interests
        self.editedEvents = summary.events
        self.editedDates = summary.dates
        self.editedWorkInfo = summary.workInfo ?? ""
        self.editedTopicsToAvoid = summary.topicsToAvoid ?? []
        self.editedFamilyDetails = summary.familyDetails ?? ""
        self.editedTravelNotes = summary.travelNotes ?? ""
        self.editedReligiousEvents = summary.religiousEvents ?? []
        self.editedBirthday = summary.birthday
        self.rawTranscription = rawTranscription
        self.contact = contact
        self.dataManager = dataManager
        self.onSave = onSave
    }
    
    func save() {
        let trimmedSummary = editedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSummary.isEmpty else {
            errorMessage = "Summary cannot be empty"
            showingError = true
            return
        }
        
        let finalSummary = VoiceNoteSummary(
            summary: trimmedSummary,
            interests: editedInterests.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            events: editedEvents.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            dates: editedDates,
            workInfo: editedWorkInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedWorkInfo.trimmingCharacters(in: .whitespacesAndNewlines),
            topicsToAvoid: editedTopicsToAvoid.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.isEmpty ? nil : editedTopicsToAvoid.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            familyDetails: editedFamilyDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedFamilyDetails.trimmingCharacters(in: .whitespacesAndNewlines),
            travelNotes: editedTravelNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedTravelNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            religiousEvents: editedReligiousEvents.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.isEmpty ? nil : editedReligiousEvents.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            birthday: editedBirthday
        )
        
        onSave(finalSummary)
    }
}

