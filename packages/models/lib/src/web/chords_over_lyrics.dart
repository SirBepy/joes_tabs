/// Converts the plain-text chord sheets found on chord sites into ChordPro.
library;

/// Turns "chords-over-lyrics" text (a line of chords sitting above the lyric it
/// belongs to, aligned by column) into ChordPro with inline `[X]` markers.
///
/// Text that is already inline ChordPro (`[Am]I was scared...`) passes through
/// unchanged, so one entry point covers both formats chord sites use.
class ChordsOverLyrics {
  const ChordsOverLyrics._();

  // A chord: root, optional accidental, any run of known quality tokens, and an
  // optional slash bass. Quality tokens are whole words (`maj`, `sus`, `add`)
  // rather than free letters so lyric words like "Bad" or "Each" never match.
  static final RegExp _chord = RegExp(
    r'^[A-G][#b]?(?:maj|min|dim|aug|sus|add|m|M|\+|°|ø|[0-9]|#|b|\(|\))*'
    r'(?:/[A-G][#b]?)?$',
  );

  // Tokens that may sit on a chord line without being chords: bar lines,
  // repeat counts, "no chord" marks. They are dropped from the output.
  static final RegExp _chordLineFiller = RegExp(
    r'^(?:\||\|\||-+|/|%|\.+|x\d+|\(x\d+\)|\d+x|N\.?C\.?)$',
    caseSensitive: false,
  );

  static final RegExp _bracketHeader = RegExp(r'^\[([^\]]+)\]$');

  static final RegExp _colonHeader = RegExp(
    r'^(intro|outro|verse|chorus|pre-chorus|prechorus|bridge|interlude|instrumental|solo|refrain|coda|ending|hook)'
    r'(\s*\d+)?\s*:?$',
    caseSensitive: false,
  );

  /// Whether [token] is a chord symbol.
  static bool isChord(String token) => _chord.hasMatch(token);

  /// Whether [line] holds only chords (plus bar lines / repeat marks), with at
  /// least one real chord.
  static bool isChordLine(String line) {
    final tokens = line.trim().split(RegExp(r'\s+'));
    if (tokens.length == 1 && tokens.first.isEmpty) return false;
    var chords = 0;
    for (final token in tokens) {
      if (isChord(token)) {
        chords++;
      } else if (!_chordLineFiller.hasMatch(token)) {
        return false;
      }
    }
    return chords > 0;
  }

  /// Converts [text] to ChordPro, prefixed with `{title}` / `{artist}`
  /// directives when given.
  static String toChordPro(String text, {String? title, String? artist}) {
    final out = <String>[];
    if (title != null && title.trim().isNotEmpty) {
      out.add('{title: ${_directiveValue(title)}}');
    }
    if (artist != null && artist.trim().isNotEmpty) {
      out.add('{artist: ${_directiveValue(artist)}}');
    }

    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\t', '    ')
        // Non-breaking spaces are common in scraped HTML and break column math.
        .replaceAll(String.fromCharCode(0xa0), ' ')
        .split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        out.add('');
        continue;
      }

      final header = _header(trimmed);
      if (header != null) {
        out.add('{comment: ${_directiveValue(header)}}');
        continue;
      }

      if (isChordLine(line)) {
        final next = i + 1 < lines.length ? lines[i + 1].trimRight() : '';
        if (_isLyric(next)) {
          out.add(_merge(line, next));
          i++;
        } else {
          out.add(_chordsOnly(line));
        }
        continue;
      }

      out.add(line);
    }

    // Collapse the runs of blank lines that page markup tends to leave behind.
    final collapsed = <String>[];
    for (final l in out) {
      if (l.isEmpty && (collapsed.isEmpty || collapsed.last.isEmpty)) continue;
      collapsed.add(l);
    }
    while (collapsed.isNotEmpty && collapsed.last.isEmpty) {
      collapsed.removeLast();
    }
    return collapsed.join('\n');
  }

  /// A section label from `[Verse 1]` or `Chorus:`, or null. A bracketed chord
  /// (`[Am]` alone on a line) is ChordPro already, not a header.
  static String? _header(String trimmed) {
    final bracket = _bracketHeader.firstMatch(trimmed);
    if (bracket != null) {
      final inner = bracket.group(1)!.trim();
      return isChord(inner) ? null : inner;
    }
    if (_colonHeader.hasMatch(trimmed)) {
      return trimmed.endsWith(':')
          ? trimmed.substring(0, trimmed.length - 1).trim()
          : trimmed;
    }
    return null;
  }

  static bool _isLyric(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (_header(trimmed) != null) return false;
    return !isChordLine(line);
  }

  /// Inserts each chord of [chordLine] into [lyric] at the chord's column.
  static String _merge(String chordLine, String lyric) {
    final placed = <({int column, String chord})>[];
    for (final m in RegExp(r'\S+').allMatches(chordLine)) {
      final token = m.group(0)!;
      if (isChord(token)) placed.add((column: m.start, chord: token));
    }

    var result = lyric;
    final lastColumn = placed.isEmpty ? 0 : placed.last.column;
    if (result.length < lastColumn) result = result.padRight(lastColumn);
    // Right to left so earlier insertions don't shift later columns.
    for (final p in placed.reversed) {
      result =
          '${result.substring(0, p.column)}[${p.chord}]'
          '${result.substring(p.column)}';
    }
    return result.trimRight();
  }

  static String _chordsOnly(String chordLine) => chordLine
      .trim()
      .split(RegExp(r'\s+'))
      .where(isChord)
      .map((c) => '[$c]')
      .join(' ');

  static String _directiveValue(String value) =>
      value.replaceAll(RegExp(r'[{}]'), '').replaceAll('\n', ' ').trim();
}
