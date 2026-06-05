-- 0001_init.sql
-- Initial schema for joes_tabs: instruments, songs, tabs, enums, FTS, RLS.
-- Applies cleanly to a local Supabase/Postgres stack via `supabase db reset`.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.tab_source as enum ('official', 'imported', 'community');
create type public.tab_status as enum ('draft', 'published');

-- ---------------------------------------------------------------------------
-- Helper: shared updated_at trigger function
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- instruments (lookup table, enum-ish)
-- ---------------------------------------------------------------------------
create table public.instruments (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,
  name          text not null,
  string_count  int  not null check (string_count > 0),
  default_tuning text not null
);

-- Seed the two v1 instruments.
insert into public.instruments (slug, name, string_count, default_tuning) values
  ('ukulele', 'Ukulele', 4, 'GCEA'),
  ('guitar',  'Guitar',  6, 'EADGBE');

-- ---------------------------------------------------------------------------
-- songs (with generated FTS tsvector over title + artist)
-- ---------------------------------------------------------------------------
create table public.songs (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  artist      text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  search_tsv  tsvector generated always as (
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(artist, '')), 'B')
  ) stored
);

create index songs_search_tsv_idx on public.songs using gin (search_tsv);

create trigger songs_set_updated_at
  before update on public.songs
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- tabs (ChordPro content, fk to songs + instruments)
-- ---------------------------------------------------------------------------
create table public.tabs (
  id            uuid primary key default gen_random_uuid(),
  song_id       uuid not null references public.songs (id) on delete cascade,
  instrument_id uuid not null references public.instruments (id) on delete restrict,
  content       text not null,                 -- ChordPro source
  original_key  text,
  capo          int check (capo is null or capo >= 0),
  difficulty    text,
  source        public.tab_source not null default 'imported',
  status        public.tab_status not null default 'draft',
  author_id     uuid,                           -- nullable; for future accounts
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index tabs_song_id_idx on public.tabs (song_id);
create index tabs_status_idx  on public.tabs (status);

create trigger tabs_set_updated_at
  before update on public.tabs
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- Anonymous (anon) read-only access for v1:
--   * published tabs are publicly selectable
--   * songs that have at least one published tab are publicly selectable
--   * instruments are public reference data
--   * no public insert/update/delete anywhere (seeding uses the service role,
--     which bypasses RLS)
-- ---------------------------------------------------------------------------
alter table public.instruments enable row level security;
alter table public.songs       enable row level security;
alter table public.tabs        enable row level security;

-- instruments: public read of reference data.
create policy "instruments are publicly readable"
  on public.instruments
  for select
  to anon, authenticated
  using (true);

-- tabs: only published rows are visible to the public.
create policy "published tabs are publicly readable"
  on public.tabs
  for select
  to anon, authenticated
  using (status = 'published');

-- songs: visible only if they have at least one published tab.
create policy "songs with a published tab are publicly readable"
  on public.songs
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tabs t
      where t.song_id = songs.id
        and t.status = 'published'
    )
  );

-- ---------------------------------------------------------------------------
-- search_songs RPC: full-text search over title + artist.
-- Returns songs (with a published tab, enforced by RLS) ranked by relevance.
-- security invoker => RLS of the calling role still applies.
-- ---------------------------------------------------------------------------
create or replace function public.search_songs(query text)
returns setof public.songs
language sql
stable
security invoker
set search_path = public
as $$
  select s.*
  from public.songs s
  where
    query is null
    or btrim(query) = ''
    or s.search_tsv @@ websearch_to_tsquery('simple', query)
  order by
    case
      when query is null or btrim(query) = '' then 0
      else ts_rank(s.search_tsv, websearch_to_tsquery('simple', query))
    end desc,
    s.title asc;
$$;

-- Allow the app roles to call the RPC.
grant execute on function public.search_songs(text) to anon, authenticated;
