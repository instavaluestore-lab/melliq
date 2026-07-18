-- MellIQ Supabase migration
-- Date: 2026-07-18
-- Purpose:
-- Add project_activity_logs for project operational history:
-- status changes, materials, tasks, notes, files, and project updates.

begin;

create table if not exists public.project_activity_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  activity_type text not null,
  title text not null,
  body text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint project_activity_logs_activity_type_check check (
    activity_type in (
      'status_changed',
      'material_created',
      'material_status_changed',
      'task_created',
      'task_completed',
      'task_reopened',
      'task_deleted',
      'note_created',
      'note_deleted',
      'file_uploaded',
      'file_deleted',
      'project_updated'
    )
  )
);

create index if not exists project_activity_logs_company_id_idx
on public.project_activity_logs(company_id);

create index if not exists project_activity_logs_project_id_idx
on public.project_activity_logs(project_id);

create index if not exists project_activity_logs_created_by_idx
on public.project_activity_logs(created_by);

create index if not exists project_activity_logs_created_at_idx
on public.project_activity_logs(created_at desc);

alter table public.project_activity_logs enable row level security;

drop policy if exists "Active company members can view project activity logs"
on public.project_activity_logs;

drop policy if exists "Operational roles can create project activity logs"
on public.project_activity_logs;

drop policy if exists "Managers can delete project activity logs"
on public.project_activity_logs;

create policy "Active company members can view project activity logs"
on public.project_activity_logs
for select
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_activity_logs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

create policy "Operational roles can create project activity logs"
on public.project_activity_logs
for insert
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_activity_logs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager', 'field_user')
  )
);

create policy "Managers can delete project activity logs"
on public.project_activity_logs
for delete
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = project_activity_logs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
      and cm.role in ('primary_admin', 'cfo', 'admin', 'manager')
  )
);

commit;
