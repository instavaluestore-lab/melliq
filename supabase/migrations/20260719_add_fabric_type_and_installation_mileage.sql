alter table public.project_stage_costs
add column if not exists fabric_type text;

alter table public.project_stage_costs
add column if not exists installation_miles numeric not null default 0;

alter table public.project_stage_costs
add column if not exists installation_cost_per_mile numeric not null default 0;

alter table public.project_stage_costs
drop constraint if exists project_stage_costs_fabric_type_check;

alter table public.project_stage_costs
add constraint project_stage_costs_fabric_type_check
check (
  fabric_type is null
  or fabric_type in (
    'GP 340',
    'GP 430',
    'Sunbrella',
    'Serge Ferrari',
    'Custom'
  )
);
