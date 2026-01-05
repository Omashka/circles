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
        .onAppear {
            // Apply Liquid Glass styling to tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            
            // Use ultra-thin material for glass effect
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.01)
            
            // Apply blur effect
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)
            appearance.backgroundEffect = blurEffect
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(DataManager())
}

