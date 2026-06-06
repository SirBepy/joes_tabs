# Onboarding + Persisted Preferences - Design

Date: 2026-06-06
Status: Approved (ready for implementation plan)

## Goal

Add a first-launch onboarding wizard that captures which instrument(s) the user
plays, and persist user preferences (instruments, theme, font size, onboarding
state) to disk. Make every preference editable in Settings. When the user plays
only one instrument, hide the Ukulele/Guitar picker everywhere and force that
instrument.

## Motivation

Today all three preferences (`defaultInstrumentProvider`, `darkModeProvider`,
`fontSizeProvider`) are session-only Riverpod `StateProvider`s with no disk
backing, and there is no onboarding. New users land directly on the home screen
with ukulele defaulted and a Ukulele/Guitar picker shown on four screens even if
they only play one instrument.

## Decisions (locked)

- **Instrument model**: a *set* of instruments, multi-select, minimum one
  required. Today the set is `{ukulele, guitar}`; built to extend (e.g. Bass)
  later by adding one more option, no model change.
- **Persistence backend**: a new Drift table (the app already ships Drift; no new
  dependency).
- **Theme**: NOT part of onboarding. Defaults to **System**. Editable in Settings
  as a 3-way **System / Light / Dark** selector.
- **Onboarding steps**: Welcome -> Instrument -> Account. One-time only (not
  replayable). No text-size step.
- **Flow shape**: multi-step wizard with progress dots.

## Architecture

### 1. Persistence - Drift `AppSettings` table

A single-row typed table (fixed primary key, e.g. `id = 0`) in
`packages/data/lib/src/drift/app_database.dart`:

| Column               | Type   | Default            | Notes                                  |
|----------------------|--------|--------------------|----------------------------------------|
| `id`                 | int    | 0                  | Fixed single-row key                   |
| `onboardingComplete` | bool   | false              | Gates the onboarding route             |
| `themeMode`          | text   | `system`           | One of `system` / `light` / `dark`     |
| `instruments`        | text   | `ukulele,guitar`   | Comma-joined `ChordShapes` slugs       |
| `fontSize`           | int    | 20                 | Matches current `fontSizeProvider` default |

- Bump Drift `schemaVersion`. `onCreate` creates all tables and seeds the single
  `AppSettings` row. `onUpgrade` (migration) creates the new table and inserts the
  default row for existing installs.
- `instruments` is stored as a comma-separated list of slugs and decoded to a
  `Set<ChordShapes>` at the repository boundary. Chosen over a child table for
  simplicity; the set is tiny and adding Bass later is just another slug.

### 2. Repository - `AppSettingsRepository` (in `packages/data`)

Thin DAO/repository over the table:

- `Future<AppSettingsData> read()` - reads (and lazily seeds) the row.
- `Stream<AppSettingsData> watch()` - reactive reads.
- `Future<void> update({...})` - partial update of any subset of fields.

Decoding/encoding of `instruments` (`Set<ChordShapes>` <-> text) and `themeMode`
(`ThemeMode` <-> text) lives here so the app layer deals in typed values only.

### 3. State layer (`apps/app/lib/state/settings_provider.dart`)

Replace the three session-only `StateProvider`s with write-through providers
backed by the repository:

- `themeModeProvider` -> `ThemeMode` (default `system`).
- `instrumentsProvider` -> `Set<ChordShapes>` (min one).
- `fontSizeProvider` -> `int` (now persisted).

Each is seeded at startup via `ProviderScope` overrides in `main.dart`, mirroring
the existing favorites-seed pattern (read the row before `runApp`, pass initial
values in). Mutations call the repository to persist, then update provider state.

Derived helpers:

- `showInstrumentPickerProvider` -> `instruments.length > 1`.
- When the picker is hidden, the forced instrument is `instruments.first`.

`defaultInstrumentProvider` is removed; consumers move to `instrumentsProvider` +
the derived helpers.

### 4. Routing (`apps/app/lib/router/`)

