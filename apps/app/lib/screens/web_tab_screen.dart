import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../router/app_routes.dart';
import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../web_tabs/open_external.dart';
import '../web_tabs/web_tab_extraction.dart';
import '../web_tabs/web_tab_importer.dart';
import '../widgets/song_tiles.dart';

/// Opens a chord page from web search in a WebView, reads the chords out of the
/// loaded page on the device, stores them as an imported tab, and replaces
/// itself with that song. Android/iOS only: the web build links out instead
/// (no WebView there, and browsers block reading another site's page).
///
/// The page stays visible underneath, so a bot challenge (e-chords sits behind
/// Cloudflare) can be passed by hand; every finished load is read again, so the
/// real page still imports after the challenge redirects.
class WebTabScreen extends ConsumerStatefulWidget {
  const WebTabScreen({super.key, required this.url, required this.title});

  final Uri url;

  /// The search result's title, the preferred source of song title/artist.
  final String title;

  @override
  ConsumerState<WebTabScreen> createState() => _WebTabScreenState();
}

enum _Phase { reading, failed, saving }

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
          onPageFinished: (_) =>
              _controller?.runJavaScript(webTabExtractionScript(site)),
        ),
      )
      ..loadRequest(widget.url);
  }

  Future<void> _onExtracted(String message) async {
    final site = _site;
    // A save already in flight wins; a later load's message would only
    // re-import the same URL.
    if (_done || _phase == _Phase.saving || site == null || !mounted) return;
    final importer = WebTabImporter(
      repository: ref.read(webTabsRepositoryProvider),
      url: widget.url,
      site: site,
      resultTitle: widget.title,
      instrumentSlug: ref.read(selectedInstrumentProvider),
    );
    setState(() => _phase = _Phase.saving);
    try {
      final songId = await importer.import(message);
      if (!mounted) return;
      if (songId == null) {
        setState(() => _phase = _Phase.failed);
        return;
      }
      _done = true;
      ref.invalidate(searchFilteredProvider);
      ref.invalidate(webSearchProvider);
      context.pushReplacement(AppRoutes.songPath(songId));
    } on CatalogException {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
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
                Icon(icon, color: AppColors.rust),
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
