//
//  MainTabView.swift
//  Circles
//

import SwiftUI

/// Main tab navigation container for the app
/// Follows Apple's Liquid Glass tab bar guidelines:
/// https://developer.apple.com/design/Human-Interface-Guidelines/tab-bars
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // People Tab
            PeopleView()
                .tabItem {
                    Label("People", systemImage: "person.2.fill")
                }
                .tag(0)
            
            // Web Tab
            WebView()
                .tabItem {
                    Label("Web", systemImage: "circle.hexagongrid.fill")
                }
                .tag(1)
            
            // Reminders Tab
            RemindersView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
                .tag(2)
        }
        .tint(Color.glassBlue)
        // Apply Liquid Glass background to tab bar per Apple HIG:
        // "A tab bar floats above content at the bottom of the screen."
        // "Its items rest on a Liquid Glass background that allows content beneath to peek through"
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(DataManager())
}

