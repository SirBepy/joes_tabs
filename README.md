# Joes Tabs (working title)

Cross-platform ukulele + guitar tabs app: browse and play along to chord sheets,
with transpose, autoscroll, chord diagrams, a tuner, and offline favorites.
Flutter (web/iOS/Android) frontend, Supabase (Postgres) backend.

See the design spec: `docs/superpowers/specs/2026-05-30-tabs-app-design.md`.

## Monorepo layout

```
apps/app          Flutter app (web, android, ios)
packages/models   Shared Dart domain models
packages/data     Repositories, Supabase client, Drift cache, providers
supabase/         SQL migrations + seed (added by later plans)
docs/             Specs, plans, night-run state, design screen docs
```

This is a native Dart pub workspace (Dart 3.6+). Melos provides convenience
scripts on top.

## Bootstrap

```sh
dart pub get          # resolves the whole workspace from the root
```

Then, in `apps/app`:

```sh
flutter run -d chrome
```

## Common scripts (via melos, once activated)

```sh
melos run analyze     # dart analyze across all packages
melos run format      # dart format
melos run test        # run package tests
```
