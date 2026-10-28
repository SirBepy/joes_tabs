import 'package:models/models.dart';

import 'web_tab_extraction.dart';

/// Turns the WebView extraction message for the page at [url] into an
/// in-memory song whose id is [url], or null when the page held no chord
/// sheet. Nothing is stored: the result lives in `webSongsProvider` for this
/// session only.
SongWithTabs? webSongFromMessage(
  String message, {
  required Uri url,
  required WebTabSite site,
  required String resultTitle,
  String? resultArtist,
}) {
  final draft = webTabDraftFromMessage(
    message,
    resultTitle: resultTitle,
    resultArtist: resultArtist,
  );
  if (draft == null) return null;
  final id = url.toString();
  final now = DateTime.now().toUtc();
  final sheet = ChordProParser.parse(draft.chordPro);
  return SongWithTabs(
    song: webSongStub(id, title: draft.title, artist: draft.artist ?? ''),
    tabs: [
      Tab(
        id: id,
        songId: id,
        // The viewer resolves an unknown instrument id to ukulele shapes,
        // which is what every ukulele-tabs.com sheet is written for.
        instrumentId: site.instrumentSlug ?? ChordShapes.ukulele,
        content: draft.chordPro,
        originalKey: sheet.key ?? '',
        source: TabSource.imported,
        status: TabStatus.published,
        sourceUrl: id,
        sourceSite: site.id,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}
