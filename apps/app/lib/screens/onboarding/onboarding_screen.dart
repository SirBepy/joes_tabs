import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../router/app_routes.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/brand_mascot.dart';

/// First-run onboarding wizard (spec sections 3-5). A three-step [PageView]:
///
///   1. Welcome - brand + mascot placeholder, "Get started".
///   2. Instrument - "Which do you play?" multi-select, min one to continue.
///   3. Account - sign in / create account / skip, each finishing onboarding.
///
/// Onboarding is one-time: completion (any path out of the Account step) sets
/// `onboardingComplete = true` so the splash never routes here again.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _stepCount = 3;

  final _controller = PageController();
  int _page = 0;

  /// Instruments selected on the Instrument step. Starts EMPTY (the user must
  /// pick at least one); committed to [instrumentsProvider] on continue.
  final Set<String> _selectedInstruments = <String>{};

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

  void _toggleInstrument(String slug) {
    setState(() {
      if (_selectedInstruments.contains(slug)) {
        _selectedInstruments.remove(slug);
      } else {
        _selectedInstruments.add(slug);
      }
    });
  }

  Future<void> _commitInstrumentsAndContinue() async {
    if (_selectedInstruments.isEmpty) return;
    await ref
        .read(instrumentsProvider.notifier)
        .set(Set<String>.from(_selectedInstruments));
    _goTo(2);
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                key: const Key('onboarding-pageview'),
                controller: _controller,
                // Steps must be driven by the buttons (and gated on the
                // instrument step), not by free swiping.
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _WelcomeStep(onGetStarted: () => _goTo(1)),
                  _InstrumentStep(
                    selected: _selectedInstruments,
                    onToggle: _toggleInstrument,
                    onContinue: _commitInstrumentsAndContinue,
                  ),
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
              color: i == current ? AppColors.orange : AppColors.peach,
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
            "JOE'S\nTABS",
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 44, height: 1.0),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Chord sheets for ukulele and guitar, made simple.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
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

/// Step 2: instrument multi-select. Continue is disabled until at least one is
/// chosen. The card list is driven by [kSupportedInstrumentSlugs] so adding a
/// new supported instrument needs no change here.
class _InstrumentStep extends StatelessWidget {
  const _InstrumentStep({
    required this.selected,
    required this.onToggle,
    required this.onContinue,
  });

  final Set<String> selected;
  final void Function(String slug) onToggle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final canContinue = selected.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Which do you play?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Pick at least one. You can change this later in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final slug in kSupportedInstrumentSlugs) ...[
            _InstrumentCard(
              slug: slug,
              selected: selected.contains(slug),
              onTap: () => onToggle(slug),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('onboarding-instrument-continue'),
              onPressed: canContinue ? onContinue : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single selectable instrument card. Selected cards fill orange with a check.
class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({
    required this.slug,
    required this.selected,
    required this.onTap,
  });

  final String slug;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : AppColors.cardPeach,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: InkWell(
        key: Key('onboarding-instrument-$slug'),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                slug == ChordShapes.guitar
                    ? PhosphorIconsFill.guitar
                    : PhosphorIconsFill.musicNote,
                color: selected ? AppColors.white : AppColors.orange,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                instrumentDisplayName(slug),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: selected ? AppColors.white : AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(
                  PhosphorIconsFill.checkCircle,
                  color: AppColors.white,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 3: account. Each action persists `onboardingComplete = true` before it
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
          const Text(
            'Sign in to keep your saved tabs across devices, '
            'or skip and start playing right away.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
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
