/**
 * Cloudflare Worker: Reddit API Proxy
 *
 * Proxies requests to Reddit API to avoid IP blocking on the VPS.
 */

// In-memory rate limiting
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 100;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Only allow GET and OPTIONS methods
    if (request.method !== "GET" && request.method !== "OPTIONS") {
      return new Response("Method Not Allowed", { status: 405 });
    }

    // Handle CORS preflight requests first
    if (request.method === "OPTIONS") {
      return handlePreflight(request);
    }

    // Validate SECRET TOKEN
    const authToken = request.headers.get("X-Proxy-Auth");
    const expectedToken = env.REDDIT_PROXY_SECRET;

    if (!expectedToken) {
      console.error("REDDIT_PROXY_SECRET environment variable not set!");
      return new Response("Internal Server Error", { status: 500 });
    }

    if (!authToken || authToken !== expectedToken) {
      const origin = request.headers.get("Origin");
      const referer = request.headers.get("Referer");
      const ip = request.headers.get("CF-Connecting-IP");
      console.warn(
        `Unauthorized request: Invalid or missing auth token - IP: ${ip}, Origin: ${origin}, Referer: ${referer}`,
      );
      return new Response("Forbidden", { status: 403 });
    }

    // Rate limiting
    const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
    const rateLimitKey = `${clientIP}`;
    const now = Date.now();

    const rateLimitData = rateLimitMap.get(rateLimitKey) || {
      count: 0,
      resetTime: now + RATE_LIMIT_WINDOW,
    };

    if (now > rateLimitData.resetTime) {
      // Reset the rate limit window
      rateLimitData.count = 1;
      rateLimitData.resetTime = now + RATE_LIMIT_WINDOW;
    } else {
      rateLimitData.count++;
    }

    rateLimitMap.set(rateLimitKey, rateLimitData);

    if (rateLimitData.count > RATE_LIMIT_MAX_REQUESTS) {
      console.warn(`Rate limit exceeded for IP: ${clientIP}`);
      return new Response("Too Many Requests", {
        status: 429,
        headers: {
          "Retry-After": String(
            Math.ceil((rateLimitData.resetTime - now) / 1000),
          ),
        },
      });
    }

    // Periodic clean up old rate limit entries
    if (rateLimitMap.size > 1000) {
      for (const [key, data] of rateLimitMap.entries()) {
        if (now > data.resetTime) {
          rateLimitMap.delete(key);
        }
      }
    }

    // Proxy request to Reddit API
    const redditPath = url.pathname.replace("/proxy/", "");
    const redditUrl = `https://www.reddit.com/${redditPath}${url.search}`;

    // Check Cloudflare cache (5 minute TTL)
    const cacheKey = new Request(redditUrl, { method: "GET" });
    const cache = caches.default;
    let response = await cache.match(cacheKey);

    if (!response) {
      // Cache miss - fetch from Reddit
      const redditRequest = new Request(redditUrl, {
        method: "GET",
        headers: {
          "User-Agent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
          Accept: "application/json",
        },
      });

      response = await fetch(redditRequest);

      // Cache successful responses for 5 minutes
      if (response.ok) {
        const responseToCache = response.clone();
        const headers = new Headers(responseToCache.headers);
        headers.set("Cache-Control", "public, max-age=300");

        const cachedResponse = new Response(responseToCache.body, {
          status: responseToCache.status,
          statusText: responseToCache.statusText,
          headers,
        });

        ctx.waitUntil(cache.put(cacheKey, cachedResponse));
      }
    }

    // Add CORS headers to response
    const newResponse = new Response(response.body, response);
    const origin = request.headers.get("Origin");
    if (origin) {
      newResponse.headers.set("Access-Control-Allow-Origin", origin);
    }
    newResponse.headers.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    newResponse.headers.set(
      "Access-Control-Allow-Headers",
      "Content-Type, X-Proxy-Auth",
    );

    return newResponse;
  },
};

function handlePreflight(request) {
  const origin = request.headers.get("Origin");

  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": origin || "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, X-Proxy-Auth",
      "Access-Control-Max-Age": "86400", // Cache preflight for 24 hours
    },
  });
}
