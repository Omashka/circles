//
//  ProfileUpdateService.swift
//  Circles
//
//  Service for merging AI-extracted data into contact profiles

import Foundation
import CoreData
import os.log

/// Service for updating contact profiles from AI-extracted data
@MainActor
class ProfileUpdateService {
    static let shared = ProfileUpdateService()
    
    private let logger = Logger(subsystem: "com.circles.app", category: "ProfileUpdate")
    
    // MARK: - Profile Update
    
    /// Merge AI-extracted data into contact profile
    func updateContactProfile(
        _ contact: Contact,
        with summary: VoiceNoteSummary,
        dataManager: DataManager
    ) async throws {
        var hasUpdates = false
        
        // Update interests (merge arrays)
        if !summary.interests.isEmpty {
            let updated = mergeInterests(contact.interestsArray, with: summary.interests)
            if updated.count != contact.interestsArray.count {
                contact.interestsArray = updated
                hasUpdates = true
                logger.info("Updated interests: \(contact.interestsArray.count) -> \(updated.count)")
            }
        }
        
        // Update work info (smart replace)
        if let workInfo = summary.workInfo, !workInfo.isEmpty {
            logger.info("AI extracted work info: '\(workInfo)' for contact '\(contact.name ?? "Unknown")'")
            let updated = mergeWorkInfo(contact.jobInfo, with: workInfo)
            if updated != contact.jobInfo {
                contact.jobInfo = updated
                hasUpdates = true
                logger.info("Updated work info: '\(contact.jobInfo ?? "")' -> '\(updated)'")
            } else {
                logger.info("Work info not updated - existing: '\(contact.jobInfo ?? "")', AI: '\(workInfo)'")
            }
        } else {
            logger.info("No work info extracted from AI summary")
        }
        
        // Update topics to avoid (merge arrays)
        if let topics = summary.topicsToAvoid, !topics.isEmpty {
            let updated = mergeTopicsToAvoid(contact.topicsToAvoidArray, with: topics)
            if updated.count != contact.topicsToAvoidArray.count {
                contact.topicsToAvoidArray = updated
                hasUpdates = true
                logger.info("Updated topics to avoid: \(contact.topicsToAvoidArray.count) -> \(updated.count)")
            }
        }
        
        // Update family details (append)
        if let familyDetails = summary.familyDetails, !familyDetails.isEmpty {
            let updated = mergeFamilyDetails(contact.familyDetails, with: familyDetails)
            if updated != contact.familyDetails {
                contact.familyDetails = updated
                hasUpdates = true
                logger.info("Updated family details")
            }
        }
        
        // Update travel notes (append)
        if let travelNotes = summary.travelNotes, !travelNotes.isEmpty {
            let updated = mergeTravelNotes(contact.travelNotes, with: travelNotes)
            if updated != contact.travelNotes {
                contact.travelNotes = updated
                hasUpdates = true
                logger.info("Updated travel notes")
            }
        }
        
        // Update religious events (merge arrays)
        if let religiousEvents = summary.religiousEvents, !religiousEvents.isEmpty {
            let updated = mergeReligiousEvents(contact.religiousEventsArray, with: religiousEvents)
            if updated.count != contact.religiousEventsArray.count {
                contact.religiousEventsArray = updated
                hasUpdates = true
                logger.info("Updated religious events: \(contact.religiousEventsArray.count) -> \(updated.count)")
            }
        }
        
        // Update birthday (replace if better)
        if let birthday = summary.birthday {
            let updated = mergeBirthday(contact.birthday, with: birthday)
            if updated != contact.birthday {
                contact.birthday = updated
                hasUpdates = true
                logger.info("Updated birthday")
            }
        }
        
        // Save if there are updates
        if hasUpdates {
            contact.modifiedAt = Date()
            try await dataManager.saveContact(contact)
            logger.info("Contact profile updated successfully")
        }
    }
    
    // MARK: - Merge Strategies
    
    /// Merge interests: add new, keep existing (case-insensitive)
    private func mergeInterests(_ existing: [String], with new: [String]) -> [String] {
        var merged = Set(existing.map { $0.lowercased() })
        for interest in new {
            let trimmed = interest.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                merged.insert(trimmed.lowercased())
            }
        }
        
        // Preserve original casing from existing, use new casing for new items
        var result: [String] = []
        var added = Set<String>()
        
