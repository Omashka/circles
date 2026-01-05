//
//  SettingsView.swift
//  Circles
//

import SwiftUI

/// Settings screen with app configuration options
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // App Info Section
                        GlassCard {
                            VStack(spacing: 16) {
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.glassBlue)
                                
                                Text("Circles")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Version 1.0.0")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Settings Sections
                        VStack(spacing: 12) {
                            settingsRow(
                                icon: "bell.badge.fill",
                                title: "Notifications",
                                subtitle: "Manage reminders"
                            )
                            
                            settingsRow(
                                icon: "crown.fill",
                                title: "Premium",
                                subtitle: "Unlock all features"
                            )
                            
                            settingsRow(
                                icon: "icloud.fill",
                                title: "iCloud Sync",
                                subtitle: "Cloud backup"
                            )
                            
                            settingsRow(
                                icon: "paintbrush.fill",
                                title: "Appearance",
                                subtitle: "Theme settings"
                            )
                            
                            settingsRow(
                                icon: "lock.fill",
                                title: "Privacy",
                                subtitle: "Data & security"
                            )
                            
                            settingsRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                subtitle: "Get assistance"
                            )
                            
                            settingsRow(
                                icon: "info.circle.fill",
                                title: "About",
                                subtitle: "Learn more"
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Settings Row
    
    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        Button {
            // Navigation will be implemented in later prompts
        } label: {
            GlassCard(padding: 16) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.glassBlue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(DataManager())
}

