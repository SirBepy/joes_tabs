import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_repository.dart';
import 'mappers.dart';

/// [CatalogRepository] backed by a Supabase Postgres backend.
///
/// All reads go through the public RLS policies (anon role): only published
/// tabs and the songs that have at least one published tab are visible. Decode
/// of every row is delegated to [CatalogMappers] so the parsing stays pure and
/// unit-testable apart from the network.
class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Song>> trending({int limit = 20}) async {
    try {
      final rows = await _client
          .from('songs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return CatalogMappers.songs(rows);
    } catch (e) {
      throw CatalogException('Failed to load trending songs', e);
    }
  }

  @override
  Future<List<Song>> listSongs({String? instrumentSlug, int limit = 50}) async {
    try {
      if (instrumentSlug == null) {
        final rows = await _client
            .from('songs')
            .select()
            .order('title', ascending: true)
            .limit(limit);
        return CatalogMappers.songs(rows);
      }

      // Songs having at least one published tab for the given instrument.
      // The inner joins drop songs with no matching tab; RLS already restricts
      // tabs to published rows. `instruments.slug` is the human-facing filter.
      final rows = await _client
          .from('songs')
          .select('*, tabs!inner(instruments!inner(slug))')
          .eq('tabs.instruments.slug', instrumentSlug)
          .order('title', ascending: true)
          .limit(limit);

      // Strip the embedded join payload before decoding to plain songs, and
      // de-duplicate songs that matched on multiple tabs.
      final seen = <String>{};
      final songs = <Song>[];
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map)..remove('tabs');
        final song = CatalogMappers.song(map);
        if (seen.add(song.id)) songs.add(song);
      }
      return songs;
    } catch (e) {
      throw CatalogException('Failed to list songs', e);
    }
  }

  @override
  Future<List<Song>> search(String query) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'search_songs',
        params: <String, dynamic>{'query': query},
      );
      return CatalogMappers.songs(rows);
    } catch (e) {
      throw CatalogException('Search failed', e);
    }
  }

  @override
  Future<List<Song>> searchSongs(String query, {String? instrumentSlug}) async {
    final matches = await search(query);
    if (instrumentSlug == null) return matches;

    // Narrow to songs that have a published tab for the instrument. listSongs
    // already encodes that membership (inner join on published tabs).
    final withInstrument = await listSongs(instrumentSlug: instrumentSlug);
    return intersectByInstrument(matches, withInstrument);
  }

  /// Keeps the [matches] (search ranking) whose id also appears in
  /// [withInstrument] (songs having a published tab for the chosen instrument),
  /// preserving the search order. Pure + exposed for unit testing.
  @visibleForTesting
  static List<Song> intersectByInstrument(
    List<Song> matches,
    List<Song> withInstrument,
  ) {
    final allowed = {for (final s in withInstrument) s.id};
    return matches.where((s) => allowed.contains(s.id)).toList();
  }

  @override
  Future<SongWithTabs?> getSong(String id) async {
    try {
      final row = await _client
          .from('songs')
          .select('*, tabs(*)')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return CatalogMappers.songWithEmbeddedTabs(
        Map<String, dynamic>.from(row),
      );
    } catch (e) {
      throw CatalogException('Failed to load song $id', e);
    }
  }

  @override
  Future<List<Instrument>> instruments() async {
    try {
      final rows = await _client
          .from('instruments')
          .select()
          .order('string_count', ascending: false);
      return rows
          .map((r) => Instrument.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw CatalogException('Failed to load instruments', e);
    }
  }
}
