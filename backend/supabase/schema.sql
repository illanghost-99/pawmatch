-- PawMatch v1 schema. Också: supabase/migrations/20260920120000_init.sql
create extension if not exists pgcrypto;
create type user_role as enum ('owner', 'kennel', 'vet', 'enthusiast');
create type swipe_dir as enum ('left', 'right', 'super');
create type report_status as enum ('open', 'reviewing', 'actioned', 'dismissed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  city text, lat double precision, lng double precision,
  country text default 'SE', bio text,
  role user_role not null default 'owner',
  avatar_url text, is_premium boolean not null default false,
  created_at timestamptz not null default now(), deleted_at timestamptz
);

create table public.dogs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null, breed text, birth_date date,
  sex text check (sex in ('male', 'female', 'unknown')),
  description text, is_active boolean not null default true,
  city text, lat double precision, lng double precision,
  created_at timestamptz not null default now()
);

create table public.discover_prefs (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  breeds text[] not null default '{}',
  age_min int not null default 0, age_max int not null default 15,
  radius_km int not null default 50, area text
);

create table public.dog_media (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references public.dogs(id) on delete cascade,
  kind text not null check (kind in ('image', 'video')),
  url text not null, sort_order int not null default 0
);

create table public.swipes (
  id uuid primary key default gen_random_uuid(),
  swiper_id uuid not null references public.profiles(id) on delete cascade,
  target_dog_id uuid not null references public.dogs(id) on delete cascade,
  direction swipe_dir not null, created_at timestamptz not null default now(),
  unique (swiper_id, target_dog_id)
);

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id),
  user_b uuid not null references public.profiles(id),
  dog_a uuid not null references public.dogs(id),
  dog_b uuid not null references public.dogs(id),
  created_at timestamptz not null default now(), unique (dog_a, dog_b)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  body text, media_url text, created_at timestamptz not null default now()
);

create table public.blocks (
  blocker uuid not null references public.profiles(id) on delete cascade,
  blocked uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(), primary key (blocker, blocked)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter uuid not null references public.profiles(id),
  target_user uuid references public.profiles(id),
  reason text not null, status report_status not null default 'open',
  created_at timestamptz not null default now()
);

create table public.swipe_quotas (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  day date not null default current_date, used int not null default 0
);

alter table public.profiles enable row level security;
alter table public.dogs enable row level security;
alter table public.swipes enable row level security;
alter table public.matches enable row level security;
alter table public.messages enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.swipe_quotas enable row level security;
alter table public.discover_prefs enable row level security;

create policy "profiles readable" on public.profiles for select using (deleted_at is null);
create policy "profiles self write" on public.profiles for update using (auth.uid() = id);
create policy "dogs public active" on public.dogs for select using (is_active);
create policy "dogs owner write" on public.dogs for all using (auth.uid() = owner_id);
create policy "swipes own" on public.swipes for all using (auth.uid() = swiper_id);
create policy "matches members" on public.matches for select using (auth.uid() in (user_a, user_b));
create policy "messages members" on public.messages for select using (
  exists (select 1 from matches m where m.id = match_id and auth.uid() in (m.user_a, m.user_b)));
create policy "messages send" on public.messages for insert with check (auth.uid() = sender_id);
create policy "blocks own" on public.blocks for all using (auth.uid() = blocker);
create policy "reports insert" on public.reports for insert with check (auth.uid() = reporter);
create policy "prefs own" on public.discover_prefs for all using (auth.uid() = user_id);
