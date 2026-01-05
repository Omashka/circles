//
//  Color+Glass.swift
//  Circles
//

import SwiftUI

extension Color {
    // MARK: - Glass UI Color Palette
    
    /// Primary glass blue
    static let glassBlue = Color(red: 0.4, green: 0.6, blue: 0.9)
    
    /// Secondary glass purple
    static let glassPurple = Color(red: 0.6, green: 0.4, blue: 0.9)
    
    /// Accent glass teal
    static let glassTeal = Color(red: 0.4, green: 0.8, blue: 0.8)
    
    /// Relationship health colors
    static let healthExcellent = Color.green
    static let healthGood = Color.yellow
    static let healthWarning = Color.orange
    static let healthCritical = Color.red
    
    // MARK: - Urgency Colors
    
    /// Urgency level color for contacts
    static func urgencyColor(for days: Int) -> Color {
        switch days {
        case 0..<7:
            return .healthExcellent
        case 7..<30:
            return .healthGood
        case 30..<60:
            return .healthWarning
        default:
            return .healthCritical
        }
    }
}

