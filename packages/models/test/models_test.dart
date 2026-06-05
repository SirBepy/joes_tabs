import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  group('Instrument', () {
    final json = <String, dynamic>{
      'id': '11111111-1111-1111-1111-111111111111',
      'slug': 'ukulele',
      'name': 'Ukulele',
      'string_count': 4,
      'default_tuning': 'GCEA',
    };

    test('fromJson reads snake_case keys', () {
      final instrument = Instrument.fromJson(json);
      expect(instrument.id, json['id']);
      expect(instrument.slug, 'ukulele');
      expect(instrument.name, 'Ukulele');
      expect(instrument.stringCount, 4);
      expect(instrument.defaultTuning, 'GCEA');
    });

    test('toJson round-trips with snake_case keys', () {
      final instrument = Instrument.fromJson(json);
      expect(instrument.toJson(), equals(json));
    });
  });

  group('Song', () {
    final json = <String, dynamic>{
      'id': '22222222-2222-2222-2222-222222222222',
      'title': 'Riptide',
      'artist': 'Vance Joy',
      'created_at': '2026-05-30T12:00:00.000Z',
      'updated_at': '2026-05-31T08:30:00.000Z',
    };

    test('fromJson reads snake_case timestamps', () {
      final song = Song.fromJson(json);
      expect(song.title, 'Riptide');
      expect(song.artist, 'Vance Joy');
      expect(song.createdAt, DateTime.parse('2026-05-30T12:00:00.000Z'));
      expect(song.updatedAt, DateTime.parse('2026-05-31T08:30:00.000Z'));
    });

    test('toJson round-trips', () {
      final song = Song.fromJson(json);
      expect(song.toJson(), equals(json));
    });
  });

  group('Tab', () {
    final fullJson = <String, dynamic>{
      'id': '33333333-3333-3333-3333-333333333333',
      'song_id': '22222222-2222-2222-2222-222222222222',
      'instrument_id': '11111111-1111-1111-1111-111111111111',
      'content': '{title: Riptide}\n[Am]I was scared of [G]...',
      'original_key': 'Am',
      'capo': 1,
      'difficulty': 'beginner',
      'source': 'official',
      'status': 'published',
      'author_id': '44444444-4444-4444-4444-444444444444',
      'created_at': '2026-05-30T12:00:00.000Z',
      'updated_at': '2026-05-31T08:30:00.000Z',
    };

    test('fromJson maps fields, enums, and snake_case keys', () {
      final tab = Tab.fromJson(fullJson);
      expect(tab.songId, fullJson['song_id']);
      expect(tab.instrumentId, fullJson['instrument_id']);
      expect(tab.originalKey, 'Am');
      expect(tab.capo, 1);
      expect(tab.difficulty, 'beginner');
      expect(tab.source, TabSource.official);
      expect(tab.status, TabStatus.published);
      expect(tab.authorId, fullJson['author_id']);
    });

    test('toJson round-trips with enum string values', () {
      final tab = Tab.fromJson(fullJson);
      final out = tab.toJson();
      expect(out, equals(fullJson));
      expect(out['source'], 'official');
      expect(out['status'], 'published');
    });

    test('nullable fields default to null when absent', () {
      final minimalJson = <String, dynamic>{
        'id': '33333333-3333-3333-3333-333333333333',
        'song_id': '22222222-2222-2222-2222-222222222222',
        'instrument_id': '11111111-1111-1111-1111-111111111111',
        'content': '[C]Some [G]content',
        'original_key': 'C',
        'capo': null,
        'difficulty': null,
        'source': 'imported',
        'status': 'draft',
        'author_id': null,
        'created_at': '2026-05-30T12:00:00.000Z',
        'updated_at': '2026-05-30T12:00:00.000Z',
      };
      final tab = Tab.fromJson(minimalJson);
      expect(tab.capo, isNull);
      expect(tab.difficulty, isNull);
      expect(tab.authorId, isNull);
      expect(tab.source, TabSource.imported);
      expect(tab.status, TabStatus.draft);
      expect(tab.toJson(), equals(minimalJson));
    });

    test('all TabSource values decode', () {
      for (final value in {
        'official': TabSource.official,
        'imported': TabSource.imported,
        'community': TabSource.community,
      }.entries) {
        final tab = Tab.fromJson({...fullJson, 'source': value.key});
        expect(tab.source, value.value);
      }
    });
  });

  group('SongWithTabs', () {
    final json = <String, dynamic>{
      'song': {
        'id': '22222222-2222-2222-2222-222222222222',
        'title': 'Riptide',
        'artist': 'Vance Joy',
        'created_at': '2026-05-30T12:00:00.000Z',
        'updated_at': '2026-05-31T08:30:00.000Z',
      },
      'tabs': [
        {
          'id': '33333333-3333-3333-3333-333333333333',
          'song_id': '22222222-2222-2222-2222-222222222222',
          'instrument_id': '11111111-1111-1111-1111-111111111111',
          'content': '[Am]content',
          'original_key': 'Am',
          'capo': null,
          'difficulty': null,
          'source': 'official',
          'status': 'published',
          'author_id': null,
          'created_at': '2026-05-30T12:00:00.000Z',
          'updated_at': '2026-05-30T12:00:00.000Z',
        },
        {
          'id': '55555555-5555-5555-5555-555555555555',
          'song_id': '22222222-2222-2222-2222-222222222222',
          'instrument_id': '66666666-6666-6666-6666-666666666666',
          'content': '[G]content',
          'original_key': 'G',
          'capo': null,
          'difficulty': null,
          'source': 'community',
          'status': 'draft',
          'author_id': null,
          'created_at': '2026-05-30T12:00:00.000Z',
          'updated_at': '2026-05-30T12:00:00.000Z',
        },
      ],
    };

    test('fromJson nests Song and list of Tab', () {
      final swt = SongWithTabs.fromJson(json);
      expect(swt.song.title, 'Riptide');
      expect(swt.tabs, hasLength(2));
      expect(swt.tabs.first.status, TabStatus.published);
    });

    test('toJson round-trips nested structure', () {
      final swt = SongWithTabs.fromJson(json);
      expect(swt.toJson(), equals(json));
    });

    test('publishedTabs filters to published only', () {
      final swt = SongWithTabs.fromJson(json);
      expect(swt.publishedTabs, hasLength(1));
      expect(swt.publishedTabs.single.status, TabStatus.published);
    });

    test('hasTabForInstrument checks instrument presence', () {
      final swt = SongWithTabs.fromJson(json);
      expect(
        swt.hasTabForInstrument('11111111-1111-1111-1111-111111111111'),
        isTrue,
      );
      expect(swt.hasTabForInstrument('does-not-exist'), isFalse);
    });

    test('defaults to empty tabs list', () {
      final swt = SongWithTabs(
        song: Song.fromJson(json['song'] as Map<String, dynamic>),
      );
      expect(swt.tabs, isEmpty);
      expect(swt.publishedTabs, isEmpty);
    });
  });
}
