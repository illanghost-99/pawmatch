create table if not exists public.pm_reports (
  id uuid primary key default gen_random_uuid(),
  from_email text not null,
  from_name text default '',
  body text not null,
  created_at timestamptz default now(),
  reply text default '',
  replied_at timestamptz
);

create table if not exists public.pm_admins (
  email text primary key
);

alter table public.pm_dogs add column if not exists owner_verified boolean default false;
alter table public.pm_dogs add column if not exists dog_verified boolean default false;

alter table public.pm_reports enable row level security;
alter table public.pm_admins enable row level security;

drop policy if exists pm_reports_all on public.pm_reports;
create policy pm_reports_all on public.pm_reports for all using (true) with check (true);

drop policy if exists pm_admins_all on public.pm_admins;
create policy pm_admins_all on public.pm_admins for all using (true) with check (true);

insert into public.pm_admins (email) values ('dilanahanna@hotmail.com')
on conflict (email) do nothing;
