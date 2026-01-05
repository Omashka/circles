//
//  GlassCard.swift
//  Circles
//

import SwiftUI

/// A reusable glass-styled card component with Liquid Glass UI support
/// Uses iOS 18+ Liquid Glass APIs when available, falls back to standard glassmorphism
struct GlassCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    @ViewBuilder
    var body: some View {
        if #available(iOS 18.0, *) {
            // Liquid Glass UI for iOS 18+
            // Note: .liquidGlass requires iOS 18+ and may need Xcode beta
            // Using enhanced ultraThinMaterial as fallback until API is available
            content
                .padding(padding)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        } else {
            // Fallback to standard glassmorphism for iOS 16-17
            content
                .padding(padding)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GlassBackground()
        
        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sarah Chen")
                        .font(.headline)
                    Text("Friend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            GlassCard(cornerRadius: 16) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                    Text("Profile Card")
                }
            }
        }
        .padding()
    }
}

