-- LupinusBuild Supabase migration
-- Date: 2026-07-19
-- Purpose:
-- Add top-of-quote MaxShade configuration fields.

begin;

alter table public.quotes
add column if not exists structure_type text,
add column if not exists mount_type text,
add column if not exists footer_type text,
add column if not exists permit_required boolean not null default false,
add column if not exists specialty_equipment_required boolean not null default false;

alter table public.quotes
drop constraint if exists quotes_structure_type_check;

alter table public.quotes
add constraint quotes_structure_type_check
check (
  structure_type is null
  or structure_type in ('HT', 'HR', 'SP', 'CL', 'CSTM')
);

alter table public.quotes
drop constraint if exists quotes_mount_type_check;

alter table public.quotes
add constraint quotes_mount_type_check
check (
  mount_type is null
  or mount_type in ('in_ground', 'base_plate')
);

alter table public.quotes
drop constraint if exists quotes_footer_type_check;

alter table public.quotes
add constraint quotes_footer_type_check
check (
  footer_type is null
  or footer_type in ('standard_2x2x5', 'standard_7x30', 'custom')
);

create index if not exists quotes_structure_type_idx
on public.quotes(company_id, structure_type);

create index if not exists quotes_mount_type_idx
on public.quotes(company_id, mount_type);

create index if not exists quotes_footer_type_idx
on public.quotes(company_id, footer_type);

commit;
