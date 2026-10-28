import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  group('isChord', () {
    test('accepts common chord symbols', () {
      for (final c in [
        'A',
        'Am',
        'C#m',
        'Bb',
        'G7',
        'Cmaj7',
        'Asus4',
        'Dm7b5',
        'Am7/G',
        'F#/A#',
        'Cadd9',
        'Edim',
        'Gaug',
        'E7(#9)',
      ]) {
        expect(ChordsOverLyrics.isChord(c), isTrue, reason: c);
      }
    });

    test('rejects lyric words that start with a note letter', () {
      for (final w in ['Bad', 'Each', 'Garnet', 'Am,', 'Bee', 'Cry', 'Dance']) {
        expect(ChordsOverLyrics.isChord(w), isFalse, reason: w);
      }
    });
  });

  group('isChordLine', () {
    test('a line of spaced chords', () {
      expect(ChordsOverLyrics.isChordLine('Cm        Eb      Bb'), isTrue);
    });

    test('bar lines and repeat marks are allowed', () {
      expect(ChordsOverLyrics.isChordLine('| Am | G | x2'), isTrue);
    });

    test('a lyric line is not a chord line', () {
      expect(ChordsOverLyrics.isChordLine('Am I the only one'), isFalse);
      expect(ChordsOverLyrics.isChordLine(''), isFalse);
    });

    test('filler alone is not a chord line', () {
      expect(ChordsOverLyrics.isChordLine('| | x2'), isFalse);
    });
  });

  group('toChordPro', () {
    test('places chords at their columns in the lyric below', () {
      final out = ChordsOverLyrics.toChordPro(
        'Am                G\n'
        'I was scared of dentists and the dark',
      );
      expect(out, '[Am]I was scared of de[G]ntists and the dark');
    });

    test('reads chords wrapped in parentheses (ukulele-tabs.com style)', () {
      final out = ChordsOverLyrics.toChordPro(
        '            (F)\n'
        'All I want to do\n'
        '(Am   G7)\n'
        'Is see you',
      );
      expect(
        out,
        'All I want to[F] do\n'
        'I[Am]s see[G7] you',
      );
    });

    test('pads a lyric shorter than its last chord', () {
      final out = ChordsOverLyrics.toChordPro('C       G\nHi');
      expect(out, '[C]Hi      [G]');
    });

    test('a chord line with no lyric below stays a chord-only line', () {
      final out = ChordsOverLyrics.toChordPro(
        'Ab G Cm Eb Bb\n\nThis is Garnet.',
      );
      expect(out, '[Ab] [G] [Cm] [Eb] [Bb]\n\nThis is Garnet.');
    });

    test('two chord lines in a row do not merge into each other', () {
      final out = ChordsOverLyrics.toChordPro('C  G\nAm    F\nWords here');
      expect(out, '[C] [G]\n[Am]Words [F]here');
    });

    test('bracket and colon headers become section comments', () {
      final out = ChordsOverLyrics.toChordPro(
        '[Intro]\nC G\n\nChorus:\nF\nLa la',
      );
      expect(out, '{comment: Intro}\n[C] [G]\n\n{comment: Chorus}\n[F]La la');
    });

    test('a bracketed chord alone on a line is not a header', () {
      expect(ChordsOverLyrics.toChordPro('[Am]'), '[Am]');
    });

    test('inline ChordPro passes through unchanged', () {
      const inline = '[Am]I was scared of dentis[G]ts and the dark,';
      expect(ChordsOverLyrics.toChordPro(inline), inline);
    });

    test('drops bar lines and repeat marks from merged chords', () {
      final out = ChordsOverLyrics.toChordPro('| C   G | x2\nHello there');
      expect(out, 'He[C]llo [G]there');
    });

    test('adds title and artist directives, stripping braces', () {
      final out = ChordsOverLyrics.toChordPro(
        'C\nHi',
        title: 'Love {Like} You',
        artist: 'Steven Universe',
      );
      expect(out, '{title: Love Like You}\n{artist: Steven Universe}\n[C]Hi');
    });

    test('normalises CRLF, tabs and non-breaking spaces, collapses blanks', () {
      final nbsp3 = String.fromCharCode(0xa0) * 3;
      final out = ChordsOverLyrics.toChordPro(
        'C${nbsp3}G\r\nabc def\r\n\r\n\r\n\r\nEnd\r\n\r\n',
      );
      expect(out, '[C]abc [G]def\n\nEnd');
    });

    test('output parses into chord segments', () {
      final sheet = ChordProParser.parse(
        ChordsOverLyrics.toChordPro(
          'Am       G\nI was scared',
          title: 'Riptide',
          artist: 'Vance Joy',
        ),
      );
      expect(sheet.title, 'Riptide');
      expect(sheet.artist, 'Vance Joy');
      expect(sheet.chordsUsed, ['Am', 'G']);
    });
  });
}
