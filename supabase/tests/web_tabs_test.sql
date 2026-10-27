-- web_tabs_test.sql
-- Checks the RLS split and RPCs from 20261027120000_web_tabs.sql. Run against a
-- throwaway database with every migration applied (see supabase/tests/README.md);
-- any failed check raises, and the whole run is rolled back either way.
\set ON_ERROR_STOP 1
begin;

-- Fixtures: one public-domain song with an official tab, and a test user.
insert into auth.users (id) values ('00000000-0000-0000-0000-0000000000aa');
insert into public.songs (id, title, artist)
values ('00000000-0000-0000-0000-000000000001', 'Amazing Grace', 'Traditional');
insert into public.tabs (song_id, instrument_id, content, source, status)
select '00000000-0000-0000-0000-000000000001', id, '{title: Amazing Grace}', 'official', 'published'
from public.instruments where slug = 'ukulele';

-- Anonymous callers cannot import.
set local role anon;
do $$
begin
  perform public.import_web_tab('X', 'Y', 'https://chordie.com/x', 'chordie', 'guitar', '[C]x');
  raise exception 'FAIL: anon could call import_web_tab';
exception when insufficient_privilege then null;
end $$;
reset role;

-- A signed-in user imports a page.
set local role authenticated;
-- Both claim forms: the bare postgres image's auth.uid() reads the legacy
-- per-claim setting, a full Supabase stack reads the JSON one.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000aa","role":"authenticated"}', true),
       set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000aa', true);

do $$
declare
  v_song uuid;
  v_again uuid;
  v_count int;
begin
  v_song := public.import_web_tab(
    'Love Like You', 'Steven Universe',
    'https://ukulele-tabs.com/love-like-you.html', 'ukulele-tabs', 'ukulele',
    '{title: Love Like You}' || chr(10) || '[C]If I could begin to be');

  -- Re-importing the same page updates the tab in place, same song.
  v_again := public.import_web_tab(
    'Love Like You (ver 2)', 'Steven Universe',
    'https://ukulele-tabs.com/love-like-you.html', 'ukulele-tabs', 'ukulele',
    '[G]updated');
  if v_again <> v_song then
    raise exception 'FAIL: re-import moved the page to another song';
  end if;
  select count(*) into v_count from public.tabs
  where source_url = 'https://ukulele-tabs.com/love-like-you.html';
  if v_count <> 1 then raise exception 'FAIL: % tabs for one page', v_count; end if;
  if (select content from public.tabs
      where source_url = 'https://ukulele-tabs.com/love-like-you.html') <> '[G]updated' then
    raise exception 'FAIL: re-import did not update content';
  end if;

  -- A second page of the same song (case-insensitive match) joins that song.
  if public.import_web_tab(
       'love like you', 'STEVEN UNIVERSE',
       'https://www.chordie.com/chord.pere/love-like-you', 'chordie', 'guitar',
       '[Am]x') <> v_song then
    raise exception 'FAIL: same title/artist created a second song';
  end if;

  -- Signed-in users see imported tabs, attributed, and the song in search.
  if (select count(*) from public.tabs where song_id = v_song) <> 2 then
    raise exception 'FAIL: signed-in user cannot read imported tabs';
  end if;
  if (select author_id from public.tabs
      where source_url = 'https://ukulele-tabs.com/love-like-you.html')
     <> '00000000-0000-0000-0000-0000000000aa' then
    raise exception 'FAIL: author_id not set to the caller';
  end if;
  if not exists (select 1 from public.search_songs('steven universe')) then
    raise exception 'FAIL: imported song missing from signed-in search';
  end if;
  if (select count(*) from public.imported_song_ids(array[
        'https://ukulele-tabs.com/love-like-you.html', 'https://nope.example/'])) <> 1 then
    raise exception 'FAIL: imported_song_ids did not map exactly the known url';
  end if;

  -- Rejected input.
  begin
    perform public.import_web_tab('T', 'A', 'https://tabs.ultimate-guitar.com/t', 'ultimate-guitar', 'guitar', '[C]x');
    raise exception 'FAIL: Ultimate Guitar import accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.import_web_tab('T', 'A', 'javascript:alert(1)', 'chordie', 'guitar', '[C]x');
    raise exception 'FAIL: non-http source_url accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.import_web_tab('', 'A', 'https://chordie.com/y', 'chordie', 'guitar', '[C]x');
    raise exception 'FAIL: empty title accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.import_web_tab('T', 'A', 'https://chordie.com/y', 'chordie', 'banjo', '[C]x');
    raise exception 'FAIL: unknown instrument accepted';
  exception when invalid_parameter_value then null;
  end;
end $$;
reset role;

-- Anonymous callers see the official song only.
set local role anon;
do $$
begin
  if exists (select 1 from public.tabs where source = 'imported') then
    raise exception 'FAIL: anon can read imported tabs';
  end if;
  if exists (select 1 from public.songs where artist ilike 'steven universe') then
    raise exception 'FAIL: anon can see a song whose only tabs are imported';
  end if;
  if exists (select 1 from public.search_songs('steven universe')) then
    raise exception 'FAIL: anon search returns imported songs';
  end if;
  if not exists (select 1 from public.search_songs('amazing grace')) then
    raise exception 'FAIL: anon lost the public-domain catalog';
  end if;
end $$;
reset role;

select 'web_tabs_test: all checks passed' as result;
rollback;
