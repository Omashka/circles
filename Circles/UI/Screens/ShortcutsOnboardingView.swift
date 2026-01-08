//
//  ShortcutsOnboardingView.swift
//  Circles
//
//  Onboarding instructions for setting up Apple Shortcuts with Back Tap

import SwiftUI

/// View showing instructions for setting up Shortcuts integration
struct ShortcutsOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "app.badge")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.glassBlue)
                        
                        Text("Import Messages with Shortcuts")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Automatically import iMessage and WhatsApp screenshots using Back Tap")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    
                    // Step 1: Get the Shortcut
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("1")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.glassBlue)
                                .clipShape(Circle())
                            
                            Text("Get the Shortcut")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Setup")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("Tap the button below to install the shortcut. It will open in the Shortcuts app where you can add it with one tap.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            
                            // iCloud Link (primary method)
                            if let shortcutURL = getShortcutURL() {
                                Link(destination: shortcutURL) {
                                    HStack {
                                        Image(systemName: "link.circle.fill")
                                        Text("Install Shortcut")
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.glassBlue)
                                    .cornerRadius(12)
                                }
                                
                                Text("Opens directly in Shortcuts app - tap 'Add Shortcut' to install")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                // Placeholder when link not configured
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                        Text("Shortcut link not configured")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("To enable one-tap installation, add your iCloud shortcut link in ShortcutsOnboardingView.swift")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Button {
                                        if let shortcutsURL = URL(string: "shortcuts://") {
                                            UIApplication.shared.open(shortcutsURL)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Open Shortcuts App (Manual Setup)")
                                        }
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.glassBlue.opacity(0.8))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            Text("Manual Setup (Alternative)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                instructionStep(number: "1", text: "Open the Shortcuts app")
                                instructionStep(number: "2", text: "Tap the + button to create a new shortcut")
                                instructionStep(number: "3", text: "Add these actions in order:")
                                VStack(alignment: .leading, spacing: 4) {
                                    instructionStep(number: "•", text: "Get Latest Screenshots (set to 1 photo)")
                                    instructionStep(number: "•", text: "Extract Text from Image")
                                    instructionStep(number: "•", text: "Open URL: circles://import?text=[Extracted Text]")
                                }
                                .padding(.leading, 16)
                                instructionStep(number: "4", text: "Name it 'Import to Circles'")
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Step 2: Set up Back Tap
                    instructionSection(
                        number: 2,
                        title: "Enable Back Tap (Optional)",
                        steps: [
                            "Open Settings app",
                            "Go to Accessibility → Touch → Back Tap",
                            "Select Double Tap",
                            "Choose your 'Import to Circles' shortcut"
                        ]
                    )
                    
                    // Step 3: How to use
                    instructionSection(
                        number: 3,
                        title: "How to Use",
                        steps: [
                            "Take a screenshot of a message conversation",
                            "Double tap the back of your iPhone",
                            "The text will be automatically imported",
                            "Review and assign in the Inbox (tray icon)"
                        ]
                    )
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            tipRow(icon: "lightbulb.fill", text: "Works best with clear, readable screenshots")
                            tipRow(icon: "lightbulb.fill", text: "The app will try to detect the contact automatically")
                            tipRow(icon: "lightbulb.fill", text: "Low confidence matches go to Inbox for review")
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    // Done button
                    Button {
                        dismiss()
                    } label: {
                        Text("Got it!")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.glassBlue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding()
            }
            .background(GlassBackground())
            .navigationTitle("Shortcuts Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Instruction Section
    
    private func instructionSection(number: Int, title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.glassBlue)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(steps, id: \.self) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(step)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Tip Row
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.glassBlue)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Instruction Step Helper
    
    private func instructionStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .foregroundStyle(.secondary)
                .font(.body)
                .frame(width: 20, alignment: .leading)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Shortcut URL Helper
    
    /// Returns the iCloud shortcut URL
    /// 
    /// To get this URL:
    /// 1. Create the shortcut in Shortcuts app (see manual setup instructions)
    /// 2. Tap the ... button on the shortcut
    /// 3. Tap Share
    /// 4. Choose "Copy Link" to get the iCloud link
    /// 5. Replace the URL below with your actual link
    private func getShortcutURL() -> URL? {
        // TODO: Replace with your actual iCloud shortcut link after creating and sharing it
        // Example format: https://www.icloud.com/shortcuts/abc123def456...
        // For now, return nil to show manual setup option
        return nil
        
        // Once you have the link, uncomment and replace:
        // return URL(string: "https://www.icloud.com/shortcuts/YOUR_SHORTCUT_ID_HERE")
    }
}

// MARK: - Preview

#Preview {
    ShortcutsOnboardingView()
}

