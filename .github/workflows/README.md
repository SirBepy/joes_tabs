# CI/CD workflows

GitHub Actions for Joes Tabs. Nothing runs until the repo is pushed to GitHub;
once it is, these activate automatically. Default branch is `master`. Flutter is
pinned to `3.35.5` (stable, carries Dart 3.10.1 to match the workspace SDK
`^3.10.1`).

## Workflows

### `ci.yml` - CI

- Triggers: push and pull_request to `master`.
- Steps: checkout, Java 17 (Temurin), Flutter 3.35.5, `flutter pub get` (single
  workspace resolve from the repo root), `flutter analyze`, three test suites
  (`flutter test` in `apps/app` and `packages/data`, `dart test` in
  `packages/models`), and `flutter build web`.
- No secrets needed: the web build uses empty placeholder dart-defines and the
  app launches without a backend.

### `release-apk.yml` - Release APK

- Triggers: pushing a tag matching `v*`, or manual `workflow_dispatch`.
- Builds an UNSIGNED debug APK (no release keystore yet), uploads it as the
  `joes-tabs-debug-apk` artifact, and attaches `joes-tabs-debug.apk` to the
  GitHub Release for the tag.
- Commented scaffolding is included for the signed build and Play Store upload;
  enable it once the keystore and secrets exist (see below).

### `deploy-web.yml` - Deploy Web (GitHub Pages)

- Triggers: push to `master`, or manual dispatch.
- Builds the web app and deploys to GitHub Pages.
- Needs one-time setup: Settings > Pages > Source = GitHub Actions. Base href is
  `/joes_tabs/` (project site); change to `/` for a root site.

## Cutting a release

1. Commit and push to `master`.
2. Tag the release and push the tag:
   - `git tag v0.1.0`
   - `git push origin v0.1.0`
3. The Release APK workflow builds the debug APK and creates a GitHub Release
   with the APK attached.

## Secrets to add later (GitHub > Settings > Secrets and variables > Actions)

Only needed for signed/Play Store builds. CI and the debug-APK release need
none.

Signed Android build:

- `KEYSTORE_BASE64` - base64 of the upload keystore (`.jks`)
- `STORE_PASSWORD` - keystore password
- `KEY_ALIAS` - key alias
- `KEY_PASSWORD` - key password

Play Store upload (in addition to the above):

- `PLAY_SERVICE_ACCOUNT_JSON` - Google Play service-account JSON

## Notes

- A web bundle is produced by both `ci.yml` (validation only) and
  `deploy-web.yml` (validation plus deploy).
- Real Supabase values (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) are never committed
  and are not required to build; supply them at deploy time if/when a live
  backend is wired up.
