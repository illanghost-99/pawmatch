# Koppla GitHub + Supabase

1. supabase.com → Project Settings → Integrations → GitHub
2. Välj repo illanghost-99/pawmatch
3. Enable migrations from supabase/migrations
4. Kör även SQL Editor om integrationen inte auto-migrerar:
   - supabase/migrations/20260920120000_init.sql
   - supabase/migrations/20260920120100_functions.sql
5. Auth → Providers → Apple
6. Skapa review@pawmatch.app
7. Kopiera Project URL + anon key till iOS Info.plist (aldrig service_role)
