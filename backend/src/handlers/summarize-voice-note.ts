/**
 * Summarize voice note endpoint
 * 
 * POST /api/summarize-voice-note
 * 
 * Request body:
 * {
 *   transcription: string;
 *   contactName?: string;
 * }
 * 
 * Response:
 * {
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

interface SummarizeRequest {
  transcription: string;
  contactName?: string;
}

export async function handleSummarizeVoiceNote(
  request: Request,
  env: Env
): Promise<Response> {
  try {
    // Parse request body
    const body: SummarizeRequest = await request.json();

    if (!body.transcription || body.transcription.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'transcription is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Build prompt for Gemini
    const prompt = buildSummarizationPrompt(body.transcription, body.contactName);

    // Call Gemini API
    const geminiResponse = await callGemini(prompt, env.GEMINI_API_KEY, {
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 1024,
    });

    // Parse response
    const summary = parseSummaryResponse(geminiResponse);

    return new Response(
      JSON.stringify(summary),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error summarizing voice note:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to summarize voice note',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

function buildSummarizationPrompt(transcription: string, contactName?: string): string {
  const contactContext = contactName 
    ? `This voice note is about a contact named "${contactName}". `
    : '';

  return `You are analyzing a voice note transcription. Extract key information and structure it as JSON.

${contactContext}Transcription:
${transcription}

Extract and return ONLY valid JSON with this structure:
{
  "summary": "A brief summary of the conversation",
  "interests": ["interest1", "interest2"],
  "events": ["event1", "event2"],
  "dates": ["date1", "date2"],
  "workInfo": "Information about their job, company, or career",
  "topicsToAvoid": ["topic1", "topic2"],
  "familyDetails": "Information about family members or family situation",
  "travelNotes": "Travel plans, destinations, or travel-related information",
  "religiousEvents": ["event1", "event2"],
  "birthday": "YYYY-MM-DD format if mentioned, or null"
}

Rules:
- Return ONLY the JSON object, no markdown, no code blocks
- If a field has no information, use null or empty array/string
- Extract all mentioned interests, events, dates, and other information
- Be specific and accurate
- For workInfo, include company names, job titles, or career updates
- For topicsToAvoid, list sensitive topics or things to avoid discussing
- For birthday, use YYYY-MM-DD format if a date is mentioned`;
}

function parseSummaryResponse(text: string): any {
  // Try to extract JSON from the response
  // Gemini sometimes wraps JSON in markdown or adds text
  
  // Remove markdown code blocks if present
  let cleaned = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
  
  // Try to find JSON object
  const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      return JSON.parse(jsonMatch[0]);
    } catch (e) {
      console.error('Failed to parse JSON:', e);
    }
  }

  // Fallback: try parsing the whole text
  try {
    return JSON.parse(cleaned);
  } catch (e) {
    // If all else fails, return a basic structure
    return {
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

