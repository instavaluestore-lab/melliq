-- LupinusBuild
-- Harden company member and team invitation authorization.

begin;

alter table public.company_members enable row level security;
alter table public.team_invitations enable row level security;

-- Remove legacy and overly broad company member policies.
drop policy if exists "Owners and admins can manage company members"
  on public.company_members;
drop policy if exists "Users can insert their own owner membership"
  on public.company_members;
drop policy if exists "Company members can view company membership"
  on public.company_members;
drop policy if exists "Users can view their own membership"
  on public.company_members;

create policy "Active members can view company membership"
on public.company_members
for select
to authenticated
using (
  public.is_company_member(company_id)
  or user_id = auth.uid()
);

create policy "Executives can update non-primary members"
on public.company_members
for update
to authenticated
using (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo']::text[]
  )
  and user_id <> auth.uid()
  and role <> 'primary_admin'
)
with check (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo']::text[]
  )
  and user_id <> auth.uid()
  and role <> 'primary_admin'
);

-- Enforce row invariants independently of client code and RLS expressions.
create or replace function public.protect_company_member_identity()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
begin
  -- Allow trusted server-side administration and migrations.
  if auth.uid() is null then
    return new;
  end if;

  if old.company_id is distinct from new.company_id
      or old.user_id is distinct from new.user_id then
    raise exception 'Company and user identity cannot be changed.'
      using errcode = '42501';
  end if;

  if old.user_id = auth.uid() then
    raise exception 'You cannot change your own membership.'
      using errcode = '42501';
  end if;

  if old.role = 'primary_admin' or new.role = 'primary_admin' then
    raise exception 'Primary Admin membership cannot be changed here.'
      using errcode = '42501';
  end if;

  return new;
end;
$function$;

drop trigger if exists protect_company_member_identity
  on public.company_members;

create trigger protect_company_member_identity
before update on public.company_members
for each row
execute function public.protect_company_member_identity();

-- Replace invitation policies with authenticated-only policies.
drop policy if exists "Primary admins and CFOs can create team invitations"
  on public.team_invitations;
drop policy if exists "Company members can view team invitations"
  on public.team_invitations;
drop policy if exists "Primary admins and CFOs can update team invitations"
  on public.team_invitations;

create policy "Active members can view team invitations"
on public.team_invitations
for select
to authenticated
using (public.is_company_member(company_id));

create policy "Executives can create non-primary invitations"
on public.team_invitations
for insert
to authenticated
with check (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo']::text[]
  )
  and role <> 'primary_admin'
  and status = 'pending'
  and invited_by = auth.uid()
  and accepted_by is null
  and accepted_at is null
  and canceled_at is null
);

create policy "Executives can cancel non-primary invitations"
on public.team_invitations
for update
to authenticated
using (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo']::text[]
  )
  and role <> 'primary_admin'
  and status = 'pending'
)
with check (
  public.has_company_role(
    company_id,
    array['primary_admin', 'cfo']::text[]
  )
  and role <> 'primary_admin'
  and status = 'canceled'
);

create or replace function public.protect_team_invitation_update()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
begin
  -- Allow trusted server-side invitation acceptance and administration.
  if auth.uid() is null then
    return new;
  end if;

  if old.company_id is distinct from new.company_id
      or old.email is distinct from new.email
      or old.full_name is distinct from new.full_name
      or old.phone is distinct from new.phone
      or old.role is distinct from new.role
      or old.invited_by is distinct from new.invited_by
      or old.created_at is distinct from new.created_at then
    raise exception 'Invitation identity and assigned role cannot be changed.'
      using errcode = '42501';
  end if;

  if old.role = 'primary_admin' or new.role = 'primary_admin' then
    raise exception 'Primary Admin invitations are not permitted.'
      using errcode = '42501';
  end if;

  if old.status <> 'pending' or new.status <> 'canceled' then
    raise exception 'Only pending invitations can be canceled.'
      using errcode = '42501';
  end if;

  if new.accepted_by is distinct from old.accepted_by
      or new.accepted_at is distinct from old.accepted_at then
    raise exception 'Cancellation cannot change acceptance details.'
      using errcode = '42501';
  end if;

  return new;
end;
$function$;

drop trigger if exists protect_team_invitation_update
  on public.team_invitations;

create trigger protect_team_invitation_update
before update on public.team_invitations
for each row
execute function public.protect_team_invitation_update();

commit;
