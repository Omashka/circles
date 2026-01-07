//
//  ContactDetailView.swift
//  Circles
//

import SwiftUI

/// Detailed view for a contact with all profile information and interaction timeline
struct ContactDetailView: View {
    let contact: Contact
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var interactionViewModel: InteractionViewModel
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddInteraction = false
    @State private var showingVoiceNote = false
    @State private var editingInteraction: Interaction?
    
    init(contact: Contact) {
        self.contact = contact
        // Initialize with placeholder - will be updated in .task with actual dataManager
        _interactionViewModel = StateObject(wrappedValue: InteractionViewModel(
            contact: contact,
            dataManager: DataManager(persistence: .shared)
        ))
    }
    
    var body: some View {
        ZStack {
            GlassBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Important Dates
                    if hasImportantDates {
                        importantDatesSection
                    }
                    
                    // Key Facts
                    if hasKeyFacts {
                        keyFactsSection
                    }
                    
                    // Timeline
                    timelineSection
                }
                .padding()
            }
        }
        .navigationTitle(contact.name ?? "Contact")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditView = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Contact", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            ContactEditView(contact: contact)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingAddInteraction) {
            InteractionEditView(contact: contact)
                .environmentObject(dataManager)
                .onDisappear {
                    Task {
                        await interactionViewModel.loadInteractions()
                    }
                }
        }
        .sheet(isPresented: $showingVoiceNote) {
            VoiceNoteRecordingView(
                viewModel: VoiceNoteViewModel(contact: contact, dataManager: dataManager)
            )
            .onDisappear {
                Task {
                    await interactionViewModel.loadInteractions()
                }
            }
        }
        .sheet(item: $editingInteraction) { interaction in
            InteractionEditView(contact: contact, interaction: interaction)
                .environmentObject(dataManager)
                .onDisappear {
                    Task {
                        await interactionViewModel.loadInteractions()
                    }
                }
        }
        .confirmationDialog(
            "Delete Contact",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteContact()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(contact.name ?? "this contact")? This action cannot be undone.")
        }
        .task {
            // Update view model with injected dataManager
            interactionViewModel.dataManager = dataManager
            await interactionViewModel.loadInteractions()
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ProfilePhotoView(
                photoData: contact.profilePhotoData,
                name: contact.name ?? "?",
                size: 100
            )
            
            VStack(spacing: 8) {
                Text(contact.name ?? "Unknown")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Relationship type with connection strength
                VStack(spacing: 6) {
                    Text(contact.relationshipType ?? "Contact")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    // Connection strength indicator (bar only)
                    RelationshipMeter(score: contact.relationshipScore)
                        .frame(height: 8)
                        .frame(width: 120)
                }
                
                // Last connected
                if let lastConnected = contact.lastConnectedDate {
                    Text("Last connected \(formatLastConnectedDate(lastConnected))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    // MARK: - Important Dates Section
    
    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Important Dates")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                if let birthday = contact.birthday {
                    importantDateRow(
                        icon: "calendar",
                        label: "Birthday",
                        value: formatBirthday(birthday)
                    )
                }
                
                // Show religious events as important dates (e.g., "Anniversary at new job: May 31")
                ForEach(contact.religiousEventsArray, id: \.self) { event in
                    importantDateRow(
                        icon: "star.fill",
                        label: event,
                        value: ""
                    )
                }
            }
        }
    }
    
    private func importantDateRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.glassBlue)
                .frame(width: 24)
            
            if value.isEmpty {
                Text(label)
                    .font(.body)
            } else {
                Text("\(label): \(value)")
                    .font(.body)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Key Facts Section
    
    private var keyFactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Facts")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // Work - Beige/pale orange background with golden-brown text
                if let jobInfo = contact.jobInfo, !jobInfo.isEmpty {
                    keyFactCard(
                        icon: "briefcase.fill",
                        title: "Work",
                        content: jobInfo,
                        backgroundColor: Color(red: 0.98, green: 0.95, blue: 0.88), // Beige/pale orange
                        textColor: Color(red: 0.6, green: 0.4, blue: 0.2) // Golden-brown
                    )
                }
                
                // Interests - Light green background with darker green text
                if !contact.interestsArray.isEmpty {
                    keyFactCard(
                        icon: "star",
                        title: "Interests",
                        content: contact.interestsArray.joined(separator: ", "),
                        backgroundColor: Color(red: 0.9, green: 0.95, blue: 0.9), // Light green/sage
                        textColor: Color(red: 0.2, green: 0.5, blue: 0.2) // Darker green
                    )
                }
                
                // Preferences - Light blue/purple background with darker blue text
                if !contact.topicsToAvoidArray.isEmpty {
                    keyFactCard(
                        icon: "heart",
                        title: "Preferences",
                        content: contact.topicsToAvoidArray.joined(separator: ", "),
                        backgroundColor: Color(red: 0.9, green: 0.9, blue: 0.95), // Light blue/purple
                        textColor: Color(red: 0.3, green: 0.3, blue: 0.6) // Darker blue
                    )
                }
            }
        }
    }
    
    private func keyFactCard(icon: String, title: String, content: String, backgroundColor: Color, textColor: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(textColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(textColor)
                
                Text(content)
                    .font(.body)
                    .foregroundStyle(textColor)
            }
            
            Spacer()
        }
        .padding(16)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(textColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Timeline")
                    .font(.headline)
                    .padding(.horizontal, 4)
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Voice note button
                    Button {
                        showingVoiceNote = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.fill")
                            Text("Voice")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.glassBlue)
                    }
                    
                    // Add interaction button
                    Button {
                        showingAddInteraction = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.glassBlue)
                    }
                }
            }
            
            if interactionViewModel.interactions.isEmpty {
                GlassCard {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No interactions yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Log your first interaction to start tracking your relationship")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                ForEach(interactionViewModel.interactions) { interaction in
                    TimelineCard(
                        interaction: interaction,
                        onEdit: {
                            editingInteraction = interaction
                        },
                        onDelete: {
                            Task {
                                try? await interactionViewModel.deleteInteraction(interaction)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var hasImportantDates: Bool {
        contact.birthday != nil || !contact.religiousEventsArray.isEmpty
    }
    
    private var hasKeyFacts: Bool {
        (contact.jobInfo != nil && !contact.jobInfo!.isEmpty) ||
        !contact.interestsArray.isEmpty ||
        !contact.topicsToAvoidArray.isEmpty
    }
    
    private func formatBirthday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    private func formatLastConnectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    
    private func deleteContact() async {
        do {
            try await dataManager.deleteContact(contact)
            dismiss()
        } catch {
            // TODO: Show error alert
            print("Failed to delete contact: \(error)")
        }
    }
}

// MARK: - Timeline Card

struct TimelineCard: View {
    let interaction: Interaction
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(formatDate(interaction.interactionDate ?? Date()))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(interactionTypeLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
                
                if let content = interaction.content, !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .foregroundStyle(.primary)
                } else {
                    Text("No summary available")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .confirmationDialog(
            "Delete Interaction",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this interaction? This action cannot be undone.")
        }
    }
    
    private var interactionTypeLabel: String {
        switch interaction.source ?? "manual" {
        case "voice_note":
            return "Voice Note"
        case "shortcut_import":
            return "Imported"
        default:
            // Try to infer from content or default to "Meeting"
            if let content = interaction.content?.lowercased() {
                if content.contains("call") || content.contains("phone") {
                    return "Call"
                } else if content.contains("dinner") || content.contains("lunch") || content.contains("coffee") || content.contains("breakfast") {
                    return "Meeting"
                } else if content.contains("event") || content.contains("party") || content.contains("celebration") {
                    return "Event"
                }
            }
            return "Meeting"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.viewContext
    let contact = Contact(context: context)
    contact.id = UUID()
    contact.name = "Sarah Chen"
    contact.relationshipType = "Friend"
    contact.birthday = Calendar.current.date(byAdding: .year, value: -30, to: Date())
    contact.jobInfo = "Former VP at Google, now angel investor"
    contact.interestsArray = ["Passionate about women in tech mentorship", "loves reading biographies"]
    contact.topicsToAvoidArray = ["Prefers early morning meetings, before 9am. Tea over coffee."]
    contact.religiousEventsArray = ["Anniversary at new job: May 31"]
    contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
    
    // Add sample interactions
    let interaction1 = Interaction(context: context)
    interaction1.id = UUID()
    interaction1.contact = contact
    interaction1.content = "Coffee catch-up at Blue Bottle. She mentioned considering a career change to consulting. Kids doing well in school."
    interaction1.source = "manual"
    interaction1.interactionDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
    interaction1.createdAt = interaction1.interactionDate
    
    let interaction2 = Interaction(context: context)
    interaction2.id = UUID()
    interaction2.contact = contact
    interaction2.content = "Quick call about weekend plans. Rescheduled hiking trip to January."
    interaction2.source = "manual"
    interaction2.interactionDate = Calendar.current.date(byAdding: .day, value: -23, to: Date())
    interaction2.createdAt = interaction2.interactionDate
    
    let interaction3 = Interaction(context: context)
    interaction3.id = UUID()
    interaction3.contact = contact
    interaction3.content = "Thanksgiving dinner together. Her place. Met her parents for the first time. They moved from Shanghai 20 years ago."
    interaction3.source = "manual"
    interaction3.interactionDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())
    interaction3.createdAt = interaction3.interactionDate
    
    return ContactDetailView(contact: contact)
        .environmentObject(DataManager(persistence: PersistenceController.preview))
}
