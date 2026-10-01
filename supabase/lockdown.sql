-- Kör detta EFTER att version 34 är installerad och du har loggat in en gång.
-- Då är chattar, rapporter och konton låsta till den som är inloggad.

create or replace function public.pm_me()
returns text
language sql
stable
as $$
  select lower(coalesce(auth.jwt() ->> 'email', ''))
$$;

create or replace function public.pm_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.pm_me() <> '' and (
    public.pm_me() = 'dilanahanna@hotmail.com'
    or exists (select 1 from public.pm_admins a where lower(a.email) = public.pm_me())
  )
$$;

create or replace function public.pm_in_match(mid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.pm_matches m
    where m.id = mid
      and (lower(m.user_a) = public.pm_me() or lower(m.user_b) = public.pm_me())
  )
$$;

create or replace function public.pm_in_group(gid text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.pm_group_members m
    where m.group_id::text = gid and lower(m.email) = public.pm_me()
  )
$$;

create or replace function public.pm_redeem_invite(p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := public.pm_me();
  v_code text := upper(trim(coalesce(p_code, '')));
begin
  if v_email = '' or length(v_code) < 4 then
    return false;
  end if;
  update public.pm_admin_invites
    set used_by = v_email, used_at = now()
    where upper(code) = v_code and coalesce(used_by, '') = '';
  if not found then
    return false;
  end if;
  insert into public.pm_admins(email) values (v_email)
    on conflict (email) do nothing;
  return true;
end;
$$;

revoke all on function public.pm_redeem_invite(text) from public;
grant execute on function public.pm_redeem_invite(text) to authenticated;

insert into public.pm_admins(email) values ('dilanahanna@hotmail.com')
  on conflict (email) do nothing;

alter table public.pm_dogs add column if not exists visible boolean default true;

-- Dogs
alter table public.pm_dogs enable row level security;
drop policy if exists pm_dogs_all on public.pm_dogs;
drop policy if exists pm_dogs_read on public.pm_dogs;
drop policy if exists pm_dogs_insert on public.pm_dogs;
drop policy if exists pm_dogs_update on public.pm_dogs;
drop policy if exists pm_dogs_delete on public.pm_dogs;
create policy pm_dogs_read on public.pm_dogs for select to authenticated
  using (coalesce(visible, true) or lower(owner_email) = public.pm_me() or public.pm_is_admin());
create policy pm_dogs_insert on public.pm_dogs for insert to authenticated
  with check (lower(owner_email) = public.pm_me());
create policy pm_dogs_update on public.pm_dogs for update to authenticated
  using (lower(owner_email) = public.pm_me() or public.pm_is_admin())
  with check (lower(owner_email) = public.pm_me() or public.pm_is_admin());
create policy pm_dogs_delete on public.pm_dogs for delete to authenticated
  using (lower(owner_email) = public.pm_me() or public.pm_is_admin());

-- Likes
alter table public.pm_likes enable row level security;
drop policy if exists pm_likes_all on public.pm_likes;
drop policy if exists pm_likes_read on public.pm_likes;
drop policy if exists pm_likes_write on public.pm_likes;
drop policy if exists pm_likes_delete on public.pm_likes;
create policy pm_likes_read on public.pm_likes for select to authenticated
  using (lower(from_email) = public.pm_me() or lower(to_email) = public.pm_me() or public.pm_is_admin());
create policy pm_likes_write on public.pm_likes for insert to authenticated
  with check (lower(from_email) = public.pm_me());
create policy pm_likes_delete on public.pm_likes for delete to authenticated
  using (lower(from_email) = public.pm_me() or lower(to_email) = public.pm_me() or public.pm_is_admin());

-- Matches
alter table public.pm_matches enable row level security;
drop policy if exists pm_matches_all on public.pm_matches;
drop policy if exists pm_matches_read on public.pm_matches;
drop policy if exists pm_matches_insert on public.pm_matches;
drop policy if exists pm_matches_update on public.pm_matches;
drop policy if exists pm_matches_delete on public.pm_matches;
create policy pm_matches_read on public.pm_matches for select to authenticated
  using (lower(user_a) = public.pm_me() or lower(user_b) = public.pm_me() or public.pm_is_admin());
create policy pm_matches_insert on public.pm_matches for insert to authenticated
  with check (lower(user_a) = public.pm_me() or lower(user_b) = public.pm_me());
create policy pm_matches_update on public.pm_matches for update to authenticated
  using (lower(user_a) = public.pm_me() or lower(user_b) = public.pm_me() or public.pm_is_admin());
create policy pm_matches_delete on public.pm_matches for delete to authenticated
  using (lower(user_a) = public.pm_me() or lower(user_b) = public.pm_me() or public.pm_is_admin());

-- Messages
alter table public.pm_messages enable row level security;
drop policy if exists pm_messages_all on public.pm_messages;
drop policy if exists pm_messages_read on public.pm_messages;
drop policy if exists pm_messages_insert on public.pm_messages;
drop policy if exists pm_messages_update on public.pm_messages;
create policy pm_messages_read on public.pm_messages for select to authenticated
  using (public.pm_in_match(match_id) or public.pm_is_admin());
create policy pm_messages_insert on public.pm_messages for insert to authenticated
  with check (lower(sender) = public.pm_me() and public.pm_in_match(match_id));
create policy pm_messages_update on public.pm_messages for update to authenticated
  using (public.pm_in_match(match_id) or public.pm_is_admin());

-- Groups
alter table public.pm_groups enable row level security;
drop policy if exists pm_groups_all on public.pm_groups;
drop policy if exists pm_groups_read on public.pm_groups;
drop policy if exists pm_groups_insert on public.pm_groups;
drop policy if exists pm_groups_delete on public.pm_groups;
create policy pm_groups_read on public.pm_groups for select to authenticated
  using (lower(owner_email) = public.pm_me() or public.pm_in_group(id::text) or public.pm_is_admin());
create policy pm_groups_insert on public.pm_groups for insert to authenticated
  with check (lower(owner_email) = public.pm_me());
create policy pm_groups_delete on public.pm_groups for delete to authenticated
  using (lower(owner_email) = public.pm_me() or public.pm_is_admin());

alter table public.pm_group_members enable row level security;
drop policy if exists pm_group_members_all on public.pm_group_members;
drop policy if exists pm_group_members_read on public.pm_group_members;
drop policy if exists pm_group_members_write on public.pm_group_members;
drop policy if exists pm_group_members_delete on public.pm_group_members;
create policy pm_group_members_read on public.pm_group_members for select to authenticated
  using (public.pm_in_group(group_id::text) or lower(email) = public.pm_me() or public.pm_is_admin());
create policy pm_group_members_write on public.pm_group_members for insert to authenticated
  with check (
    public.pm_is_admin()
    or exists (
      select 1 from public.pm_groups g
      where g.id::text = group_id::text and lower(g.owner_email) = public.pm_me()
    )
  );
create policy pm_group_members_delete on public.pm_group_members for delete to authenticated
  using (lower(email) = public.pm_me() or public.pm_is_admin());

alter table public.pm_group_messages enable row level security;
drop policy if exists pm_group_messages_all on public.pm_group_messages;
drop policy if exists pm_group_messages_read on public.pm_group_messages;
drop policy if exists pm_group_messages_insert on public.pm_group_messages;
create policy pm_group_messages_read on public.pm_group_messages for select to authenticated
  using (public.pm_in_group(group_id::text) or public.pm_is_admin());
create policy pm_group_messages_insert on public.pm_group_messages for insert to authenticated
  with check (lower(sender) = public.pm_me() and public.pm_in_group(group_id::text));

-- Reports and sanctions
alter table public.pm_reports enable row level security;
drop policy if exists pm_reports_all on public.pm_reports;
drop policy if exists pm_reports_read on public.pm_reports;
drop policy if exists pm_reports_insert on public.pm_reports;
drop policy if exists pm_reports_update on public.pm_reports;
create policy pm_reports_read on public.pm_reports for select to authenticated
  using (lower(from_email) = public.pm_me() or public.pm_is_admin());
create policy pm_reports_insert on public.pm_reports for insert to authenticated
  with check (lower(from_email) = public.pm_me());
create policy pm_reports_update on public.pm_reports for update to authenticated
  using (public.pm_is_admin());

alter table public.pm_sanctions enable row level security;
drop policy if exists pm_sanctions_all on public.pm_sanctions;
drop policy if exists pm_sanctions_read on public.pm_sanctions;
drop policy if exists pm_sanctions_write on public.pm_sanctions;
create policy pm_sanctions_read on public.pm_sanctions for select to authenticated
  using (lower(email) = public.pm_me() or public.pm_is_admin());
create policy pm_sanctions_write on public.pm_sanctions for all to authenticated
  using (public.pm_is_admin())
  with check (public.pm_is_admin());

alter table public.pm_admins enable row level security;
drop policy if exists pm_admins_all on public.pm_admins;
drop policy if exists pm_admins_read on public.pm_admins;
drop policy if exists pm_admins_write on public.pm_admins;
create policy pm_admins_read on public.pm_admins for select to authenticated
  using (public.pm_is_admin());
create policy pm_admins_write on public.pm_admins for all to authenticated
  using (public.pm_is_admin())
  with check (public.pm_is_admin());

alter table public.pm_admin_invites enable row level security;
drop policy if exists pm_admin_invites_all on public.pm_admin_invites;
drop policy if exists pm_admin_invites_read on public.pm_admin_invites;
drop policy if exists pm_admin_invites_insert on public.pm_admin_invites;
create policy pm_admin_invites_read on public.pm_admin_invites for select to authenticated
  using (public.pm_is_admin());
create policy pm_admin_invites_insert on public.pm_admin_invites for insert to authenticated
  with check (public.pm_is_admin());

create table if not exists public.pm_profiles (
  email text primary key,
  first_name text default '',
  last_name text default '',
  bio text default '',
  city text default '',
  photo_url text default '',
  updated_at timestamptz default now()
);

alter table public.pm_profiles enable row level security;
drop policy if exists pm_profiles_all on public.pm_profiles;
drop policy if exists pm_profiles_read on public.pm_profiles;
drop policy if exists pm_profiles_write on public.pm_profiles;
create policy pm_profiles_read on public.pm_profiles for select to authenticated
  using (true);
create policy pm_profiles_write on public.pm_profiles for all to authenticated
  using (lower(email) = public.pm_me() or public.pm_is_admin())
  with check (lower(email) = public.pm_me() or public.pm_is_admin());

alter table public.pm_devices enable row level security;
drop policy if exists pm_devices_all on public.pm_devices;
drop policy if exists pm_devices_own on public.pm_devices;
create policy pm_devices_own on public.pm_devices for all to authenticated
  using (lower(email) = public.pm_me() or public.pm_is_admin())
  with check (lower(email) = public.pm_me() or public.pm_is_admin());
