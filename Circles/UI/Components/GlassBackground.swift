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
            // Liquid Glass UI - Enhanced implementation
            // Note: glassEffect(_:in:) API will be available in future SDK updates
            // Using sophisticated multi-layer approach as recommended by Apple
            ZStack {
                // Layer 1: Rich color gradient base
                LinearGradient(
                    colors: [
                        Color.glassBlue.opacity(0.6),
                        Color.glassPurple.opacity(0.5),
                        Color.glassTeal.opacity(0.45),
                        Color.glassBlue.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Layer 2: Secondary gradient for depth
                LinearGradient(
                    colors: [
                        Color.glassPurple.opacity(0.4),
                        Color.clear,
                        Color.glassTeal.opacity(0.3)
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
                .blur(radius: 120)
                
                // Layer 3: Radial accent for focal point
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
                .blendMode(.plusLighter)
                
                // Layer 4: Glass material overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                // Layer 5: Subtle texture overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.02),
                                .clear,
                                .black.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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

