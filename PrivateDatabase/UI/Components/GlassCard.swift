//
//  GlassCard.swift
//  Circles
//

import SwiftUI

/// A reusable glass-styled card component with translucent background
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
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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

