/// The chord sites web search may surface, and what the app may do with each.
library;

/// A chord site on the web-tabs allowlist.
///
/// Membership and [parseable] follow the terms-of-service review in
/// `docs/superpowers/specs/2026-10-27-web-tabs-design.md`: a site is parseable
/// only when its terms don't forbid extraction or framing.
class WebTabSite {
  const WebTabSite({
    required this.id,
    required this.name,
    required this.host,
    required this.parseable,
    this.instrumentSlug,
  });

  /// Stable id stored in `tabs.source_site`.
  final String id;

  /// Display name, e.g. in "Source: Chordie".
  final String name;

  /// Registrable domain; subdomains (`www.`, `tabs.`) match too.
  final String host;

  /// Whether the app may open the page in its WebView and read the chords.
  /// False means the result only ever opens in the system browser.
  final bool parseable;

  /// The instrument the site's sheets are written for, or null when they are
  /// instrument-agnostic chord names.
  final String? instrumentSlug;

  static const ukuleleTabs = WebTabSite(
    id: 'ukulele-tabs',
    name: 'Ukulele-tabs.com',
    host: 'ukulele-tabs.com',
    parseable: true,
    instrumentSlug: 'ukulele',
  );

  static const chordie = WebTabSite(
    id: 'chordie',
    name: 'Chordie',
    host: 'chordie.com',
    parseable: true,
  );

  static const eChords = WebTabSite(
    id: 'e-chords',
    name: 'E-Chords',
    host: 'e-chords.com',
    parseable: true,
  );

  // Its terms forbid copying, derivative works and framing (sections 6.2, 6.4,
  // 14(a)), so it is listed for links only.
  static const ultimateGuitar = WebTabSite(
    id: 'ultimate-guitar',
    name: 'Ultimate Guitar',
    host: 'ultimate-guitar.com',
    parseable: false,
  );

  static const List<WebTabSite> all = [
    ukuleleTabs,
    chordie,
    eChords,
    ultimateGuitar,
  ];

  /// The allowlisted site serving [url], or null for any other host.
  static WebTabSite? forUrl(Uri url) {
    if (url.scheme != 'https' && url.scheme != 'http') return null;
    final host = url.host.toLowerCase();
    for (final site in all) {
      if (host == site.host || host.endsWith('.${site.host}')) return site;
    }
    return null;
  }

  /// The site with stored id [id], or null.
  static WebTabSite? byId(String? id) {
    for (final site in all) {
      if (site.id == id) return site;
    }
    return null;
  }
}

/// Splits a chord page or search-result title into song title and artist.
///
/// Chord sites pad titles with words like "Chords", "Ukulele" or the site name,
/// and join the two parts with " by " or " - " in either order. The artist is
/// null when the title doesn't say.
({String title, String? artist}) parseWebTabTitle(String raw) {
  var text = raw
      // Anything after a pipe or " @ " is the site name, not the song.
      .split(RegExp(r'\||\s@\s'))
      .first
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final noise = RegExp(
    r'\b(?:ukulele|uke|guitar|chords?|tabs?|tablature|lyrics|easy|'
    r'acoustic|version\s*\d*|ver\s*\d+|e-chords|chordie)\b',
    caseSensitive: false,
  );
  // Dangling separators left after the noise words are removed.
  String clean(String s) => s
      .replaceAll(noise, ' ')
      .replaceAll(RegExp(r'[()\[\]]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s\-:,]+|[\s\-:,]+$'), '')
      .trim();

  final by = RegExp(r'\s+by\s+', caseSensitive: false).firstMatch(text);
  if (by != null) {
    final title = clean(text.substring(0, by.start));
    final artist = clean(text.substring(by.end));
    return (title: title, artist: artist.isEmpty ? null : artist);
  }

  final parts = text
      .split(RegExp(r'\s+[-–]\s+'))
      .map(clean)
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length >= 2) return (title: parts[0], artist: parts[1]);

  text = clean(text);
  return (title: text, artist: null);
}
