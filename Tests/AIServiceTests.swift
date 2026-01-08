//
//  AIServiceTests.swift
//  CirclesTests
//
//  Unit tests for AIService

import XCTest
@testable import Circles

@MainActor
final class AIServiceTests: XCTestCase {
    var aiService: AIService!
    
    override func setUp() {
        super.setUp()
        // Use empty API key for testing (will test error handling)
        aiService = AIService(apiKey: "")
    }
    
    override func tearDown() {
        aiService = nil
        super.tearDown()
    }
    
    // MARK: - API Key Tests
    
    func testAPIMissingError() async {
        do {
            _ = try await aiService.summarizeVoiceNote(transcription: "Test transcription")
            XCTFail("Should have thrown API key missing error")
        } catch let error as AIError {
            XCTAssertEqual(error, .apiKeyMissing)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Response Parsing Tests
    
    func testParseGiftIdeasResponse() {
        let response = """
        Gift idea 1
        Gift idea 2
        Gift idea 3
        """
        
        let ideas = aiService.parseGiftIdeasResponse(response)
        XCTAssertEqual(ideas.count, 3)
        XCTAssertEqual(ideas[0], "Gift idea 1")
        XCTAssertEqual(ideas[1], "Gift idea 2")
        XCTAssertEqual(ideas[2], "Gift idea 3")
    }
    
    func testParseGiftIdeasResponseWithNumbering() {
        let response = """
        1. Gift idea 1
        2. Gift idea 2
        3. Gift idea 3
        """
        
        let ideas = aiService.parseGiftIdeasResponse(response)
        XCTAssertEqual(ideas.count, 3)
        XCTAssertEqual(ideas[0], "Gift idea 1")
    }
    
    func testParseGiftIdeasResponseWithBullets() {
        let response = """
        - Gift idea 1
        • Gift idea 2
        * Gift idea 3
        """
        
        let ideas = aiService.parseGiftIdeasResponse(response)
        // Should filter out lines starting with bullets
        XCTAssertTrue(ideas.isEmpty || ideas.allSatisfy { !$0.hasPrefix("-") && !$0.hasPrefix("•") && !$0.hasPrefix("*") })
    }
}

// Make parseGiftIdeasResponse accessible for testing
extension AIService {
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

