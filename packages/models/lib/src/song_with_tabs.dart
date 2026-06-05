import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'song.dart';
import 'tab.dart';

part 'song_with_tabs.freezed.dart';
part 'song_with_tabs.g.dart';

/// Convenience aggregate: a [Song] together with all of its [Tab]s. This is a
/// client-side composition (not a single DB table) used by repositories that
/// fetch a song and its tabs in one shot.
@freezed
abstract class SongWithTabs with _$SongWithTabs {
  const SongWithTabs._();

  const factory SongWithTabs({
    required Song song,
    @Default(<Tab>[]) List<Tab> tabs,
  }) = _SongWithTabs;

  factory SongWithTabs.fromJson(Map<String, dynamic> json) =>
      _$SongWithTabsFromJson(json);

  /// Only the published tabs, in input order.
  List<Tab> get publishedTabs =>
      tabs.where((t) => t.status == TabStatus.published).toList();

  /// True when at least one tab exists for the given instrument id.
  bool hasTabForInstrument(String instrumentId) =>
      tabs.any((t) => t.instrumentId == instrumentId);
}
