import 'package:flutter_test/flutter_test.dart';
import 'package:joes_tabs_app/tuner/tone_player.dart';
import 'package:models/models.dart';

void main() {
  test('maps ukulele strings to the right tone assets', () {
    expect(toneAssetFor(ChordShapes.ukulele, 0), 'assets/tones/uke_g4.wav');
    expect(toneAssetFor(ChordShapes.ukulele, 3), 'assets/tones/uke_a4.wav');
  });
  test('maps guitar strings to the right tone assets', () {
    expect(toneAssetFor(ChordShapes.guitar, 0), 'assets/tones/guitar_e2.wav');
    expect(toneAssetFor(ChordShapes.guitar, 5), 'assets/tones/guitar_e4.wav');
  });
  test('out-of-range index returns null', () {
    expect(toneAssetFor(ChordShapes.ukulele, 9), isNull);
  });
}
