import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'tab.freezed.dart';
part 'tab.g.dart';

/// A single tab/chord sheet for a song on a given instrument. Mirrors the
/// `tabs` table. JSON keys are snake_case to match the Postgres columns
/// (song_id, instrument_id, original_key, author_id, created_at, updated_at).
@freezed
abstract class Tab with _$Tab {
  const factory Tab({
    required String id,
    required String songId,
    required String instrumentId,
    required String content,
    required String originalKey,
    int? capo,
    String? difficulty,
    required TabSource source,
    required TabStatus status,
    String? authorId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Tab;

  factory Tab.fromJson(Map<String, dynamic> json) => _$TabFromJson(json);
}
