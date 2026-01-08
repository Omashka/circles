//
//  ImportService.swift
//  Circles
//
//  Service for processing imported text from Shortcuts and detecting contacts

import Foundation
import CoreData
import os.log

/// Service for processing imported text and detecting contacts
@MainActor
class ImportService {
    static let shared = ImportService()
    
    private let logger = Logger(subsystem: "com.circles.app", category: "ImportService")
    private let aiService = AIService.shared
    private let confidenceThreshold: Double = 0.7
    
    // MARK: - Import Processing
    
    /// Process imported text and either assign to contact or add to inbox
    func processImportedText(
        _ text: String,
        source: String = "shortcut_import",
        dataManager: DataManager
    ) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Empty text received for import")
            return
        }
        
        logger.info("Processing imported text, length: \(text.count)")
        
        // Try to detect contact and get AI summary
        let detectionResult = try await detectContactAndSummarize(
            text: text,
            dataManager: dataManager
        )
        
        if let contact = detectionResult.contact, detectionResult.confidence >= confidenceThreshold {
            // High confidence - assign directly to contact
            logger.info("High confidence match (\(detectionResult.confidence)) for contact: \(contact.name ?? "Unknown")")
            
            // Create interaction with AI summary
            _ = try await dataManager.createInteraction(
                for: contact,
                content: detectionResult.summary.summary,
                source: .shortcutImport,
                rawTranscription: text,
                extractedInterests: detectionResult.summary.interests.isEmpty ? nil : detectionResult.summary.interests,
                extractedEvents: detectionResult.summary.events.isEmpty ? nil : detectionResult.summary.events,
                extractedDates: detectionResult.summary.dates.isEmpty ? nil : detectionResult.summary.dates
            )
            
            // Update contact profile with AI-extracted data
            try await ProfileUpdateService.shared.updateContactProfile(
                contact,
                with: detectionResult.summary,
                dataManager: dataManager
            )
            
            logger.info("Successfully assigned imported text to contact")
        } else {
            // Low confidence or no match - add to inbox
            logger.info("Low confidence (\(detectionResult.confidence)) or no match, adding to inbox")
            
            let summary = detectionResult.summary.summary.isEmpty ? text : detectionResult.summary.summary
            let suggestions = detectionResult.suggestedContacts.map { $0.name ?? "Unknown" }
            
            let note = try await dataManager.createUnassignedNote(
                content: summary,
                rawText: text,
                source: source
            )
            
            // Store suggestions in note (if aiSuggestions attribute exists)
            if let suggestionsData = try? JSONEncoder().encode(suggestions) {
                note.aiSuggestions = suggestionsData as NSObject
            }
            
            // Save the note (createUnassignedNote already saves, but we need to save again after setting aiSuggestions)
            try await dataManager.saveUnassignedNote(note)
            logger.info("Added to inbox with \(suggestions.count) suggestions")
        }
    }
    
    // MARK: - Contact Detection
    
    private struct DetectionResult {
        let contact: Contact?
        let confidence: Double
        let summary: VoiceNoteSummary
        let suggestedContacts: [Contact]
    }
    
    /// Detect contact from text and generate AI summary
    private func detectContactAndSummarize(
        text: String,
        dataManager: DataManager
    ) async throws -> DetectionResult {
        // Get all contacts for matching
        let allContacts = await dataManager.fetchAllContacts()
        
        // Use AI to detect contact and summarize
        let aiResult = try await aiService.detectContactAndSummarize(
            text: text,
            contacts: allContacts
        )
        
        // Find matching contact
        var matchedContact: Contact?
        var confidence: Double = 0.0
        
        if let detectedName = aiResult.detectedContactName {
            // Find contact by name (fuzzy matching)
            matchedContact = findContactByName(detectedName, in: allContacts)
            confidence = aiResult.confidence
        }
        
        // Get top suggested contacts for inbox
        let suggestedContacts = getSuggestedContacts(
            from: allContacts,
            text: text,
            limit: 5
        )
        
        return DetectionResult(
            contact: matchedContact,
            confidence: confidence,
            summary: aiResult.summary,
            suggestedContacts: suggestedContacts
        )
    }
    
    /// Find contact by name with fuzzy matching
    private func findContactByName(_ name: String, in contacts: [Contact]) -> Contact? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Exact match first
        if let exact = contacts.first(where: { ($0.name ?? "").lowercased() == normalizedName }) {
            return exact
        }
        
        // Partial match (contains)
        if let partial = contacts.first(where: { ($0.name ?? "").lowercased().contains(normalizedName) || normalizedName.contains(($0.name ?? "").lowercased()) }) {
            return partial
        }
        
        // Word-based matching
        let nameWords = normalizedName.components(separatedBy: .whitespaces)
        for contact in contacts {
            guard let contactName = contact.name?.lowercased() else { continue }
            let contactWords = contactName.components(separatedBy: .whitespaces)
            
            // Check if any word matches
            for word in nameWords {
                if contactWords.contains(where: { $0.contains(word) || word.contains($0) }) {
                    return contact
                }
            }
        }
        
        return nil
    }
    
    /// Get suggested contacts based on text content
    private func getSuggestedContacts(
        from contacts: [Contact],
        text: String,
        limit: Int
    ) -> [Contact] {
        let normalizedText = text.lowercased()
        var scoredContacts: [(Contact, Int)] = []
        
        for contact in contacts {
            var score = 0
            
            // Check if contact name appears in text
            if let name = contact.name?.lowercased(), normalizedText.contains(name) {
                score += 10
            }
            
            // Check if interests match
            for interest in contact.interestsArray {
                if normalizedText.contains(interest.lowercased()) {
                    score += 3
                }
            }
            
            // Check if work info matches
            if let workInfo = contact.jobInfo?.lowercased(), normalizedText.contains(workInfo) {
                score += 5
            }
            
            if score > 0 {
                scoredContacts.append((contact, score))
            }
        }
        
        // Sort by score and return top matches
        return scoredContacts
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
}

