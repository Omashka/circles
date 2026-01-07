//
//  ContactCard.swift
//  Circles
//

import SwiftUI

/// A glass-styled card displaying contact information
/// Follows Apple's design guidelines for list rows
struct ContactCard: View {
    let contact: Contact
    
    var body: some View {
        GlassCard(padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                // Profile photo with fallback initials
                ProfilePhotoView(
                    photoData: contact.profilePhotoData,
                    name: contact.name ?? "?",
                    size: 50
                )
                
                // Contact info - flexible width
                VStack(alignment: .leading, spacing: 6) {
                    // Name - can truncate (max 2 lines)
                    Text(contact.name ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata row - never truncates, baseline-aligned
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Relationship pill
                        RelationshipPill(type: contact.relationshipType ?? "Contact")
                        
                        // Time - normalized format (always days)
                        Text(formatTimeAgo(contact.daysSinceLastContact))
                            .font(.subheadline)
                            .foregroundStyle(checkInColor)
                        
                        // Check in icon (always visible if needed)
                        if contact.daysSinceLastContact >= 30 {
                            CheckInButton(contact: contact)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
                
                Spacer(minLength: 8)
                
                // Relationship meter - fixed width, right-aligned
                RelationshipMeter(score: contact.relationshipScore)
                    .frame(width: 50, height: 6)
                    .layoutPriority(0)
                
                // Chevron - interaction affordance
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
    }
    
    // MARK: - Helper Properties
    
    private var checkInColor: Color {
        switch contact.urgencyLevel {
        case .medium:
            return Color(red: 0.7, green: 0.5, blue: 0.3) // Golden-brown
        case .high, .critical:
            return Color(red: 0.6, green: 0.3, blue: 0.2) // Reddish-brown
        default:
            return .secondary
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTimeAgo(_ days: Int) -> String {
        // Compact format for constrained rows
        if days == 0 {
            return "today"
        } else if days == 1 {
            return "1d ago"
        } else {
            return "\(days)d ago"
        }
    }
}

// MARK: - Relationship Pill

struct RelationshipPill: View {
    let type: String
    
    var body: some View {
        Text(type)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(pillColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .minimumScaleFactor(0.9)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.white)
            )
            .overlay(
                Capsule()
                    .stroke(pillColor.opacity(0.85), lineWidth: 0.8) // Reduced opacity and line width
            )
    }
    
    private var pillColor: Color {
        // Use a subtle, pleasant color instead of grey
        Color(red: 0.4, green: 0.5, blue: 0.7) // Soft blue-grey
    }
}

// MARK: - Check In Button

struct CheckInButton: View {
    let contact: Contact
    @State private var showLabel = false
    
    var body: some View {
        Button {
            // TODO: Implement check-in action
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .font(.caption2)
                    .foregroundStyle(checkInColor)
                
                if showLabel {
                    Text("Check in")
                        .font(.caption)
                        .foregroundStyle(checkInColor)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.1) {
            withAnimation {
                showLabel = true
            }
        } onPressingChanged: { pressing in
            if !pressing {
                withAnimation {
                    showLabel = false
                }
            }
        }
    }
    
    private var checkInColor: Color {
        switch contact.urgencyLevel {
        case .medium:
            return Color(red: 0.7, green: 0.5, blue: 0.3) // Golden-brown
        case .high, .critical:
            return Color(red: 0.6, green: 0.3, blue: 0.2) // Reddish-brown
        default:
            return .secondary
        }
    }
}

// MARK: - Profile Photo View

struct ProfilePhotoView: View {
    let photoData: Data?
    let name: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData) {
                // Show photo
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Show initials fallback
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.glassBlue.opacity(0.6),
                                Color.glassPurple.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Text(initials(from: name))
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// MARK: - Relationship Meter

struct RelationshipMeter: View {
    let score: Double // 0.0 to 1.0
    @State private var isAnimated = false
    
    var meterColor: Color {
        switch score {
        case 0.75...:
            return .green
        case 0.5..<0.75:
            return .yellow
        case 0.25..<0.5:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background with subtle fade
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.secondary.opacity(0.15),
                                Color.secondary.opacity(0.25)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                
                // Progress with rounded end cap
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [meterColor, meterColor.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: isAnimated ? geometry.size.width * score : 0,
                        height: 6
                    )
                    .animation(
                        .easeOut(duration: 0.6)
                        .delay(0.1),
                        value: isAnimated
                    )
            }
        }
        .onAppear {
            isAnimated = true
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GlassBackground()
        
        VStack(spacing: 16) {
            // Sample contact with check-in
            ContactCard(contact: {
                let contact = Contact(context: PersistenceController.preview.viewContext)
                contact.id = UUID()
                contact.name = "Jessica Martinez"
                contact.relationshipType = "Colleague"
                contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -35, to: Date())
                return contact
            }())
            
            // Sample contact without check-in
            ContactCard(contact: {
                let contact = Contact(context: PersistenceController.preview.viewContext)
                contact.id = UUID()
                contact.name = "Sarah Chen"
                contact.relationshipType = "Friend"
                contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                return contact
            }())
        }
        .padding()
    }
}
