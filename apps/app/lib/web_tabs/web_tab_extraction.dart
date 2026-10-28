import 'dart:convert';

import 'package:models/models.dart';

/// Name of the JavaScript channel the extraction script posts its result to.
const String kWebTabChannel = 'JoesTabs';

/// JavaScript that reads the chord sheet out of an already-loaded page of
/// [site] and posts `{title, text}` as JSON to [kWebTabChannel].
///
/// Runs inside the user's own WebView after a normal page load; it never
/// fetches anything. Each site gets a specific reader (selectors from the
/// 2026-10-27 spike) with the generic "largest <pre> that holds chords" reader
/// as the fallback, so a site layout change degrades instead of breaking.
String webTabExtractionScript(WebTabSite site) {
  final specific = switch (site.id) {
    // Chords-over-lyrics in a <pre>; chords are <a class="chord"> links.
    'ukulele-tabs' =>
      r'''
      var pres = Array.from(document.querySelectorAll('pre'))
        .filter(function (p) { return p.querySelector('a.chord'); });
      pres.sort(function (a, b) {
        return b.querySelectorAll('a.chord').length -
          a.querySelectorAll('a.chord').length;
      });
      return pres.length ? pres[0].innerText : '';
    ''',
    // Inline [Am] markers: one div per line, chords inside .absc spans with
    // the brackets as separate .bracket spans, so textContent is ChordPro.
    'chordie' =>
      r'''
      var song = document.querySelector('#song');
      if (!song) return '';
      var lines = Array.from(song.querySelectorAll('.chordline, .textline'));
      // Text lines before the first chord line are the title/credit header.
      var first = lines.findIndex(function (l) {
        return l.classList.contains('chordline');
      });
      if (first < 0) return '';
      return lines.slice(first)
        .map(function (l) { return l.textContent; }).join('\n');
    ''',
    'e-chords' =>
      r'''
      var core = document.querySelector('pre#core');
      return core ? core.innerText : '';
    ''',
    _ => "return '';",
  };

  return '''
(function () {
  function specific() {
    $specific
  }
  function generic() {
    var best = '';
    Array.from(document.querySelectorAll('pre')).forEach(function (p) {
      var t = p.innerText || '';
      if (t.split('\\n').length > 3 && t.length > best.length) best = t;
    });
    return best;
  }
  var text = '';
  try { text = specific(); } catch (e) { text = ''; }
  if (!text || !text.trim()) text = generic();
  var h1 = document.querySelector('h1');
  $kWebTabChannel.postMessage(JSON.stringify({
    title: (h1 && h1.innerText) || document.title || '',
    text: text || ''
  }));
})();
''';
}

/// A parsed web tab.
class WebTabDraft {
  const WebTabDraft({
    required this.title,
    required this.artist,
    required this.chordPro,
  });

  final String title;
  final String? artist;
  final String chordPro;
}

/// Turns the extraction script's message into a [WebTabDraft], or null when
/// the page held no usable chord sheet (a challenge page, a layout the readers
/// don't know, an empty or chordless block).
///
/// Title and artist come from the search result's title when it names them,
/// since search titles are more uniform than page headings; the page heading
/// fills whatever the result title lacks. A [resultArtist] means the result
/// already split the two (ukulele-tabs.com's own search), so both are taken
/// as given.
WebTabDraft? webTabDraftFromMessage(
  String message, {
  required String resultTitle,
  String? resultArtist,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(message);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final text = decoded['text'];
  if (text is! String || text.trim().isEmpty) return null;
  final pageTitle = decoded['title'] is String
      ? decoded['title'] as String
      : '';

  final fromResult = resultArtist != null && resultTitle.trim().isNotEmpty
      ? (title: resultTitle.trim(), artist: resultArtist)
      : parseWebTabTitle(resultTitle);
  final fromPage = parseWebTabTitle(pageTitle);
  final title = fromResult.title.isNotEmpty ? fromResult.title : fromPage.title;
  if (title.isEmpty) return null;
  final artist = fromResult.artist ?? fromPage.artist;

  final chordPro = ChordsOverLyrics.toChordPro(
    text,
    title: title,
    artist: artist,
  );
  if (ChordProParser.parse(chordPro).chordsUsed.isEmpty) return null;
  return WebTabDraft(title: title, artist: artist, chordPro: chordPro);
}
