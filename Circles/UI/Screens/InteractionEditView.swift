//
//  InteractionEditView.swift
//  Circles
//

import SwiftUI

/// View for adding or editing an interaction
struct InteractionEditView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let contact: Contact
    let interaction: Interaction?
    
    // Form fields
    @State private var content: String = ""
    @State private var interactionDate: Date = Date()
    @State private var isSaving = false
    
    init(contact: Contact, interaction: Interaction? = nil) {
        self.contact = contact
        self.interaction = interaction
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                Form {
                    Section("Interaction Details") {
                        DatePicker("Date", selection: $interactionDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                    .listRowBackground(Color.clear)
                    
                    Section("Notes") {
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(interaction == nil ? "Add Interaction" : "Edit Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveInteraction()
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onAppear {
                if let interaction = interaction {
                    content = interaction.content ?? ""
                    interactionDate = interaction.interactionDate ?? Date()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveInteraction() async {
        isSaving = true
        
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            isSaving = false
            return
        }
        
        do {
            if let interaction = interaction {
                // Update existing interaction
                interaction.content = trimmedContent
                interaction.interactionDate = interactionDate
                try await dataManager.saveInteraction(interaction)
            } else {
                // Create new interaction
                _ = try await dataManager.createInteraction(
                    for: contact,
                    content: trimmedContent,
                    source: .manual,
                    rawTranscription: nil,
                    extractedInterests: nil,
                    extractedEvents: nil,
                    extractedDates: nil
                )
            }
            
            isSaving = false
            dismiss()
        } catch {
            isSaving = false
            // TODO: Show error alert
            print("Failed to save interaction: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.viewContext
    let contact = Contact(context: context)
    contact.id = UUID()
    contact.name = "Sarah Chen"
    
    return InteractionEditView(contact: contact)
        .environmentObject(DataManager(persistence: PersistenceController.preview))
}

