/**
 * Bakong Regional Proxy (Node.js) — run on a machine inside Cambodia
 *
 * Bakong's production /v1/check_transaction_by_md5 endpoint blocks
 * requests from outside Cambodia.  Supabase Edge Functions run in
 * Tokyo, so this proxy relays requests from inside Cambodia.
 *
 * Usage (3 terminals):
 *
 *   Terminal 1 — Start proxy:
 *     set BAKONG_ACCESS_TOKEN=your_token_here
 *     node bakong-regional-proxy/server.mjs
 *
 *   Terminal 2 — Tunnel to internet:
 *     npx ngrok http 8080
 *     # Copy the https://xxxx.ngrok-free.app URL
 *
 *   Terminal 3 — Tell Supabase about the tunnel:
 *     cd D:\Sv23\SA\BusExpress\bus_express
 *     supabase secrets set BAKONG_PROXY_URL=https://xxxx.ngrok-free.app
 *
 * Then restart the Flutter app and try a Bakong payment.
 */

const BAKONG_API_BASE = "https://api-bakong.nbc.gov.kh";
const BAKONG_ACCESS_TOKEN = process.env.BAKONG_ACCESS_TOKEN;
const PORT = parseInt(process.env.PORT || "8080", 10);

if (!BAKONG_ACCESS_TOKEN) {
  console.error("FATAL: BAKONG_ACCESS_TOKEN environment variable is required");
  process.exit(1);
}

import { createServer } from "node:http";

const server = createServer(async (req, res) => {
  const origin = req.headers.origin || "*";

  // CORS headers
  res.setHeader("Access-Control-Allow-Origin", origin);
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "content-type, authorization");
  res.setHeader("Access-Control-Max-Age", "86400");

  // CORS preflight
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  // Only accept POST
  if (req.method !== "POST") {
    res.writeHead(405, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Method not allowed" }));
    return;
  }

  // Read body
  let body = "";
  for await (const chunk of req) body += chunk;

  let md5;
  try {
    md5 = JSON.parse(body)?.md5;
  } catch {
    res.writeHead(400, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Invalid JSON" }));
    return;
  }

  if (!md5 || typeof md5 !== "string") {
    res.writeHead(400, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "md5 field required" }));
    return;
  }

  const bakongUrl = `${BAKONG_API_BASE}/v1/check_transaction_by_md5`;
  console.log(`[proxy] → ${bakongUrl}  md5=${md5.substring(0, 16)}…`);

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
    const snippet = JSON.stringify(bakongJson).substring(0, 200);
    console.log(`[proxy] ← ${bakongRes.status}: ${snippet}`);

    res.writeHead(bakongRes.status, { "Content-Type": "application/json" });
    res.end(JSON.stringify(bakongJson));
  } catch (err) {
    console.error("[proxy] error:", err.message);
    res.writeHead(502, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Failed to reach Bakong API" }));
  }
});

server.listen(PORT, () => {
  console.log(`\n Bakong proxy listening on :${PORT}`);
  console.log(`   TOKEN: ${BAKONG_ACCESS_TOKEN.substring(0, 8)}…`);
  console.log(`   Test: curl -X POST http://localhost:${PORT} -H "content-type: application/json" -d "{\\"md5\\":\\"test\\"}"\n`);
});
