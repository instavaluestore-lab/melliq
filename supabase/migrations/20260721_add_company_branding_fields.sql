alter table public.companies
  add column if not exists brand_name text,
  add column if not exists workspace_name text,
  add column if not exists logo_url text,
  add column if not exists login_subtitle text,
  add column if not exists primary_brand_color text,
  add column if not exists accent_brand_color text,
  add column if not exists powered_by_lupinusbuild boolean not null default true;

comment on column public.companies.brand_name is
  'Customer-facing company or tenant brand name shown in branded workspace UI.';

comment on column public.companies.workspace_name is
  'Workspace display name, such as MaxShade Project Operations or ABC Roofing Operations.';

comment on column public.companies.logo_url is
  'Company logo URL or storage path used for workspace branding.';

comment on column public.companies.login_subtitle is
  'Optional branded subtitle shown on login or workspace entry screens.';

comment on column public.companies.primary_brand_color is
  'Optional primary brand color hex value for tenant-branded UI.';

comment on column public.companies.accent_brand_color is
  'Optional accent brand color hex value for tenant-branded UI.';

comment on column public.companies.powered_by_lupinusbuild is
  'Controls whether Powered by LupinusBuild is shown in tenant-branded UI.';
