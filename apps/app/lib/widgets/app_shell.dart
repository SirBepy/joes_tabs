import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_drawer.dart';

/// Shared chrome around the main destinations: an orange top app bar with a
/// hamburger that opens the full-screen [AppDrawer], plus a rounded search
/// field (wired up in plan 08).
///
/// Used by the [ShellRoute] in the router so every top-level screen shares the
/// same bar + drawer.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  /// The current route's screen body.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(PhosphorIconsRegular.list),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const _SearchField(),
      ),
      body: child,
    );
  }
}

/// Rounded search field in the app bar. Tapping it opens the dedicated
/// [SearchScreen] (`/search`) where the query drives `searchProvider`.
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: () => context.push(AppRoutes.search),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'Search tabs',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            Icon(
              PhosphorIconsRegular.magnifyingGlass,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
