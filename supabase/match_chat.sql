-- Kör i Supabase → SQL Editor → Run.
-- Beta: öppna policies så testare kan se varandra. Skärp före App Store.

create table if not exists public.pm_dogs (
  id text primary key,
  owner_email text not null,
  owner_name text default '',
  name text not null,
  breed text default '',
  sex text default '',
  age int default 1,
  city text default '',
  intent text default 'friends',
  bio text default '',
  photos text[] default '{}',
  lat double precision default 59.33,
  lng double precision default 18.07,
  updated_at timestamptz default now()
);

create table if not exists public.pm_likes (
  id bigserial primary key,
  from_email text not null,
  to_email text not null,
  dog_id text,
  created_at timestamptz default now(),
  unique (from_email, to_email, dog_id)
);

create table if not exists public.pm_matches (
  id uuid primary key default gen_random_uuid(),
  user_a text not null,
  user_b text not null,
  dog_json jsonb default '{}',
  accepted boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.pm_messages (
  id bigserial primary key,
  match_id uuid references public.pm_matches(id) on delete cascade,
  sender text not null,
  text text not null,
  created_at timestamptz default now()
);

alter table public.pm_dogs enable row level security;
alter table public.pm_likes enable row level security;
alter table public.pm_matches enable row level security;
alter table public.pm_messages enable row level security;

drop policy if exists pm_dogs_all on public.pm_dogs;
create policy pm_dogs_all on public.pm_dogs for all using (true) with check (true);

drop policy if exists pm_likes_all on public.pm_likes;
create policy pm_likes_all on public.pm_likes for all using (true) with check (true);

drop policy if exists pm_matches_all on public.pm_matches;
create policy pm_matches_all on public.pm_matches for all using (true) with check (true);

drop policy if exists pm_messages_all on public.pm_messages;
create policy pm_messages_all on public.pm_messages for all using (true) with check (true);
