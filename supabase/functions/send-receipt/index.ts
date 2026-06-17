/// <reference lib="deno.window" />
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SECRET_MAILTRAP_KEY = Deno.env.get("MAILTRAP_API_KEY");

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, x-client-info",
  "Access-Control-Max-Age": "86400",
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

serve(async (req: any) => {
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
    const { to, subject, html, attachments, mailtrapApiKey } = await req.json();
    if (!to || !subject || !html) {
      return jsonResponse({ error: "Missing required fields" }, 400);
    }

    // Try Mailtrap key from request body first, fall back to Supabase secret
    const mtKey = mailtrapApiKey || SECRET_MAILTRAP_KEY;

    // 1) Attempt Resend
    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "BusExpress <onboarding@resend.dev>",
        to: [to],
        subject,
        html,
        attachments: attachments ?? [],
      }),
    });
    if (resendRes.ok) return jsonResponse({ success: true });

    const resendBody = await resendRes.text();
    const isTestMode =
      resendRes.status === 403 && resendBody.includes("testing emails");

    // 2) Resend rejected (test mode) — try Mailtrap if key is available
    if (isTestMode && mtKey) {
      const attachmentsPayload = (attachments ?? []).map((a: any) => ({
        filename: a.filename,
        content: a.content,
        type: "application/pdf",
        disposition: "attachment",
      }));
      const mtBody = JSON.stringify({
        from: { email: "noreply@busexpress.com", name: "Bus Express" },
        to: [{ email: to }],
        subject,
        html,
        attachments: attachmentsPayload,
      });

      // Try Authorization: Bearer first (newer), fall back to Api-Token
      let mtRes = await fetch("https://send.api.mailtrap.io/api/send", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${mtKey}`,
          "Content-Type": "application/json",
        },
        body: mtBody,
      });
      if (mtRes.ok) return jsonResponse({ success: true });

      if (mtRes.status === 401) {
        mtRes = await fetch("https://send.api.mailtrap.io/api/send", {
          method: "POST",
          headers: {
            "Api-Token": mtKey,
            "Content-Type": "application/json",
          },
          body: mtBody,
        });
        if (mtRes.ok) return jsonResponse({ success: true });
      }

      const errBody = await mtRes.text();
      return jsonResponse({ error: errBody }, mtRes.status);
    }

    // 3) Dev mode — log to console
    console.log("[DEV] Receipt for", to);
    console.log("[DEV] Subject:", subject);
    console.log("[DEV] HTML:", html.substring(0, 500));
    return jsonResponse({ devMode: true, message: "Logged to console" });
  } catch (error) {
    console.error("send-receipt error:", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
