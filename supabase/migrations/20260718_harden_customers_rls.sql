-- LupinusBuild Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Harden customers RLS policies for current LupinusBuild company roles:
-- primary_admin, cfo, admin, manager, field_user, viewer.

begin;

drop policy if exists "Company members can view customers"
on public.customers;

drop policy if exists "Owners admins can delete customers"
on public.customers;

drop policy if exists "Owners admins managers can insert customers"
on public.customers;

drop policy if exists "Owners admins managers can update customers"
on public.customers;

drop policy if exists "Active company members can view customers"
on public.customers;

drop policy if exists "Customer managers can insert customers"
on public.customers;

drop policy if exists "Customer managers can update customers"
on public.customers;

drop policy if exists "Customer managers can delete customers"
on public.customers;

create policy "Active company members can view customers"
on public.customers
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = customers.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Customer managers can insert customers"
on public.customers
for insert
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = customers.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Customer managers can update customers"
on public.customers
for update
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = customers.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = customers.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Customer managers can delete customers"
on public.customers
for delete
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = customers.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

commit;
