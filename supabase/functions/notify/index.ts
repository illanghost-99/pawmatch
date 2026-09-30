import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function b64url(bytes: Uint8Array) {
  let bin = "";
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function b64urlText(text: string) {
  return b64url(new TextEncoder().encode(text));
}

async function googleAccessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  const header = b64urlText(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64urlText(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claim}`;
  const pem = sa.private_key.replace(/\\n/g, "\n");
  const body = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)));
  const jwt = `${unsigned}.${b64url(sig)}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(`google ${res.status}`);
  return json.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const payload = await req.json();
    const email = String(payload.to_email ?? "").trim().toLowerCase();
    const title = String(payload.title ?? "PawMatch").slice(0, 80);
    const text = String(payload.body ?? "").slice(0, 180);
    if (!email.includes("@") || !text) {
      return new Response(JSON.stringify({ ok: false }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data, error } = await supabase.from("pm_devices").select("token").eq("email", email);
    if (error) throw error;
    const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!raw) {
      return new Response(JSON.stringify({ ok: false, error: "missing firebase" }), {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }
    const sa = JSON.parse(raw);
    const access = await googleAccessToken(sa);
    let sent = 0;
    for (const row of data ?? []) {
      const token = String(row.token ?? "");
      if (!token) continue;
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${access}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body: text },
            apns: { payload: { aps: { sound: "default" } } },
          },
        }),
      });
      if (res.ok) {
        sent++;
      } else {
        const errText = await res.text();
        if (errText.includes("UNREGISTERED") || errText.includes("NOT_FOUND")) {
          await supabase.from("pm_devices").delete().eq("token", token);
        }
      }
    }
    return new Response(JSON.stringify({ ok: true, sent }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
