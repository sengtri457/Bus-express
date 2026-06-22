/// <reference lib="deno.window" />
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// When BAKONG_PROXY_URL is set, use the Cambodian VPS proxy instead of
// calling Bakong directly (production Bakong API blocks non-Cambodian IPs).
const BAKONG_PROXY_URL = Deno.env.get("BAKONG_PROXY_URL") ?? "";
const BAKONG_API_BASE = BAKONG_PROXY_URL ||
  (Deno.env.get("BAKONG_API_BASE_URL") ?? "https://api-bakong.nbc.gov.kh");
const BAKONG_ACCESS_TOKEN = Deno.env.get("BAKONG_ACCESS_TOKEN") ?? "";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, content-type, x-client-info",
  "Access-Control-Max-Age": "86400",
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: CORS_HEADERS,
    });
  }

  try {
    const { md5 } = await req.json();

    if (
      !md5 || typeof md5 !== "string" || md5.length < 1 || md5.length > 255
    ) {
      return jsonResponse({ error: "Invalid md5 hash" }, 400);
    }

    if (!BAKONG_ACCESS_TOKEN) {
      console.warn(
        "[Bakong] BAKONG_ACCESS_TOKEN not configured — returning NOT_PAID",
      );
      return jsonResponse({ status: "NOT_PAID" });
    }

    const bakongUrl = `${BAKONG_API_BASE}/v1/check_transaction_by_md5`;
    console.log("[Bakong] Calling:", bakongUrl);
    console.log("[Bakong] md5:", md5);

    let bakongRes: Response;
    try {
      bakongRes = await fetch(bakongUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${BAKONG_ACCESS_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ md5 }),
      });
    } catch (fetchError) {
      console.error("[Bakong] Fetch failed (likely IP blocked):", fetchError);
      return jsonResponse({
        status: "NOT_PAID",
        _debug: "Bakong API unreachable — server may be outside Cambodia",
      });
    }

    console.log("[Bakong] HTTP status:", bakongRes.status);

    if (!bakongRes.ok) {
      const text = await bakongRes.text();
      console.error("[Bakong] HTTP error response:", text);
      return jsonResponse({
        status: "FAILED",
        reason: `Bakong API returned ${bakongRes.status}`,
        _debug: text.substring(0, 500),
      });
    }

    let bakongBody: Record<string, unknown>;
    try {
      bakongBody = await bakongRes.json();
    } catch (parseError) {
      const text = await bakongRes.text();
      console.error("[Bakong] Non-JSON response:", text);
      return jsonResponse({
        status: "FAILED",
        reason: "Invalid response from Bakong API",
        _debug: text.substring(0, 500),
      });
    }

    console.log("[Bakong] Response body:", JSON.stringify(bakongBody));

    // Bakong check_transaction_by_md5 returns responseCode=0 with populated
    // data when paid. The data contains hash, fromAccountId, toAccountId, etc.
    // A non-zero responseCode or null/empty data means not found/unpaid.
    const responseCode = bakongBody?.responseCode;
    const data = bakongBody?.data;

    // Check if data is a Map with a hash → transaction was paid
    if (
      responseCode === 0 &&
      data &&
      typeof data === "object" &&
      !Array.isArray(data)
    ) {
      const dataObj = data as Record<string, unknown>;
      const hash = dataObj?.hash as string | undefined;
      if (hash && hash.length > 0) {
        return jsonResponse({
          status: "PAID",
          transaction_id: hash,
          amount: dataObj.amount ?? null,
          currency: dataObj.currency ?? null,
          _source: "data_with_hash",
        });
      }
    }

    // Data as array — check first element for hash
    if (Array.isArray(data) && data.length > 0) {
      const firstItem = data[0] as Record<string, unknown>;
      const hash = firstItem?.hash as string | undefined;
      if (hash && hash.length > 0) {
        return jsonResponse({
          status: "PAID",
          transaction_id: hash,
          amount: firstItem.amount ?? null,
          currency: firstItem.currency ?? null,
          _source: "data_array_hash",
        });
      }
      return jsonResponse({ status: "NOT_PAID", _source: "data_array" });
    }

    return jsonResponse({ status: "NOT_PAID", _source: "fallback" });
  } catch (error) {
    console.error("[Bakong] check-bakong-transaction error:", error);
    return jsonResponse(
      { error: "Internal server error", status: "FAILED" },
      500,
    );
  }
});
