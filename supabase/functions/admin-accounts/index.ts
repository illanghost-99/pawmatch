import { createClient } from "npm:@supabase/supabase-js@2";

function ownerFile(email: string) {
  return `owners/${email.toLowerCase().replace(/[^a-z0-9]/g, "_")}.jpg`;
}

function storagePath(url: string) {
  const mark = "/dog-photos/";
  const at = url.indexOf(mark);
  if (at < 0) return "";
  return decodeURIComponent(url.slice(at + mark.length).split("?")[0]);
}

async function removeFiles(admin: ReturnType<typeof createClient>, paths: string[]) {
  const clean = [...new Set(paths.filter((p) => p.length > 0))];
  if (clean.length == 0) return;
  await admin.storage.from("dog-photos").remove(clean);
}

async function wipePhotos(admin: ReturnType<typeof createClient>, email: string) {
  const paths = [ownerFile(email)];
  const { data: dogs } = await admin.from("pm_dogs").select("photos").eq("owner_email", email);
  for (const dog of dogs ?? []) {
    const photos = Array.isArray(dog.photos) ? dog.photos : [];
    for (const photo of photos) paths.push(storagePath(String(photo ?? "")));
  }
  const { data: profile } = await admin.from("pm_profiles").select("photo_url").eq("email", email).maybeSingle();
  if (profile?.photo_url) paths.push(storagePath(String(profile.photo_url)));
  try {
    await removeFiles(admin, paths);
  } catch (_) { /* filen kan redan vara borta */ }
  try {
    await admin.from("pm_dogs").update({ photos: [] }).eq("owner_email", email);
  } catch (_) { /* ignore */ }
  try {
    await admin.from("pm_profiles").update({ photo_url: "" }).eq("email", email);
  } catch (_) { /* ignore */ }
}

async function wipeRows(admin: ReturnType<typeof createClient>, email: string) {
  const tables: Array<[string, string]> = [
    ["pm_dogs", "owner_email"],
    ["pm_likes", "from_email"],
    ["pm_likes", "to_email"],
    ["pm_devices", "email"],
    ["pm_profiles", "email"],
    ["pm_messages", "sender"],
    ["pm_group_messages", "sender"],
    ["pm_group_members", "email"],
    ["pm_sanctions", "email"],
    ["pm_push_log", "email"],
  ];
  for (const [table, column] of tables) {
    try {
      await admin.from(table).delete().eq(column, email);
    } catch (_) { /* tabellen kan saknas */ }
  }
  try {
    await admin.from("pm_matches").delete().or(`user_a.eq.${email},user_b.eq.${email}`);
  } catch (_) { /* ignore */ }
  try {
    await admin.from("pm_groups").delete().eq("owner_email", email);
  } catch (_) { /* ignore */ }
  try {
    await admin.from("pm_reports").delete().eq("from_email", email);
  } catch (_) { /* ignore */ }
}

