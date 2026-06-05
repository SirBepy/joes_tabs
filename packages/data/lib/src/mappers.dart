import 'package:models/models.dart';

/// Pure JSON -> model mapping functions for catalog rows.
///
/// These are deliberately free of any Supabase/network dependency so they can
/// be unit-tested directly against representative row maps. The repository
/// implementations delegate all row decoding here.
///
/// Postgres columns are snake_case and the models' generated `fromJson`
/// (field_rename: snake) already expects snake_case keys, so most rows map
/// straight through. The exceptions are normalized below.
class CatalogMappers {
  const CatalogMappers._();

  /// Maps a single `songs` row to a [Song].
  static Song song(Map<String, dynamic> row) => Song.fromJson(row);

  /// Maps a list of `songs` rows (e.g. from a select or the `search_songs`
  /// RPC) to a list of [Song].
  static List<Song> songs(Iterable<dynamic> rows) =>
      rows.map((r) => song(_asMap(r))).toList();

  /// Maps a single `tabs` row to a [Tab].
  ///
  /// The DB allows `original_key` to be null, but [Tab.originalKey] is a
  /// non-null `String`; a null is normalized to the empty string here so the
  /// model's invariant holds.
  static Tab tab(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    normalized['original_key'] ??= '';
    return Tab.fromJson(normalized);
  }

  /// Maps a list of `tabs` rows to a list of [Tab].
  static List<Tab> tabs(Iterable<dynamic> rows) =>
      rows.map((r) => tab(_asMap(r))).toList();

  /// Builds a [SongWithTabs] from a song row plus its tab rows.
  static SongWithTabs songWithTabs({
    required Map<String, dynamic> songRow,
    required Iterable<dynamic> tabRows,
  }) => SongWithTabs(song: song(songRow), tabs: tabs(tabRows));

  /// Builds a [SongWithTabs] from a single nested row where the tabs come back
  /// as an embedded `tabs` array (Supabase relational select), e.g.
  /// `select('*, tabs(*)')`.
  static SongWithTabs songWithEmbeddedTabs(Map<String, dynamic> row) {
    final tabRows = (row['tabs'] as List<dynamic>?) ?? const <dynamic>[];
    final songRow = Map<String, dynamic>.from(row)..remove('tabs');
    return songWithTabs(songRow: songRow, tabRows: tabRows);
  }

  static Map<String, dynamic> _asMap(dynamic row) =>
      Map<String, dynamic>.from(row as Map);
}
