# Production Configuration Guide

## Where to Put BACKEND_URL and BACKEND_API_KEY for Production

For production iOS apps, you have several options. Here's the recommended approach:

### ✅ Recommended: Info.plist (Production Ready)

**Why:** Similar to how `GEMINI_API_KEY` is stored, keeps configuration out of source code.

**How:**

1. **Add to `Circles/Info.plist`** (already done):
```xml
<key>BACKEND_URL</key>
<string>https://circles-backend.khansaad6786.workers.dev</string>
<key>BACKEND_API_KEY</key>
<string>your-production-api-key-here</string>
```

2. **Update the values:**
   - Replace `https://circles-backend.khansaad6786.workers.dev` with your actual worker URL
   - Replace `your-production-api-key-here` with your actual API key

3. **The code already reads from Info.plist** - `Config.swift` will automatically use these values.

**Pros:**
- ✅ Works in production builds
- ✅ Not in source code (better security)
- ✅ Easy to update per build configuration
- ✅ Follows same pattern as GEMINI_API_KEY

**Cons:**
- ⚠️ Still in the app bundle (can be extracted, but better than source code)
- ⚠️ Requires rebuilding to change

---

### Alternative: Xcode Build Configurations (Most Flexible)

For different environments (Dev, Staging, Production):

1. **Create build configurations:**
   - Xcode → Project → Info → Configurations
   - Add: Debug, Staging, Release

2. **Add to Build Settings:**
   - Xcode → Project → Build Settings
   - Add User-Defined Settings:
     - `BACKEND_URL` (different per configuration)
     - `BACKEND_API_KEY` (different per configuration)

3. **Update Config.swift to read from build settings:**
```swift
static let backendBaseURL: String = {
    #if DEBUG
    return "${BACKEND_URL_DEBUG}"
    #elseif STAGING
    return "${BACKEND_URL_STAGING}"
    #else
    return "${BACKEND_URL_RELEASE}"
    #endif
}()
```

**Pros:**
- ✅ Different values per environment
- ✅ No code changes needed
- ✅ Managed in Xcode

**Cons:**
- ⚠️ More complex setup
- ⚠️ Still in build settings (visible in project file)

---

### Most Secure: Server-Side Configuration (Advanced)

For maximum security, fetch configuration from your server on first launch:

1. **Create a configuration endpoint** on your backend
2. **Fetch on first launch** and store in Keychain
3. **Use Keychain** to store the API key securely

**Pros:**
- ✅ Most secure
- ✅ Can update without app update
- ✅ Per-user keys possible

**Cons:**
- ⚠️ More complex implementation
- ⚠️ Requires network on first launch

---

## Current Setup (What We've Done)

✅ **Info.plist** - Added `BACKEND_URL` and `BACKEND_API_KEY` keys  
✅ **Config.swift** - Updated to read from Info.plist (with fallbacks)  
✅ **Priority order:**
   1. Environment variable (for Xcode schemes)
   2. Info.plist (for production)
   3. Hardcoded fallback (for development)

## Next Steps for Production

1. **Update Info.plist:**
   ```xml
   <key>BACKEND_URL</key>
   <string>https://your-actual-worker-url.workers.dev</string>
   <key>BACKEND_API_KEY</key>
   <string>your-actual-production-api-key</string>
   ```

2. **Generate a production API key:**
   - Use a strong, random string
   - Store it securely (password manager, etc.)
   - Update the backend to validate this specific key (if needed)

3. **Test:**
   - Build a Release configuration
   - Verify the app uses the backend
   - Check logs to confirm backend is being used

4. **For App Store submission:**
   - Make sure Info.plist has production values
   - Remove any debug/test API keys
   - Archive and submit

## Security Notes

- **BACKEND_URL**: Not sensitive (public URL), can be hardcoded
- **BACKEND_API_KEY**: More sensitive, should be in Info.plist (not source code)
- **Future improvement**: Implement Apple Sign-In token validation instead of API keys
- **Best practice**: Rotate API keys periodically

## Quick Reference

**For Production:**
- ✅ Use Info.plist (already set up)
- ✅ Update values in Info.plist
- ✅ Build Release configuration
- ✅ Test before App Store submission

**For Development:**
- Use Xcode scheme environment variables
- Or hardcode in Config.swift (DEBUG section)
- Or use Info.plist with different values

