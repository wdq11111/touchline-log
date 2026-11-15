-- Touchline card talk (community forum): run once in Supabase → SQL Editor.
-- Everyone can read; signed-in players with a nickname can post, comment, like and report.

create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  nickname   text not null check (char_length(nickname) between 2 and 20 and nickname !~ '[<>]'),
  created_at timestamptz not null default now()
);
create unique index if not exists profiles_nickname_key on public.profiles (lower(nickname));

create table if not exists public.forum_threads (
  id           bigint generated always as identity primary key,
  user_id      uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  card_name    text not null check (char_length(card_name) between 1 and 40),
  card_ovr     int check (card_ovr between 1 and 200),
  card_pos     text check (char_length(card_pos) <= 4),
  card_version text check (char_length(card_version) <= 30),
  rating       int check (rating between 1 and 10),
  title        text not null check (char_length(title) between 3 and 80),
  body         text not null check (char_length(body) between 1 and 2000),
  created_at   timestamptz not null default now()
);
create index if not exists forum_threads_created on public.forum_threads (created_at desc);

create table if not exists public.forum_comments (
  id         bigint generated always as identity primary key,
  thread_id  bigint not null references public.forum_threads (id) on delete cascade,
  user_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index if not exists forum_comments_thread on public.forum_comments (thread_id, created_at);

create table if not exists public.forum_likes (
  thread_id  bigint not null references public.forum_threads (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table if not exists public.forum_reports (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  thread_id  bigint references public.forum_threads (id) on delete cascade,
  comment_id bigint references public.forum_comments (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Permissions: anyone reads posts; you can only write and delete your own things.
alter table public.profiles       enable row level security;
alter table public.forum_threads  enable row level security;
alter table public.forum_comments enable row level security;
alter table public.forum_likes    enable row level security;
alter table public.forum_reports  enable row level security;
revoke all on public.profiles, public.forum_threads, public.forum_comments, public.forum_likes, public.forum_reports from anon, authenticated;
grant select on public.profiles, public.forum_threads, public.forum_comments, public.forum_likes to anon, authenticated;
grant insert, update on public.profiles to authenticated;
grant insert, delete on public.forum_threads, public.forum_comments, public.forum_likes to authenticated;
grant insert on public.forum_reports to authenticated;

create policy "read profiles"   on public.profiles for select using (true);
create policy "create profile"  on public.profiles for insert with check ((select auth.uid()) = id);
create policy "rename profile"  on public.profiles for update using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "read threads"    on public.forum_threads for select using (true);
create policy "post threads"    on public.forum_threads for insert with check ((select auth.uid()) = user_id);
create policy "delete own thread" on public.forum_threads for delete using ((select auth.uid()) = user_id);
create policy "read comments"   on public.forum_comments for select using (true);
create policy "post comments"   on public.forum_comments for insert with check ((select auth.uid()) = user_id);
create policy "delete own comment" on public.forum_comments for delete using ((select auth.uid()) = user_id);
create policy "read likes"      on public.forum_likes for select using (true);
create policy "like"            on public.forum_likes for insert with check ((select auth.uid()) = user_id);
create policy "unlike"          on public.forum_likes for delete using ((select auth.uid()) = user_id);
create policy "report"          on public.forum_reports for insert with check ((select auth.uid()) = user_id);

-- Anti-spam: at most 5 posts, 30 comments and 20 reports per player per hour.
create or replace function public.forum_rate_limit() returns trigger
language plpgsql security definer set search_path = public as $$
declare c int;
begin
  execute format('select count(*) from public.%I where user_id = $1 and created_at > now() - interval ''1 hour''', TG_TABLE_NAME)
    into c using new.user_id;
  if c >= TG_ARGV[0]::int then raise exception 'rate_limit'; end if;
  return new;
end $$;
drop trigger if exists forum_threads_rate on public.forum_threads;
drop trigger if exists forum_comments_rate on public.forum_comments;
drop trigger if exists forum_reports_rate on public.forum_reports;
create trigger forum_threads_rate  before insert on public.forum_threads  for each row execute function public.forum_rate_limit('5');
create trigger forum_comments_rate before insert on public.forum_comments for each row execute function public.forum_rate_limit('30');
create trigger forum_reports_rate  before insert on public.forum_reports  for each row execute function public.forum_rate_limit('20');
