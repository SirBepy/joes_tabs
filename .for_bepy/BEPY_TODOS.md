# Bepy Todos

### Done this session (no action needed, FYI)
- App is LIVE on the web: https://sirbepy.github.io/joes_tabs/ (GitHub Pages, auto-deploys on every push to master, so /commit pushbump redeploys it).
- GitHub: repo is SirBepy/joes_tabs (public). Account question resolved to SirBepy (it is the repo git author and the only gh login with the workflow scope).
- Cloud backend: new Supabase project "joes-tabs" (ref cqvcgeyxlcofnohlpfjr, Paris). Schema + 30 public-domain songs pushed. Web + mobile both point at it, so saved favorites sync across platforms once you sign in.
- Cloud creds are in the gitignored .env.local (DB password, anon/publishable, service_role). Keep that file safe; it is never committed.

### When you want it (not blocking)
- The chord-picker work is on an unmerged branch `feature/chord-picker` (all committed, not pushed). Decide its fate when ready: rebase onto `master` + PR for a picker-only review, or merge once tuner is done. NOTE it branches off `feature/tuner-rework`, so a plain merge into master would also drag the in-flight tuner work along.
- Hosted-site signups currently require an email-confirmation click (Supabase default). If you want INSTANT signup on the live site, in the Supabase dashboard for the joes-tabs project: Authentication > Providers > Email > turn OFF "Confirm email". (I was blocked from changing prod auth config automatically, by design.)
- Mobile app: the release-apk workflow builds an APK wired to the cloud backend when you push a tag (git tag v0.1.0 then git push origin v0.1.0). For a Play-Store-signed build, add the keystore secrets (KEYSTORE_BASE64, STORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD) and uncomment the signed-build block in release-apk.yml. Play Store upload also needs PLAY_SERVICE_ACCOUNT_JSON.
- Real AdMob ids (app id + rewarded unit id) when your AdMob account exists, to replace the test ids.

### Visual QA (let's do this together)
- 2026-06-14 autopilot run (develop, unpushed): (1) DARK MODE - the section-header bar and
  the dark app bar now darken with the body (was cream/orange-staying); flip Settings >
  Theme > Dark and confirm every screen reads consistently. (2) DESKTOP RESPONSIVE first
  cut - Chords Browse-all, Saved tabs, and Search now reflow into grids on wide windows
  (mobile keeps the carousel/list, verified byte-identical at 390). Eyeball at a wide width:
  do the grid column counts + the 600/1100 max-widths feel right? See the proposed layout
  language in docs/desktop-layout-language.md and the deferred items (nav rail, multi-pane)
  in ai_todos/013. Screens NOT touched (still your call): Home, Song detail, Tuner, Settings,
  Chords Pick. Live screenshots: .for_bepy/screenshots/autopilot-0614-*.png.
- DECIDE: do you want the bright orange app-bar BAND kept in dark mode as a brand accent
  (instead of the new dark bar)? If so, revert only the dark appBarTheme block in
  apps/app/lib/theme/app_theme.dart (one block). The cream-section-header dark fix stays.
- Eyeball the 3 UI changes from the 2026-06-13 autopilot run (all on develop, unpushed) at 390x844 AND on a wide desktop window: (1) Chords screen instrument picker is now a top-bar icon dropdown instead of the inline pill (011); (2) the chord picker's Family/Type is now a family tab bar + a tappable chord list instead of two chip strips (012); (3) desktop now centers content at 600px instead of stretching full-bleed (013) - confirm 600 feels right and pick a real value.
- Confirm the ukulele top-bar icon: there's no Phosphor uke glyph so it's a musicNote stand-in (guitar uses the guitar glyph) - swap when real brand art exists.
- Review the wireframe screens against DesignImages/ for the final UI polish pass. Brand-level fidelity is in (Fredoka font, orange headers, Home/Song/section screens matched); remaining finer polish + the mascot character art are in ai_todos 006. Screenshots from this session are in .for_bepy/screenshots/.
- Tune a real ukulele and guitar on a physical iOS + Android device: confirm the mic auto-detects the right string, the gauge slides smoothly, and green/amber/red + the lock glow/haptic feel right.
- (Optional) Swap the generated Karplus-Strong pluck WAVs in apps/app/assets/tones/ for real CC0 ukulele/guitar single-note recordings if you want a warmer tone.
