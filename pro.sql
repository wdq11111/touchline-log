-- Touchline Pro: run once in Supabase → SQL Editor (after supabase.sql).

-- Who has Pro. Users can only read their own row; only the payment webhook
-- (server side, with the secret key) will ever write here.
create table if not exists public.entitlements (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  plan       text not null default 'free' check (plan in ('free', 'pro')),
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.entitlements enable row level security;
revoke all on public.entitlements from anon, authenticated;
grant select on public.entitlements to authenticated;
create policy "read own plan" on public.entitlements for select using ((select auth.uid()) = user_id);

-- People who tapped "Notify me when Pro opens".
create table if not exists public.pro_waitlist (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  email      text,
  plan       text check (plan in ('month', 'year')),
  created_at timestamptz not null default now()
);
alter table public.pro_waitlist enable row level security;
revoke all on public.pro_waitlist from anon;
grant select, insert, update on public.pro_waitlist to authenticated;
create policy "read own signup"   on public.pro_waitlist for select using ((select auth.uid()) = user_id);
create policy "insert own signup" on public.pro_waitlist for insert with check ((select auth.uid()) = user_id);
create policy "update own signup" on public.pro_waitlist for update using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
