# CI/CD workflows

GitHub Actions for Joes Tabs. Nothing runs until the repo is pushed to GitHub;
once it is, these activate automatically. Default branch is `master`. Flutter is
pinned to `3.38.3` (stable, carries Dart 3.10.1 to match the workspace SDK
`^3.10.1`).

## Workflows

### `ci.yml` - CI

- Triggers: push and pull_request to `master`.
- Steps: checkout, Java 17 (Temurin), Flutter 3.38.3, `flutter pub get` (single
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

- Triggers: push to `master`, or manual dispatch. One concurrent deploy
  (`concurrency: pages`), in-progress deploys are not cancelled.
- Builds the web app and deploys to GitHub Pages.
- Live site: https://sirbepy.github.io/joes_tabs/ (project site, served under
  `/joes_tabs/`).
- Base href is `/joes_tabs/`; change to `/` for a user/org root site.

**One-time manual repo setup (Joe):**

1. Settings > Pages > Build and deployment > Source = **GitHub Actions**. Until
   this is set, the build step passes but the deploy step fails.
2. Settings > Secrets and variables > Actions > add repo secrets
   `SUPABASE_URL` and `SUPABASE_ANON_KEY`. These are injected into the build via
   `--dart-define` (compile time). If absent, the build still succeeds (empty
   defines) and the app runs without a backend, but the hosted site has no
   Supabase backend until both are set. Re-run the workflow after adding them.

**Deep-link fallback:** the app uses path-based URL routing
(`usePathUrlStrategy`), so routes look like `/joes_tabs/song/<id>`. GitHub Pages
serves static files only and does no SPA fallback, so a direct load or refresh
of a deep link would 404. The workflow copies the built `index.html` to
`404.html`; Pages serves `404.html` for any unknown path, and Flutter's router
then resolves the route client side. The copy is verbatim, so its base href and
bootstrap match `index.html` exactly. Nothing extra is committed to `web/`.

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
  and are not required to build. For the hosted Pages site, set them as repo
  secrets (see the `deploy-web.yml` section) so they are injected at build time.
