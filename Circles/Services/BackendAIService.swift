//
//  BackendAIService.swift
//  Circles
//
//  AI service that calls the Cloudflare Workers backend instead of Gemini directly
//

import Foundation
import os.log

/// Service for interacting with Circles backend API
@MainActor
class BackendAIService: ObservableObject {
    static let shared = BackendAIService()
    
    private let logger = Logger(subsystem: "com.circles.app", category: "BackendAIService")
    private let baseURL: String
    private let apiKey: String
    
    // MARK: - Initialization
    
    init(baseURL: String? = nil, apiKey: String? = nil) {
        self.baseURL = baseURL ?? Config.backendBaseURL
        self.apiKey = apiKey ?? Config.backendAPIKey
        
        if self.apiKey.isEmpty {
            logger.warning("Backend API key not configured. AI features will not work.")
        }
    }
    
    // MARK: - Voice Note Summarization
    
    /// Summarize a voice note transcription and extract structured data
    func summarizeVoiceNote(
        transcription: String,
        contactName: String? = nil
    ) async throws -> VoiceNoteSummary {
        guard !apiKey.isEmpty else {
            logger.error("Backend API key is missing")
            throw AIError.apiKeyMissing
        }
        
        let url = URL(string: "\(baseURL)/api/summarize-voice-note")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "transcription": transcription,
            "contactName": contactName as Any
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("Sending summarization request to backend")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw AIError.invalidResponse
        }
        
        logger.info("HTTP status code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("Backend request failed with status \(httpResponse.statusCode): \(errorMessage, privacy: .public)")
            throw AIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let backendResponse = try decoder.decode(BackendSummaryResponse.self, from: data)
        
        // Convert to VoiceNoteSummary
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        let dates = backendResponse.dates.compactMap { dateFormatter.date(from: $0) }
        let birthday = backendResponse.birthday.flatMap { dateFormatter.date(from: $0) }
        
        return VoiceNoteSummary(
            summary: backendResponse.summary,
            interests: backendResponse.interests,
            events: backendResponse.events,
            dates: dates,
            workInfo: backendResponse.workInfo,
            topicsToAvoid: backendResponse.topicsToAvoid,
            familyDetails: backendResponse.familyDetails,
            travelNotes: backendResponse.travelNotes,
            religiousEvents: backendResponse.religiousEvents,
            birthday: birthday
        )
    }
    
    // MARK: - Contact Detection and Summarization
    
    /// Detect contact from text and generate summary
    func detectContactAndSummarize(
        text: String,
        contacts: [Contact]
    ) async throws -> ContactDetectionResult {
        guard !apiKey.isEmpty else {
            throw AIError.apiKeyMissing
        }
        
        let url = URL(string: "\(baseURL)/api/process-screenshot")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let contactsList = contacts.map { contact in
            [
                "name": contact.name ?? "Unknown",
                "id": contact.id?.uuidString ?? ""
            ]
        }
        
        let requestBody: [String: Any] = [
            "text": text,
            "contacts": contactsList
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("Sending contact detection request to backend")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("Backend request failed with status \(httpResponse.statusCode): \(errorMessage, privacy: .public)")
            throw AIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let backendResponse = try decoder.decode(BackendContactDetectionResponse.self, from: data)
        
        // Convert to VoiceNoteSummary
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        let dates = backendResponse.dates.compactMap { dateFormatter.date(from: $0) }
        let birthday = backendResponse.birthday.flatMap { dateFormatter.date(from: $0) }
        
        let summary = VoiceNoteSummary(
            summary: backendResponse.summary,
            interests: backendResponse.interests,
            events: backendResponse.events,
            dates: dates,
            workInfo: backendResponse.workInfo,
            topicsToAvoid: backendResponse.topicsToAvoid,
            familyDetails: backendResponse.familyDetails,
            travelNotes: backendResponse.travelNotes,
            religiousEvents: backendResponse.religiousEvents,
            birthday: birthday
        )
        
        return ContactDetectionResult(
            detectedContactName: backendResponse.detectedContactName,
            confidence: backendResponse.confidence,
            summary: summary
        )
    }
    
    // MARK: - Gift Idea Generation
    
    /// Generate gift ideas for a contact based on their interests and information
    func generateGiftIdeas(
        for contact: Contact,
        budget: String? = nil
    ) async throws -> [String] {
        guard !apiKey.isEmpty else {
            throw AIError.apiKeyMissing
        }
        
        let url = URL(string: "\(baseURL)/api/generate-gift-ideas")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "contactName": contact.name ?? "Unknown",
            "interests": contact.interestsArray,
            "budget": budget as Any
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("Sending gift ideas request to backend")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("Backend request failed with status \(httpResponse.statusCode): \(errorMessage)")
            throw AIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let backendResponse = try decoder.decode(BackendGiftIdeasResponse.self, from: data)
        
        return backendResponse.ideas
    }
}

// MARK: - Backend Response Models

private struct BackendSummaryResponse: Codable {
    let summary: String
    let interests: [String]
    let events: [String]
    let dates: [String]
    let workInfo: String?
    let topicsToAvoid: [String]?
    let familyDetails: String?
    let travelNotes: String?
    let religiousEvents: [String]?
    let birthday: String?
}

private struct BackendContactDetectionResponse: Codable {
    let detectedContactName: String?
    let confidence: Double
    let summary: String
    let interests: [String]
    let events: [String]
    let dates: [String]
    let workInfo: String?
    let topicsToAvoid: [String]?
    let familyDetails: String?
    let travelNotes: String?
    let religiousEvents: [String]?
    let birthday: String?
}

private struct BackendGiftIdeasResponse: Codable {
    let ideas: [String]
}

