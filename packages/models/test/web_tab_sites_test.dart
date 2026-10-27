import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  group('WebTabSite.forUrl', () {
    test('matches bare hosts and subdomains', () {
      expect(
        WebTabSite.forUrl(Uri.parse('https://ukulele-tabs.com/x.html')),
        WebTabSite.ukuleleTabs,
      );
      expect(
        WebTabSite.forUrl(Uri.parse('https://www.chordie.com/chord.pere/a')),
        WebTabSite.chordie,
      );
      expect(
        WebTabSite.forUrl(Uri.parse('https://tabs.ultimate-guitar.com/tab/x')),
        WebTabSite.ultimateGuitar,
      );
    });

    test('rejects look-alike hosts and non-web schemes', () {
      expect(WebTabSite.forUrl(Uri.parse('https://notchordie.com/a')), isNull);
      expect(
        WebTabSite.forUrl(Uri.parse('https://chordie.com.evil.io/a')),
        isNull,
      );
      expect(WebTabSite.forUrl(Uri.parse('javascript:alert(1)')), isNull);
    });

    test('Ultimate Guitar is link-only', () {
      expect(WebTabSite.ultimateGuitar.parseable, isFalse);
      expect(WebTabSite.all.where((s) => s.parseable).map((s) => s.id), [
        'ukulele-tabs',
        'chordie',
        'e-chords',
      ]);
    });

    test('byId round-trips', () {
      for (final site in WebTabSite.all) {
        expect(WebTabSite.byId(site.id), site);
      }
      expect(WebTabSite.byId('nope'), isNull);
      expect(WebTabSite.byId(null), isNull);
    });
  });

  group('parseWebTabTitle', () {
    test('"<title> chords by <artist>"', () {
      final r = parseWebTabTitle(
        'HERE COMES A THOUGHT CHORDS by Steven Universe @ Ultimate-Guitar.Com',
      );
      expect(r.title, 'HERE COMES A THOUGHT');
      expect(r.artist, 'Steven Universe');
    });

    test('"<title> - <artist> | site"', () {
      final r = parseWebTabTitle('Riptide Chords - Vance Joy | Chordie');
      expect(r.title, 'Riptide');
      expect(r.artist, 'Vance Joy');
    });

    test('ukulele words are stripped', () {
      final r = parseWebTabTitle(
        'Love Like You Ukulele Tabs by Steven Universe (ver 2)',
      );
      expect(r.title, 'Love Like You');
      expect(r.artist, 'Steven Universe');
    });

    test('no separator leaves the artist null', () {
      final r = parseWebTabTitle('Stronger Than You chords');
      expect(r.title, 'Stronger Than You');
      expect(r.artist, isNull);
    });
  });
}
