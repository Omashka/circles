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
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
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

