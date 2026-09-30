-- Kör i Supabase SQL Editor innan version 20 testas.
alter table public.pm_messages add column if not exists recalled boolean default false;
alter table public.pm_matches add column if not exists hidden_by text[] default '{}';
