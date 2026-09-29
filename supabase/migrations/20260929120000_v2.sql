-- PawMatch v2 foundation. Run in Supabase SQL editor when ready.
create table if not exists public.health_events (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid,
  owner_id uuid,
  kind text not null,
  title text not null,
  notes text,
  happened_on date,
  created_at timestamptz default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid,
  dog_id uuid,
  kind text not null,
  storage_path text,
  status text default 'pending',
  reviewer_note text,
  created_at timestamptz default now()
);

create table if not exists public.community_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  city text,
  starts_at timestamptz,
  kind text,
  created_at timestamptz default now()
);

create table if not exists public.guardian_flags (
  id uuid primary key default gen_random_uuid(),
  subject_type text,
  subject_id text,
  code text,
  reason text,
  score int,
  status text default 'open',
  created_at timestamptz default now()
);

alter table public.health_events enable row level security;
alter table public.documents enable row level security;
alter table public.community_events enable row level security;
alter table public.guardian_flags enable row level security;
