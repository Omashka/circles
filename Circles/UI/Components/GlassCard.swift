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
            // Enhanced Liquid Glass UI for iOS 18+
            // Multi-layered approach with depth, vibrancy, and sophisticated translucency
            content
                .padding(padding)
                .background {
                    ZStack {
                        // Base layer: ultra-thin material for blur
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // Vibrancy layer: subtle color tint
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.15),
                                        .white.opacity(0.05),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.plusLighter)
                    }
                }
                .overlay(
                    // Enhanced border with multi-layer gradient
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.6),
                                    .white.opacity(0.3),
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .overlay(
                    // Inner glow for depth
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .inset(by: 1)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: -1)
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

