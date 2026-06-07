import 'package:joes_tabs_app/widgets/scrollable_chip_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders label + options and reports taps', (tester) async {
    var picked = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollableChipRow(
            label: 'Note',
            options: const ['C', 'D', 'E'],
            selected: 'C',
            onSelected: (v) => picked = v,
          ),
        ),
      ),
    );
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    await tester.tap(find.text('D'));
    expect(picked, 'D');
  });
}
