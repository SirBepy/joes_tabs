import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';
part 'song.g.dart';

/// A song (title + artist) independent of any particular tab. Mirrors the
/// `songs` table. JSON keys are snake_case to match the Postgres columns.
@freezed
abstract class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}
