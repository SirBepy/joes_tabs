/// Shared domain models for Joes Tabs.
///
/// Pure-Dart, immutable models mirroring the Supabase Postgres schema. JSON
/// serialization uses snake_case keys to match the DB columns.
library;

export 'src/chordpro/chord_catalog.dart';
export 'src/chordpro/chord_sheet.dart';
export 'src/chordpro/chord_shapes.dart';
export 'src/chordpro/chordpro_parser.dart';
export 'src/chordpro/transposer.dart';
export 'src/enums.dart';
export 'src/instrument.dart';
export 'src/song.dart';
export 'src/song_with_tabs.dart';
export 'src/tab.dart';
export 'src/web/chords_over_lyrics.dart';
export 'src/web/ukulele_tabs_search.dart';
export 'src/web/web_tab_sites.dart';
