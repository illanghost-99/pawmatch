alter table public.pm_reports add column if not exists match_id text default '';
alter table public.pm_reports add column if not exists reported_email text default '';
alter table public.pm_reports add column if not exists agent_note text default '';
alter table public.pm_reports add column if not exists kind text default 'problem';
alter table public.pm_reports add column if not exists case_no bigint;

create sequence if not exists public.pm_reports_case_seq;
alter table public.pm_reports alter column case_no set default nextval('public.pm_reports_case_seq');
update public.pm_reports set case_no = nextval('public.pm_reports_case_seq') where case_no is null;

create table if not exists public.pm_sanctions (
  email text primary key,
  strikes int default 0,
  banned_until timestamptz,
  permanent boolean default false,
  reason text default '',
  updated_at timestamptz default now()
);

alter table public.pm_sanctions enable row level security;
drop policy if exists pm_sanctions_all on public.pm_sanctions;
create policy pm_sanctions_all on public.pm_sanctions for all using (true) with check (true);
