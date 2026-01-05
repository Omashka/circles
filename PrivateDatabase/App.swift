//
//  CirclesApp.swift
//  Circles
//

import SwiftUI

@main
struct CirclesApp: App {
    // Initialize persistence controller
    let persistenceController = PersistenceController.shared
    
    // Initialize data manager
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(dataManager)
        }
    }
}

