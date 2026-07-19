-- LupinusBuild Supabase migration
-- Date: 2026-07-19
-- Purpose:
-- Clean and standardize RLS policies for project_stage_cost_items.

begin;

alter table public.project_stage_cost_items enable row level security;

drop policy if exists "Company members can view project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Active company members can view project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Owners admins managers can manage project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Executive users can insert project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Executive users can update project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Executive users can delete project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Active members can view project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Financial operators can insert project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Financial operators can update project stage cost items"
on public.project_stage_cost_items;

drop policy if exists "Financial operators can delete project stage cost items"
on public.project_stage_cost_items;

create policy "Active members can view project stage cost items"
on public.project_stage_cost_items
for select
to authenticated
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_cost_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Financial operators can insert project stage cost items"
on public.project_stage_cost_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_cost_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Financial operators can update project stage cost items"
on public.project_stage_cost_items
for update
to authenticated
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_cost_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_cost_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

create policy "Financial operators can delete project stage cost items"
on public.project_stage_cost_items
for delete
to authenticated
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_cost_items.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

commit;
