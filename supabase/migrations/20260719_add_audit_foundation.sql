-- LupinusBuild Supabase migration
-- Date: 2026-07-19
-- Purpose:
-- Add standardized audit fields and a universal append-only audit log table.

begin;

-- =========================================================
-- 1. Standard audit fields
-- =========================================================

alter table public.customers
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.leads
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.quotes
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.quote_line_items
add column if not exists created_by uuid references auth.users(id) on delete set null,
add column if not exists updated_by uuid references auth.users(id) on delete set null;

alter table public.projects
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null,
add column if not exists source_quote_id uuid references public.quotes(id) on delete set null;

alter table public.project_tasks
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.materials
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.expenses
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.project_files
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.project_notes
add column if not exists updated_by uuid references auth.users(id) on delete set null,
add column if not exists archived_by uuid references auth.users(id) on delete set null;

alter table public.project_stage_costs
add column if not exists updated_by uuid references auth.users(id) on delete set null;


-- =========================================================
-- 2. Universal audit log table
-- =========================================================

create table if not exists public.record_audit_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  record_type text not null,
  record_id uuid not null,
  action text not null,
  field_name text,
  old_value text,
  new_value text,
  summary text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamp with time zone not null default now(),
  metadata jsonb not null default '{}'::jsonb
);


-- =========================================================
-- 3. Indexes
-- =========================================================

create index if not exists record_audit_logs_company_id_idx
on public.record_audit_logs(company_id);

create index if not exists record_audit_logs_record_idx
on public.record_audit_logs(record_type, record_id);

create index if not exists record_audit_logs_created_at_idx
on public.record_audit_logs(created_at desc);

create index if not exists record_audit_logs_created_by_idx
on public.record_audit_logs(created_by);

create index if not exists customers_updated_by_idx
on public.customers(updated_by);

create index if not exists leads_updated_by_idx
on public.leads(updated_by);

create index if not exists quotes_updated_by_idx
on public.quotes(updated_by);

create index if not exists projects_updated_by_idx
on public.projects(updated_by);

create index if not exists projects_source_quote_id_idx
on public.projects(source_quote_id);

create index if not exists materials_updated_by_idx
on public.materials(updated_by);

create index if not exists project_tasks_updated_by_idx
on public.project_tasks(updated_by);


-- =========================================================
-- 4. RLS
-- =========================================================

alter table public.record_audit_logs enable row level security;

drop policy if exists "Active company members can view audit logs"
on public.record_audit_logs;

create policy "Active company members can view audit logs"
on public.record_audit_logs
for select
to authenticated
using (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = record_audit_logs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

drop policy if exists "Active company members can insert audit logs"
on public.record_audit_logs;

create policy "Active company members can insert audit logs"
on public.record_audit_logs
for insert
to authenticated
with check (
  exists (
    select 1
    from public.company_members cm
    where cm.company_id = record_audit_logs.company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  )
);

commit;
