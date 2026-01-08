# Circles Backend - Cloudflare Workers

Serverless backend API for the Circles iOS app, handling AI operations via Gemini API.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set up Cloudflare Workers:
```bash
# Login to Cloudflare
npx wrangler login

# Set the Gemini API key as a secret
npx wrangler secret put GEMINI_API_KEY
```

3. Run locally:
```bash
npm run dev
```

4. Deploy:
```bash
npm run deploy
```

## API Endpoints

### POST /api/summarize-voice-note
Summarizes a voice note transcription and extracts structured data.

**Request:**
```json
{
  "transcription": "string",
  "contactName": "string (optional)"
}
```

**Response:**
```json
{
  "summary": "string",
  "interests": ["string"],
  "events": ["string"],
  "dates": ["string"],
  "workInfo": "string (optional)",
  "topicsToAvoid": ["string"],
  "familyDetails": "string (optional)",
  "travelNotes": "string (optional)",
  "religiousEvents": ["string"],
  "birthday": "string (optional, YYYY-MM-DD)"
}
```

### POST /api/process-screenshot
Processes text extracted from a screenshot and detects contacts.

**Request:**
```json
{
  "text": "string",
  "contacts": [{"name": "string", "id": "string"}] (optional)
}
```

**Response:**
```json
{
  "detectedContactName": "string (optional)",
  "confidence": 0.0-1.0,
  "summary": "string",
  "interests": ["string"],
  "events": ["string"],
  "dates": ["string"],
  "workInfo": "string (optional)",
  "topicsToAvoid": ["string"],
  "familyDetails": "string (optional)",
  "travelNotes": "string (optional)",
  "religiousEvents": ["string"],
  "birthday": "string (optional, YYYY-MM-DD)"
}
```

### POST /api/generate-gift-ideas
Generates personalized gift ideas for a contact.

**Request:**
```json
{
  "contactName": "string",
  "interests": ["string"] (optional),
  "budget": "string" (optional)
}
```

**Response:**
```json
{
  "ideas": ["string"]
}
```

### GET /health
Health check endpoint (no authentication required).

## Authentication

Currently uses a simple API key approach. In production, this should validate Apple Sign-In tokens.

Include in request headers:
```
Authorization: Bearer <api-key>
```

## Rate Limiting

- 30 requests per minute per IP address
- Returns 429 status when limit exceeded

## Environment Variables

Set via `wrangler secret put`:
- `GEMINI_API_KEY`: Google Gemini API key

## Development

```bash
# Run locally with hot reload
npm run dev

# Deploy to Cloudflare
npm run deploy
```

## Testing

```bash
npm test
```

