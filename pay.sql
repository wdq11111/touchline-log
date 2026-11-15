-- Touchline Pro manual payments: run once in Supabase → SQL Editor (after pro.sql).

-- Orders users submit after paying by QR code or link. Users can create and read
-- their own orders, but can only ever create them as "pending".
create table if not exists public.pro_orders (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  email      text,
  plan       text not null check (plan in ('month', 'year')),
  method     text,
  amount     text,
  ref        text check (char_length(ref) <= 80),
  status     text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);
alter table public.pro_orders enable row level security;
revoke all on public.pro_orders from anon, authenticated;
grant select, insert on public.pro_orders to authenticated;
create policy "read own orders"   on public.pro_orders for select using ((select auth.uid()) = user_id);
create policy "create own orders" on public.pro_orders for insert with check ((select auth.uid()) = user_id and status = 'pending');

-- Approve an order after checking the payment arrived: select approve_order(ORDER_ID);
-- Only you can run this (from the SQL Editor); website users cannot call it.
create or replace function public.approve_order(order_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare o public.pro_orders;
begin
  update public.pro_orders set status = 'approved' where id = order_id and status = 'pending' returning * into o;
  if o.id is null then raise exception 'Order % is not pending', order_id; end if;
  insert into public.entitlements (user_id, plan, expires_at, updated_at)
  values (o.user_id, 'pro', now() + case when o.plan = 'year' then interval '1 year' else interval '1 month' end, now())
  on conflict (user_id) do update set plan = 'pro',
    expires_at = greatest(coalesce(public.entitlements.expires_at, now()), now())
               + case when o.plan = 'year' then interval '1 year' else interval '1 month' end,
    updated_at = now();
end $$;
revoke execute on function public.approve_order(bigint) from public, anon, authenticated;

-- Reject an order that never arrived: select reject_order(ORDER_ID);
create or replace function public.reject_order(order_id bigint) returns void
language sql security definer set search_path = public as $$
  update public.pro_orders set status = 'rejected' where id = order_id and status = 'pending';
$$;
revoke execute on function public.reject_order(bigint) from public, anon, authenticated;
