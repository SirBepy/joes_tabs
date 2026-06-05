import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Branded launch screen (per `docs/design/screens/splash-screen.md`). Shown
/// briefly, then auto-advances to Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Timer-based advance; startup init already happened in main().
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) context.go(AppRoutes.home);
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
