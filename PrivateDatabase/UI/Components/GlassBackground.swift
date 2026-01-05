//
//  GlassBackground.swift
//  Circles
//

import SwiftUI

/// A gradient background with Liquid Glass effect for the app
/// Uses iOS 18+ Liquid Glass APIs when available
struct GlassBackground: View {
    @ViewBuilder
    var body: some View {
        if #available(iOS 18.0, *) {
            // Liquid Glass UI for iOS 18+
            ZStack {
                // Base gradient - vibrant colors for Liquid Glass
                LinearGradient(
                    colors: [
                        Color.glassBlue.opacity(0.5),
                        Color.glassPurple.opacity(0.4),
                        Color.glassTeal.opacity(0.35),
                        Color.glassBlue.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Additional gradient layer for depth
                LinearGradient(
                    colors: [
                        Color.glassPurple.opacity(0.3),
                        Color.glassBlue.opacity(0.2)
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
                .blur(radius: 100)
                
                // Liquid Glass material overlay
                // Note: .liquidGlass requires iOS 18+ and may need Xcode beta
                // Using enhanced ultraThinMaterial as fallback until API is available
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
        } else {
            // Fallback to standard glassmorphism for iOS 16-17
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color.glassBlue.opacity(0.4),
                        Color.glassPurple.opacity(0.3),
                        Color.glassTeal.opacity(0.25),
                        Color.glassBlue.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated blur layer for depth
                LinearGradient(
                    colors: [
                        Color.glassPurple.opacity(0.2),
                        Color.glassBlue.opacity(0.15)
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
                .blur(radius: 80)
                
                // Glass overlay - ultra thin material for translucency
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    GlassBackground()
}

