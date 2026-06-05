import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Logged-in home / dashboard (despite the source mockup being named
/// `welcome.md`). Wireframe greeting + section placeholders; plan 08 fills in
/// the live saved-tabs row and trending list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: Column(
            children: [
              Text('WELCOME BACK', style: textTheme.headlineMedium),
              Text(
                'PLACEHOLDER NAME!',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // TODO(design): replace with the orange ukulele mascot avatar.
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.peach,
                child: Icon(
                  PhosphorIconsFill.guitar,
                  size: 56,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('SAVED TABS', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        const _PlaceholderPanel(note: 'Saved tabs row (plan 08).'),
        const SizedBox(height: AppSpacing.lg),
        Text('TRENDING', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        const _PlaceholderPanel(note: 'Trending list (plan 08).'),
      ],
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardPeach,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Text(note, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}
