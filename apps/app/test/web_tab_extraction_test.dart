import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/web_tabs/web_tab_extraction.dart';
import 'package:joes_tabs_app/web_tabs/web_song_reader.dart';
import 'package:models/models.dart';

String _message({String title = '', String text = ''}) =>
    jsonEncode({'title': title, 'text': text});

void main() {
  group('webTabExtractionScript', () {
    test('posts to the channel and falls back to the generic reader', () {
      for (final site in WebTabSite.all.where((s) => s.parseable)) {
        final script = webTabExtractionScript(site);
        expect(script, contains('$kWebTabChannel.postMessage'));
        expect(script, contains('function generic()'));
      }
    });

    test('uses each site\'s own selector', () {
      expect(
        webTabExtractionScript(WebTabSite.ukuleleTabs),
        contains("querySelector('a.chord')"),
      );
      expect(
        webTabExtractionScript(WebTabSite.chordie),
        contains('.chordline, .textline'),
      );
      expect(webTabExtractionScript(WebTabSite.eChords), contains('pre#core'));
    });
  });

  group('webTabDraftFromMessage', () {
    test('converts chords-over-lyrics, naming the song from the result', () {
      final draft = webTabDraftFromMessage(
        _message(
          title: 'Some page heading',
          text: '[Intro]\nC  G\n\nC          G\nIf I could begin to be',
        ),
        resultTitle: 'Love Like You Ukulele Tabs by Steven Universe',
      )!;
      expect(draft.title, 'Love Like You');
      expect(draft.artist, 'Steven Universe');
      expect(draft.chordPro, startsWith('{title: Love Like You}\n'));
      expect(draft.chordPro, contains('[C]If I could [G]begin to be'));
    });

    test('falls back to the page heading for a missing artist', () {
      final draft = webTabDraftFromMessage(
        _message(title: 'Riptide - Vance Joy', text: '[Am]I was scared'),
        resultTitle: 'Riptide chords',
      )!;
      expect(draft.title, 'Riptide');
      expect(draft.artist, 'Vance Joy');
    });

    test('a page without chords is not a draft', () {
      expect(
        webTabDraftFromMessage(
          _message(title: 'Just a moment...', text: 'Checking your browser'),
          resultTitle: 'Love Like You',
        ),
        isNull,
      );
      expect(
        webTabDraftFromMessage(_message(), resultTitle: 'Love Like You'),
        isNull,
      );
      expect(
        webTabDraftFromMessage('not json', resultTitle: 'Love Like You'),
        isNull,
      );
    });
  });

  group('webSongFromMessage', () {
    final url = Uri.parse(
      'https://www.ukulele-tabs.com/uke-songs/rebecca-sugar/love-like-you-uke-tab-1.html',
    );

    test('builds an in-memory ukulele song whose id is the page URL', () {
      final song = webSongFromMessage(
        _message(text: 'C\nIf I could'),
        url: url,
        site: WebTabSite.ukuleleTabs,
        resultTitle: 'Love Like You (steven Universe)',
        resultArtist: 'Rebecca Sugar',
      )!;

      expect(song.song.id, url.toString());
      expect(song.song.title, 'Love Like You (steven Universe)');
      expect(song.song.artist, 'Rebecca Sugar');
      final tab = song.tabs.single;
      expect(tab.songId, url.toString());
      expect(tab.instrumentId, ChordShapes.ukulele);
      expect(tab.sourceUrl, url.toString());
      expect(tab.sourceSite, 'ukulele-tabs');
      expect(tab.status, TabStatus.published);
      expect(tab.content, contains('[C]If I could'));
    });

    test('a page without chords is no song', () {
      expect(
        webSongFromMessage(
          _message(text: 'Just a moment...'),
          url: url,
          site: WebTabSite.ukuleleTabs,
          resultTitle: 'X',
        ),
        isNull,
      );
    });
  });
}
