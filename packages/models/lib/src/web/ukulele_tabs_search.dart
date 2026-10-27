/// Reading ukulele-tabs.com's own search page, fetched on the user's device.
library;

/// One song row from a ukulele-tabs.com search page.
class UkuleleTabsHit {
  const UkuleleTabsHit({
    required this.title,
    required this.url,
    required this.kind,
    this.artist,
  });

  final String title;
  final String? artist;
  final Uri url;

  /// The site's sheet type: `chrd` (chords over lyrics), `tab` (tablature) or
  /// `mix`. Only `chrd` and `mix` carry chord names the reader can convert.
  final String kind;

  bool get hasChords => kind == 'chrd' || kind == 'mix';
}

/// The search page for [query]. robots.txt allows it; the site caps results
/// at 50 songs with no pagination.
Uri ukuleleTabsSearchUrl(String query) => Uri.https(
  'www.ukulele-tabs.com',
  '/search-uke-chords.html',
  {'find': query.trim()},
);

// Each result is `<div class="song_res"><span class="tabtype KIND">..</span>
// <a href="/uke-songs/<artist>/<title>-uke-tab-<n>.html">TITLE</a> - <em>
// <a class="parenth" ..>ARTIST</a></em></div>`. The title anchor's markup is
// sloppy (a stray `</span>` before `</a>`), so the text is taken up to `</a>`
// and stripped of tags.
final _songRes = RegExp(
  r'<div class="song_res">(.*?)</div>',
  dotAll: true,
  caseSensitive: false,
);
final _kind = RegExp(r'class="tabtype\s+(\w+)"', caseSensitive: false);
final _songLink = RegExp(
  r'''<a\s+href="(/uke-songs/[^"]+-uke-tab-\d+\.html)"[^>]*>(.*?)</a>''',
  dotAll: true,
  caseSensitive: false,
);
final _artistLink = RegExp(
  r'''<a\s+class="parenth"[^>]*>(.*?)</a>''',
  dotAll: true,
  caseSensitive: false,
);

/// The song rows in a ukulele-tabs.com search page's [html], in page order.
/// Rows without a song link are skipped, so artist-only rows and markup
/// changes yield fewer hits rather than an exception.
List<UkuleleTabsHit> parseUkuleleTabsSearch(String html) {
  final hits = <UkuleleTabsHit>[];
  for (final row in _songRes.allMatches(html)) {
    final body = row.group(1)!;
    final link = _songLink.firstMatch(body);
    if (link == null) continue;
    final title = _text(link.group(2)!);
    if (title.isEmpty) continue;
    final artist = _artistLink.firstMatch(body);
    final artistText = artist == null ? '' : _text(artist.group(1)!);
    hits.add(
      UkuleleTabsHit(
        title: title,
        artist: artistText.isEmpty ? null : artistText,
        url: Uri.https('www.ukulele-tabs.com', link.group(1)!),
        kind: _kind.firstMatch(body)?.group(1)?.toLowerCase() ?? 'chrd',
      ),
    );
  }
  return hits;
}

String _text(String markup) => decodeHtmlEntities(
  markup.replaceAll(RegExp(r'<[^>]*>'), ''),
).replaceAll(RegExp(r'\s+'), ' ').trim();

const _named = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
};

/// Decodes the named entities above plus decimal and hex numeric ones.
String decodeHtmlEntities(String s) =>
    s.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (m) {
      final e = m.group(1)!;
      if (e.startsWith('#x') || e.startsWith('#X')) {
        return String.fromCharCode(int.parse(e.substring(2), radix: 16));
      }
      if (e.startsWith('#')) {
        return String.fromCharCode(int.parse(e.substring(1)));
      }
      return _named[e.toLowerCase()] ?? m.group(0)!;
    });
