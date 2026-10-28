import 'package:http/http.dart' as http;
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
    this.artist,
    this.songId,
  });

  final String title;

  /// The artist as the site lists it, or null when only [title] carries it.
  final String? artist;
  final Uri url;
  final String description;
  final WebTabSite site;

  /// The catalog song this page was already imported into, if any. Such a
  /// result opens the stored song instead of the page.
  final String? songId;

  WebSearchResult withSongId(String? id) => WebSearchResult(
    title: title,
    artist: artist,
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

/// [WebTabsRepository] that searches ukulele-tabs.com's own search page from
/// the device. Nothing about the search touches our backend, so it works
/// signed out.
class SupabaseWebTabsRepository implements WebTabsRepository {
  SupabaseWebTabsRepository(this._client, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  @override
  Future<List<WebSearchResult>> search(String query) async {
    try {
      final res = await _http.get(ukuleleTabsSearchUrl(query));
      if (res.statusCode != 200) {
        throw http.ClientException('HTTP ${res.statusCode}', res.request?.url);
      }
      return ukuleleTabsSearchResults(res.body);
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

/// The readable results on a ukulele-tabs.com search page. Tablature-only
/// sheets are dropped: they carry no chord names for the reader to convert.
List<WebSearchResult> ukuleleTabsSearchResults(String html) => [
  for (final hit in parseUkuleleTabsSearch(html))
    if (hit.hasChords)
      WebSearchResult(
        title: hit.title,
        artist: hit.artist,
        url: hit.url,
        description: '',
        site: WebTabSite.ukuleleTabs,
      ),
];
