-- LupinusBuild
-- Add secure task-assignment notifications and harden project task RLS.

begin;

create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null
    references public.companies(id) on delete cascade,
  user_id uuid not null
    references public.profiles(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text,
  project_id uuid
    references public.projects(id) on delete cascade,
  task_id uuid
    references public.project_tasks(id) on delete cascade,
  actor_user_id uuid
    references public.profiles(id) on delete set null,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint user_notifications_type_check check (
    notification_type in ('task_assigned', 'task_reassigned')
  ),
  constraint user_notifications_title_not_blank check (
    length(trim(title)) > 0
  )
);

create index if not exists user_notifications_user_created_idx
on public.user_notifications(user_id, created_at desc);

create index if not exists user_notifications_user_unread_idx
on public.user_notifications(user_id, created_at desc)
where read_at is null;

create index if not exists user_notifications_task_idx
on public.user_notifications(task_id);

alter table public.user_notifications enable row level security;

revoke insert, delete on public.user_notifications from authenticated;
grant select, update on public.user_notifications to authenticated;

drop policy if exists "Users can view their own notifications"
on public.user_notifications;

create policy "Users can view their own notifications"
on public.user_notifications
for select
to authenticated
using (
  user_id = auth.uid()
  and public.is_company_member(company_id)
);

drop policy if exists "Users can mark their own notifications read"
on public.user_notifications;

create policy "Users can mark their own notifications read"
on public.user_notifications
for update
to authenticated
using (
  user_id = auth.uid()
  and public.is_company_member(company_id)
)
with check (
  user_id = auth.uid()
  and public.is_company_member(company_id)
);

create or replace function public.protect_notification_update()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
begin
  if auth.uid() is null then
    return new;
  end if;

  if old.id is distinct from new.id
      or old.company_id is distinct from new.company_id
      or old.user_id is distinct from new.user_id
      or old.notification_type is distinct from new.notification_type
      or old.title is distinct from new.title
      or old.body is distinct from new.body
      or old.project_id is distinct from new.project_id
      or old.task_id is distinct from new.task_id
      or old.actor_user_id is distinct from new.actor_user_id
      or old.created_at is distinct from new.created_at then
    raise exception 'Only notification read status can be changed.'
      using errcode = '42501';
  end if;

  return new;
end;
$function$;

drop trigger if exists protect_notification_update
on public.user_notifications;

create trigger protect_notification_update
before update on public.user_notifications
for each row
execute function public.protect_notification_update();

-- Remove duplicate and legacy project task policies.
drop policy if exists "Owners admins managers can delete project tasks"
on public.project_tasks;

drop policy if exists "Primary admin CFO admin managers can delete project tasks"
on public.project_tasks;

drop policy if exists "Owners admins managers field users can insert project tasks"
on public.project_tasks;

drop policy if exists "Primary admin CFO admin managers can create project tasks"
on public.project_tasks;

drop policy if exists "Active company members can view project tasks"
on public.project_tasks;

drop policy if exists "Company members can view project tasks"
on public.project_tasks;

drop policy if exists "Owners admins managers field users can update project tasks"
on public.project_tasks;

drop policy if exists "Primary admin CFO admin managers field users can update project"
on public.project_tasks;

alter table public.project_tasks enable row level security;

create policy "Active members can view project tasks"
on public.project_tasks
for select
to authenticated
using (public.is_company_member(company_id));

create policy "Task managers can create project tasks"
on public.project_tasks
for insert
to authenticated
with check (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo', 'admin', 'manager']::text[]
  )
);

create policy "Field users can create unassigned or self-assigned tasks"
on public.project_tasks
for insert
to authenticated
with check (
  public.has_company_role(company_id, array['field_user']::text[])
  and (assigned_to is null or assigned_to = auth.uid())
);

create policy "Task managers can update project tasks"
on public.project_tasks
for update
to authenticated
using (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo', 'admin', 'manager']::text[]
  )
)
with check (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo', 'admin', 'manager']::text[]
  )
);

