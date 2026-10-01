import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method == "OPTIONS") return new Response("ok");
  try {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const header = req.headers.get("Authorization") ?? "";
    if (!url || !service || !header.toLowerCase().startsWith("bearer ")) {
      return Response.json({ ok: false }, { status: 401 });
    }
    const userClient = createClient(url, anon, { global: { headers: { Authorization: header } } });
    const got = await userClient.auth.getUser();
    const user = got.data.user;
    if (!user) return Response.json({ ok: false }, { status: 401 });
    const admin = createClient(url, service);
    const who = (user.email ?? "").toLowerCase();
    if (who.includes("@")) {
      await admin.from("pm_dogs").delete().eq("owner_email", who);
      await admin.from("pm_profiles").delete().eq("email", who);
      await admin.from("pm_devices").delete().eq("email", who);
      await admin.from("pm_likes").delete().eq("from_email", who);
      await admin.from("pm_likes").delete().eq("to_email", who);
      await admin.from("pm_matches").delete().or(`user_a.eq.${who},user_b.eq.${who}`);
    }
    const gone = await admin.auth.admin.deleteUser(user.id);
    if (gone.error) return Response.json({ ok: false, error: gone.error.message }, { status: 500 });
    return Response.json({ ok: true });
  } catch (e) {
    return Response.json({ ok: false, error: String(e) }, { status: 500 });
  }
});
