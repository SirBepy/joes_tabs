import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A single navigable destination shown in the [AppDrawer].
class DrawerDestination {
  const DrawerDestination(this.label, this.icon, this.route);
  final String label;
  final PhosphorIconData icon;
  final String route;
}

/// The full-screen slide-out navigation drawer (per `docs/design/screens/navbar.md`).
///
/// Order matches the mockup: Home, Trending, Saved Tabs, Chords, Tuner,
/// Settings; then a divider; a "Support Us" call to action; the mascot; and the
/// "Log In | Register" account links at the bottom.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static final List<DrawerDestination> destinations = [
    DrawerDestination('Home', PhosphorIconsRegular.house, AppRoutes.home),
    DrawerDestination(
      'Trending',
      PhosphorIconsRegular.trendUp,
      AppRoutes.trending,
    ),
    DrawerDestination(
      'Saved Tabs',
      PhosphorIconsRegular.bookmarkSimple,
      AppRoutes.saved,
    ),
    DrawerDestination(
      'Chords',
      PhosphorIconsRegular.musicNotes,
      AppRoutes.chords,
    ),
    DrawerDestination('Tuner', PhosphorIconsRegular.gauge, AppRoutes.tuner),
    DrawerDestination(
      'Settings',
      PhosphorIconsRegular.gearSix,
      AppRoutes.settings,
    ),
  ];

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop(); // close the drawer first
    context.go(route);
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // close the drawer first
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Drawer(
      width: MediaQuery.sizeOf(context).width,
      backgroundColor: AppColors.peach,
      child: SafeArea(
        child: Column(
          children: [
            // Top orange band with a close button.
            Container(
              color: AppColors.orange,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    color: AppColors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  for (final d in destinations)
                    ListTile(
                      leading: Icon(d.icon, color: AppColors.rust),
                      title: Text(
                        d.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      onTap: () => _go(context, d.route),
                    ),
                  const Divider(height: AppSpacing.xl),
                  ListTile(
                    leading: const Icon(
                      PhosphorIconsFill.heart,
                      color: AppColors.orange,
                    ),
                    title: const Text(
                      'Support Us',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                    onTap: () => _go(context, AppRoutes.support),
                  ),
                ],
              ),
            ),
            // TODO(design): replace with the orange ukulele mascot illustration.
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.white,
              child: Icon(
                PhosphorIconsFill.guitar,
                size: 40,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: user == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _go(context, AppRoutes.login),
                          child: const Text('Log In'),
                        ),
                        const Text(
                          '|',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        TextButton(
                          onPressed: () => _go(context, AppRoutes.register),
                          child: const Text('Register'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.email ?? 'Signed in',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _logOut(context, ref),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
