/**
 * Bakong Regional Proxy — run this on a machine inside Cambodia
 *
 * Supabase Edge Functions run in Tokyo (global edge network), but
 * Bakong's production /v1/check_transaction_by_md5 endpoint is
 * restricted to Cambodian IPs only.  This proxy relays requests from
 * the Edge Function to Bakong within Cambodia.
 *
 * ┌──────────────┐   Supabase Edge Function runs in Tokyo
 * │  Flutter App  │───→  check-bakong-transaction
 * └──────────────┘      │
 *                       ▼  BAKONG_PROXY_URL → http://your-vps:8080
 *                 ┌──────────────────────┐
 *                 │  Regional Proxy      │  ← runs INSIDE Cambodia
 *                 │  (this server)       │
 *                 └──────────┬───────────┘
 *                            │  http://api-bakong.nbc.gov.kh
 *                            ▼
 *                      ┌──────────┐
 *                      │  Bakong  │
 *                      │  API     │
 *                      └──────────┘
 *
 * Quick test (your machine is in Cambodia):
 *   BAKONG_ACCESS_TOKEN=your_token deno run --allow-net --allow-env server.ts
 *
 * Then tunnel with ngrok:
 *   ngrok http 8080
 *   supabase secrets set BAKONG_PROXY_URL=https://your-ngrok-url.ngrok-free.app
 *
 * Production (VPS in Cambodia):
 *   Use systemd to keep it running, nginx as reverse proxy with SSL.
 *   supabase secrets set BAKONG_PROXY_URL=https://your-domain.com
 */

const BAKONG_API_BASE = "https://api-bakong.nbc.gov.kh";
const BAKONG_ACCESS_TOKEN = Deno.env.get("BAKONG_ACCESS_TOKEN");
const PORT = parseInt(Deno.env.get("PORT") ?? "8080", 10);

if (!BAKONG_ACCESS_TOKEN) {
  console.error("FATAL: BAKONG_ACCESS_TOKEN environment variable is required");
  Deno.exit(1);
}

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-allow-headers": "content-type, authorization",
  "access-control-max-age": "86400",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS_HEADERS },
  });
}

async function handler(req: Request): Promise<Response> {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  // Accept POST on any path (so ngrok/nginx path config is flexible)
  if (req.method !== "POST") {
    return json({ error: "Method not allowed, use POST" }, 405);
  }

  let md5: string;
  try {
    const body = await req.json();
    md5 = body?.md5;
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  if (!md5 || typeof md5 !== "string") {
    return json({ error: 'md5 field required in JSON body' }, 400);
  }

  const bakongUrl = `${BAKONG_API_BASE}/v1/check_transaction_by_md5`;
  console.log(`[proxy] → ${bakongUrl}`);

  try {
    const bakongRes = await fetch(bakongUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${BAKONG_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ md5 }),
    });

    const bakongJson = await bakongRes.json();
    console.log(`[proxy] ← ${bakongRes.status}: ${JSON.stringify(bakongJson).substring(0, 200)}`);
    return json(bakongJson, bakongRes.status);
  } catch (err) {
    console.error("[proxy] error:", err);
    return json({ error: "Failed to reach Bakong API" }, 502);
  }
}

Deno.serve({ port: PORT }, handler);
console.log(`\n Bakong proxy listening on :${PORT}`);
console.log(`   TOKEN: ${BAKONG_ACCESS_TOKEN.substring(0, 8)}…`);
console.log(`\n   Quick test: curl -X POST http://localhost:${PORT} -H 'content-type: application/json' -d '{"md5":"test"}'`);
