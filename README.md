# Joes Tabs (working title)

Cross-platform ukulele + guitar chord-sheet app: browse songs, render ChordPro
with chord diagrams, transpose, autoscroll, tune by ear or mic, and save
favorites that sync across devices when you sign in.

**Live web app: https://sirbepy.github.io/joes_tabs/**

Flutter (web / iOS / Android) frontend, Supabase (Postgres) backend, Drift
offline cache. Design spec: `docs/superpowers/specs/2026-05-30-tabs-app-design.md`.

## Features

- Browse a catalog of public-domain songs (trending list, search by song/artist
  with an instrument filter).
- Song view: ChordPro rendered chords-over-lyrics, ukulele/guitar toggle,
  transpose, autoscroll with speed control, and chord-diagram strip - controls
  live in a floating-button sheet.
- Chords dictionary, and a Tuner (note strip + pointers, reference-tone plus
  live web microphone pitch detection).
- Accounts (optional): email auth via Supabase. Favorites are local when
  anonymous and sync to your account across web + mobile when signed in.
- Offline: favorites and recently-viewed songs cached locally (Drift, LRU 20,
  favorites never evicted).
- Light + dark themes; brand font (Fredoka) and peach/orange styling.

## Monorepo layout

```
apps/app          Flutter app (web, android, ios)
packages/models   Shared domain models + ChordPro parser/transposer/chord shapes
packages/data     Repositories, Supabase client + auth, Drift cache, providers
supabase/         Postgres migrations + public-domain ChordPro seed
docs/             Spec, plans, design screen docs
.github/workflows CI, web deploy (GitHub Pages), release (APK)
```

Native Dart pub workspace (Dart 3.10.1 / Flutter 3.38.3). No Melos required -
use plain `flutter` / `dart`.

## Running locally

The app reads `SUPABASE_URL` + `SUPABASE_ANON_KEY` at compile time via
`--dart-define`. A gitignored `apps/app/dart_define.local.json` holds local dev
values. Cloud creds live in the gitignored `.env.local`.

```sh
# 1. Start the local Supabase stack (needs Docker)
supabase start
# (first run only) apply migrations are automatic; seed the songs:
#   cd supabase/seed && SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... dart run seed.dart

# 2. Resolve the workspace
flutter pub get

# 3. Generate code (freezed / json_serializable / drift) - gitignored, so required
dart run build_runner build --delete-conflicting-outputs   # in packages/models
dart run build_runner build --delete-conflicting-outputs   # in packages/data

# 4. Run the app
cd apps/app
flutter run -d chrome --dart-define-from-file=dart_define.local.json
```

## Quality floor

```sh
flutter analyze                                  # clean
flutter test       # in apps/app and packages/data
dart test          # in packages/models
flutter build web  # in apps/app
```

Generated `*.g.dart` / `*.freezed.dart` are gitignored, so run `build_runner`
before analyzing/testing/building from a clean checkout (CI does this).

## CI/CD

GitHub Actions (`.github/workflows/`, details in its README):

- **CI** - analyze + tests + web build on every push/PR.
- **Deploy Web** - builds and deploys to GitHub Pages on every push to `master`.
- **Release APK** - version-driven: bumping `package.json` (via
  `/commit pushnbump`) auto-publishes a `v<version>` GitHub Release with an APK.

The hosted web build and the release APK are both wired to the cloud Supabase
project, so web and mobile share account data.
