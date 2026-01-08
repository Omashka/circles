//
//  WebView.swift
//  Circles
//

import SwiftUI

/// Main view for the Web tab showing relationship graph visualization
struct WebView: View {
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
                                    Image(systemName: "circle.hexagongrid.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Web")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Your relationship network will be visualized here")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("This is a premium feature")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Web")
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
    WebView()
}

