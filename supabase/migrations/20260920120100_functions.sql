-- Kör efter init-migrationen.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1), 'Hundvän'),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'owner')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.record_swipe(
  p_target_dog uuid,
  p_direction swipe_dir
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
  v_my_dog uuid;
  v_match uuid;
  v_quota int;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select owner_id into v_owner from dogs where id = p_target_dog and is_active;
  if v_owner is null then
    raise exception 'dog not found';
  end if;
  if v_owner = auth.uid() then
    raise exception 'cannot swipe own dog';
  end if;

  insert into swipe_quotas (user_id, day, used)
  values (auth.uid(), current_date, 0)
  on conflict (user_id) do update
    set used = case when swipe_quotas.day = current_date then swipe_quotas.used else 0 end,
        day = current_date;

  select used into v_quota from swipe_quotas where user_id = auth.uid();
  if coalesce(v_quota, 0) >= 20 and not exists (
    select 1 from profiles where id = auth.uid() and is_premium
  ) then
    return jsonb_build_object('ok', false, 'reason', 'quota');
  end if;

  update swipe_quotas set used = used + 1, day = current_date where user_id = auth.uid();

  insert into swipes (swiper_id, target_dog_id, direction)
  values (auth.uid(), p_target_dog, p_direction)
  on conflict (swiper_id, target_dog_id) do update set direction = excluded.direction;

  if p_direction = 'left' then
    return jsonb_build_object('ok', true, 'matched', false);
  end if;

  select id into v_my_dog from dogs where owner_id = auth.uid() and is_active order by created_at limit 1;

  if v_my_dog is not null and exists (
    select 1 from swipes
    where swiper_id = v_owner and target_dog_id = v_my_dog and direction in ('right', 'super')
  ) then
    insert into matches (user_a, user_b, dog_a, dog_b)
    values (auth.uid(), v_owner, v_my_dog, p_target_dog)
    on conflict (dog_a, dog_b) do update set user_a = matches.user_a
    returning id into v_match;
    if v_match is null then
      select id into v_match from matches
      where (dog_a = v_my_dog and dog_b = p_target_dog) or (dog_a = p_target_dog and dog_b = v_my_dog);
    end if;
    return jsonb_build_object('ok', true, 'matched', true, 'match_id', v_match);
  end if;

  return jsonb_build_object('ok', true, 'matched', false);
end;
$$;

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  update profiles set deleted_at = now(), display_name = 'Raderat konto' where id = auth.uid();
  update dogs set is_active = false where owner_id = auth.uid();
  delete from messages where sender_id = auth.uid();
end;
$$;

grant execute on function public.discover_dogs(double precision, double precision, int, int, int, text[], text) to authenticated;
grant execute on function public.record_swipe(uuid, swipe_dir) to authenticated;
grant execute on function public.delete_my_account() to authenticated;

create policy "profiles self insert" on public.profiles for insert with check (auth.uid() = id);
create policy "matches insert members" on public.matches for insert with check (auth.uid() in (user_a, user_b));
create policy "quotas own" on public.swipe_quotas for all using (auth.uid() = user_id);
