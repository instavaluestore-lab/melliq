-- LupinusBuild Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Harden quotes and quote_line_items RLS policies for current LupinusBuild company roles.

begin;

drop policy if exists "Company members can view quotes"
on public.quotes;

drop policy if exists "Owners admins can delete quotes"
on public.quotes;

drop policy if exists "Owners admins managers can insert quotes"
on public.quotes;

drop policy if exists "Owners admins managers can update quotes"
on public.quotes;

drop policy if exists "Active company members can view quotes"
on public.quotes;

drop policy if exists "Quote managers can insert quotes"
on public.quotes;

drop policy if exists "Quote managers can update quotes"
on public.quotes;

drop policy if exists "Quote admins can delete quotes"
on public.quotes;

create policy "Active company members can view quotes"
on public.quotes
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quotes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Quote managers can insert quotes"
on public.quotes
for insert
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quotes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Quote managers can update quotes"
on public.quotes
for update
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quotes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quotes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Quote admins can delete quotes"
on public.quotes
for delete
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quotes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin')
  )
);

drop policy if exists "Company members can view quote line items"
on public.quote_line_items;

drop policy if exists "Owners admins can delete quote line items"
on public.quote_line_items;

drop policy if exists "Owners admins managers can insert quote line items"
on public.quote_line_items;

drop policy if exists "Owners admins managers can update quote line items"
on public.quote_line_items;

drop policy if exists "Active company members can view quote line items"
on public.quote_line_items;

drop policy if exists "Quote managers can insert quote line items"
on public.quote_line_items;

drop policy if exists "Quote managers can update quote line items"
on public.quote_line_items;

drop policy if exists "Quote admins can delete quote line items"
on public.quote_line_items;

create policy "Active company members can view quote line items"
on public.quote_line_items
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_line_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Quote managers can insert quote line items"
on public.quote_line_items
for insert
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_line_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Quote managers can update quote line items"
on public.quote_line_items
for update
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_line_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_line_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Quote admins can delete quote line items"
on public.quote_line_items
for delete
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_line_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin')
  )
);

commit;
