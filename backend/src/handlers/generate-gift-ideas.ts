/**
 * Generate gift ideas endpoint
 * 
 * POST /api/generate-gift-ideas
 * 
 * Request body:
 * {
 *   contactName: string;
 *   interests?: string[];
 *   budget?: string;
 * }
 * 
 * Response:
 * {
 *   ideas: string[];
 * }
 */

import { callGemini } from '../services/gemini';
import { Env } from '../index';

interface GenerateGiftIdeasRequest {
  contactName: string;
  interests?: string[];
  budget?: string;
}

export async function handleGenerateGiftIdeas(
  request: Request,
  env: Env
): Promise<Response> {
  try {
    // Parse request body
    const body: GenerateGiftIdeasRequest = await request.json();

    if (!body.contactName || body.contactName.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'contactName is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Build prompt for gift ideas
    const prompt = buildGiftIdeasPrompt(
      body.contactName,
      body.interests || [],
      body.budget
    );

    // Call Gemini API
    const geminiResponse = await callGemini(prompt, env.GEMINI_API_KEY, {
      temperature: 0.8,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 512,
    });

    // Parse response
    const ideas = parseGiftIdeasResponse(geminiResponse);

    return new Response(
      JSON.stringify({ ideas }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error generating gift ideas:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to generate gift ideas',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

function buildGiftIdeasPrompt(
  contactName: string,
  interests: string[],
  budget?: string
): string {
  const interestsText = interests.length > 0
    ? `Their interests include: ${interests.join(', ')}.`
    : '';

  const budgetText = budget ? `Budget: ${budget}.` : '';

  return `Generate thoughtful gift ideas for someone named "${contactName}".

${interestsText}
${budgetText}

Provide 5-7 creative and personalized gift ideas. Consider their interests, hobbies, and preferences.

Return ONLY a JSON array of gift idea strings:
["idea1", "idea2", "idea3", ...]

Rules:
- Return ONLY the JSON array, no markdown, no code blocks
- Make ideas specific and personalized
- Consider a variety of price points
- Be creative and thoughtful`;
}

function parseGiftIdeasResponse(text: string): string[] {
  // Try to extract JSON array from the response
  let cleaned = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
  
  const arrayMatch = cleaned.match(/\[[\s\S]*\]/);
  if (arrayMatch) {
    try {
      return JSON.parse(arrayMatch[0]);
    } catch (e) {
      console.error('Failed to parse JSON array:', e);
    }
  }

  try {
    return JSON.parse(cleaned);
  } catch (e) {
    // Fallback: try to extract ideas from text
    const lines = cleaned.split('\n').filter(line => line.trim().length > 0);
    return lines.slice(0, 7); // Return up to 7 ideas
  }
}

