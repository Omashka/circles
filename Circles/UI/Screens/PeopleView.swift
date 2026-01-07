//
//  PeopleView.swift
//  Circles
//

import SwiftUI

/// Main view for the People tab showing contact list
struct PeopleView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel = ContactsViewModel()
    
    @State private var showingSettings = false
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                VStack(spacing: 0) {
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if viewModel.contacts.isEmpty {
                        emptyStateView
                    } else {
                        contactListView
                    }
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Settings button
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Add contact button
                        Button {
                            showingAddContact = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color.glassBlue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAddContact) {
                ContactEditView()
                    .environmentObject(dataManager)
            }
            .navigationDestination(for: Contact.self) { contact in
                ContactDetailView(contact: contact)
                    .environmentObject(dataManager)
            }
            .task {
                await viewModel.loadContacts()
            }
        }
    }
    
    // MARK: - Contact List View
    
    private var contactListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredContacts) { contact in
                    NavigationLink(value: contact) {
                        ContactCard(contact: contact)
                    }
                    .buttonStyle(CardButtonStyle())
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshContacts()
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No Contacts Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Add your first contact to start building your network")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showingAddContact = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Contact")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.glassBlue)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .padding()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.glassBlue)
            
            Text("Loading contacts...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)
                        
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            Task {
                                await viewModel.loadContacts()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.glassBlue)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .padding()
            }
        }
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.05 : 0.1),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let onSearchChanged: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            
            TextField("Search contacts...", text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .onChange(of: text) { newValue in
                    onSearchChanged(newValue)
                }
            
            if !text.isEmpty {
                Button {
                    text = ""
                    onSearchChanged("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            if #available(iOS 18.0, *) {
                // Enhanced glass search bar for iOS 18+
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.08),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Preview
#Preview {
    PeopleView()
        .environmentObject(DataManager())
}

