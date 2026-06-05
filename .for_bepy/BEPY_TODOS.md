# Bepy Todos

### Done this session (no action needed, FYI)
- App is LIVE on the web: https://sirbepy.github.io/joes_tabs/ (GitHub Pages, auto-deploys on every push to master, so /commit pushbump redeploys it).
- GitHub: repo is SirBepy/joes_tabs (public). Account question resolved to SirBepy (it is the repo git author and the only gh login with the workflow scope).
- Cloud backend: new Supabase project "joes-tabs" (ref cqvcgeyxlcofnohlpfjr, Paris). Schema + 30 public-domain songs pushed. Web + mobile both point at it, so saved favorites sync across platforms once you sign in.
- Cloud creds are in the gitignored .env.local (DB password, anon/publishable, service_role). Keep that file safe; it is never committed.

### When you want it (not blocking)
- Hosted-site signups currently require an email-confirmation click (Supabase default). If you want INSTANT signup on the live site, in the Supabase dashboard for the joes-tabs project: Authentication > Providers > Email > turn OFF "Confirm email". (I was blocked from changing prod auth config automatically, by design.)
- Mobile app: the release-apk workflow builds an APK wired to the cloud backend when you push a tag (git tag v0.1.0 then git push origin v0.1.0). For a Play-Store-signed build, add the keystore secrets (KEYSTORE_BASE64, STORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD) and uncomment the signed-build block in release-apk.yml. Play Store upload also needs PLAY_SERVICE_ACCOUNT_JSON.
- Real AdMob ids (app id + rewarded unit id) when your AdMob account exists, to replace the test ids.

### Visual QA (let's do this together)
- Review the wireframe screens against DesignImages/ for the final UI polish pass. Brand-level fidelity is in (Fredoka font, orange headers, Home/Song/section screens matched); remaining finer polish + the mascot character art are in ai_todos 006. Screenshots from this session are in .for_bepy/screenshots/.
