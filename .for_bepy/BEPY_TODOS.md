# Bepy Todos

### Urgent
- Keep this PC awake and Claude Code open from now until ~13:00 today. The overnight build runs LOCAL cron ticks starting 05:02; if the PC sleeps or Claude Code closes, the build stalls. (For a PC-off run we'd use /night-run instead.)
- Confirm the GitHub account: you said `joephus321`, but the gh CLI is logged in as `josipmuzic` and `SirBepy` (not joephus321). Once confirmed, connect the GitHub remote - for tonight `origin` points at a local bare repo so cron pushes work offline.
- Local Supabase needs Docker Desktop running for plan 03 (schema/migrations) and plan 06 (seed). If Docker is off, those plans will author SQL but mark themselves blocked. Start Docker before 05:02 if you want them fully applied.
- Later: create a hosted Supabase project, then provide `SUPABASE_URL` + anon key (via --dart-define) and the service-role key (in an untracked .env) for seeding.

### Visual QA
- After the wireframe build lands, review the screens against DesignImages/ so we can do the UI polish pass together (polish is intentionally NOT part of the overnight run).
