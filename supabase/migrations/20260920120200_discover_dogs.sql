create or replace function public.discover_dogs(
  p_lat double precision,
  p_lng double precision,
  p_radius_km int default 50,
  p_age_min int default 0,
  p_age_max int default 15,
  p_breeds text[] default '{}',
  p_area text default null
)
returns table (
  id uuid,
  name text,
  breed text,
  age_years int,
  city text,
  km double precision
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    d.id,
    d.name,
    d.breed,
    extract(year from age(current_date, d.birth_date))::int as age_years,
    coalesce(d.city, p.city) as city,
    case
      when p_lat is null or d.lat is null then null
      else 6371 * acos(least(1.0, greatest(-1.0,
        cos(radians(p_lat)) * cos(radians(d.lat)) *
        cos(radians(d.lng) - radians(p_lng)) +
        sin(radians(p_lat)) * sin(radians(d.lat))
      )))
    end as km
  from public.dogs d
  join public.profiles p on p.id = d.owner_id
  where d.is_active
    and p.deleted_at is null
    and d.owner_id <> auth.uid()
    and (d.birth_date is null or extract(year from age(current_date, d.birth_date)) between p_age_min and p_age_max)
    and (p_breeds = '{}' or d.breed = any (p_breeds))
    and (p_area is null or p_area = '' or coalesce(d.city, p.city) ilike '%' || p_area || '%')
    and (
      p_lat is null or d.lat is null or
      6371 * acos(least(1.0, greatest(-1.0,
        cos(radians(p_lat)) * cos(radians(d.lat)) *
        cos(radians(d.lng) - radians(p_lng)) +
        sin(radians(p_lat)) * sin(radians(d.lat))
      ))) <= p_radius_km
    )
  order by km nulls last
  limit 50;
$$;

grant execute on function public.discover_dogs(double precision, double precision, int, int, int, text[], text) to authenticated;
