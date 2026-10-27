import 'package:data/data.dart';
import 'package:models/models.dart';

import 'web_tab_extraction.dart';

/// Turns one extraction-script message from the WebView into a stored song.
class WebTabImporter {
  const WebTabImporter({
    required this.repository,
    required this.url,
    required this.site,
    required this.resultTitle,
    required this.instrumentSlug,
  });

  final WebTabsRepository repository;
  final Uri url;
  final WebTabSite site;
  final String resultTitle;

  /// Used when [site] doesn't write for one instrument.
  final String instrumentSlug;

  /// The imported song's id, or null when the page held no chord sheet. Backend
  /// failures surface as the repository's [CatalogException].
  Future<String?> import(String message) async {
    final draft = webTabDraftFromMessage(message, resultTitle: resultTitle);
    if (draft == null) return null;
    return repository.importTab(
      title: draft.title,
      artist: draft.artist,
      sourceUrl: url,
      site: site,
      instrumentSlug: site.instrumentSlug ?? instrumentSlug,
      chordPro: draft.chordPro,
    );
  }
}
