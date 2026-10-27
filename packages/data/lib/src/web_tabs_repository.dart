import 'package:models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'catalog_repository.dart';

/// One chord page found by web search, on an allowlisted [site].
class WebSearchResult {
  const WebSearchResult({
    required this.title,
    required this.url,
    required this.description,
    required this.site,
    this.songId,
  });

  final String title;
  final Uri url;
  final String description;
  final WebTabSite site;

  /// The catalog song this page was already imported into, if any. Such a
  /// result opens the stored song instead of the page.
  final String? songId;

  WebSearchResult withSongId(String? id) => WebSearchResult(
    title: title,
    url: url,
    description: description,
    site: site,
    songId: id,
  );
}

/// Web tabs (spec `docs/superpowers/specs/2026-10-27-web-tabs-design.md`):
/// search chord sites, and store a page the user opened and parsed on device.
/// Every call needs a signed-in user; the backend rejects anonymous callers.
abstract class WebTabsRepository {
  /// Chord pages on the allowlisted sites matching [query], each annotated with
  /// the song it was already imported into.
  Future<List<WebSearchResult>> search(String query);

  /// Stores a parsed page as an `imported` tab and returns its song id. Saving
  /// the same [sourceUrl] again updates that tab in place.
  Future<String> importTab({
    required String title,
    String? artist,
    required Uri sourceUrl,
    required WebTabSite site,
    required String instrumentSlug,
    required String chordPro,
  });
}

/// [WebTabsRepository] over the `web-search` Edge Function and the
/// `import_web_tab` / `imported_song_ids` RPCs.
class SupabaseWebTabsRepository implements WebTabsRepository {
  SupabaseWebTabsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WebSearchResult>> search(String query) async {
    try {
      final res = await _client.functions.invoke(
        'web-search',
        body: {'query': query},
      );
      final results = parseWebSearchResponse(res.data);
      if (results.isEmpty) return results;

      final known = await _client.rpc<List<dynamic>>(
        'imported_song_ids',
        params: {'urls': results.map((r) => r.url.toString()).toList()},
      );
      final songIdByUrl = <String, String>{
        for (final row in known)
          (row as Map)['source_url'] as String: row['song_id'] as String,
      };
      return [
        for (final r in results) r.withSongId(songIdByUrl[r.url.toString()]),
      ];
    } catch (e) {
      throw CatalogException('Web search failed', e);
    }
  }

  @override
  Future<String> importTab({
    required String title,
    String? artist,
    required Uri sourceUrl,
    required WebTabSite site,
    required String instrumentSlug,
    required String chordPro,
  }) async {
    try {
      final songId = await _client.rpc<String>(
        'import_web_tab',
        params: {
          'p_title': title,
          'p_artist': artist,
          'p_source_url': sourceUrl.toString(),
          'p_source_site': site.id,
          'p_instrument_slug': instrumentSlug,
          'p_content': chordPro,
        },
      );
      return songId;
    } catch (e) {
      throw CatalogException('Saving the web tab failed', e);
    }
  }
}

/// Decodes the `web-search` function's `{results: [{title, url, description}]}`
/// body, keeping only results on an allowlisted site. Malformed entries are
/// skipped rather than failing the whole search.
List<WebSearchResult> parseWebSearchResponse(Object? body) {
  final results = body is Map ? body['results'] : null;
  if (results is! List) return const [];
  final out = <WebSearchResult>[];
  for (final item in results) {
    if (item is! Map) continue;
    final rawUrl = item['url'];
    if (rawUrl is! String) continue;
    final url = Uri.tryParse(rawUrl);
    if (url == null) continue;
    final site = WebTabSite.forUrl(url);
    if (site == null) continue;
    out.add(
      WebSearchResult(
        title: item['title'] is String ? item['title'] as String : '',
        url: url,
        description: item['description'] is String
            ? item['description'] as String
            : '',
        site: site,
      ),
    );
  }
  return out;
}
