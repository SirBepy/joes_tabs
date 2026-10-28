import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../router/app_routes.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/brand_mascot.dart';

/// First-run onboarding wizard (spec sections 3-5). A two-step [PageView]:
///
///   1. Welcome - brand + mascot placeholder, "Get started".
///   2. Account - sign in / create account / skip, each finishing onboarding.
///
/// There is no instrument step: the ukulele-tabs.com client is ukulele only.
///
/// Onboarding is one-time: completion (any path out of the Account step) sets
/// `onboardingComplete = true` so the splash never routes here again.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _stepCount = 2;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Marks onboarding complete (persisted) then routes to [destination]. Used by
  /// all three Account-step actions so the wizard never reappears.
  Future<void> _finishOnboarding(String destination) async {
    await ref
        .read(appSettingsRepositoryProvider)
        .update(onboardingComplete: true);
    if (!mounted) return;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_page - 1);
      },
      child: _buildSteps(context),
    );
  }

  Widget _buildSteps(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                key: const Key('onboarding-pageview'),
                controller: _controller,
                // Steps must be driven by the buttons, not by free swiping.
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _WelcomeStep(onGetStarted: () => _goTo(1)),
                  _AccountStep(
                    onSignIn: () => _finishOnboarding(AppRoutes.login),
                    onCreateAccount: () =>
                        _finishOnboarding(AppRoutes.register),
                    onSkip: () => _finishOnboarding(AppRoutes.home),
                  ),
                ],
              ),
            ),
            _ProgressDots(count: _stepCount, current: _page),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Progress indicator: one dot per step, the current step filled orange.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('onboarding-progress-dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == current ? AppColors.orange : context.palette.chip,
            ),
          ),
      ],
    );
  }
}

/// Step 1: branded welcome with the mascot placeholder.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO(design): swap the Phosphor placeholder for the orange ukulele
          // mascot art once the brand asset is delivered.
          const BrandMascot(size: 160, icon: PhosphorIconsFill.guitar),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'UKULELE\nTABS',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 44, height: 1.0),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Every ukulele-tabs.com song, made simple to play.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.mutedInk),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('onboarding-get-started'),
              onPressed: onGetStarted,
              child: const Text('Get started'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2: account. Each action persists `onboardingComplete = true` before it
/// navigates, so onboarding is one-time regardless of which path is taken.
class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.onSignIn,
    required this.onCreateAccount,
    required this.onSkip,
  });

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: BrandMascot(size: 120, icon: PhosphorIconsFill.heart),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Sync your favorites',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sign in to keep your saved tabs across devices, '
            'or skip and start playing right away.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.mutedInk),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            key: const Key('onboarding-sign-in'),
            onPressed: onSignIn,
            child: const Text('Sign in'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            key: const Key('onboarding-create-account'),
            onPressed: onCreateAccount,
            child: const Text('Create account'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const Key('onboarding-skip'),
            onPressed: onSkip,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}
