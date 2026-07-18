-- LupinusBuild Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Harden project_stage_costs RLS policies for current LupinusBuild company roles.

begin;

drop policy if exists "Company members can view project stage costs"
on public.project_stage_costs;

drop policy if exists "Owners admins managers can manage project stage costs"
on public.project_stage_costs;

drop policy if exists "Active company members can view project stage costs"
on public.project_stage_costs;

drop policy if exists "Executive roles can manage project stage costs"
on public.project_stage_costs;

create policy "Active company members can view project stage costs"
on public.project_stage_costs
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_costs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Executive roles can manage project stage costs"
on public.project_stage_costs
for all
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_costs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_stage_costs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

commit;