        // Add existing items first (preserve original casing)
        for item in existing {
            let lower = item.lowercased()
            if !added.contains(lower) {
                result.append(item)
                added.insert(lower)
            }
        }
        
        // Add new items
        for item in new {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let lower = trimmed.lowercased()
                if !added.contains(lower) {
                    result.append(trimmed)
                    added.insert(lower)
                }
            }
        }
        
        return result
    }
    
    /// Merge work info: replace if AI is more specific, otherwise keep existing
    private func mergeWorkInfo(_ existing: String?, with new: String) -> String {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If existing is empty, use new
        guard let existing = existing, !existing.isEmpty else {
            return trimmed
        }
        
        // If new is more specific (longer and contains company name or more detail), use it
        let newLower = trimmed.lowercased()
        let existingLower = existing.lowercased()
        
        // Check if new contains company indicators (expanded list)
        let companyIndicators = [" at ", " for ", " company", " inc", " corp", " ltd", "works at", "job at", "employed at", "working at"]
        let hasCompanyInfo = companyIndicators.contains { newLower.contains($0) } || containsCompanyName(newLower)
        let existingHasCompanyInfo = companyIndicators.contains { existingLower.contains($0) } || containsCompanyName(existingLower)
        
        // If new has company info and existing doesn't, use new
        if hasCompanyInfo && !existingHasCompanyInfo {
            return trimmed
        }
        
        // If new mentions a company name that existing doesn't, use new
        if let newCompany = extractCompanyName(newLower), !existingLower.contains(newCompany.lowercased()) {
            return trimmed
        }
        
        // If new is significantly longer (more specific), use it
        if trimmed.count > Int(Double(existing.count) * 1.5) {
            return trimmed
        }
        
        // If new contains "new job" or "new role", prefer it (indicates update)
        if newLower.contains("new job") || newLower.contains("new role") || newLower.contains("started") {
            return trimmed
        }
        
        // Otherwise keep existing
        return existing
    }
    
    /// Check if text contains a company name (common patterns)
    private func containsCompanyName(_ text: String) -> Bool {
        // Common company name patterns
        let companyPatterns = [
            "morgan stanley", "goldman sachs", "jpmorgan", "bank of america",
            "microsoft", "apple", "google", "amazon", "meta", "tesla",
            "consulting", "partners", "group", "holdings", "ventures"
        ]
        return companyPatterns.contains { text.contains($0) }
    }
    
    /// Extract company name from text (simple heuristic)
    private func extractCompanyName(_ text: String) -> String? {
        // Look for patterns like "at [Company]" or "for [Company]"
        let patterns = [
            #"at\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#,
            #"for\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        
        return nil
    }
    
    /// Merge topics to avoid: add new, keep existing (case-insensitive)
    private func mergeTopicsToAvoid(_ existing: [String], with new: [String]) -> [String] {
        return mergeInterests(existing, with: new) // Same strategy as interests
    }
    
    /// Merge family details: append new info if existing, replace if empty
    private func mergeFamilyDetails(_ existing: String?, with new: String) -> String {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let existing = existing, !existing.isEmpty else {
            return trimmed
        }
        
        // Append new info with separator
        return "\(existing). \(trimmed)"
    }
    
    /// Merge travel notes: append new info if existing, replace if empty
    private func mergeTravelNotes(_ existing: String?, with new: String) -> String {
        return mergeFamilyDetails(existing, with: new) // Same strategy as family details
    }
    
    /// Merge religious events: add new, keep existing (case-insensitive)
    private func mergeReligiousEvents(_ existing: [String], with new: [String]) -> [String] {
        return mergeInterests(existing, with: new) // Same strategy as interests
    }
    
    /// Merge birthday: replace only if more specific or existing is nil
    private func mergeBirthday(_ existing: Date?, with new: Date) -> Date? {
        // If existing is nil, use new
        guard let existing = existing else {
            return new
        }
        
        // Check if new has year information (more specific)
        let calendar = Calendar.current
        let existingComponents = calendar.dateComponents([.year, .month, .day], from: existing)
        let newComponents = calendar.dateComponents([.year, .month, .day], from: new)
        
        // If existing doesn't have year but new does, use new
        if existingComponents.year == nil && newComponents.year != nil {
            return new
        }
        
        // If both have years, keep existing (user may have corrected it)
        // Otherwise keep existing
        return existing
    }
}

