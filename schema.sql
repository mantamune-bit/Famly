-- =========================================================
-- Famly — database schema for Supabase
-- One shared Google login for the family; profiles (members)
-- are picked inside the app, once per phone.
-- =========================================================

-- Google emails that may open Famly
create table public.family_accounts (
  email text primary key
);

create or replace function public.is_family() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.family_accounts
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- Family members (profiles)
create table public.members (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  sleep_target numeric not null default 7,
  steps_target int not null default 7000,
  ingest_token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  created_at   timestamptz not null default now()
);

-- Daily health check-in (one row per person per day)
create table public.checkins (
  member_id   uuid not null references public.members(id) on delete cascade,
  day         date not null,
  wake_time   time,
  sleep_hours numeric,
  feeling     text check (feeling in ('good','meh','sick')),
  food_prev   text check (food_prev in ('good','meh','bad')),  -- rating for the PREVIOUS day
  steps       int,
  updated_at  timestamptz not null default now(),
  primary key (member_id, day)
);

-- Buy / do requests
create table public.requests (
  id         bigint generated always as identity primary key,
  kind       text not null check (kind in ('buy','do')),
  title      text not null,
  note       text,
  assignee   uuid references public.members(id),   -- null = both of us
  created_by uuid references public.members(id),
  created_at timestamptz not null default now(),
  done_at    timestamptz,
  done_by    uuid references public.members(id)
);

-- Weekend plans
create table public.plans (
  id         bigint generated always as identity primary key,
  day        date not null,
  title      text not null,
  who        uuid references public.members(id),   -- null = both of us
  created_by uuid references public.members(id),
  created_at timestamptz not null default now()
);

-- ---------- Row level security: only the family Google account ----------
alter table public.family_accounts enable row level security;
alter table public.members  enable row level security;
alter table public.checkins enable row level security;
alter table public.requests enable row level security;
alter table public.plans    enable row level security;

create policy "family only" on public.members  for all to authenticated using (public.is_family()) with check (public.is_family());
create policy "family only" on public.checkins for all to authenticated using (public.is_family()) with check (public.is_family());
create policy "family only" on public.requests for all to authenticated using (public.is_family()) with check (public.is_family());
create policy "family only" on public.plans    for all to authenticated using (public.is_family()) with check (public.is_family());
-- family_accounts: no policies = nobody can read or change it from the app

-- ---------- Endpoint for the iPhone Shortcut ----------
-- POST /rest/v1/rpc/log_steps  body: {"p_token": "...", "p_steps": 1234}
create or replace function public.log_steps(p_token text, p_steps int) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_id  uuid;
  v_day date := (now() at time zone 'Asia/Jakarta')::date;
begin
  select id into v_id from public.members where ingest_token = p_token;
  if v_id is null then
    raise exception 'invalid token';
  end if;
  insert into public.checkins (member_id, day, steps)
  values (v_id, v_day, greatest(p_steps, 0))
  on conflict (member_id, day) do update set steps = excluded.steps, updated_at = now();
  return 'ok ' || v_day || ' ' || p_steps;
end $$;

revoke all on function public.log_steps(text, int) from public;
grant execute on function public.log_steps(text, int) to anon, authenticated;
