create table if not exists public.pm_push_log (
  id bigserial primary key,
  email text,
  note text,
  created_at timestamptz default now()
);

alter table public.pm_push_log enable row level security;

drop policy if exists pm_push_log_all on public.pm_push_log;
create policy pm_push_log_all on public.pm_push_log for all using (true) with check (true);
