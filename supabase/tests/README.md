# Database tests

Plain SQL scripts that apply fixtures, check RLS and RPC behaviour, raise on the
first failed check, and roll back. Run them against a throwaway database with
every migration applied. The Supabase Postgres image (the one `supabase start`
pulls) already ships the `anon` / `authenticated` roles and `auth.uid()`:

```bash
docker run -d --name jt-migtest -p 127.0.0.1:55432:5432 \
  -e POSTGRES_PASSWORD=postgres public.ecr.aws/supabase/postgres:17.6.1.127
# wait for: docker exec jt-migtest pg_isready -U postgres -h localhost
for f in supabase/migrations/*.sql; do
  docker exec -i jt-migtest psql -U postgres -v ON_ERROR_STOP=1 -q < "$f"
done
docker exec -i jt-migtest psql -U postgres -q < supabase/tests/web_tabs_test.sql
docker rm -f jt-migtest
```

A pass prints `web_tabs_test: all checks passed`; a failure prints `FAIL: ...`
and exits non-zero. Against a running `supabase start` stack, point psql at
`postgresql://postgres:postgres@127.0.0.1:54322/postgres` instead.