create policy "Field users can complete their assigned tasks"
on public.project_tasks
for update
to authenticated
using (
  assigned_to = auth.uid()
  and public.has_company_role(company_id, array['field_user']::text[])
)
with check (
  assigned_to = auth.uid()
  and public.has_company_role(company_id, array['field_user']::text[])
);

create policy "Task managers can delete project tasks"
on public.project_tasks
for delete
to authenticated
using (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo', 'admin', 'manager']::text[]
  )
);

create or replace function public.protect_project_task_mutation()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  actor_role text;
begin
  if auth.uid() is null then
    return new;
  end if;

  select cm.role
  into actor_role
  from public.company_members cm
  where cm.company_id = new.company_id
    and cm.user_id = auth.uid()
    and cm.status = 'active'
  limit 1;

  if actor_role is null then
    raise exception 'Active company membership is required.'
      using errcode = '42501';
  end if;

if not exists (
  select 1
  from public.projects project_record
  where project_record.id = new.project_id
    and project_record.company_id = new.company_id
) then
  raise exception 'Task project must belong to the same company.'
    using errcode = '23514';
end if;

if tg_op = 'UPDATE' then
    if old.company_id is distinct from new.company_id
        or old.project_id is distinct from new.project_id
        or old.created_by is distinct from new.created_by
        or old.created_at is distinct from new.created_at then
      raise exception 'Task identity cannot be changed.'
        using errcode = '42501';
    end if;

    if actor_role = 'field_user' then
      if old.assigned_to is distinct from auth.uid()
          or new.assigned_to is distinct from auth.uid() then
        raise exception 'Field Users can update only their assigned tasks.'
          using errcode = '42501';
      end if;

      if old.title is distinct from new.title
          or old.description is distinct from new.description
          or old.priority is distinct from new.priority
          or old.due_date is distinct from new.due_date
          or old.assigned_to is distinct from new.assigned_to
          or old.archived_by is distinct from new.archived_by then
        raise exception 'Field Users can update only task completion status.'
          using errcode = '42501';
      end if;
    end if;
  end if;

  if new.assigned_to is not null
      and (
        tg_op = 'INSERT'
        or old.assigned_to is distinct from new.assigned_to
      )
      and not exists (
        select 1
        from public.company_members assignee
        where assignee.company_id = new.company_id
          and assignee.user_id = new.assigned_to
          and assignee.status = 'active'
          and assignee.role <> 'viewer'
      ) then
    raise exception 'Tasks can be assigned only to active non-viewer company users.'
      using errcode = '23514';
  end if;

  if actor_role = 'field_user'
      and new.assigned_to is not null
      and new.assigned_to is distinct from auth.uid() then
    raise exception 'Field Users cannot assign tasks to other users.'
      using errcode = '42501';
  end if;

  return new;
end;
$function$;

drop trigger if exists protect_project_task_mutation
on public.project_tasks;

create trigger protect_project_task_mutation
before insert or update on public.project_tasks
for each row
execute function public.protect_project_task_mutation();

create or replace function public.notify_project_task_assignment()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  event_type text;
  notification_body text;
begin
  if new.assigned_to is null then
    return new;
  end if;

  if tg_op = 'UPDATE'
      and old.assigned_to is not distinct from new.assigned_to then
    return new;
  end if;

  event_type := case
    when tg_op = 'INSERT' then 'task_assigned'
    else 'task_reassigned'
  end;

  notification_body := case
    when new.due_date is null then 'Open the project to review this task.'
    else 'Due date: ' || to_char(new.due_date, 'MM/DD/YYYY')
  end;

  insert into public.user_notifications (
    company_id,
    user_id,
    notification_type,
    title,
    body,
    project_id,
    task_id,
    actor_user_id
  )
  values (
    new.company_id,
    new.assigned_to,
    event_type,
    'Task assigned: ' || new.title,
    notification_body,
    new.project_id,
    new.id,
    auth.uid()
  );

  return new;
end;
$function$;

drop trigger if exists notify_project_task_assignment
on public.project_tasks;

create trigger notify_project_task_assignment
after insert or update of assigned_to on public.project_tasks
for each row
execute function public.notify_project_task_assignment();

commit;
