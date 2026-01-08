//
//  GlassBackground.swift
//  Circles
//

import SwiftUI

/// A white background for the app
struct GlassBackground: View {
    @ViewBuilder
    var body: some View {
        Color.white
                    .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    GlassBackground()
}

