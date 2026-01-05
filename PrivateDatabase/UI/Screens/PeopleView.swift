//
//  PeopleView.swift
//  Circles
//

import SwiftUI

/// Main view for the People tab showing contact list
struct PeopleView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSettings = false
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                VStack {
                    // Content placeholder
                    ScrollView {
                        VStack(spacing: 16) {
                            GlassCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("People")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Your contacts will appear here")
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
            .navigationTitle("People")
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddContact = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundStyle(.primary)
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
            .sheet(isPresented: $showingAddContact) {
                Text("Add Contact (Coming in Prompt 5)")
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PeopleView()
        .environmentObject(DataManager())
}

