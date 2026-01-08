/**
 * Rate limiting middleware
 * 
 * Simple in-memory rate limiting (for production, use Cloudflare Rate Limiting or Durable Objects)
 */

interface RateLimitStore {
  [key: string]: {
    count: number;
    resetTime: number;
  };
}

// In-memory store (resets on worker restart)
// For production, use Durable Objects or Cloudflare Rate Limiting
const rateLimitStore: RateLimitStore = {};

const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 30; // 30 requests per minute

export async function rateLimit(
  request: Request,
  env: any
): Promise<Response | null> {
  // Get client identifier (IP address or user ID)
  const clientId = request.headers.get('CF-Connecting-IP') || 
                   request.headers.get('X-Forwarded-For') || 
                   'unknown';

  const now = Date.now();
  const record = rateLimitStore[clientId];

  // Check if record exists and is still valid
  if (record && record.resetTime > now) {
    // Increment count
    record.count++;
    
    // Check if limit exceeded
    if (record.count > RATE_LIMIT_MAX_REQUESTS) {
      return new Response(null, { status: 429 });
    }
  } else {
    // Create new record or reset expired one
    rateLimitStore[clientId] = {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW,
    };
  }

  // Clean up old records (simple cleanup)
  if (Object.keys(rateLimitStore).length > 1000) {
    const keys = Object.keys(rateLimitStore);
    for (const key of keys) {
      if (rateLimitStore[key].resetTime < now) {
        delete rateLimitStore[key];
      }
    }
  }

  return null; // No rate limit exceeded
}

