//
//  ContactExtensions.swift
//  Circles
//

import Foundation
import CoreData

// MARK: - Contact Extensions

extension Contact {
    /// Number of days since last contact
    var daysSinceLastContact: Int {
        Calendar.current.dateComponents(
            [.day],
            from: lastConnectedDate ?? createdAt ?? Date(),
            to: Date()
        ).day ?? 0
    }
    
    /// Relationship health score (0.0 to 1.0)
    var relationshipScore: Double {
        let days = Double(daysSinceLastContact)
        let interactionCount = Double(interactions?.count ?? 0)
        
        // Recency score: decreases as time passes (90 days = 0)
        let recencyScore = max(0, 1.0 - (days / 90.0))
        
        // Frequency score: increases with more interactions (50 interactions = 1.0)
        let frequencyScore = min(1.0, interactionCount / 50.0)
        
        // Weight recency more heavily (70/30)
        return (recencyScore * 0.7) + (frequencyScore * 0.3)
    }
    
    /// Urgency level for check-in reminders
    var urgencyLevel: UrgencyLevel {
        switch daysSinceLastContact {
        case 0..<7:
            return .low
        case 7..<30:
            return .medium
        case 30..<60:
            return .high
        default:
            return .critical
        }
    }
    
    /// Array of interests (convenience accessor)
    var interestsArray: [String] {
        get { interests as? [String] ?? [] }
        set { interests = newValue as NSObject }
    }
    
    /// Array of religious events (convenience accessor)
    var religiousEventsArray: [String] {
        get { religiousEvents as? [String] ?? [] }
        set { religiousEvents = newValue as NSObject }
    }
    
    /// Array of topics to avoid (convenience accessor)
    var topicsToAvoidArray: [String] {
        get { topicsToAvoid as? [String] ?? [] }
        set { topicsToAvoid = newValue as NSObject }
    }
    
    /// Interactions sorted by date (most recent first)
    var sortedInteractions: [Interaction] {
        let interactionsSet = interactions as? Set<Interaction> ?? []
        return interactionsSet.sorted { ($0.interactionDate ?? Date()) > ($1.interactionDate ?? Date()) }
    }
}

// MARK: - Urgency Level

enum UrgencyLevel: String, CaseIterable {
    case low
    case medium
    case high
    case critical
    
    var description: String {
        switch self {
        case .low: return "Recently connected"
        case .medium: return "Check in soon"
        case .high: return "Needs attention"
        case .critical: return "Long overdue"
        }
    }
}
