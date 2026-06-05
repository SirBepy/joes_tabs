-- 20260605195159_user_favorites.sql
-- Per-user favorites for signed-in accounts (spec section 5: local favorites
-- migrate to the account on first sign-in). Anonymous use keeps its local-only
-- Drift favorites and never touches this table.
--
-- song_id is text (not an FK to public.songs) on purpose: the catalogue is RLS
-- gated to songs with a published tab, and we want a favorite row to survive
-- even if a song is temporarily unpublished. Stable song ids let the client
-- resolve the song separately, matching the local Drift favorites contract.

create table public.user_favorites (
  user_id    uuid not null references auth.users (id) on delete cascade,
  song_id    text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, song_id)
);

create index user_favorites_user_id_idx on public.user_favorites (user_id);

-- ---------------------------------------------------------------------------
-- Row Level Security: each user reads/writes ONLY their own favorites.
-- ---------------------------------------------------------------------------
alter table public.user_favorites enable row level security;

create policy "users read their own favorites"
  on public.user_favorites
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "users insert their own favorites"
  on public.user_favorites
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "users update their own favorites"
  on public.user_favorites
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users delete their own favorites"
  on public.user_favorites
  for delete
  to authenticated
  using (auth.uid() = user_id);
