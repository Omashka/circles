# Backend API Key Guide

## What is BACKEND_API_KEY?

The `BACKEND_API_KEY` is a simple authentication token that your iOS app sends to the backend to authenticate requests. It's **not** something you get from Cloudflare or anywhere else - **you create it yourself**.

## How to Generate an API Key

### Option 1: Use a Random String Generator

Generate a random, secure string (at least 10 characters):

**Online tools:**
- https://www.random.org/strings/
- https://randomkeygen.com/

**Command line:**
```bash
# Generate a random 32-character key
openssl rand -hex 16
# or
uuidgen
```

**Example keys:**
- `circles-api-key-2024-secure-12345`
- `example`
- `sk_live_`

### Option 2: Use a Simple String (For Development)

For development/testing, you can use any string:
- `my-secret-api-key-123`
- `circles-dev-key-2024`
- `test-key-abc123xyz`

**Note:** The backend currently accepts any token that's at least 10 characters long.

## Where to Use It

### 1. In iOS App (`Circles/Info.plist`)

```xml
<key>BACKEND_API_KEY</key>
<string>your-generated-api-key-here</string>
```

### 2. In Backend (Optional - For Production)

Currently, the backend accepts any valid token. For production, you can:

**Option A: Keep current behavior** (accepts any token ≥10 chars)
- Simplest
- Less secure (anyone with the app can use it)

**Option B: Validate specific keys** (more secure)
- Update `backend/src/middleware/auth.ts` to check against a list of valid keys
- Store valid keys in Cloudflare Workers secrets or KV

## Current Backend Behavior

Looking at `backend/src/middleware/auth.ts`:

```typescript
// Currently accepts any non-empty token that's at least 10 characters
if (!token || token.length < 10) {
  return new Response(null, { status: 401 });
}
// Authentication passed
return null;
```

This means:
- ✅ Any string ≥10 characters will work
- ✅ You can use any key you want
- ⚠️ Anyone with the app can use it (for now)

## Recommended Setup

### For Development:
1. Generate a simple key: `circles-dev-key-2024`
2. Add to `Info.plist`
3. Use it in your app

### For Production:
1. Generate a strong, random key (32+ characters)
2. Add to `Info.plist`
3. (Optional) Update backend to validate this specific key

## Example: Complete Setup

1. **Generate key:**
   ```bash
   openssl rand -hex 16
   # Output: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
   ```

2. **Add to Info.plist:**
   ```xml
   <key>BACKEND_API_KEY</key>
   <string></string>
   ```

3. **Test it:**
   ```bash
   curl -X POST https://your-worker-url.workers.dev/api/summarize-voice-note \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" \
     -d '{"transcription": "test"}'
   ```

## Security Notes

- **Current implementation:** Accepts any valid token (not very secure)
- **For production:** Consider implementing proper validation
- **Future improvement:** Use Apple Sign-In tokens instead of API keys
- **Best practice:** Rotate keys periodically

## Quick Answer

**You don't "get" the API key - you create it yourself!**

Just generate any random string (at least 10 characters) and use it in both:
1. iOS app's `Info.plist` as `BACKEND_API_KEY`
2. (Optional) Backend validation if you want to restrict access

For now, any string ≥10 characters will work!

