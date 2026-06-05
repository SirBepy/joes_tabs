import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  group('directives', () {
    test('title / artist / key / capo promoted to fields', () {
      final sheet = ChordProParser.parse(
        '{title: Amazing Grace}\n'
        '{artist: Traditional}\n'
        '{key: G}\n'
        '{capo: 2}\n',
      );
      expect(sheet.title, 'Amazing Grace');
      expect(sheet.artist, 'Traditional');
      expect(sheet.key, 'G');
      expect(sheet.capo, 2);
    });

    test('short directive aliases (t/a/k)', () {
      final sheet = ChordProParser.parse('{t: Song}\n{a: Me}\n{k: C}\n');
      expect(sheet.title, 'Song');
      expect(sheet.artist, 'Me');
      expect(sheet.key, 'C');
    });

    test('non-numeric capo is ignored', () {
      final sheet = ChordProParser.parse('{capo: nope}\n');
      expect(sheet.capo, isNull);
    });

    test('unknown directive lands in directives map', () {
      final sheet = ChordProParser.parse('{tempo: 120}\n');
      expect(sheet.directives['tempo'], '120');
    });

    test('comment directive {c:} becomes a section line', () {
      final sheet = ChordProParser.parse('{c: Verse 1}\nHello\n');
      final sections = sheet.lines
          .where((l) => l.kind == ChordLineKind.section)
          .toList();
      expect(sections.single.label, 'Verse 1');
    });

    test('section start/end directives', () {
      final sheet = ChordProParser.parse(
        '{start_of_chorus}\n[C]Sing\n{end_of_chorus}\n',
      );
      final sections = sheet.lines
          .where((l) => l.kind == ChordLineKind.section)
          .toList();
      expect(sections.single.label, 'Chorus');
      // end_of_chorus produces no line.
      expect(
        sheet.lines.where((l) => l.kind == ChordLineKind.lyrics).length,
        1,
      );
    });
  });

  group('lyric lines', () {
    test('inline chord attaches to following lyric run', () {
      final sheet = ChordProParser.parse('A[G]mazing [C]grace\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(line.segments, [
        const ChordSegment(lyric: 'A'),
        const ChordSegment(chord: 'G', lyric: 'mazing '),
        const ChordSegment(chord: 'C', lyric: 'grace'),
      ]);
    });

    test('leading chord with no preceding text', () {
      final sheet = ChordProParser.parse('[G]Hello\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(
        line.segments.single,
        const ChordSegment(chord: 'G', lyric: 'Hello'),
      );
    });

    test('standalone chord sequence (intro line)', () {
      final sheet = ChordProParser.parse('[A] [A] [F#m]\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      final chords = line.segments.map((s) => s.chord).toList();
      expect(chords, ['A', 'A', 'F#m']);
    });

    test('line with no chords is a single plain segment', () {
      final sheet = ChordProParser.parse('just lyrics here\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(
        line.segments.single,
        const ChordSegment(lyric: 'just lyrics here'),
      );
    });
  });

  group('robustness', () {
    test('blank lines preserved', () {
      final sheet = ChordProParser.parse('A\n\nB');
      expect(sheet.lines.where((l) => l.kind == ChordLineKind.blank).length, 1);
    });

    test('# comment line becomes a comment line', () {
      final sheet = ChordProParser.parse('# a note\n');
      final c = sheet.lines.firstWhere((l) => l.kind == ChordLineKind.comment);
      expect(c.label, 'a note');
    });

    test('unmatched bracket treated literally', () {
      final sheet = ChordProParser.parse('a [ b\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(line.segments.single.lyric, 'a [ b');
    });

    test('empty input does not throw', () {
      expect(() => ChordProParser.parse(''), returnsNormally);
    });
  });

  group('chordsUsed', () {
    test('distinct chords in first-seen order', () {
      final sheet = ChordProParser.parse('[G]a [C]b [G]c [D]d\n[Em]e\n');
      expect(sheet.chordsUsed, ['G', 'C', 'D', 'Em']);
    });

    test('spans multiple sections and ignores empty/standalone gaps', () {
      final sheet = ChordProParser.parse(
        '{soc}\n[C]Sing [G]out\n{eoc}\n'
        '{sov}\n[Am]Quiet [F]now\n{eov}\n'
        '[C] [C]\n', // re-used C across sections must not duplicate
      );
      expect(sheet.chordsUsed, ['C', 'G', 'Am', 'F']);
    });
  });

  group('directive robustness (edge cases)', () {
    test('first title/artist/key win (later duplicates ignored)', () {
      final sheet = ChordProParser.parse(
        '{title: First}\n{title: Second}\n'
        '{key: C}\n{key: G}\n',
      );
      expect(sheet.title, 'First');
      expect(sheet.key, 'C');
    });

    test('subtitle (st) and a (a) both map to artist', () {
      expect(ChordProParser.parse('{st: Trad}\n').artist, 'Trad');
      expect(ChordProParser.parse('{subtitle: Trad}\n').artist, 'Trad');
    });

    test('capo 0 and negative are kept (int.tryParse succeeds)', () {
      expect(ChordProParser.parse('{capo: 0}\n').capo, 0);
      expect(ChordProParser.parse('{capo: -1}\n').capo, -1);
    });

    test('bare directive with no value is dropped from the directives map', () {
      // {grid} has no value; the default branch only stores non-empty values.
      final sheet = ChordProParser.parse('{grid}\n');
      expect(sheet.directives, isEmpty);
    });

    test('directive name is case-insensitive and whitespace-tolerant', () {
      final sheet = ChordProParser.parse('{ TITLE :  Hi  }\n');
      expect(sheet.title, 'Hi');
    });

    test('short section aliases sov/sob and their ends', () {
      final sheet = ChordProParser.parse(
        '{sov}\n[C]v\n{eov}\n{sob}\n[G]b\n{eob}\n',
      );
      final labels = sheet.lines
          .where((l) => l.kind == ChordLineKind.section)
          .map((l) => l.label)
          .toList();
      expect(labels, ['Verse', 'Bridge']);
    });

    test('labeled section directive uses the provided label', () {
      final sheet = ChordProParser.parse('{start_of_chorus: Final Chorus}\n');
      final section = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.section,
      );
      expect(section.label, 'Final Chorus');
    });

    test('start_of_tab / sot map to a Tab section', () {
      final sheet = ChordProParser.parse('{sot}\ne|--0--|\n{eot}\n');
      final section = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.section,
      );
      expect(section.label, 'Tab');
    });

    test('comment_italic (ci) directive becomes a section label', () {
      final sheet = ChordProParser.parse('{ci: play softly}\n');
      final section = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.section,
      );
      expect(section.label, 'play softly');
    });

    test('empty comment directive {c:} produces no line', () {
      final sheet = ChordProParser.parse('{c: }\nHi\n');
      expect(
        sheet.lines.where((l) => l.kind == ChordLineKind.section),
        isEmpty,
      );
    });
  });

  group('lyric/line robustness (edge cases)', () {
    test('CRLF line endings are stripped, lines still parse', () {
      final sheet = ChordProParser.parse('{title: Hi}\r\n[C]Hello\r\n');
      expect(sheet.title, 'Hi');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(
        line.segments.single,
        const ChordSegment(chord: 'C', lyric: 'Hello'),
      );
    });

    test('empty brackets [] yield an empty-chord standalone segment', () {
      // indexOf finds the close, substring is empty -> trimmed to ''.
      final sheet = ChordProParser.parse('[]Hello\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(line.segments.single.chord, '');
      expect(line.segments.single.lyric, 'Hello');
      // An empty chord is excluded from chordsUsed.
      expect(sheet.chordsUsed, isEmpty);
    });

    test('trailing chord with no following lyric is a standalone segment', () {
      final sheet = ChordProParser.parse('end[G]\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(line.segments, [
        const ChordSegment(lyric: 'end'),
        const ChordSegment(chord: 'G', lyric: ''),
      ]);
    });

    test('whitespace inside a chord bracket is trimmed', () {
      final sheet = ChordProParser.parse('[ G ]Hello\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(line.segments.single.chord, 'G');
    });

    test('a line that is only an unmatched-open bracket is literal text', () {
      final sheet = ChordProParser.parse('[unclosed\n');
      final line = sheet.lines.firstWhere(
        (l) => l.kind == ChordLineKind.lyrics,
      );
      expect(line.segments.single.lyric, '[unclosed');
      expect(line.segments.single.chord, isNull);
    });

    test('whitespace-only line is preserved as a blank line', () {
      // No trailing newline so the only blank is the deliberate spaces line.
      final sheet = ChordProParser.parse('A\n   \nB');
      expect(sheet.lines.where((l) => l.kind == ChordLineKind.blank).length, 1);
    });

    test('a bare # (hash only) becomes a blank line, not a comment', () {
      // '#' alone (no trailing newline) is a single blank line, never a comment.
      final sheet = ChordProParser.parse('#');
      expect(sheet.lines.single.kind, ChordLineKind.blank);
    });

    test('input with no trailing newline still parses the last line', () {
      final sheet = ChordProParser.parse('{t: NoNL}\n[C]last');
      expect(sheet.title, 'NoNL');
      expect(sheet.chordsUsed, ['C']);
    });
  });
}
