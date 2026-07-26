create table if not exists public.standard_structure_prices (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  structure_type text not null,
  structure_name text not null,
  size_label text not null,
  width_feet numeric not null,
  length_feet numeric not null,
  price numeric not null default 0,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint standard_structure_prices_structure_type_check
    check (structure_type in ('HR', 'SP', 'CL', 'SWC'))
);

create unique index if not exists standard_structure_prices_unique_global_size
on public.standard_structure_prices (
  structure_type,
  width_feet,
  length_feet
)
where company_id is null;

create index if not exists standard_structure_prices_company_idx
on public.standard_structure_prices(company_id);

create index if not exists standard_structure_prices_type_idx
on public.standard_structure_prices(structure_type, is_active, sort_order);

alter table public.standard_structure_prices enable row level security;

drop policy if exists "Active members can view standard structure prices"
on public.standard_structure_prices;

create policy "Active members can view standard structure prices"
on public.standard_structure_prices
for select
to authenticated
using (
  company_id is null
  or public.is_active_company_member(company_id)
);

drop policy if exists "Financial admins can manage standard structure prices"
on public.standard_structure_prices;

create policy "Financial admins can manage standard structure prices"
on public.standard_structure_prices
for all
to authenticated
using (
  company_id is not null
  and public.user_company_role(company_id) in ('primary_admin', 'cfo')
)
with check (
  company_id is not null
  and public.user_company_role(company_id) in ('primary_admin', 'cfo')
);

insert into public.standard_structure_prices
  (company_id, structure_type, structure_name, size_label, width_feet, length_feet, price, sort_order)
values
  -- Hip Roof: 12x12 $6,850 to 40x40 $17,500, generated in 2-foot increments.
  (null, 'HR', 'Hip Roof', '12 ft × 12 ft — $6,850', 12, 12, 6850, 12012),
  (null, 'HR', 'Hip Roof', '14 ft × 14 ft — $7,611', 14, 14, 7611, 14014),
  (null, 'HR', 'Hip Roof', '16 ft × 16 ft — $8,371', 16, 16, 8371, 16016),
  (null, 'HR', 'Hip Roof', '18 ft × 18 ft — $9,132', 18, 18, 9132, 18018),
  (null, 'HR', 'Hip Roof', '20 ft × 20 ft — $9,893', 20, 20, 9893, 20020),
  (null, 'HR', 'Hip Roof', '22 ft × 22 ft — $10,654', 22, 22, 10654, 22022),
  (null, 'HR', 'Hip Roof', '24 ft × 24 ft — $11,414', 24, 24, 11414, 24024),
  (null, 'HR', 'Hip Roof', '26 ft × 26 ft — $12,175', 26, 26, 12175, 26026),
  (null, 'HR', 'Hip Roof', '28 ft × 28 ft — $12,936', 28, 28, 12936, 28028),
  (null, 'HR', 'Hip Roof', '30 ft × 30 ft — $13,696', 30, 30, 13696, 30030),
  (null, 'HR', 'Hip Roof', '32 ft × 32 ft — $14,457', 32, 32, 14457, 32032),
  (null, 'HR', 'Hip Roof', '34 ft × 34 ft — $15,218', 34, 34, 15218, 34034),
  (null, 'HR', 'Hip Roof', '36 ft × 36 ft — $15,979', 36, 36, 15979, 36036),
  (null, 'HR', 'Hip Roof', '38 ft × 38 ft — $16,739', 38, 38, 16739, 38038),
  (null, 'HR', 'Hip Roof', '40 ft × 40 ft — $17,500', 40, 40, 17500, 40040),

  -- Single Post Pyramid: 10x10 $5,650 to 20x20 $12,950, generated in 2-foot increments.
  (null, 'SP', 'Single Post Pyramid', '10 ft × 10 ft — $5,650', 10, 10, 5650, 10010),
  (null, 'SP', 'Single Post Pyramid', '12 ft × 12 ft — $7,110', 12, 12, 7110, 12012),
  (null, 'SP', 'Single Post Pyramid', '14 ft × 14 ft — $8,570', 14, 14, 8570, 14014),
  (null, 'SP', 'Single Post Pyramid', '16 ft × 16 ft — $10,030', 16, 16, 10030, 16016),
  (null, 'SP', 'Single Post Pyramid', '18 ft × 18 ft — $11,490', 18, 18, 11490, 18018),
  (null, 'SP', 'Single Post Pyramid', '20 ft × 20 ft — $12,950', 20, 20, 12950, 20020),

  -- Cantilever: 8x14 $6,950 to 25x40 $27,500.
  -- Width uses 2-foot increments from 14 to 40. Length uses 8, then 10 through 24 by 2, plus 25 max.
  (null, 'CL', 'Cantilever', '8 ft × 14 ft — $6,950', 14, 8, 6950, 8014),
  (null, 'CL', 'Cantilever', '10 ft × 16 ft — $9,176', 16, 10, 9176, 10016),
  (null, 'CL', 'Cantilever', '12 ft × 18 ft — $11,403', 18, 12, 11403, 12018),
  (null, 'CL', 'Cantilever', '14 ft × 20 ft — $13,629', 20, 14, 13629, 14020),
  (null, 'CL', 'Cantilever', '16 ft × 22 ft — $15,856', 22, 16, 15856, 16022),
  (null, 'CL', 'Cantilever', '18 ft × 24 ft — $18,082', 24, 18, 18082, 18024),
  (null, 'CL', 'Cantilever', '20 ft × 26 ft — $20,309', 26, 20, 20309, 20026),
  (null, 'CL', 'Cantilever', '22 ft × 28 ft — $22,535', 28, 22, 22535, 22028),
  (null, 'CL', 'Cantilever', '24 ft × 30 ft — $24,762', 30, 24, 24762, 24030),
  (null, 'CL', 'Cantilever', '25 ft × 40 ft — $27,500', 40, 25, 27500, 25040),

  -- Slanted Wing Cantilever: only one current known price.
  -- More rows can be added once min/max pricing is confirmed.
  (null, 'SWC', 'Slanted Wing Cantilever', '18 ft × 20 ft — $19,490', 20, 18, 19490, 18020)
on conflict do nothing;
