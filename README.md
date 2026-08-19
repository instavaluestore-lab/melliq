# LupinusBuild

LupinusBuild is a multi-role project operations and financial management platform for construction, installation, fabrication, and field-service companies.

## Current capabilities

- Company-based authentication and role permissions
- Customers, leads, quotes, and projects
- Quote-to-project conversion
- Project tasks and team assignment
- In-app task notifications
- Company-wide task center
- Project materials, files, notes, and activity
- Financial visibility restricted by role

## Local development

Run:

    cd /Users/veracalc/Projects/melliq
    flutter pub get
    flutter test
    flutter analyze
    flutter run -d chrome

## Production web build

Run:

    flutter build web

The generated production files are placed in `build/web`.

Supabase configuration can be supplied during the build:

flutter build web \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY

Default development values are currently defined in:

    lib/core/config/supabase_config.dart

Never place a Supabase service-role key or another server secret in the Flutter application.

## Product roadmap

The agreed product requirements and delivery priorities are maintained in:

    docs/LUPINUSBUILD_PRODUCT_ROADMAP.md
