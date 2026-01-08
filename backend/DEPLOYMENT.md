# Deployment Instructions

## Prerequisites

1. Cloudflare account (free tier works)
2. Node.js and npm installed
3. Wrangler CLI installed globally: `npm install -g wrangler`

## Setup Steps

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Login to Cloudflare

```bash
npx wrangler login
```

This will open your browser to authenticate with Cloudflare.

### 3. Set Gemini API Key

```bash
npx wrangler secret put GEMINI_API_KEY
```

When prompted, paste your Gemini API key.

### 4. Update wrangler.toml

Edit `wrangler.toml` and update the `name` field to your desired worker name:

```toml
name = "circles-backend"
```

### 5. Deploy

```bash
npm run deploy
```

Or for staging:

```bash
npx wrangler deploy --env staging
```

### 6. Get Your Worker URL

After deployment, you'll see output like:

```
✨ Deployment complete!
🌍 https://circles-backend.your-subdomain.workers.dev
```

Copy this URL and update `Config.swift` in the iOS app:

```swift
static let backendBaseURL: String = {
    return "https://circles-backend.your-subdomain.workers.dev"
}()
```

## Testing

### Health Check

```bash
curl https://your-worker-url.workers.dev/health
```

### Test Summarize Endpoint

```bash
curl -X POST https://your-worker-url.workers.dev/api/summarize-voice-note \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "transcription": "I had a great conversation with Sarah today. She loves her new job at Apple and is really excited about the iOS development work."
  }'
```

## Environment Variables

- `GEMINI_API_KEY`: Set via `wrangler secret put GEMINI_API_KEY`
- `BACKEND_API_KEY`: For iOS app authentication (set in iOS app Config.swift)

## Monitoring

View logs in Cloudflare Dashboard:
1. Go to Workers & Pages
2. Select your worker
3. Click "Logs" tab

## Troubleshooting

### Error: "GEMINI_API_KEY is not defined"
- Make sure you ran `wrangler secret put GEMINI_API_KEY`

### Error: "Rate limit exceeded"
- The worker has rate limiting (30 requests/minute per IP)
- For production, consider using Cloudflare Rate Limiting or Durable Objects

### CORS Issues
- CORS is already configured in the worker
- Make sure your iOS app is using the correct backend URL

