-- MellIQ Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Add project_notes for daily field updates, customer notes, issues, delays,
-- weather/site notes, and next steps without exposing financial data.

begin;

create table if not exists public.project_notes (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  note_type text not null default 'general',
  body text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint project_notes_note_type_check check (
    note_type in (
      'general',
      'field_update',
      'issue',
      'delay',
      'customer_note',
      'weather_site',
      'next_step'
    )
  )
);

create index if not exists project_notes_company_id_idx
on public.project_notes(company_id);

create index if not exists project_notes_project_id_idx
on public.project_notes(project_id);

create index if not exists project_notes_created_by_idx
on public.project_notes(created_by);

create index if not exists project_notes_created_at_idx
on public.project_notes(created_at desc);

alter table public.project_notes enable row level security;

drop policy if exists "Active company members can view project notes"
on public.project_notes;

drop policy if exists "Operational roles can create project notes"
on public.project_notes;

drop policy if exists "Creators and managers can update project notes"
on public.project_notes;

drop policy if exists "Creators and managers can delete project notes"
on public.project_notes;

create policy "Active company members can view project notes"
on public.project_notes
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_notes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Operational roles can create project notes"
on public.project_notes
for insert
with check (
  created_by = auth.uid()
  and exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_notes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager', 'field_user')
  )
);

create policy "Creators and managers can update project notes"
on public.project_notes
for update
using (
  created_by = auth.uid()
  or exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_notes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_notes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager', 'field_user')
  )
);

create policy "Creators and managers can delete project notes"
on public.project_notes
for delete
using (
  created_by = auth.uid()
  or exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_notes.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

commit;
