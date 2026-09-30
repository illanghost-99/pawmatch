alter table public.pm_messages add column if not exists seen_at timestamptz;
