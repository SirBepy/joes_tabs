import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_drawer.dart';

/// Chrome around the main destinations. The top bar is route-dependent:
///
///  * Browse screens (Home, Trending) keep the solid-orange app bar with the
///    hamburger that opens the full-screen [AppDrawer] plus the rounded search
///    field.
///  * Section screens (Settings, Support Us, Saved Tabs, Chords, Tuner) instead
///    show a [SectionHeader]: a circular back button and the screen title in the
///    orange "bubble" heading font, on the cream background, with no search.
///
/// Used by the [ShellRoute] in the router so every top-level screen shares the
/// same scaffold + drawer.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  /// The current route's screen body.
  final Widget child;

  /// Section screens: route path -> the title shown in the bubble header.
  static const Map<String, String> _sectionTitles = {
    AppRoutes.settings: 'SETTINGS',
    AppRoutes.support: 'SUPPORT US',
    AppRoutes.saved: 'SAVED TABS',
    AppRoutes.chords: 'CHORDS',
    AppRoutes.tuner: 'TUNER',
  };

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final sectionTitle = _sectionTitles[location];
    final isSection = sectionTitle != null;

    return Scaffold(
      // The drawer is only reachable from the browse screens (Home, Trending),
      // matching the hamburger-only mockups; section screens use the back
      // button. Omitting it on section routes keeps the edge-swipe gesture off
      // where there is no hamburger to reveal it.
      drawer: isSection ? null : const AppDrawer(),
      appBar: isSection
          ? SectionHeader(title: sectionTitle)
          : AppBar(
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

/// The section-screen header: a cream bar with a circular orange-outlined back
/// button (Phosphor caret) at the leading edge and the screen [title] in the
/// brand "bubble" heading font (Fredoka, orange). Tapping back returns to Home
/// so navigation stays coherent with the drawer-driven model.
///
/// Implemented as a [PreferredSizeWidget] so it can slot straight into
/// [Scaffold.appBar]. The back tap is tolerant of being rendered outside a
/// GoRouter (e.g. a bare widget test) - it simply no-ops there.
class SectionHeader extends StatelessWidget implements PreferredSizeWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.orange,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,
      leadingWidth: 72,
      shape: const Border(bottom: BorderSide(color: AppColors.peach, width: 1)),
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: _BackCircle(
          onTap: () => GoRouter.maybeOf(context)?.go(AppRoutes.home),
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      centerTitle: false,
    );
  }
}

/// The circular back control: an orange-outlined circle wrapping a Phosphor
/// caret-left, matching the section mockups.
class _BackCircle extends StatelessWidget {
  const _BackCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.orange, width: 2),
          ),
          child: const Icon(
            PhosphorIconsBold.caretLeft,
            color: AppColors.orange,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Rounded search field in the browse app bar. Tapping it opens the dedicated
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
