import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Branded launch screen (per `docs/design/screens/splash-screen.md`). Shown
/// briefly, then auto-advances: first-run users (onboarding not complete) go to
/// the onboarding wizard, returning users go to Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Timer-based advance; startup init already happened in main(). The
    // destination depends on whether onboarding was completed on a prior run.
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final onboardingComplete = ref
          .read(initialAppSettingsProvider)
          .onboardingComplete;
      context.go(onboardingComplete ? AppRoutes.home : AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "JOE'S\nTABS",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 48, height: 1.0),
            ),
            const SizedBox(height: AppSpacing.xl),
            // TODO(design): replace with the orange ukulele mascot illustration.
            const Icon(
              PhosphorIconsFill.guitar,
              size: 120,
              color: AppColors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
