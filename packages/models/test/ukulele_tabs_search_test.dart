import 'package:models/models.dart';
import 'package:test/test.dart';

// Synthetic rows in the shape of the site's search page (2026-10-27),
// including its stray `</span>` inside the title anchor.
const _page = '''
<ul class="resp_list"><li><img src="/images/flags/pl.png" alt="Poland" />
<a href="/uke-songs/Some+Band-uke-tabs.html">Some Band</a></li></ul>
<ul class="resp_list"><li><div class="song_res"><span class="tabtype chrd">chords</span>&nbsp; <a href="/uke-songs/some-band/first-song-uke-tab-101.html">First Song (theme)</span></a> - <em><a class="parenth" href="/uke-songs/Some+Band-uke-tabs.html">Some Band</a></em>
</div><span class="starslist"></span></li>
<li><div class="song_res"><span class="tabtype tab">tab</span>&nbsp; <a href="/uke-songs/r-amp-b/rock-amp-roll-uke-tab-102.html">Rock &amp; Roll &#39;Live&#x27;</span></a> - <em><a class="parenth" href="/x.html">R&amp;B Group</a></em>
</div></li>
<li><div class="song_res"><span class="tabtype mix">mix</span>&nbsp; <a href="/uke-songs/solo/no-artist-uke-tab-103.html">No Artist</a>
</div></li>
<li><div class="song_res"><span class="tabtype chrd">chords</span> <a href="/elsewhere.html">Not a song</a></div></li>
</ul>
''';

void main() {
  group('parseUkuleleTabsSearch', () {
    final hits = parseUkuleleTabsSearch(_page);

    test('reads every song row in page order and skips the rest', () {
      expect(hits.map((h) => h.title), [
        'First Song (theme)',
        "Rock & Roll 'Live'",
        'No Artist',
      ]);
    });

    test('keeps the artist, absolute url and sheet type', () {
      expect(hits[0].artist, 'Some Band');
      expect(
        hits[0].url.toString(),
        'https://www.ukulele-tabs.com/uke-songs/some-band/first-song-uke-tab-101.html',
      );
      expect(hits[0].kind, 'chrd');
      expect(hits[1].artist, 'R&B Group');
      expect(hits[1].kind, 'tab');
      expect(hits[2].artist, isNull);
    });

    test('only chord and mixed sheets count as having chords', () {
      expect(hits.map((h) => h.hasChords), [true, false, true]);
    });

    test('a page without results yields nothing', () {
      expect(parseUkuleleTabsSearch('<html><body>none</body></html>'), isEmpty);
    });
  });

  test('ukuleleTabsSearchUrl encodes the trimmed query', () {
    expect(
      ukuleleTabsSearchUrl('  steven universe ').toString(),
      'https://www.ukulele-tabs.com/search-uke-chords.html?find=steven+universe',
    );
  });
}