- Add `/onboarding` route, **outside** the `ShellRoute` (no drawer/top bar).
- Splash (`splash_screen.dart`) reads `onboardingComplete`: `false` ->
  `/onboarding`, `true` -> `/home`. Keep the existing brief splash delay.

### 5. Onboarding wizard (`apps/app/lib/screens/onboarding/`)

A `PageView`-based wizard with progress dots and Back/Next controls:

1. **Welcome** - app name + mascot placeholder (Phosphor icon for now, per the
   brand-asset TODO in `.for_bepy/ai_todos/`). "Get started" advances.
2. **Instrument** - "Which do you play?" multi-select cards (Ukulele, Guitar).
   Continue is disabled until at least one is selected. Adding Bass later = one
   more card.
3. **Account** - "Sign in to sync your favorites" with **Sign in** /
   **Create account** / **Skip for now**. Skip finishes onboarding to home;
   Sign in / Create account detour to `/login` (or `/register`) and return home
   after auth.

On completion (any path out of the Account step): persist `instruments` and set
`onboardingComplete = true`, then navigate to home (or to login for the auth
paths). There is no global skip; the instrument step's min-one requirement is the
only gate.

### 6. Settings changes (`apps/app/lib/screens/settings_screen.dart`)

- **Theme**: replace the Dark Mode on/off toggle with a 3-way **System / Light /
  Dark** selector bound to `themeModeProvider`. `main.dart` switches from
  `isDark ? dark : light` to driving `MaterialApp.router`'s `themeMode` directly
  from `themeModeProvider`.
- **Instruments**: replace the single "Default Instrument" dropdown with an
  "Instruments I play" multi-select (min one) bound to `instrumentsProvider`.
  This is the same value that controls picker visibility app-wide.
- Font size control stays; it now persists.
- No "Show intro again" entry (onboarding is one-time).

### 7. Picker hiding (the four sites)

When `showInstrumentPicker == false` (exactly one instrument), hide the toggle
and force `instruments.first`:

| Screen              | File                                   | Current                          |
|---------------------|----------------------------------------|----------------------------------|
| Chords              | `widgets/instrument_toggle.dart` used in `screens/chords_screen.dart` | `InstrumentToggle` + global update |
| Search              | `screens/search_screen.dart`           | seeded local toggle              |
| Song-detail controls| `widgets/song_controls_sheet.dart`     | per-song instrument tab selector |
| Tuner               | `screens/tuner_screen.dart`            | local toggle, single tuning      |

When both instruments are selected, all four behave exactly as today.

## Error handling

- If the settings row read fails at startup, fall back to in-memory defaults
  (`system` theme, both instruments, font 20) and continue; persistence resumes
  on next successful write. Do not block app launch on settings IO.
- Drift migration must be idempotent for existing installs (create-if-not-exists
  table, insert-if-absent row).

## Testing

- **Drift**: migration from prior schema version creates the table + seeds the
  row; repository `read`/`update`/`watch` round-trip, including `instruments`
  and `themeMode` encode/decode.
- **State**: providers hydrate from the seeded initial values; mutations
  write through to the repository.
- **Onboarding**: instrument step enforces min one (Continue disabled at zero);
  completion writes `onboardingComplete = true` and the chosen instruments;
  Account step Skip vs Sign in routing.
- **Splash routing**: `onboardingComplete == false` -> `/onboarding`; `true` ->
  `/home`.
- **Picker visibility**: single instrument hides the toggle and forces that
  instrument across Chords, Search, Song-detail controls, and Tuner; both
  instruments shows the toggle.
- **Quality floor**: `flutter analyze` clean, `dart format` applied, full test
  suite passes, `flutter build web` succeeds.

## Migration / rollout note

Existing installs have no settings row. After this ships they get the seeded row
with `onboardingComplete = false`, so they see onboarding once. If they somehow
exit without choosing, the default is both instruments (current behavior). This
is acceptable for a personal project.

## Out of scope (YAGNI)

- Theme step in onboarding (defaults to System).
- Text-size step in onboarding (Settings-only).
- Replayable onboarding.
- Additional instruments beyond ukulele/guitar (the model supports them; UI cards
  are added when the instrument is actually supported).
