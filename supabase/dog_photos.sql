-- Kör i Supabase → SQL Editor → Run. Behövs för hundbilder.
insert into storage.buckets (id, name, public)
values ('dog-photos', 'dog-photos', true)
on conflict (id) do update set public = true;

drop policy if exists dog_photos_read on storage.objects;
create policy dog_photos_read on storage.objects
  for select using (bucket_id = 'dog-photos');

drop policy if exists dog_photos_write on storage.objects;
create policy dog_photos_write on storage.objects
  for insert with check (bucket_id = 'dog-photos');

drop policy if exists dog_photos_update on storage.objects;
create policy dog_photos_update on storage.objects
  for update using (bucket_id = 'dog-photos');
