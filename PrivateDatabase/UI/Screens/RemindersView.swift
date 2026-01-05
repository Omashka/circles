//
//  RemindersView.swift
//  Circles
//

import SwiftUI

/// Main view for the Reminders tab showing contacts needing attention
struct RemindersView: View {
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                VStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            GlassCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Reminders")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Check-in reminders will appear here")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RemindersView()
}

