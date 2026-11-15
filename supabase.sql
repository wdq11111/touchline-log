-- Touchline Log: run once in Supabase → SQL Editor → New query → Run.
-- One row per user holding their whole log as JSON. Row Level Security
-- makes sure each signed-in user can only ever read or change their own row.

create table if not exists public.user_data (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_data enable row level security;

-- Only signed-in users get access to this table (the project does not expose new tables automatically).
revoke all on public.user_data from anon;
grant select, insert, update, delete on public.user_data to authenticated;

create policy "read own data"   on public.user_data for select using ((select auth.uid()) = user_id);
create policy "insert own data" on public.user_data for insert with check ((select auth.uid()) = user_id);
create policy "update own data" on public.user_data for update using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "delete own data" on public.user_data for delete using ((select auth.uid()) = user_id);
