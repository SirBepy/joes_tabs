import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';

/// Makes system back on a page with nothing beneath it (reached via `go`, a
/// deep link, or the drawer) return to Home instead of closing the app. Pages
/// pushed on top of something pop normally, and Home itself still exits.
class BackToHomeScope extends StatelessWidget {
  const BackToHomeScope({
    super.key,
    required this.location,
    required this.child,
  });

  /// The matched route path of the page being wrapped.
  final String location;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // ModalRoute.canPop also covers an open drawer, which back should close.
    final canPop =
        location == AppRoutes.home || (ModalRoute.of(context)?.canPop ?? true);
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: child,
    );
  }
}
