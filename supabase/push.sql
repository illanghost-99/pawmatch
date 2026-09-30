-- Kör i Supabase → SQL Editor → Run.
create table if not exists public.pm_devices (
  token text primary key,
  email text not null,
  updated_at timestamptz default now()
);

alter table public.pm_devices enable row level security;
drop policy if exists pm_devices_all on public.pm_devices;
create policy pm_devices_all on public.pm_devices for all using (true) with check (true);
