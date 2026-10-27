import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the system browser (never an in-app view), for pages the app
/// may only link to. Returns false when no app could handle it.
Future<bool> openExternally(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);
