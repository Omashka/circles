//
//  AIService.swift
//  Circles
//
//  AI service for Gemini API integration

import Foundation
import os.log

/// Service for interacting with Gemini AI API
/// Uses backend API if configured, otherwise falls back to direct Gemini API calls
@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    private let logger = Logger(subsystem: "com.circles.app", category: "AIService")
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    private let backendService: BackendAIService?
    
    // MARK: - Initialization
    
    init(apiKey: String? = nil) {
        // Initialize backend service if configured
        if Config.useBackend {
            self.backendService = BackendAIService(
                baseURL: Config.backendBaseURL,
                apiKey: Config.backendAPIKey
            )
            self.apiKey = "" // Not needed when using backend
            logger.info("Using backend API for AI operations")
        } else {
            self.backendService = nil
            // Get API key from environment variable or Info.plist
            if let key = apiKey {
                self.apiKey = key
            } else if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
                self.apiKey = key
            } else if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
                      let plist = NSDictionary(contentsOfFile: path),
                      let key = plist["GEMINI_API_KEY"] as? String {
                self.apiKey = key
            } else {
                // Fallback: empty key (will fail gracefully)
                self.apiKey = ""
                logger.warning("Gemini API key not found. AI features will not work.")
            }
            logger.info("Using direct Gemini API (backend not configured)")
        }
    }
    
    // MARK: - Voice Note Summarization
    
    /// Summarize a voice note transcription and extract structured data
    func summarizeVoiceNote(
        transcription: String,
        contactName: String? = nil
    ) async throws -> VoiceNoteSummary {
        // Use backend if configured
        if let backend = backendService {
            return try await backend.summarizeVoiceNote(
                transcription: transcription,
                contactName: contactName
            )
        }
        
        // Fallback to direct Gemini API
        logger.info("API key present: \(!self.apiKey.isEmpty), length: \(self.apiKey.count)")
        
        guard !apiKey.isEmpty else {
            logger.error("API key is missing")
            throw AIError.apiKeyMissing
        }
        
        let prompt = buildSummarizationPrompt(transcription: transcription, contactName: contactName)
        logger.info("Built prompt, length: \(prompt.count)")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("Sending summarization request to Gemini API")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        logger.info("Received response, data size: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw AIError.invalidResponse
        }
        
        logger.info("HTTP status code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("API request failed with status \(httpResponse.statusCode): \(errorMessage, privacy: .public)")
            throw AIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        logger.info("Response successful, parsing JSON...")
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = apiResponse.candidates.first?.content.parts.first?.text else {
            logger.error("No content in response")
            throw AIError.noContentInResponse
        }
        
        logger.info("Extracted text from response, length: \(text.count)")
        let summary = try parseSummaryResponse(text)
        logger.info("Successfully parsed summary - Work Info: \(summary.workInfo ?? "nil", privacy: .public), Interests: \(summary.interests, privacy: .public)")
        
        return summary
    }
    
    // MARK: - Contact Detection and Summarization
    
    /// Detect contact from text and generate summary
    func detectContactAndSummarize(
        text: String,
        contacts: [Contact]
    ) async throws -> ContactDetectionResult {
        // Use backend if configured
        if let backend = backendService {
            return try await backend.detectContactAndSummarize(
                text: text,
                contacts: contacts
            )
        }
        
        // Fallback to direct Gemini API
        guard !apiKey.isEmpty else {
            throw AIError.apiKeyMissing
        }
        
        let prompt = buildContactDetectionPrompt(text: text, contacts: contacts)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("Sending contact detection request to Gemini API")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("API request failed with status \(httpResponse.statusCode): \(errorMessage, privacy: .public)")
            throw AIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = apiResponse.candidates.first?.content.parts.first?.text else {
            throw AIError.noContentInResponse
        }
        
        return try parseContactDetectionResponse(text)
    }
    
    private func buildContactDetectionPrompt(text: String, contacts: [Contact]) -> String {
        let contactList = contacts.map { contact in
            "- \(contact.name ?? "Unknown")"
        }.joined(separator: "\n")
        
        return """
        Analyze the following text and:
        1. Detect which contact (if any) this text is about from this list:
        \(contactList.isEmpty ? "No contacts available" : contactList)
        
        2. Generate a summary and extract structured data (same format as voice notes)
        
        3. Provide a confidence score (0.0 to 1.0) for the contact match
        
        Format your response as JSON:
        {
          "detectedContactName": "Name of contact or null",
          "confidence": 0.85,
          "summary": "Brief summary of the conversation",
          "interests": ["interest1", "interest2"],
          "events": ["event1", "event2"],
          "dates": ["2024-12-25"],
          "workInfo": "Job title and company if mentioned",
          "topicsToAvoid": ["topic1"],
          "familyDetails": "Family information if mentioned",
          "travelNotes": "Travel preferences or notes",
          "religiousEvents": ["event1"],
          "birthday": "YYYY-MM-DD or null"
        }
        
        Text to analyze:
        \(text)
        """
    }
    
    private func parseContactDetectionResponse(_ text: String) throws -> ContactDetectionResult {
        // Try to extract JSON from the response
        let jsonPattern = #"\{[^}]+\}"#
        let regex = try NSRegularExpression(pattern: jsonPattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let jsonRange = Range(match.range, in: text) else {
            // Fallback: no contact detected, just summarize
            let summary = try parseSummaryResponse(text)
            return ContactDetectionResult(
                detectedContactName: nil,
                confidence: 0.0,
                summary: summary
            )
        }
        
        let jsonString = String(text[jsonRange])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIError.invalidResponseFormat
        }
        
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ParsedContactDetection.self, from: jsonData)
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dates = parsed.dates.compactMap { dateFormatter.date(from: $0) }
        
        // Parse birthday
        let birthday: Date?
        if let birthdayString = parsed.birthday, !birthdayString.isEmpty {
            birthday = dateFormatter.date(from: birthdayString)
        } else {
            birthday = nil
        }
        
        let summary = VoiceNoteSummary(
            summary: parsed.summary,
            interests: parsed.interests,
            events: parsed.events,
            dates: dates,
            workInfo: parsed.workInfo?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? parsed.workInfo : nil,
            topicsToAvoid: parsed.topicsToAvoid?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            familyDetails: parsed.familyDetails?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? parsed.familyDetails : nil,
            travelNotes: parsed.travelNotes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? parsed.travelNotes : nil,
            religiousEvents: parsed.religiousEvents?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            birthday: birthday
        )
        
        return ContactDetectionResult(
            detectedContactName: parsed.detectedContactName,
            confidence: parsed.confidence,
            summary: summary
        )
    }
    
    // MARK: - Gift Idea Generation
    
    /// Generate gift ideas for a contact based on their interests and information
    func generateGiftIdeas(
        for contact: Contact,
        budget: String? = nil
    ) async throws -> [String] {
        // Use backend if configured
        if let backend = backendService {
            return try await backend.generateGiftIdeas(
                for: contact,
                budget: budget
            )
        }
        
        // Fallback to direct Gemini API
        guard !apiKey.isEmpty else {
            throw AIError.apiKeyMissing
        }
        
        let prompt = buildGiftIdeasPrompt(contact: contact, budget: budget)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 512
            ]
        ]
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("Sending gift ideas request to Gemini API")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("API request failed with status \(httpResponse.statusCode): \(errorMessage)")
            throw AIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = apiResponse.candidates.first?.content.parts.first?.text else {
            throw AIError.noContentInResponse
        }
        
        let ideas = parseGiftIdeasResponse(text)
        return ideas
    }
    
    // MARK: - Private Helpers
    
    private func buildSummarizationPrompt(transcription: String, contactName: String?) -> String {
        let nameContext = contactName.map { " for \($0)" } ?? ""
        
        return """
        Analyze the following voice note transcription\(nameContext) and extract all relevant information about this person.
        
        Extract and provide:
        1. A concise summary (2-3 sentences)
        2. Interests or hobbies mentioned
        3. Events or activities mentioned
        4. Important dates mentioned (extract actual dates if possible)
        5. Work/job information (extract company name and job title if mentioned - examples: "Software Engineer at Apple", "works at Morgan Stanley", "new job at Google" - extract the full job description including company name)
        6. Topics to avoid or sensitive subjects
        7. Family details (children, spouse, family structure)
        8. Travel preferences or notes
        9. Religious or cultural events/holidays
        10. Birthday (if mentioned with context)
        
        Format your response as JSON with this structure:
        {
          "summary": "Brief summary of the conversation",
          "interests": ["interest1", "interest2"],
          "events": ["event1", "event2"],
          "dates": ["2024-12-25", "2024-01-15"],
          "workInfo": "Job title and company name if mentioned (e.g., 'Software Engineer at Apple' or 'works at Morgan Stanley')",
          "topicsToAvoid": ["topic1", "topic2"],
          "familyDetails": "Family information if mentioned",
          "travelNotes": "Travel preferences or notes",
          "religiousEvents": ["event1", "event2"],
          "birthday": "YYYY-MM-DD or null"
        }
        
        Rules:
        - If no information is found for a category, use null (for strings) or empty array [] (for arrays)
        - For dates, use ISO 8601 format (YYYY-MM-DD)
        - Only extract information explicitly mentioned or clearly implied
        - Be specific: "Software Engineer at Apple" not just "Engineer"
        - For birthday, only extract if there's clear context (e.g., "their birthday is...", "born on...")
        
        Transcription:
        \(transcription)
        """
    }
    
    private func buildGiftIdeasPrompt(contact: Contact, budget: String?) -> String {
        var context = "Generate 5-7 thoughtful gift ideas"
        
        if let budget = budget {
            context += " within a \(budget) budget"
        }
        
        context += " for \(contact.name ?? "this person")"
        
        var details: [String] = []
        
        let interests = contact.interestsArray
        if !interests.isEmpty {
            details.append("Interests: \(interests.joined(separator: ", "))")
        }
        
        if let jobInfo = contact.jobInfo, !jobInfo.isEmpty {
            details.append("Work: \(jobInfo)")
        }
        
        if let relationshipType = contact.relationshipType, !relationshipType.isEmpty {
            details.append("Relationship: \(relationshipType)")
        }
        
        if !details.isEmpty {
            context += "\n\nContext:\n" + details.joined(separator: "\n")
        }
        
        context += "\n\nProvide gift ideas as a simple list, one per line, without numbering or bullets."
        
        return context
    }
    
    private func parseSummaryResponse(_ text: String) throws -> VoiceNoteSummary {
        // Try to extract JSON from the response
        let jsonPattern = #"\{[^}]+\}"#
        let regex = try NSRegularExpression(pattern: jsonPattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let jsonRange = Range(match.range, in: text) else {
            // Fallback: try to parse the entire text as JSON
            return try parseSummaryFromText(text)
        }
        
        let jsonString = String(text[jsonRange])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIError.invalidResponseFormat
        }
        
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ParsedSummary.self, from: jsonData)
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dates = parsed.dates.compactMap { dateFormatter.date(from: $0) }
        
        // Parse birthday
        let birthday: Date?
        if let birthdayString = parsed.birthday, !birthdayString.isEmpty {
            birthday = dateFormatter.date(from: birthdayString)
        } else {
            birthday = nil
        }
        
        return VoiceNoteSummary(
            summary: parsed.summary,
            interests: parsed.interests,
            events: parsed.events,
            dates: dates,
            workInfo: parsed.workInfo?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? parsed.workInfo : nil,
            topicsToAvoid: parsed.topicsToAvoid?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            familyDetails: parsed.familyDetails?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? parsed.familyDetails : nil,
            travelNotes: parsed.travelNotes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? parsed.travelNotes : nil,
            religiousEvents: parsed.religiousEvents?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            birthday: birthday
        )
    }
    
    private func parseSummaryFromText(_ text: String) throws -> VoiceNoteSummary {
        // Fallback parser: extract information from natural language response
        let lines = text.components(separatedBy: .newlines)
        var summary = ""
        var interests: [String] = []
        var events: [String] = []
        var dates: [Date] = []
        var workInfo: String?
        var topicsToAvoid: [String]?
        var familyDetails: String?
        var travelNotes: String?
        var religiousEvents: [String]?
        var birthday: Date?
        
        var currentSection: String?
        
        for line in lines {
            let lowercased = line.lowercased()
            
            if lowercased.contains("summary") || lowercased.contains("summary:") {
                currentSection = "summary"
                summary = line.replacingOccurrences(of: "summary:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            } else if lowercased.contains("interest") {
                currentSection = "interests"
            } else if lowercased.contains("event") && !lowercased.contains("religious") {
                currentSection = "events"
            } else if lowercased.contains("date") || lowercased.contains("birthday") {
                currentSection = "dates"
            } else if lowercased.contains("work") || lowercased.contains("job") {
                currentSection = "work"
            } else if lowercased.contains("topic") || lowercased.contains("avoid") {
                currentSection = "topics"
            } else if lowercased.contains("family") {
                currentSection = "family"
            } else if lowercased.contains("travel") {
                currentSection = "travel"
            } else if lowercased.contains("religious") {
                currentSection = "religious"
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if currentSection == "summary" {
                    summary += " " + trimmed
                } else if currentSection == "interests" {
                    interests.append(trimmed)
                } else if currentSection == "events" {
                    events.append(trimmed)
                } else if currentSection == "dates" {
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withFullDate]
                    if let date = dateFormatter.date(from: trimmed) {
                        if lowercased.contains("birthday") {
                            birthday = date
                        } else {
                            dates.append(date)
                        }
                    }
                } else if currentSection == "work" {
                    workInfo = (workInfo ?? "") + (workInfo == nil ? "" : " ") + trimmed
                } else if currentSection == "topics" {
                    if topicsToAvoid == nil { topicsToAvoid = [] }
                    topicsToAvoid?.append(trimmed)
                } else if currentSection == "family" {
                    familyDetails = (familyDetails ?? "") + (familyDetails == nil ? "" : " ") + trimmed
                } else if currentSection == "travel" {
                    travelNotes = (travelNotes ?? "") + (travelNotes == nil ? "" : " ") + trimmed
                } else if currentSection == "religious" {
                    if religiousEvents == nil { religiousEvents = [] }
                    religiousEvents?.append(trimmed)
                }
            }
        }
        
        // If no structured data found, use the entire text as summary
        if summary.isEmpty && interests.isEmpty && events.isEmpty {
            summary = text.trimmingCharacters(in: .whitespaces)
        }
        
        return VoiceNoteSummary(
            summary: summary.isEmpty ? text : summary,
            interests: interests,
            events: events,
            dates: dates,
            workInfo: workInfo?.isEmpty == false ? workInfo : nil,
            topicsToAvoid: topicsToAvoid?.isEmpty == false ? topicsToAvoid : nil,
            familyDetails: familyDetails?.isEmpty == false ? familyDetails : nil,
            travelNotes: travelNotes?.isEmpty == false ? travelNotes : nil,
            religiousEvents: religiousEvents?.isEmpty == false ? religiousEvents : nil,
            birthday: birthday
        )
    }
    
    func parseGiftIdeasResponse(_ text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        return lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .filter { !$0.hasPrefix("#") && !$0.hasPrefix("-") && !$0.hasPrefix("•") }
            .map { line in
                // Remove numbering (1., 2., etc.)
                line.replacingOccurrences(of: #"^\d+[\.\)]\s*"#, with: "", options: .regularExpression)
            }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Models

struct VoiceNoteSummary {
    let summary: String
    let interests: [String]
    let events: [String]
    let dates: [Date]
    let workInfo: String?
    let topicsToAvoid: [String]?
    let familyDetails: String?
    let travelNotes: String?
    let religiousEvents: [String]?
    let birthday: Date?
}

private struct ParsedSummary: Codable {
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

struct ContactDetectionResult {
    let detectedContactName: String?
    let confidence: Double
    let summary: VoiceNoteSummary
}

private struct ParsedContactDetection: Codable {
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

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

// MARK: - Errors

enum AIError: LocalizedError, Equatable {
    case apiKeyMissing
    case invalidResponse
    case apiError(Int, String)
    case noContentInResponse
    case invalidResponseFormat
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "AI API key is missing. Please configure GEMINI_API_KEY."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .apiError(let code, let message):
            return "AI API error (\(code)): \(message)"
        case .noContentInResponse:
            return "No content in AI response."
        case .invalidResponseFormat:
            return "AI response format is invalid."
        }
    }
}

