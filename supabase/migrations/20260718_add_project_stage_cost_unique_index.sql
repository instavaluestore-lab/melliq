-- LupinusBuild Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Add unique index needed by ProjectStageCostService.createDefaultStageCosts()
-- for upsert onConflict: project_id,stage.

begin;

create unique index if not exists project_stage_costs_project_id_stage_unique
on public.project_stage_costs(project_id, stage)
where line_type = 'stage';

commit;
