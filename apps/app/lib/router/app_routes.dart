/// Centralized route paths + names for the app. Keeping them in one place lets
/// the drawer, screens, and tests refer to routes without string drift.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String trending = '/trending';
  static const String saved = '/saved';
  static const String chords = '/chords';
  static const String tuner = '/tuner';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String login = '/login';
  static const String register = '/register';
  static const String search = '/search';

  /// Search results for a query, e.g. `/search?q=riptide`.
  static String searchPath(String query) =>
      '/search?q=${Uri.encodeQueryComponent(query)}';

  /// Song detail, e.g. `/song/abc123`.
  static const String song = '/song/:id';

  static String songPath(String id) => '/song/$id';
}
