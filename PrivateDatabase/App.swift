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
    
    // Initialize view model for CloudKit tests
    @StateObject private var viewModel = ViewModel()
    
    init() {
        #if DEBUG
        // Add sample data for development
        Task { @MainActor in
            await DebugHelpers.addSampleContactsIfNeeded()
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(dataManager)
                .environmentObject(viewModel)
        }
    }
}

