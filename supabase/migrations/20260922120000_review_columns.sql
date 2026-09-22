-- Stamtavla / vaccin-granskning för admin
alter table public.dogs
  add column if not exists pedigree_status text default 'none',
  add column if not exists vaccine_status text default 'none',
  add column if not exists available_for_breeding boolean default false,
  add column if not exists available_for_friends boolean default true;

-- Tillåt autentiserade att läsa publika hundar; admin uppdaterar via service role eller policy
-- För enkel admin-demo: skapa en service-policy i dashboard eller använd service_role endast på server.
