//
//  ContactEditView.swift
//  Circles
//

import SwiftUI
import PhotosUI

/// View for adding or editing a contact
struct ContactEditView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let contact: Contact?
    
    // Form fields
    @State private var name: String = ""
    @State private var relationshipType: String = "Friend"
    @State private var birthday: Date?
    @State private var jobInfo: String = ""
    @State private var familyDetails: String = ""
    @State private var travelNotes: String = ""
    @State private var interests: [String] = []
    @State private var religiousEvents: [String] = []
    @State private var topicsToAvoid: [String] = []
    @State private var profilePhotoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingDatePicker = false
    @State private var isSaving = false
    
    let relationshipTypes = ["Friend", "Family", "Colleague", "Acquaintance", "Other"]
    
    init(contact: Contact? = nil) {
        self.contact = contact
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                Form {
                    // Profile Photo Section
                    Section {
                        HStack {
                            Spacer()
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                if let photoData = profilePhotoData,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.glassBlue, lineWidth: 3)
                                        )
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                            .foregroundStyle(Color.glassBlue)
                                        Text("Add Photo")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.glassBlue.opacity(0.3), lineWidth: 2)
                                    )
                                }
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    // Basic Information
                    Section("Basic Information") {
                        TextField("Name", text: $name)
                        
                        Picker("Relationship Type", selection: $relationshipType) {
                            ForEach(relationshipTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        
                        DatePicker("Birthday", selection: Binding(
                            get: { birthday ?? Date() },
                            set: { birthday = $0 }
                        ), displayedComponents: .date)
                        .datePickerStyle(.compact)
                    }
                    .listRowBackground(Color.clear)
                    
                    // Additional Information
                    Section("Additional Information") {
                        TextField("Job/Profession", text: $jobInfo)
                        TextField("Family Details", text: $familyDetails, axis: .vertical)
                            .lineLimit(3...6)
                        TextField("Travel Notes", text: $travelNotes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    .listRowBackground(Color.clear)
                    
                    // Interests & Preferences
                    Section("Interests") {
                        TagEditorView(tags: $interests, placeholder: "Add interest")
                    }
                    .listRowBackground(Color.clear)
                    
                    Section("Religious Events") {
                        TagEditorView(tags: $religiousEvents, placeholder: "Add event")
                    }
                    .listRowBackground(Color.clear)
                    
                    Section("Topics to Avoid") {
                        TagEditorView(tags: $topicsToAvoid, placeholder: "Add topic")
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(contact == nil ? "New Contact" : "Edit Contact")
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
                            await saveContact()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .onAppear {
                loadContactData()
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profilePhotoData = data
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadContactData() {
        guard let contact = contact else { return }
        
        name = contact.name ?? ""
        relationshipType = contact.relationshipType ?? "Friend"
        birthday = contact.birthday
        jobInfo = contact.jobInfo ?? ""
        familyDetails = contact.familyDetails ?? ""
        travelNotes = contact.travelNotes ?? ""
        interests = contact.interestsArray
        religiousEvents = contact.religiousEventsArray
        topicsToAvoid = contact.topicsToAvoidArray
        profilePhotoData = contact.profilePhotoData
    }
    
    private func saveContact() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            let contactToSave: Contact
            if let existingContact = contact {
                contactToSave = existingContact
            } else {
                contactToSave = Contact(context: dataManager.viewContext)
                contactToSave.id = UUID()
                contactToSave.createdAt = Date()
            }
            
            // Update all fields
            contactToSave.name = name
            contactToSave.relationshipType = relationshipType
            contactToSave.birthday = birthday
            contactToSave.jobInfo = jobInfo.isEmpty ? nil : jobInfo
            contactToSave.familyDetails = familyDetails.isEmpty ? nil : familyDetails
            contactToSave.travelNotes = travelNotes.isEmpty ? nil : travelNotes
            contactToSave.interestsArray = interests
            contactToSave.religiousEventsArray = religiousEvents
            contactToSave.topicsToAvoidArray = topicsToAvoid
            contactToSave.profilePhotoData = profilePhotoData
            contactToSave.modifiedAt = Date()
            
            if contact == nil {
                // New contact - set initial last connected date
                contactToSave.lastConnectedDate = Date()
            }
            
            try await dataManager.saveContact(contactToSave)
            dismiss()
        } catch {
            // TODO: Show error alert
            print("Failed to save contact: \(error)")
        }
    }
}

// MARK: - Tag Editor View

struct TagEditorView: View {
    @Binding var tags: [String]
    let placeholder: String
    @State private var newTag: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing tags
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.glassBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            
            // Add new tag
            HStack {
                TextField(placeholder, text: $newTag)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        addTag()
                    }
                
                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.glassBlue)
                }
                .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.glassBlue.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - Preview
#Preview {
    ContactEditView()
        .environmentObject(DataManager())
}

