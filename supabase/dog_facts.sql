-- Kör i Supabase SQL Editor innan version 19 testas.
alter table public.pm_dogs
  add column if not exists weight_kg double precision,
  add column if not exists chipped boolean default false,
  add column if not exists vaccinated boolean default false,
  add column if not exists dewormed boolean default false,
  add column if not exists neutered boolean default false,
  add column if not exists has_pedigree boolean default false,
  add column if not exists has_allergies boolean default false,
  add column if not exists allergy_note text default '',
  add column if not exists health_note text default '',
  add column if not exists vaccine_note text default '',
  add column if not exists pedigree_note text default '';
