import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../router/app_routes.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../web_tabs/open_external.dart';
import '../web_tabs/web_tab_extraction.dart';
import '../web_tabs/web_song_reader.dart';
import '../widgets/song_tiles.dart';

/// Opens a ukulele-tabs.com page in a WebView, reads the chords out of the
/// loaded page on the device into an in-memory song, and replaces itself with
/// that song. Nothing is stored (the site's terms forbid it without
/// permission), so every open of a saved or recent song comes back through
/// here. Android/iOS only: the web build links out instead (no WebView there,
/// and browsers block reading another site's page).
///
/// The page stays visible underneath, so a bot challenge can be passed by
/// hand; every finished load is read again.
class WebTabScreen extends ConsumerStatefulWidget {
  const WebTabScreen({
    super.key,
    required this.url,
    required this.title,
    this.artist,
  });

  final Uri url;

  /// The search result's title, the preferred source of song title/artist.
  final String title;

  /// The search result's artist, when the site listed it separately.
  final String? artist;

  @override
  ConsumerState<WebTabScreen> createState() => _WebTabScreenState();
}

enum _Phase { reading, failed }

class _WebTabScreenState extends ConsumerState<WebTabScreen> {
  WebViewController? _controller;
  _Phase _phase = _Phase.reading;
  bool _done = false;
  WebTabSite? _site;

  @override
  void initState() {
    super.initState();
    final site = WebTabSite.forUrl(widget.url);
    _site = site;
    // Only allowlisted, parseable sites may be framed and read here; anything
    // else is a link-only page.
    if (site == null || !site.parseable) {
      _phase = _Phase.failed;
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        kWebTabChannel,
        onMessageReceived: (m) => _onExtracted(m.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // A followed link to another song would otherwise be saved under
          // this song's URL and title.
          onPageFinished: (loaded) {
            if (Uri.tryParse(loaded)?.path != widget.url.path) return;
            _controller?.runJavaScript(webTabExtractionScript(site));
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  void _onExtracted(String message) {
    final site = _site;
    if (_done || site == null || !mounted) return;
    final song = webSongFromMessage(
      message,
      url: widget.url,
      site: site,
      resultTitle: widget.title,
      resultArtist: widget.artist,
    );
    if (song == null) {
      setState(() => _phase = _Phase.failed);
      return;
    }
    _done = true;
    final id = song.song.id;
    final store = ref.read(webSongsProvider.notifier);
    store.state = {...store.state, id: song};
    ref.read(appDatabaseProvider).recordView(id);
    context.pushReplacement(AppRoutes.songPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(_site?.name ?? 'Web tab'),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(PhosphorIconsRegular.arrowSquareOut),
            onPressed: () => openExternally(widget.url),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (controller != null)
            WebViewWidget(controller: controller)
          else
            const EmptyState(message: 'This page can only open in a browser.'),
          if (_phase != _Phase.failed)
            const _Banner(
              icon: PhosphorIconsRegular.musicNotes,
              message: 'Reading chords from this page...',
              busy: true,
            )
          else if (controller != null)
            _Banner(
              icon: PhosphorIconsRegular.warningCircle,
              message: "Couldn't read chords from this page.",
              action: TextButton(
                onPressed: () => openExternally(widget.url),
                child: const Text('Open in browser'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    this.busy = false,
    this.action,
  });

  final IconData icon;
  final String message;
  final bool busy;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.palette.card,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
          ),
          child: Row(
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, color: context.palette.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: context.palette.ink),
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}
