//
//  InteractionExtensions.swift
//  Circles
//

import Foundation
import CoreData

extension Interaction {
    /// Array of extracted interests (convenience accessor)
    var extractedInterestsArray: [String] {
        get { (extractedInterests as? [String]) ?? [String]() }
        set { extractedInterests = newValue as NSArray }
    }
    
    /// Array of extracted events (convenience accessor)
    var extractedEventsArray: [String] {
        get { (extractedEvents as? [String]) ?? [String]() }
        set { extractedEvents = newValue as NSArray }
    }
    
    /// Array of extracted dates (convenience accessor)
    var extractedDatesArray: [Date] {
        get { (extractedDates as? [Date]) ?? [Date]() }
        set { extractedDates = newValue as NSArray }
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
