//
//  GlassBackground.swift
//  Circles
//

import SwiftUI

/// A gradient background with glass effect for the app
struct GlassBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.glassBlue.opacity(0.3),
                    Color.glassPurple.opacity(0.2),
                    Color.glassBlue.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 100)
            
            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Preview
#Preview {
    GlassBackground()
}

