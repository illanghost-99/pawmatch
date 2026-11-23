import { withSupabase } from "npm:@supabase/server@1";

export default {
  fetch: withSupabase({ auth: ["publishable", "secret"] }, async (req, ctx) => {
    try {
      const payload = await req.json();
      const email = String(payload.email ?? "").trim().toLowerCase();
      const token = String(payload.token ?? "").trim();
      const old = Array.isArray(payload.old_tokens) ? payload.old_tokens : [];
      if (!email.includes("@") || !token) return Response.json({ ok: false }, { status: 400 });
      for (const row of old) {
        const previous = String(row ?? "").trim();
        if (previous && previous !== token) {
          await ctx.supabaseAdmin.from("pm_devices").delete().eq("token", previous);
        }
      }
      await ctx.supabaseAdmin.from("pm_devices").delete().eq("token", token).neq("email", email);
      await ctx.supabaseAdmin.from("pm_devices").delete().eq("email", email).neq("token", token);
      await ctx.supabaseAdmin.from("pm_devices").upsert({
        token,
        email,
        updated_at: new Date().toISOString(),
      });
      return Response.json({ ok: true });
    } catch (e) {
      return Response.json({ ok: false, error: String(e) }, { status: 500 });
    }
  }),
};
