-- Kör i Supabase → SQL Editor → Run.
create table if not exists public.pm_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_email text not null,
  created_at timestamptz default now()
);

create table if not exists public.pm_group_members (
  group_id uuid not null references public.pm_groups(id) on delete cascade,
  email text not null,
  display_name text default '',
  primary key (group_id, email)
);

create table if not exists public.pm_group_messages (
  id bigserial primary key,
  group_id uuid not null references public.pm_groups(id) on delete cascade,
  sender text not null,
  text text not null,
  recalled boolean default false,
  created_at timestamptz default now()
);

alter table public.pm_groups enable row level security;
alter table public.pm_group_members enable row level security;
alter table public.pm_group_messages enable row level security;

drop policy if exists pm_groups_all on public.pm_groups;
create policy pm_groups_all on public.pm_groups for all using (true) with check (true);

drop policy if exists pm_group_members_all on public.pm_group_members;
create policy pm_group_members_all on public.pm_group_members for all using (true) with check (true);

drop policy if exists pm_group_messages_all on public.pm_group_messages;
create policy pm_group_messages_all on public.pm_group_messages for all using (true) with check (true);
