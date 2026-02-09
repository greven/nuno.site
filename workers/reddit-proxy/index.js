/**
 * Cloudflare Worker: Reddit API Proxy
 *
 * Proxies requests to Reddit API to avoid IP blocking on the VPS.
 *
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
      console.warn("Unauthorized request: Invalid or missing auth token");
      return new Response("Forbidden", { status: 403 });
    }

    // Validate ORIGIN/REFERER
    const allowedDomains = ["nuno.site", "www.nuno.site"];
    const origin = request.headers.get("Origin");
    const referer = request.headers.get("Referer");

    let isValidOrigin = false;

    // Check Origin header
    if (origin) {
      const originHost = new URL(origin).hostname;
      isValidOrigin = allowedDomains.includes(originHost);
    }
    // Fallback to Referer header if Origin is not present
    else if (referer) {
      const refererHost = new URL(referer).hostname;
      isValidOrigin = allowedDomains.includes(refererHost);
    }

    if (!isValidOrigin) {
      console.warn(
        `Unauthorized request: Invalid origin/referer - Origin: ${origin}, Referer: ${referer}`,
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

    // Extract Reddit path from /proxy/...
    // Example: /proxy/r/programming/top/.json becomes https://www.reddit.com/r/programming/top/.json
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

    // Add CORS headers to response (only for valid origin)
    const newResponse = new Response(response.body, response);
    newResponse.headers.set("Access-Control-Allow-Origin", origin || referer);
    newResponse.headers.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    newResponse.headers.set(
      "Access-Control-Allow-Headers",
      "Content-Type, X-Proxy-Auth",
    );

    return newResponse;
  },
};

function handlePreflight(request) {
  const allowedDomains = ["nuno.site", "www.nuno.site"];
  const origin = request.headers.get("Origin");

  // Validate origin for preflight
  if (origin) {
    const originHost = new URL(origin).hostname;
    if (allowedDomains.includes(originHost)) {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": origin,
          "Access-Control-Allow-Methods": "GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, X-Proxy-Auth",
          "Access-Control-Max-Age": "86400", // Cache preflight for 24 hours
        },
      });
    }
  }

  return new Response("Forbidden", { status: 403 });
}
