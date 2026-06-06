import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/tuner/pitch.dart';
import 'package:joes_tabs_app/tuner/tuner_gauge.dart';

Future<void> _pump(WidgetTester t, Widget w) =>
    t.pumpWidget(MaterialApp(home: Scaffold(body: w)));

void main() {
  testWidgets('renders the center note and its chromatic neighbors', (t) async {
    await _pump(
      t,
      const TunerGauge(
        centerNote: 'G',
        cents: 0,
        zone: TuneZone.green,
        isInTune: true,
        active: true,
      ),
    );
    expect(find.text('G'), findsWidgets);
    expect(find.text('F#'), findsWidgets);
    expect(find.text('G#'), findsWidgets);
  });

  testWidgets('shows a dash for cents when inactive', (t) async {
    await _pump(
      t,
      const TunerGauge(
        centerNote: 'G',
        cents: 0,
        zone: TuneZone.red,
        isInTune: false,
        active: false,
      ),
    );
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('shows a signed cents number when active', (t) async {
    await _pump(
      t,
      const TunerGauge(
        centerNote: 'A',
        cents: -12,
        zone: TuneZone.amber,
        isInTune: false,
        active: true,
      ),
    );
    expect(find.text('-12¢'), findsOneWidget);
  });
}
