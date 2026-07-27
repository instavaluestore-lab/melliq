create table if not exists public.quote_addon_prices (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies(id) on delete cascade,
  addon_key text not null,
  addon_name text not null,
  addon_type text not null,
  unit text not null default 'each',
  unit_price numeric not null default 0,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint quote_addon_prices_addon_type_check
    check (addon_type in ('footer', 'mount'))
);

create unique index if not exists quote_addon_prices_unique_global_key
on public.quote_addon_prices(addon_key)
where company_id is null;

create unique index if not exists quote_addon_prices_unique_company_key
on public.quote_addon_prices(company_id, addon_key)
where company_id is not null;

create index if not exists quote_addon_prices_company_idx
on public.quote_addon_prices(company_id);

create index if not exists quote_addon_prices_type_idx
on public.quote_addon_prices(addon_type, is_active, sort_order);

alter table public.quote_addon_prices enable row level security;

drop policy if exists "Active members can view quote addon prices"
on public.quote_addon_prices;

create policy "Active members can view quote addon prices"
on public.quote_addon_prices
for select
to authenticated
using (
  company_id is null
  or exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_addon_prices.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

drop policy if exists "Financial admins can manage quote addon prices"
on public.quote_addon_prices;

create policy "Financial admins can manage quote addon prices"
on public.quote_addon_prices
for all
to authenticated
using (
  company_id is not null
  and exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_addon_prices.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo')
  )
)
with check (
  company_id is not null
  and exists (
    select 1
    from public.company_members cm
    where cm.company_id = quote_addon_prices.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo')
  )
);

insert into public.quote_addon_prices
  (company_id, addon_key, addon_name, addon_type, unit, unit_price, sort_order)
values
  (null, 'footer_standard_2x2x5', 'Standard 2 × 2 × 5 Footer', 'footer', 'each', 1250, 10),
  (null, 'footer_standard_7x30', 'Standard 7 ft deep × 30 in diameter Footer', 'footer', 'each', 2800, 20),
  (null, 'mount_base_plate', 'Base Plate Mount', 'mount', 'each', 2250, 30)
on conflict do nothing;
