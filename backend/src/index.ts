/**
 * Circles Backend - Cloudflare Workers
 * 
 * API endpoints for processing voice notes, screenshots, and generating gift ideas
 * using Gemini AI API.
 */

import { handleSummarizeVoiceNote } from './handlers/summarize-voice-note';
import { handleProcessScreenshot } from './handlers/process-screenshot';
import { handleGenerateGiftIdeas } from './handlers/generate-gift-ideas';
import { handleHealthCheck } from './handlers/health-check';
import { authenticateRequest } from './middleware/auth';
import { handleCORS } from './middleware/cors';
import { rateLimit } from './middleware/rate-limit';

export interface Env {
  GEMINI_API_KEY: string;
  // CONTACTS_CACHE: KVNamespace; // Optional KV for caching
}

/**
 * Main request handler
 */
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return handleCORS(new Response(null, { status: 204 }));
    }

    // Health check endpoint (no auth required)
    if (path === '/health' && request.method === 'GET') {
      return handleHealthCheck();
    }

    // Apply CORS to all responses
    const corsHeaders = handleCORS(new Response());

    // Apply rate limiting
    const rateLimitResponse = await rateLimit(request, env);
    if (rateLimitResponse) {
      return new Response(
        JSON.stringify({ error: 'Rate limit exceeded. Please try again later.' }),
        { 
          status: 429,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders.headers,
          }
        }
      );
    }

    // Authenticate request (except health check)
    const authResponse = await authenticateRequest(request);
    if (authResponse) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders.headers,
          }
        }
      );
    }

    // Route to appropriate handler
    try {
      let response: Response;

      if (path === '/api/summarize-voice-note' && request.method === 'POST') {
        response = await handleSummarizeVoiceNote(request, env);
      } else if (path === '/api/process-screenshot' && request.method === 'POST') {
        response = await handleProcessScreenshot(request, env);
      } else if (path === '/api/generate-gift-ideas' && request.method === 'POST') {
        response = await handleGenerateGiftIdeas(request, env);
      } else {
        response = new Response(
          JSON.stringify({ error: 'Not found' }),
          { 
            status: 404,
            headers: { 'Content-Type': 'application/json' }
          }
        );
      }

      // Add CORS headers to response
      Object.entries(corsHeaders.headers).forEach(([key, value]) => {
        response.headers.set(key, value);
      });

      return response;
    } catch (error) {
      console.error('Error handling request:', error);
      return new Response(
        JSON.stringify({ 
          error: 'Internal server error',
          message: error instanceof Error ? error.message : 'Unknown error'
        }),
        { 
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders.headers,
          }
        }
      );
    }
  },
};

