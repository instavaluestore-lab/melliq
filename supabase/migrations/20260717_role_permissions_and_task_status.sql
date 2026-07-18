-- LupinusBuild Supabase migration notes
-- Date: 2026-07-17
-- Purpose:
-- 1. Allow Field Users to perform operational project work without financial access.
-- 2. Fix project task status constraint to match Flutter values.
-- 3. Document materials/task RLS policy updates applied in Supabase.

begin;

-- PROJECT TASK STATUS FIX
-- Flutter uses:
--   todo
--   done
--
-- This constraint must match the app exactly.
alter table public.project_tasks
drop constraint if exists project_tasks_status_check;

alter table public.project_tasks
add constraint project_tasks_status_check check (
  status in ('todo', 'done')
);

-- NOTE:
-- Materials RLS and project_tasks RLS were updated in Supabase to allow:
-- - field_user material creation
-- - field_user material status updates
-- - field_user project task completion/reopen
--
-- Before production launch, verify all active policies with:
--
-- select
--   tablename,
--   policyname,
--   cmd
-- from pg_policies
-- where schemaname = 'public'
--   and tablename in ('materials', 'project_tasks')
-- order by tablename, policyname;

commit;
