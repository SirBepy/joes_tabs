-- 20261027120000_web_tabs.sql
-- Web tabs (docs/superpowers/specs/2026-10-27-web-tabs-design.md): a signed-in
-- user opens a chord page from an allowlisted site, the app parses it on the
-- device, and the parsed sheet is stored as an ordinary `imported` tab so the
-- viewer, favorites, offline cache and search work on it unchanged.
--
-- Imported tabs carry third-party lyrics, so only signed-in users can read them;
-- the public-domain `official` tabs stay readable by everyone.

-- ---------------------------------------------------------------------------
-- Source credit columns
-- ---------------------------------------------------------------------------
alter table public.tabs
  add column source_url  text,
  add column source_site text;

-- One stored tab per page: re-opening a page updates it instead of duplicating.
create unique index tabs_source_url_key
  on public.tabs (source_url)
  where source_url is not null;

-- ---------------------------------------------------------------------------
-- Row Level Security: split tab visibility by source
-- ---------------------------------------------------------------------------
-- The songs policy ("songs with a published tab are publicly readable") checks
-- for a visible tab through public.tabs, so it inherits this split: a song whose
-- only tabs are imported is invisible to anon too.
drop policy "published tabs are publicly readable" on public.tabs;

create policy "published official tabs are publicly readable"
  on public.tabs
  for select
  to anon
  using (status = 'published' and source = 'official');

create policy "published tabs are readable when signed in"
  on public.tabs
  for select
  to authenticated
  using (status = 'published');

-- ---------------------------------------------------------------------------
-- import_web_tab: store a parsed web tab, returning its song id
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER because clients have no insert rights on songs/tabs. It only
-- ever writes an `imported` tab for an allowlisted site, attributed to the
-- caller. The site list mirrors the parseable entries of WebTabSite in
-- packages/models; Ultimate Guitar is deliberately absent (link-only).
create function public.import_web_tab(
  p_title           text,
  p_artist          text,
  p_source_url      text,
  p_source_site     text,
  p_instrument_slug text,
  p_content         text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_title      text := btrim(coalesce(p_title, ''));
  v_artist     text := coalesce(nullif(btrim(coalesce(p_artist, '')), ''), 'Unknown');
  v_song_id    uuid;
  v_instrument uuid;
begin
  if auth.uid() is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;

  if v_title = ''
     or btrim(coalesce(p_content, '')) = ''
     or length(p_content) > 100000
     or coalesce(p_source_url, '') !~ '^https?://' then
    raise exception 'invalid web tab' using errcode = '22023';
  end if;

  if p_source_site not in ('ukulele-tabs', 'chordie', 'e-chords') then
    raise exception 'site % is not importable', p_source_site
      using errcode = '22023';
  end if;

  select id into v_instrument
  from public.instruments
  where slug = p_instrument_slug;
  if v_instrument is null then
    raise exception 'unknown instrument %', p_instrument_slug
      using errcode = '22023';
  end if;

  -- A page imported before keeps its song, even if this parse titled it
  -- differently.
  select song_id into v_song_id
  from public.tabs
  where source_url = p_source_url;

  if v_song_id is null then
    select id into v_song_id
    from public.songs
    where lower(btrim(title)) = lower(v_title)
      and lower(btrim(artist)) = lower(v_artist)
    order by created_at
    limit 1;
  end if;

  if v_song_id is null then
    insert into public.songs (title, artist)
    values (v_title, v_artist)
    returning id into v_song_id;
  end if;

  insert into public.tabs (
    song_id, instrument_id, content, source, status, author_id,
    source_url, source_site
  )
  values (
    v_song_id, v_instrument, p_content, 'imported', 'published', auth.uid(),
    p_source_url, p_source_site
  )
  on conflict (source_url) where source_url is not null
  do update set content = excluded.content;

  return v_song_id;
end;
$$;

revoke execute on function public.import_web_tab(text, text, text, text, text, text)
  from public, anon;
grant execute on function public.import_web_tab(text, text, text, text, text, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- imported_song_ids: which of these page URLs are already in the catalog
-- ---------------------------------------------------------------------------
-- SECURITY INVOKER, so the tabs RLS above decides what the caller may learn.
create function public.imported_song_ids(urls text[])
returns table (source_url text, song_id uuid)
language sql
stable
security invoker
set search_path = ''
as $$
  select t.source_url, t.song_id
  from public.tabs t
  where t.source_url = any (urls);
$$;

grant execute on function public.imported_song_ids(text[]) to authenticated;
