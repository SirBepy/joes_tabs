import 'dart:convert';

import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/web_tabs/web_tab_extraction.dart';
import 'package:joes_tabs_app/web_tabs/web_tab_importer.dart';
import 'package:models/models.dart';

String _message({String title = '', String text = ''}) =>
    jsonEncode({'title': title, 'text': text});

class _RecordingRepo implements WebTabsRepository {
  Map<String, Object?>? imported;

  @override
  Future<String> importTab({
    required String title,
    String? artist,
    required Uri sourceUrl,
    required WebTabSite site,
    required String instrumentSlug,
    required String chordPro,
  }) async {
    imported = {
      'title': title,
      'artist': artist,
      'url': sourceUrl.toString(),
      'site': site.id,
      'instrument': instrumentSlug,
      'chordPro': chordPro,
    };
    return 'song-1';
  }

  @override
  Future<List<WebSearchResult>> search(String query) async => const [];
}

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

  group('WebTabImporter', () {
    test('stores the draft with the site\'s own instrument', () async {
      final repo = _RecordingRepo();
      final songId = await WebTabImporter(
        repository: repo,
        url: Uri.parse('https://ukulele-tabs.com/love.html'),
        site: WebTabSite.ukuleleTabs,
        resultTitle: 'Love Like You by Steven Universe',
        instrumentSlug: 'guitar',
      ).import(_message(text: 'C\nIf I could'));

      expect(songId, 'song-1');
      expect(repo.imported, {
        'title': 'Love Like You',
        'artist': 'Steven Universe',
        'url': 'https://ukulele-tabs.com/love.html',
        'site': 'ukulele-tabs',
        'instrument': 'ukulele',
        'chordPro':
            '{title: Love Like You}\n{artist: Steven Universe}\n[C]If I could',
      });
    });

    test('uses the user\'s instrument for instrument-agnostic sites', () async {
      final repo = _RecordingRepo();
      await WebTabImporter(
        repository: repo,
        url: Uri.parse('https://www.chordie.com/chord.pere/riptide'),
        site: WebTabSite.chordie,
        resultTitle: 'Riptide - Vance Joy',
        instrumentSlug: 'guitar',
      ).import(_message(text: '[Am]I was scared'));

      expect(repo.imported!['instrument'], 'guitar');
    });

    test('imports nothing when the page has no chords', () async {
      final repo = _RecordingRepo();
      final songId = await WebTabImporter(
        repository: repo,
        url: Uri.parse('https://e-chords.com/x'),
        site: WebTabSite.eChords,
        resultTitle: 'X',
        instrumentSlug: 'guitar',
      ).import(_message(text: 'Just a moment...'));

      expect(songId, isNull);
      expect(repo.imported, isNull);
    });
  });
}
