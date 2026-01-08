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
    
    @State private var showingInbox = false
    @State private var importedText: String?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(dataManager)
                .environmentObject(viewModel)
                .onOpenURL { url in
                    handleURL(url)
                }
                .sheet(isPresented: $showingInbox) {
                    InboxView()
                        .environmentObject(dataManager)
                }
        }
    }
    
    // MARK: - URL Handling
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "circles",
              url.host == "import",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let textItem = components.queryItems?.first(where: { $0.name == "text" }),
              let text = textItem.value?.removingPercentEncoding else {
            return
        }
        
        // Process imported text
        Task { @MainActor in
            do {
                try await ImportService.shared.processImportedText(
                    text,
                    source: "shortcut_import",
                    dataManager: dataManager
                )
                // Show inbox to review if needed
                showingInbox = true
            } catch {
                print("Error processing imported text: \(error)")
            }
        }
    }
}

