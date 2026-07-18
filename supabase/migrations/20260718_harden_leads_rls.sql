-- LupinusBuild Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Harden leads RLS policies for current LupinusBuild company roles:
-- primary_admin, cfo, admin, manager, field_user, viewer.

begin;

drop policy if exists "Company members can view leads"
on public.leads;

drop policy if exists "Owners admins can delete leads"
on public.leads;

drop policy if exists "Owners admins managers can insert leads"
on public.leads;

drop policy if exists "Owners admins managers can update leads"
on public.leads;

drop policy if exists "Active company members can view leads"
on public.leads;

drop policy if exists "Sales roles can insert leads"
on public.leads;

drop policy if exists "Sales roles can update leads"
on public.leads;

drop policy if exists "Sales admins can delete leads"
on public.leads;

create policy "Active company members can view leads"
on public.leads
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = leads.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Sales roles can insert leads"
on public.leads
for insert
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = leads.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Sales roles can update leads"
on public.leads
for update
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = leads.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = leads.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Sales admins can delete leads"
on public.leads
for delete
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = leads.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

commit;
