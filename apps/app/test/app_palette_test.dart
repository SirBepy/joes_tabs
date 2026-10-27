import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

import 'package:joes_tabs_app/song/chord_diagram.dart';
import 'package:joes_tabs_app/song/chord_sheet_view.dart';
import 'package:joes_tabs_app/theme/app_palette.dart';
import 'package:joes_tabs_app/theme/app_theme.dart';
import 'package:joes_tabs_app/widgets/app_shell.dart';
import 'package:joes_tabs_app/widgets/song_tiles.dart';

Song _song() {
  final now = DateTime.utc(2026);
  return Song(
    id: 's1',
    title: 'Amazing Grace',
    artist: 'Traditional',
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pump(WidgetTester tester, ThemeData theme, Widget child) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      ),
    ),
  );
}

Color? _textColor(WidgetTester tester, String text) {
  final widget = tester.widget<Text>(find.text(text));
  return widget.style?.color;
}

Color? _containerColor(WidgetTester tester, Finder finder) {
  final box = tester.widget<Container>(finder).decoration as BoxDecoration;
  return box.color;
}

void main() {
  final sheet = ChordProParser.parse('{c: Verse}\n[G]Hello [C]world\n');

  for (final entry in {
    'light': (AppTheme.light, AppPalette.light),
    'dark': (AppTheme.dark, AppPalette.dark),
  }.entries) {
    final (theme, palette) = entry.value;

    group('${entry.key} palette', () {
      testWidgets('theme registers the matching extension', (tester) async {
        expect(theme.extension<AppPalette>(), same(palette));
      });

      testWidgets('chord sheet lyrics and section labels use palette ink', (
        tester,
      ) async {
        await _pump(tester, theme, ChordSheetView(sheet: sheet));
        expect(_textColor(tester, 'Hello '), palette.ink);
        expect(_textColor(tester, '[Verse]'), palette.ink);
      });

      testWidgets('song card uses palette card and ink', (tester) async {
        await _pump(tester, theme, SongCard(song: _song()));
        expect(_textColor(tester, 'Amazing Grace'), palette.ink);
        final card = find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        );
        expect(_containerColor(tester, card.first), palette.card);
      });

      testWidgets('chord diagram card uses palette card', (tester) async {
        await _pump(
          tester,
          theme,
          const ChordDiagram(chord: 'C', instrumentSlug: 'ukulele'),
        );
        final container = find.descendant(
          of: find.byType(ChordDiagram),
          matching: find.byType(Container),
        );
        expect(_containerColor(tester, container.first), palette.card);
      });

      testWidgets('section header bar and divider use the palette', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: theme,
              home: const Scaffold(appBar: SectionHeader(title: 'SAVED')),
            ),
          ),
        );
        final bar = tester.widget<AppBar>(find.byType(AppBar));
        expect(bar.backgroundColor, palette.sheet);
        final border = (bar.shape! as Border).bottom;
        expect(border.color, palette.divider);
      });
    });
  }

  test('light and dark palettes differ on every role', () {
    expect(AppPalette.light.ink, isNot(AppPalette.dark.ink));
    expect(AppPalette.light.sheet, isNot(AppPalette.dark.sheet));
    expect(AppPalette.light.card, isNot(AppPalette.dark.card));
    expect(AppPalette.light.chip, isNot(AppPalette.dark.chip));
    expect(AppPalette.light.mutedInk, isNot(AppPalette.dark.mutedInk));
  });

  test('lerp blends and copyWith overrides', () {
    final mid = AppPalette.light.lerp(AppPalette.dark, 1);
    expect(mid.ink, AppPalette.dark.ink);
    expect(AppPalette.light.copyWith(ink: Colors.red).ink, Colors.red);
  });
}
