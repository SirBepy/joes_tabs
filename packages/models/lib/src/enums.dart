import 'package:json_annotation/json_annotation.dart';

/// Where a tab originated from. Mirrors the Postgres `tab_source` enum.
enum TabSource {
  @JsonValue('official')
  official,
  @JsonValue('imported')
  imported,
  @JsonValue('community')
  community,
}

/// Publication state of a tab. Mirrors the Postgres `tab_status` enum.
enum TabStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
}
