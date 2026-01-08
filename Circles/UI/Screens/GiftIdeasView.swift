//
//  GiftIdeasView.swift
//  Circles
//
//  View for displaying AI-generated gift ideas

import SwiftUI

struct GiftIdeasView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GiftIdeasViewModel
    
    init(contact: Contact) {
        self.contact = contact
        _viewModel = StateObject(wrappedValue: GiftIdeasViewModel(contact: contact))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating gift ideas...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.generateGiftIdeas()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.giftIdeas.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No gift ideas generated")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Gift Ideas for \(contact.name ?? "Contact")")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(viewModel.giftIdeas.enumerated()), id: \.offset) { index, idea in
                                GlassCard {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.headline)
                                            .foregroundStyle(Color.glassBlue)
                                            .frame(width: 24)
                                        
                                        Text(idea)
                                            .font(.body)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Spacer()
                                    }
                                    .padding()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Gift Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Refresh") {
                        Task {
                            await viewModel.generateGiftIdeas()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.generateGiftIdeas()
            }
        }
    }
}

@MainActor
class GiftIdeasViewModel: ObservableObject {
    @Published var giftIdeas: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let contact: Contact
    private let aiService = AIService.shared
    
    init(contact: Contact) {
        self.contact = contact
    }
    
    func generateGiftIdeas(budget: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            giftIdeas = try await aiService.generateGiftIdeas(for: contact, budget: budget)
            isLoading = false
        } catch {
            if let aiError = error as? AIError, aiError == .apiKeyMissing {
                errorMessage = "AI service is not configured. Please set GEMINI_API_KEY."
            } else {
                errorMessage = "Failed to generate gift ideas: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