function statusOf(row: Record<string, unknown> | undefined) {
  if (!row) return "Aktiv";
  const reason = String(row.reason ?? "");
  if (row.permanent === true) return reason.toLowerCase().includes("rader") ? "Raderat" : "Stängt";
  const until = Date.parse(String(row.banned_until ?? ""));
  if (!Number.isNaN(until) && until > Date.now()) {
    return reason.toLowerCase().includes("avaktiver") ? "Avaktiverat" : "Avstängt";
  }
  return "Aktiv";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok");
  try {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY") ?? "";
    const header = req.headers.get("Authorization") ?? "";
    if (!url || !service || !header.toLowerCase().startsWith("bearer ")) {
      return Response.json({ ok: false, error: "auth" }, { status: 401 });
    }
    const userClient = createClient(url, anon || service, { global: { headers: { Authorization: header } } });
    const got = await userClient.auth.getUser();
    const me = (got.data.user?.email ?? "").toLowerCase();
    if (!me.includes("@")) return Response.json({ ok: false, error: "auth" }, { status: 401 });
    const admin = createClient(url, service);
    const { data: admins } = await admin.from("pm_admins").select("email").eq("email", me).limit(1);
    if (me !== "dilanahanna@hotmail.com" && (!admins || admins.length === 0)) {
      return Response.json({ ok: false, error: "inte admin" }, { status: 403 });
    }
    const body = await req.json().catch(() => ({}));
    const action = String(body.action ?? "list");
    const email = String(body.email ?? "").trim().toLowerCase();

    if (action === "list") {
      const people = new Map<string, Record<string, unknown>>();
      for (let page = 1; page <= 20; page++) {
        const res = await admin.auth.admin.listUsers({ page, perPage: 200 });
        if (res.error) throw res.error;
        const batch = res.data.users ?? [];
        for (const user of batch) {
          const mail = (user.email ?? "").toLowerCase();
          if (!mail.includes("@")) continue;
          people.set(mail, {
            email: mail,
            name: mail,
            dogs: [],
            photos: 0,
            created: user.created_at ?? "",
            status: "Aktiv",
          });
        }
        if (batch.length < 200) break;
      }
      const { data: profiles } = await admin.from("pm_profiles").select("email,first_name,last_name,photo_url");
      for (const profile of profiles ?? []) {
        const mail = String(profile.email ?? "").toLowerCase();
        if (!mail.includes("@")) continue;
        const item = people.get(mail) ?? { email: mail, name: mail, dogs: [], photos: 0, created: "", status: "Aktiv" };
        const name = `${profile.first_name ?? ""} ${profile.last_name ?? ""}`.trim();
        if (name) item.name = name;
        if (String(profile.photo_url ?? "").startsWith("http")) item.photos = Number(item.photos ?? 0) + 1;
        people.set(mail, item);
      }
      const { data: dogs } = await admin.from("pm_dogs").select("owner_email,owner_name,name,photos");
      for (const dog of dogs ?? []) {
        const mail = String(dog.owner_email ?? "").toLowerCase();
        if (!mail.includes("@")) continue;
        const item = people.get(mail) ?? { email: mail, name: mail, dogs: [], photos: 0, created: "", status: "Aktiv" };
        const owner = String(dog.owner_name ?? "").trim();
        if (owner && String(item.name).includes("@")) item.name = owner;
        const dogName = String(dog.name ?? "").trim();
        if (dogName) (item.dogs as string[]).push(dogName);
        const photos = Array.isArray(dog.photos) ? dog.photos.length : 0;
        item.photos = Number(item.photos ?? 0) + photos;
        people.set(mail, item);
      }
      const { data: bans } = await admin.from("pm_sanctions").select("email,permanent,banned_until,reason");
      for (const ban of bans ?? []) {
        const mail = String(ban.email ?? "").toLowerCase();
        if (!mail.includes("@")) continue;
        const item = people.get(mail);
        if (item) item.status = statusOf(ban as Record<string, unknown>);
      }
      const accounts = [...people.values()].sort((a, b) => String(b.created ?? "").localeCompare(String(a.created ?? "")));
      return Response.json({ ok: true, accounts });
    }

    if (!email.includes("@")) return Response.json({ ok: false, error: "e-post" }, { status: 400 });
    if (action === "delete" && email === me) {
      return Response.json({ ok: false, error: "Du kan inte radera kontot du är inloggad med." }, { status: 400 });
    }
    if (action === "photos" || action === "delete") await wipePhotos(admin, email);
    if (action === "delete") {
      await wipeRows(admin, email);
      let id = "";
      for (let page = 1; page <= 20 && !id; page++) {
        const res = await admin.auth.admin.listUsers({ page, perPage: 200 });
        const hit = (res.data?.users ?? []).find((user) => (user.email ?? "").toLowerCase() === email);
        if (hit) id = hit.id;
        if ((res.data?.users ?? []).length < 200) break;
      }
      if (id) {
        const gone = await admin.auth.admin.deleteUser(id);
        if (gone.error) return Response.json({ ok: false, error: gone.error.message }, { status: 500 });
      }
    }
    return Response.json({ ok: true });
  } catch (e) {
    return Response.json({ ok: false, error: String(e) }, { status: 500 });
  }
});
