# Backend Configuration Guide

## Where to Set BACKEND_URL and BACKEND_API_KEY

You have **three options** for configuring the backend URL and API key:

### Option 1: Directly in Config.swift (Simplest for Development)

Edit `Circles/Config.swift` and replace the values:

```swift
static let backendBaseURL: String = {
    #if DEBUG
    return "https://circles-backend.khansaad6786.workers.dev" // Your worker URL
    #else
    return "https://circles-backend.khansaad6786.workers.dev" // Your worker URL
    #endif
}()

static let backendAPIKey: String = {
    return "your-api-key-here" // Your API key
}()
```

**Pros:** Simple, works immediately  
**Cons:** API key is in source code (not secure for production)

---

### Option 2: Xcode Scheme Environment Variables (Recommended for Development)

1. In Xcode, click on your scheme (next to the play button)
2. Select "Edit Scheme..."
3. Go to "Run" → "Arguments" tab
4. Under "Environment Variables", click the "+" button
5. Add:
   - Name: `BACKEND_URL`, Value: `https://circles-backend.khansaad6786.workers.dev`
   - Name: `BACKEND_API_KEY`, Value: `your-api-key-here`

**Pros:** Keeps secrets out of source code  
**Cons:** Only works in Xcode, not in production builds

---

### Option 3: Info.plist (For Production)

Add to `Circles/Info.plist`:

```xml
<key>BACKEND_URL</key>
<string>https://circles-backend.khansaad6786.workers.dev</string>
<key>BACKEND_API_KEY</key>
<string>your-api-key-here</string>
```

Then update `Config.swift` to read from Info.plist:

```swift
static let backendBaseURL: String = {
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let url = plist["BACKEND_URL"] as? String {
        return url
    }
    return "" // Fallback
}()

static let backendAPIKey: String = {
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let key = plist["BACKEND_API_KEY"] as? String {
        return key
    }
    return "" // Fallback
}()
```

**Pros:** Works in production builds  
**Cons:** Still in the app bundle (better than source code, but not perfect)

---

## What is BACKEND_API_KEY?

The `BACKEND_API_KEY` is a simple authentication token that your iOS app sends to the backend to authenticate requests. 

**For MVP/Development:**
- You can use any string (e.g., "my-secret-key-123")
- The backend currently accepts any non-empty token (see `backend/src/middleware/auth.ts`)

**For Production:**
- Generate unique API keys per user
- Or implement Apple Sign-In token validation
- Store keys securely (Keychain, not UserDefaults)

---

## Quick Setup (Recommended for Now)

**For development, use Option 1** - directly in `Config.swift`:

1. Open `Circles/Config.swift`
2. Replace line 23 with your full worker URL (with `https://`)
3. Replace the `backendAPIKey` return value with your API key

Example:
```swift
static let backendBaseURL: String = {
    #if DEBUG
    return "https://circles-backend.khansaad6786.workers.dev"
    #else
    return "https://circles-backend.khansaad6786.workers.dev"
    #endif
}()

static let backendAPIKey: String = {
    return "my-secret-api-key-123" // Change this to your actual key
}()
```

---

## Testing

After setting the values, test if the backend is being used:

1. Run the app
2. Record a voice note
3. Check the logs - you should see "Using backend API for AI operations" if configured correctly

If you see "Using direct Gemini API (backend not configured)", check:
- Is `backendBaseURL` non-empty?
- Is `backendAPIKey` non-empty?
- Does the URL start with `https://`?

