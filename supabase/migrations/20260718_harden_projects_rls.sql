-- LupinusBuild Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Harden projects RLS policies for current LupinusBuild company roles:
-- primary_admin, cfo, admin, manager, field_user, viewer.

begin;

drop policy if exists "Company members can view projects"
on public.projects;

drop policy if exists "Owners admins can delete projects"
on public.projects;

drop policy if exists "Owners admins managers can insert projects"
on public.projects;

drop policy if exists "Owners admins managers can update projects"
on public.projects;

drop policy if exists "Active company members can view projects"
on public.projects;

drop policy if exists "Project managers can insert projects"
on public.projects;

drop policy if exists "Project managers can update projects"
on public.projects;

drop policy if exists "Project admins can delete projects"
on public.projects;

create policy "Active company members can view projects"
on public.projects
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = projects.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Project managers can insert projects"
on public.projects
for insert
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = projects.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Project managers can update projects"
on public.projects
for update
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = projects.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager', 'field_user')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = projects.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager', 'field_user')
  )
);

create policy "Project admins can delete projects"
on public.projects
for delete
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = projects.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin')
  )
);

commit;
