import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_mascot.dart';

/// Thank You screen (per `docs/design/screens/ty-screen.md`).
///
/// Full-bleed peach celebration reached after a Support Us action: a sticker
/// "THANK YOU" heading, a speech bubble, and the full-body mascot. Tapping
/// anywhere returns to the app (no auto-dismiss timer in this wireframe so the
/// state is deterministic for tests).
class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.peach,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/'),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'THANK YOU',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'FOR YOUR SUPPORT!',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  child: const Text(
                    'Glad to have you here!',
                    style: TextStyle(color: AppColors.textDark),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const BrandMascot(size: 200, icon: PhosphorIconsFill.guitar),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Tap anywhere to continue',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
