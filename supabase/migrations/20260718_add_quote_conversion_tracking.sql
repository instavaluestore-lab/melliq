-- LupinusBuild Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Track quote-to-project conversion and prevent duplicate project creation.

begin;

alter table public.quotes
add column if not exists converted_project_id uuid references public.projects(id) on delete set null;

alter table public.quotes
add column if not exists converted_at timestamp with time zone;

alter table public.quotes
add column if not exists converted_by uuid references auth.users(id) on delete set null;

create index if not exists quotes_converted_project_id_idx
on public.quotes(converted_project_id);

commit;
