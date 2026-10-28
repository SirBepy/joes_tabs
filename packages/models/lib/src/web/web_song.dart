/// Songs that live on ukulele-tabs.com rather than in our catalog.
///
/// Until the site grants permission to store its tabs (CGU art. 3.2), the app
/// keeps only links: a web song's id IS its page URL, so favorites, recent
/// views and routes carry the link and nothing of the sheet itself.
library;

import '../song.dart';

/// Whether [songId] names a page on the web rather than a catalog row.
bool isWebSongId(String songId) =>
    songId.startsWith('https://') || songId.startsWith('http://');

final _songPath = RegExp(r'^/uke-songs/([^/]+)/(.+?)-uke-tab-\d+\.html$');

/// A [Song] for the page at [url], for lists that only hold the link. [title]
/// and [artist] come from a search result when one is at hand; otherwise they
/// are read back from the URL slug (`/uke-songs/<artist>/<title>-uke-tab-<n>`),
/// which loses punctuation but needs nothing stored.
Song webSongStub(String url, {String? title, String? artist}) {
  final match = _songPath.firstMatch(Uri.tryParse(url)?.path ?? '');
  final epoch = DateTime.utc(2026);
  return Song(
    id: url,
    title: title ?? (match == null ? url : _unslug(match.group(2)!)),
    artist: artist ?? (match == null ? '' : _unslug(match.group(1)!)),
    createdAt: epoch,
    updatedAt: epoch,
  );
}

String _unslug(String slug) => Uri.decodeComponent(slug)
    .split(RegExp(r'[-+_\s]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');
