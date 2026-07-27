alter table public.quotes
add column if not exists high_tension_pole_count integer not null default 0;

alter table public.quotes
add column if not exists shade_sail_count integer not null default 0;

alter table public.quotes
add column if not exists sealed_engineering_required boolean not null default false;

alter table public.quotes
drop constraint if exists quotes_high_tension_pole_count_check;

alter table public.quotes
add constraint quotes_high_tension_pole_count_check
check (high_tension_pole_count >= 0);

alter table public.quotes
drop constraint if exists quotes_shade_sail_count_check;

alter table public.quotes
add constraint quotes_shade_sail_count_check
check (shade_sail_count >= 0);
