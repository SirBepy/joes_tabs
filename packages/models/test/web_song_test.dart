import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  const url =
      'https://www.ukulele-tabs.com/uke-songs/rebecca-sugar/love-like-you-uke-tab-35190.html';

  test('isWebSongId tells page URLs from catalog ids', () {
    expect(isWebSongId(url), isTrue);
    expect(isWebSongId('3f1c2a9e-0000-4000-8000-000000000000'), isFalse);
  });

  group('webSongStub', () {
    test('uses the given title and artist with the URL as id', () {
      final song = webSongStub(url, title: 'Love Like You', artist: 'R. Sugar');
      expect(song.id, url);
      expect(song.title, 'Love Like You');
      expect(song.artist, 'R. Sugar');
    });

    test('reads title and artist back from the URL slug', () {
      final song = webSongStub(url);
      expect(song.title, 'Love Like You');
      expect(song.artist, 'Rebecca Sugar');
    });

    test('an unknown URL shape falls back to the URL itself', () {
      final song = webSongStub('https://example.com/x.html');
      expect(song.title, 'https://example.com/x.html');
      expect(song.artist, '');
    });
  });
}
