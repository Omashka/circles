//
//  Config.swift
//  Circles
//
//

import Foundation

enum Config {
    /// iCloud container identifier for Circles app.
    /// Update this to match your own iCloud container in App Store Connect.
    static let containerIdentifier = "iCloud.com.circles.app"
    
    /// Backend API base URL
    /// For development: use localhost with ngrok or your local server
    /// For production: use your deployed Cloudflare Workers URL
    /// Set to empty string to use direct Gemini API calls (fallback)
    static let backendBaseURL: String = {
        // Priority: Environment variable > Info.plist > Hardcoded
        if let envURL = ProcessInfo.processInfo.environment["BACKEND_URL"], !envURL.isEmpty {
            return envURL
        }
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let url = plist["BACKEND_URL"] as? String, !url.isEmpty {
            return url
        }
        
        #if DEBUG
        // Development: Empty = use direct Gemini API
        return ""
        #else
        // Production: Hardcoded fallback (update this with your production URL)
        return "https://circles-backend.khansaad6786.workers.dev"
        #endif
    }()
    
    /// API Key for backend authentication
    /// TODO: Generate per-user API keys or use Apple Sign-In tokens
    static let backendAPIKey: String = {
        // Priority: Environment variable > Info.plist > UserDefaults > Empty
        if let envKey = ProcessInfo.processInfo.environment["BACKEND_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["BACKEND_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        
        // UserDefaults fallback (for runtime configuration)
        if let userDefaultsKey = UserDefaults.standard.string(forKey: "backend_api_key"), !userDefaultsKey.isEmpty {
            return userDefaultsKey
        }
        
        return ""
    }()
    
    /// Whether to use backend API (true) or direct Gemini API (false)
    static var useBackend: Bool {
        return !backendBaseURL.isEmpty && !backendAPIKey.isEmpty
    }
}
