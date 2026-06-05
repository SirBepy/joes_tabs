// Seed script for Joes Tabs - loads public-domain ChordPro songs into Supabase.
//
// Standalone Dart (no package deps): uses only dart:io + dart:convert so it runs
// with a plain `dart run` and passes `dart analyze` without `pub get`.
//
// It talks to the Supabase PostgREST API with the service_role key, which
// bypasses RLS, and upserts on the primary key so re-running is idempotent
// (deterministic UUIDs, Prefer: resolution=merge-duplicates).
//
// Usage (PowerShell, local stack):
//   $env:SUPABASE_URL = "http://127.0.0.1:54321"
//   $env:SUPABASE_SERVICE_ROLE_KEY = "<service_role key from `supabase start`>"
//   dart run supabase/seed/seed.dart
//
// The service_role key is read from the environment and is NEVER committed.
// See supabase/seed/README.md and supabase/seed/SOURCES.md.

import 'dart:convert';
import 'dart:io';

/// Deterministic song UUIDs, keyed by `.cho` file slug (filename without ext).
/// Stable across runs so upserts never duplicate. Generated once from
/// `joes_tabs_seed:<slug>`; treat as fixed identifiers.
const Map<String, String> songIds = {
  'amazing-grace': '1b76aed0-5abc-532b-a300-b37ea6f130bc',
  'scarborough-fair': '9a436ec0-3dad-5796-ba1b-690dda083d28',
  'house-of-the-rising-sun': 'ae2d5fe7-68a8-5608-a7f5-acd483deca07',
  'greensleeves': 'a2754fca-7887-5abd-889e-a38c9bb6e069',
  'oh-susanna': '7dd96076-01df-53d3-b460-8b80c1aa3271',
  'this-little-light-of-mine': '7295b550-9a90-52e4-a72c-2979d2767ee4',
  'will-the-circle-be-unbroken': '79b062fd-9831-5018-97df-aef281d95b1a',
  'down-in-the-valley': 'd009f2b6-71b3-56ef-8b32-fd86e4c0ac7b',
  'red-river-valley': 'ed360a3c-c78b-5d8e-bd27-d1ec5713452c',
  'when-the-saints-go-marching-in': '49574f80-7ece-5a42-b262-9e9253b4a9d2',
  'swing-low-sweet-chariot': 'd48a88a2-fcc5-5ccd-86a6-cb62fb12b3ea',
  'wayfaring-stranger': 'e1e66834-e8d6-574f-888e-f84b4d2c057e',
};

/// Deterministic tab UUIDs, keyed by `<instrumentSlug>/<songSlug>`.
const Map<String, String> tabIds = {
  'ukulele/amazing-grace': 'b6c35c16-4ae1-5b73-803a-6d3a3d4954c6',
  'ukulele/scarborough-fair': '71606b92-e126-5beb-924c-c10eeaabddfd',
  'ukulele/house-of-the-rising-sun': '1c812f3c-6f2a-525e-93eb-3efce805a627',
  'ukulele/greensleeves': 'a364d6aa-9041-57a0-980a-5f3bf415d5fa',
  'ukulele/oh-susanna': '2531dd5c-cc85-59a2-af7e-b38d25b91c33',
  'ukulele/this-little-light-of-mine': '7a4b1783-0bf2-5a7b-960a-06224d12cb2e',
  'ukulele/will-the-circle-be-unbroken': '470d1bc4-0b3b-50c4-bd33-a3b163a29b43',
  'ukulele/down-in-the-valley': 'd2dbcb18-08c3-553c-8de5-e7555360ba53',
  'ukulele/red-river-valley': '3f5a7240-da73-5227-9d6c-2ed5da4afdc0',
  'ukulele/when-the-saints-go-marching-in':
      '06b1464b-ae66-5c3e-b263-c1a028f0a470',
  'ukulele/swing-low-sweet-chariot': '96bea492-d320-5396-920d-fdf50bb5bc21',
  'ukulele/wayfaring-stranger': 'e0eb9355-b384-5b8f-8cf9-701656dc655a',
  'guitar/amazing-grace': 'af89b946-5d15-565c-be96-6e3fde17a32f',
  'guitar/scarborough-fair': '85b1647d-ff86-5b6f-803f-8f6c892bb127',
  'guitar/house-of-the-rising-sun': 'd37d4378-2df2-5783-a43e-b1aeebc097d5',
  'guitar/greensleeves': '1043ae63-c815-53f2-b141-401bc9737005',
  'guitar/oh-susanna': 'b86b2378-523a-548a-9a8d-3a4e31d78270',
  'guitar/this-little-light-of-mine': '623e918e-5acf-54ce-8ac0-0d049aa3dffa',
  'guitar/will-the-circle-be-unbroken': '38a43214-f874-5251-bb87-edaeb98b2d3e',
  'guitar/down-in-the-valley': '1c5ac6e2-02c7-5edc-998d-67847c08c9a9',
  'guitar/red-river-valley': 'a1e6c0b0-1541-5c08-8263-dfe6aca726b0',
  'guitar/when-the-saints-go-marching-in':
      'abf80463-dee6-5eca-bf64-5f9e8c4c10d5',
  'guitar/swing-low-sweet-chariot': '27bb0a7e-b2cc-5119-84a4-9de57e2d0824',
  'guitar/wayfaring-stranger': '39ef4aa2-8c8b-5756-ac52-9bdd54dda18a',
};

