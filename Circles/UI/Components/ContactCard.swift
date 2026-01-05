//
//  ContactCard.swift
//  Circles
//

import SwiftUI

/// A glass-styled card displaying contact information
struct ContactCard: View {
    let contact: Contact
    
    var body: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 16) {
                // Profile photo with fallback initials
                ProfilePhotoView(
                    photoData: contact.profilePhotoData,
                    name: contact.name ?? "?",
                    size: 60
                )
                
                // Contact info
                VStack(alignment: .leading, spacing: 6) {
                    Text(contact.name ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(contact.relationshipType ?? "Contact")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Relationship meter
                    RelationshipMeter(score: contact.relationshipScore)
                        .frame(height: 6)
                }
                
                Spacer()
                
                // Last contacted indicator
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(contact.daysSinceLastContact)d")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    // Urgency indicator dot
                    Circle()
                        .fill(urgencyColor(for: contact.urgencyLevel))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
    
    // MARK: - Helper
    
    private func urgencyColor(for level: UrgencyLevel) -> Color {
        switch level {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
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
                // Background
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 6)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [meterColor, meterColor.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * score, height: 6)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GlassBackground()
        
        VStack(spacing: 16) {
            // Sample contact with photo
            ContactCard(contact: {
                let contact = Contact(context: PersistenceController.preview.viewContext)
                contact.id = UUID()
                contact.name = "Sarah Chen"
                contact.relationshipType = "Friend"
                contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                return contact
            }())
            
            // Sample contact without photo
            ContactCard(contact: {
                let contact = Contact(context: PersistenceController.preview.viewContext)
                contact.id = UUID()
                contact.name = "John Doe"
                contact.relationshipType = "Family"
                contact.lastConnectedDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())
                return contact
            }())
        }
        .padding()
    }
}

