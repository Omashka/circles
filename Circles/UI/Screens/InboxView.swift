//
//  InboxView.swift
//  Circles
//
//  View for reviewing and assigning unassigned notes

import SwiftUI

/// View for reviewing unassigned notes imported from Shortcuts
struct InboxView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var unassignedNotes: [UnassignedNote] = []
    @State private var isLoading = true
    @State private var selectedNote: UnassignedNote?
    @State private var showingContactPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                if isLoading {
                    ProgressView()
                } else if unassignedNotes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                await loadNotes()
            }
            .sheet(isPresented: $showingContactPicker) {
                if let note = selectedNote {
                    ContactPickerView(note: note)
                        .environmentObject(dataManager)
                        .onDisappear {
                            Task {
                                await loadNotes()
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Notes List
    
    private var notesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(unassignedNotes) { note in
                    NoteCard(note: note) {
                        selectedNote = note
                        showingContactPicker = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Inbox Empty")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Imported messages will appear here for review")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Methods
    
    private func loadNotes() async {
        isLoading = true
        unassignedNotes = await dataManager.fetchUnassignedNotes()
        isLoading = false
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: UnassignedNote
    let onAssign: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(note.source ?? "Unknown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(note.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Content
                if let content = note.content, !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .foregroundStyle(.primary)
                } else if let rawText = note.rawText, !rawText.isEmpty {
                    Text(rawText)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
                
                // Suggested contacts
                if let suggestions = note.aiSuggestionsArray, !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suggested contacts:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(suggestions.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 4)
                }
                
                // Assign button
                Button {
                    onAssign()
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Assign to Contact")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.glassBlue)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Contact Picker

struct ContactPickerView: View {
    let note: UnassignedNote
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var contacts: [Contact] = []
    @State private var searchText = ""
    @State private var isLoading = true
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            (contact.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                if isLoading {
                    ProgressView()
                } else {
                    VStack(spacing: 0) {
                        // Search bar
                        SearchBar(text: $searchText, onSearchChanged: { _ in })
                            .padding()
                        
                        // Contact list
                        if filteredContacts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.slash")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                
                                Text("No contacts found")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(filteredContacts) { contact in
                                        Button {
                                            Task {
                                                do {
                                                    try await dataManager.assignNote(note, to: contact)
                                                    dismiss()
                                                } catch {
                                                    print("Error assigning note: \(error)")
                                                }
                                            }
                                        } label: {
                                            ContactRow(contact: contact)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assign to Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                await loadContacts()
            }
        }
    }
    
    private func loadContacts() async {
        isLoading = true
        contacts = await dataManager.fetchAllContacts()
        contacts.sort { ($0.name ?? "") < ($1.name ?? "") }
        isLoading = false
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            ProfilePhotoView(photoData: contact.profilePhotoData, name: contact.name ?? "Unknown", size: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name ?? "Unknown")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let relationshipType = contact.relationshipType, !relationshipType.isEmpty {
                    Text(relationshipType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Extensions

extension UnassignedNote {
    var aiSuggestionsArray: [String]? {
        guard let data = aiSuggestions as? Data,
              let suggestions = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return suggestions
    }
}

// MARK: - Preview

#Preview {
    InboxView()
        .environmentObject(DataManager())
}