/// Instrument slugs that each song is published for. The ChordPro content is
/// instrument-agnostic (chord names only), so the same sheet seeds both.
const List<String> instrumentSlugs = ['ukulele', 'guitar'];

/// A parsed ChordPro song.
class ParsedSong {
  ParsedSong({
    required this.slug,
    required this.title,
    required this.artist,
    required this.key,
    required this.content,
  });

  final String slug;
  final String title;
  final String artist;
  final String? key;
  final String content;
}

/// Extracts the value of a `{directive: value}` line, or null if absent.
String? _directive(String content, String name) {
  final re = RegExp(
    r'\{\s*' + name + r'\s*:\s*([^}]*)\}',
    caseSensitive: false,
  );
  final m = re.firstMatch(content);
  if (m == null) return null;
  final value = m.group(1)?.trim();
  return (value == null || value.isEmpty) ? null : value;
}

ParsedSong _parse(File file) {
  final slug = file.uri.pathSegments.last.replaceAll('.cho', '');
  final content = file.readAsStringSync();
  final title = _directive(content, 'title') ?? slug;
  final artist = _directive(content, 'artist') ?? 'Traditional';
  final key = _directive(content, 'key');
  return ParsedSong(
    slug: slug,
    title: title,
    artist: artist,
    key: key,
    content: content,
  );
}

/// Minimal PostgREST client over dart:io's HttpClient.
class Rest {
  Rest(this.baseUrl, this.serviceKey);

  final String baseUrl;
  final String serviceKey;
  final HttpClient _client = HttpClient();

  Map<String, String> get _authHeaders => {
    'apikey': serviceKey,
    'Authorization': 'Bearer $serviceKey',
  };

  Future<List<dynamic>> get(String path) async {
    final req = await _client.getUrl(Uri.parse('$baseUrl/rest/v1/$path'));
    _authHeaders.forEach(req.headers.set);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) {
      throw HttpException('GET $path -> ${res.statusCode}: $body');
    }
    return jsonDecode(body) as List<dynamic>;
  }

  /// Upserts [rows] into [table], merging on the primary key.
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    final req = await _client.postUrl(Uri.parse('$baseUrl/rest/v1/$table'));
    _authHeaders.forEach(req.headers.set);
    req.headers.set('Content-Type', 'application/json');
    req.headers.set('Prefer', 'resolution=merge-duplicates,return=minimal');
    req.add(utf8.encode(jsonEncode(rows)));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) {
      throw HttpException('UPSERT $table -> ${res.statusCode}: $body');
    }
  }

  void close() => _client.close();
}

Future<int> main(List<String> args) async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    stderr.writeln(
      'Missing env. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY. See '
      'supabase/seed/README.md.',
    );
    return 64;
  }

  final songsDir = Directory(
    '${File(Platform.script.toFilePath()).parent.path}${Platform.pathSeparator}songs',
  );
  if (!songsDir.existsSync()) {
    stderr.writeln('Songs directory not found: ${songsDir.path}');
    return 66;
  }

  final files =
      songsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.cho'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final songs = files.map(_parse).toList();
  final rest = Rest(url, key);

  try {
    // Resolve instrument ids by slug (instruments are seeded by the migration).
    final instrumentRows = await rest.get('instruments?select=id,slug');
    final instrumentIdBySlug = <String, String>{
      for (final row in instrumentRows)
        (row as Map<String, dynamic>)['slug'] as String: row['id'] as String,
    };
    for (final slug in instrumentSlugs) {
      if (!instrumentIdBySlug.containsKey(slug)) {
        stderr.writeln('Missing instrument "$slug" - run `supabase db reset`.');
        return 70;
      }
    }

    // Upsert songs.
    final songRows = <Map<String, dynamic>>[];
    for (final s in songs) {
      final id = songIds[s.slug];
      if (id == null) {
        stderr.writeln('No deterministic id for song slug "${s.slug}".');
        return 70;
      }
      songRows.add({'id': id, 'title': s.title, 'artist': s.artist});
    }
    await rest.upsert('songs', songRows);

    // Upsert one published tab per instrument per song.
    final tabRows = <Map<String, dynamic>>[];
    for (final s in songs) {
      for (final instrumentSlug in instrumentSlugs) {
        final tabId = tabIds['$instrumentSlug/${s.slug}'];
        if (tabId == null) {
          stderr.writeln('No tab id for $instrumentSlug/${s.slug}.');
          return 70;
        }
        tabRows.add({
          'id': tabId,
          'song_id': songIds[s.slug],
          'instrument_id': instrumentIdBySlug[instrumentSlug],
          'content': s.content,
          'original_key': s.key,
          'source': 'official',
          'status': 'published',
        });
      }
    }
    await rest.upsert('tabs', tabRows);

    stdout.writeln(
      'Seeded ${songRows.length} songs and ${tabRows.length} published tabs '
      '(${instrumentSlugs.join(", ")}). Idempotent: safe to re-run.',
    );
    return 0;
  } on HttpException catch (e) {
    stderr.writeln('Seeding failed: ${e.message}');
    return 1;
  } finally {
    rest.close();
  }
}
