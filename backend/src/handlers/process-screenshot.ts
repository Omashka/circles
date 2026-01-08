/**
 * Process screenshot endpoint
 * 
 * POST /api/process-screenshot
 * 
 * Request body:
 * {
 *   text: string; // Extracted text from screenshot
 *   contacts?: Array<{ name: string; id: string }>; // Optional contact list for matching
 * }
 * 
 * Response:
 * {
 *   detectedContactName?: string;
 *   confidence: number;
 *   summary: string;
 *   interests: string[];
 *   events: string[];
 *   dates: string[];
 *   workInfo?: string;
 *   topicsToAvoid?: string[];
 *   familyDetails?: string;
 *   travelNotes?: string;
 *   religiousEvents?: string[];
 *   birthday?: string;
 * }
 */

import { callGemini } from '../services/gemini';
import { Env } from '../index';

interface ProcessScreenshotRequest {
  text: string;
  contacts?: Array<{ name: string; id: string }>;
}

export async function handleProcessScreenshot(
  request: Request,
  env: Env
): Promise<Response> {
  try {
    // Parse request body
    const body: ProcessScreenshotRequest = await request.json();

    if (!body.text || body.text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'text is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Build prompt for contact detection and summarization
    const prompt = buildContactDetectionPrompt(body.text, body.contacts || []);

    // Call Gemini API
    const geminiResponse = await callGemini(prompt, env.GEMINI_API_KEY, {
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 1024,
    });

    // Parse response
    const result = parseContactDetectionResponse(geminiResponse);

    return new Response(
      JSON.stringify(result),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error processing screenshot:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to process screenshot',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

function buildContactDetectionPrompt(text: string, contacts: Array<{ name: string; id: string }>): string {
  const contactsList = contacts.length > 0
    ? `Available contacts:\n${contacts.map(c => `- ${c.name} (ID: ${c.id})`).join('\n')}\n\n`
    : '';

  return `You are analyzing text extracted from a screenshot (likely from a messaging app). 

${contactsList}Extracted text:
${text}

Your task:
1. Identify if this text is about a specific contact (if contacts list provided)
2. Provide a confidence score (0.0 to 1.0) for the match
3. Extract and summarize key information

Return ONLY valid JSON with this structure:
{
  "detectedContactName": "name of contact if detected, or null",
  "confidence": 0.0-1.0,
  "summary": "Brief summary of the conversation",
  "interests": ["interest1", "interest2"],
  "events": ["event1", "event2"],
  "dates": ["date1", "date2"],
  "workInfo": "Job, company, or career information",
  "topicsToAvoid": ["topic1", "topic2"],
  "familyDetails": "Family information",
  "travelNotes": "Travel information",
  "religiousEvents": ["event1", "event2"],
  "birthday": "YYYY-MM-DD or null"
}

Rules:
- Return ONLY the JSON object, no markdown, no code blocks
- If no contact is clearly mentioned, set detectedContactName to null and confidence to 0.0
- Confidence should be high (>= 0.7) only if the contact name is explicitly mentioned or strongly implied
- Extract all relevant information from the text
- Be accurate and specific`;
}

function parseContactDetectionResponse(text: string): any {
  // Try to extract JSON from the response
  let cleaned = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
  
  const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      return JSON.parse(jsonMatch[0]);
    } catch (e) {
      console.error('Failed to parse JSON:', e);
    }
  }

  try {
    return JSON.parse(cleaned);
  } catch (e) {
    // Fallback structure
    return {
      detectedContactName: null,
      confidence: 0.0,
      summary: cleaned,
      interests: [],
      events: [],
      dates: [],
      workInfo: null,
      topicsToAvoid: [],
      familyDetails: null,
      travelNotes: null,
      religiousEvents: [],
      birthday: null,
    };
  }
}

