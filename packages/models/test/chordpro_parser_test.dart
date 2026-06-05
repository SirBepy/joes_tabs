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
  });
}
