//
//  InteractionExtensions.swift
//  Circles
//

import Foundation

extension Interaction {
    /// Array of extracted interests (convenience accessor)
    var extractedInterestsArray: [String] {
        get { extractedInterests as? [String] ?? [] }
        set { extractedInterests = newValue as NSObject }
    }
    
    /// Array of extracted events (convenience accessor)
    var extractedEventsArray: [String] {
        get { extractedEvents as? [String] ?? [] }
        set { extractedEvents = newValue as NSObject }
    }
    
    /// Array of extracted dates (convenience accessor)
    var extractedDatesArray: [Date] {
        get { extractedDates as? [Date] ?? [] }
        set { extractedDates = newValue as NSObject }
    }
    
    /// Source type enum
    var sourceType: InteractionSource {
        InteractionSource(rawValue: source ?? "manual") ?? .manual
    }
}

// MARK: - Interaction Source

enum InteractionSource: String {
    case voiceNote = "voice_note"
    case shortcutImport = "shortcut_import"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .voiceNote: return "Voice Note"
        case .shortcutImport: return "Imported Message"
        case .manual: return "Manual Entry"
        }
    }
}
