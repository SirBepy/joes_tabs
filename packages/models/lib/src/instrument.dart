import 'package:freezed_annotation/freezed_annotation.dart';

part 'instrument.freezed.dart';
part 'instrument.g.dart';

/// A playable instrument (ukulele, guitar, ...). Mirrors the `instruments`
/// lookup table. JSON keys are snake_case to match the Postgres columns.
@freezed
abstract class Instrument with _$Instrument {
  const factory Instrument({
    required String id,
    required String slug,
    required String name,
    required int stringCount,
    required String defaultTuning,
  }) = _Instrument;

  factory Instrument.fromJson(Map<String, dynamic> json) =>
      _$InstrumentFromJson(json);
}
