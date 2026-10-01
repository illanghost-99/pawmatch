-- Kör i Supabase → SQL Editor → Run.
-- Sparar profilbilden på kontot.

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
create policy pm_profiles_all on public.pm_profiles for all using (true) with check (true);
