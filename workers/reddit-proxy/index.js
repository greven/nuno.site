/**
 * Cloudflare Worker: Reddit API Proxy
 *
 * Proxies requests to Reddit API to avoid IP blocking on the VPS.
 * Supports caching to reduce API calls.
 */

export default {
  async fetch(request, env, ctx) {
    // Only allow requests from my site domain
    const allowedOrigins = ["https://nuno.site", "https://www.nuno.site"];
    const origin = request.headers.get("Origin");

    // Block requests from unauthorized origins
    if (origin && !allowedOrigins.includes(origin)) {
      return new Response("Forbidden", { status: 403 });
    }

    const url = new URL(request.url);

    // Handle CORS preflight requests
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": origin || "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
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

    // Add CORS headers to response
    const newResponse = new Response(response.body, response);
    newResponse.headers.set("Access-Control-Allow-Origin", origin || "*");
    newResponse.headers.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    newResponse.headers.set("Access-Control-Allow-Headers", "Content-Type");

    return newResponse;
  },
};
