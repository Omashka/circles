//
//  MainTabView.swift
//  Circles
//

import SwiftUI

/// Main tab navigation container for the app
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
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(DataManager())
}

