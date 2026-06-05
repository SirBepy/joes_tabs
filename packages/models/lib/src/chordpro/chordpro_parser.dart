/// ChordPro -> [ChordSheet] parser. Pure Dart, no Flutter dependency.
library;

import 'chord_sheet.dart';

/// Parses ChordPro source text into a structured [ChordSheet].
///
/// Supported:
/// - Directives `{name: value}` and bare `{name}` (case-insensitive name).
///   `title`/`t`, `artist`/`a`/`subtitle`/`st`, `key`/`k`, `capo` are promoted
///   to typed fields; everything else lands in [ChordSheet.directives].
/// - Section directives (`start_of_chorus`/`soc`, `start_of_verse`/`sov`,
///   `start_of_bridge`/`sob`, and their `end_of_*` partners) become section
///   heading lines (using any provided label).
/// - Inline chords `[Chord]` interleaved with lyric text.
/// - Comment lines beginning with `#` become section headings when they look
///   like a label, otherwise comment lines.
/// - Blank lines are preserved as blank lines.
///
/// Malformed input never throws: unparseable directives are skipped, and stray
/// brackets are treated as literal text.
class ChordProParser {
  const ChordProParser._();

  static final RegExp _directive = RegExp(
    r'^\{\s*([^:}]+?)\s*(?::\s*(.*?))?\s*\}$',
  );

  /// Maps a section directive name to its human label prefix.
  static const Map<String, String> _sectionStarts = {
    'start_of_chorus': 'Chorus',
    'soc': 'Chorus',
    'start_of_verse': 'Verse',
    'sov': 'Verse',
    'start_of_bridge': 'Bridge',
    'sob': 'Bridge',
    'start_of_tab': 'Tab',
    'sot': 'Tab',
  };

  static const Set<String> _sectionEnds = {
    'end_of_chorus',
    'eoc',
    'end_of_verse',
    'eov',
    'end_of_bridge',
    'eob',
    'end_of_tab',
    'eot',
  };

  /// Parses [source] into a [ChordSheet].
  static ChordSheet parse(String source) {
    String? title;
    String? artist;
    String? key;
    int? capo;
    final directives = <String, String>{};
    final lines = <ChordLine>[];

    for (final raw in source.split('\n')) {
      final line = raw.replaceAll('\r', '');
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        lines.add(const ChordLine.blank());
        continue;
      }

      // Comment line.
      if (trimmed.startsWith('#')) {
        final text = trimmed.substring(1).trim();
        if (text.isEmpty) {
          lines.add(const ChordLine.blank());
        } else {
          lines.add(ChordLine(kind: ChordLineKind.comment, label: text));
        }
        continue;
      }

      // Directive line (a single {...} spanning the whole line).
      final dir = _directive.firstMatch(trimmed);
      if (dir != null) {
        final name = dir.group(1)!.trim().toLowerCase();
        final value = (dir.group(2) ?? '').trim();

        if (_sectionEnds.contains(name)) {
          // End-of-section: nothing to render.
          continue;
        }
        final sectionLabel = _sectionStarts[name];
        if (sectionLabel != null) {
          final label = value.isEmpty ? sectionLabel : value;
          lines.add(ChordLine.section(label));
          continue;
        }

        switch (name) {
          case 'title':
          case 't':
            title ??= value;
          case 'artist':
          case 'a':
          case 'subtitle':
          case 'st':
            artist ??= value;
          case 'key':
          case 'k':
            key ??= value;
          case 'capo':
            capo ??= int.tryParse(value);
          case 'comment':
          case 'c':
          case 'ci':
          case 'comment_italic':
            // A comment directive is a section/annotation label.
            if (value.isNotEmpty) lines.add(ChordLine.section(value));
          default:
            if (value.isNotEmpty) directives[name] = value;
        }
        continue;
      }

      // Otherwise a lyric line with inline [chords].
      lines.add(ChordLine.lyrics(_parseLyricLine(line)));
    }

    return ChordSheet(
      title: title,
      artist: artist,
      key: key,
      capo: capo,
      directives: directives,
      lines: lines,
    );
  }

  /// Splits a single lyric line into chord+lyric segments. A `[Chord]` marker
  /// attaches to the text that follows it, up to the next marker.
  static List<ChordSegment> _parseLyricLine(String line) {
    final segments = <ChordSegment>[];
    final buffer = StringBuffer();
    String? pendingChord;
    var sawChord = false;

    void flush() {
      final lyric = buffer.toString();
      if (pendingChord != null || lyric.isNotEmpty) {
        segments.add(ChordSegment(chord: pendingChord, lyric: lyric));
      }
      buffer.clear();
      pendingChord = null;
    }

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '[') {
        final close = line.indexOf(']', i);
        if (close > i) {
          // Close out the run before this chord, then start a new one.
          flush();
          pendingChord = line.substring(i + 1, close).trim();
          sawChord = true;
          i = close;
          continue;
        }
        // Unmatched '[': treat literally.
      }
      buffer.write(ch);
    }
    flush();

    if (segments.isEmpty) {
      // A line that was entirely whitespace inside brackets etc.
      return [ChordSegment(lyric: line)];
    }
    // If no chord ever appeared, collapse to a single plain-lyric segment so the
    // renderer does not reserve a chord row.
    if (!sawChord) {
      return [ChordSegment(lyric: line)];
    }
    return segments;
  }
}
