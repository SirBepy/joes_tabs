import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_mascot.dart';

/// Settings (per `docs/design/screens/settings*.md`).
///
/// Wireframe list of rows: an expandable Font Settings group (size stepper),
/// a Dark Mode toggle, a Default Instrument selector (the load-bearing
/// functional control, bound to [defaultInstrumentProvider] and read by the
/// Chords and Tuner screens), My Tags (placeholder), and a Log Out row that
/// opens a mascot confirmation dialog.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _fontExpanded = false;

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final darkMode = ref.watch(darkModeProvider);
    final instrument = ref.watch(defaultInstrumentProvider);
    final user = ref.watch(currentUserProvider);

    return ListView(
      children: [
        // FONT SETTINGS (expandable).
        _Row(
          label: 'FONT SETTINGS',
          trailing: Icon(
            _fontExpanded
                ? PhosphorIconsFill.caretDown
                : PhosphorIconsFill.caretRight,
            color: AppColors.orange,
          ),
          onTap: () => setState(() => _fontExpanded = !_fontExpanded),
        ),
        if (_fontExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                const Text('Font size:'),
                const Spacer(),
                IconButton(
                  tooltip: 'Decrease font size',
                  icon: const Icon(PhosphorIconsRegular.minus),
                  onPressed: fontSize > 8
                      ? () => ref.read(fontSizeProvider.notifier).state =
                            fontSize - 1
                      : null,
                ),
                Text('$fontSize', key: const Key('font-size-value')),
                IconButton(
                  tooltip: 'Increase font size',
                  icon: const Icon(PhosphorIconsRegular.plus),
                  onPressed: fontSize < 40
                      ? () => ref.read(fontSizeProvider.notifier).state =
                            fontSize + 1
                      : null,
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        // DARK MODE toggle.
        _Row(
          label: 'DARK MODE',
          trailing: Switch(
            value: darkMode,
            activeThumbColor: AppColors.orange,
            onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
          ),
        ),
        const Divider(height: 1),
        // DEFAULT INSTRUMENT (load-bearing).
        _Row(
          label: 'DEFAULT INSTRUMENT',
          trailing: DropdownButton<String>(
            key: const Key('default-instrument-dropdown'),
            value: instrument,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                value: ChordShapes.ukulele,
                child: Text('Ukulele'),
              ),
              DropdownMenuItem(
                value: ChordShapes.guitar,
                child: Text('Guitar'),
              ),
            ],
            onChanged: (slug) {
              if (slug == null) return;
              ref.read(defaultInstrumentProvider.notifier).state = slug;
            },
          ),
        ),
        const Divider(height: 1),
        // MY TAGS (placeholder, future feature).
        _Row(
          label: 'MY TAGS',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tag management coming soon.')),
          ),
        ),
        // LOG OUT only makes sense while signed in; anonymous users see nothing.
        if (user != null) ...[
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1, color: AppColors.peach),
          _Row(
            label: 'LOG OUT',
            trailing: const Icon(
              PhosphorIconsFill.caretRight,
              color: AppColors.orange,
            ),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutDialog(),
    );
    if (confirmed != true) return;
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed out.')));
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.trailing, this.onTap});

  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      trailing: trailing,
    );
  }
}

/// Log-out confirmation (per `docs/design/screens/settings-1.md`): mascot,
/// "Are you sure you want to log out?", with a plain LOG OUT confirm and an
/// orange NOPE! cancel.
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardPeach,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMascot(size: 96, icon: PhosphorIconsFill.smiley),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.textDark,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'LOG OUT',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'NOPE!',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
