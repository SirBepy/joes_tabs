import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../ads/ad_service.dart';
import '../ads/watch_ad_action.dart';
import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_mascot.dart';

/// Settings (per `docs/design/screens/settings*.md`).
///
/// Wireframe list of rows: an expandable Font Settings group (size stepper),
/// a 3-way Theme selector (System / Light / Dark, bound to [themeModeProvider]),
/// an "Instruments I play" multi-select (min one, bound to [instrumentsProvider]
/// and read app-wide to control picker visibility), My Tags (placeholder), and a
/// Log Out row that opens a mascot confirmation dialog.
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
    final themeMode = ref.watch(themeModeProvider);
    final instruments = ref.watch(instrumentsProvider);
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
                      ? () => ref
                            .read(fontSizeProvider.notifier)
                            .set(fontSize - 1)
                      : null,
                ),
                Text('$fontSize', key: const Key('font-size-value')),
                IconButton(
                  tooltip: 'Increase font size',
                  icon: const Icon(PhosphorIconsRegular.plus),
                  onPressed: fontSize < 40
                      ? () => ref
                            .read(fontSizeProvider.notifier)
                            .set(fontSize + 1)
                      : null,
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        // THEME (System / Light / Dark).
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            'THEME',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: SegmentedButton<ThemeMode>(
            key: const Key('theme-mode-selector'),
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(PhosphorIconsRegular.desktop),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(PhosphorIconsRegular.sun),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(PhosphorIconsRegular.moon),
              ),
            ],
            selected: {themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ),
        const Divider(height: 1),
        // INSTRUMENTS I PLAY (multi-select, min one). Controls picker
        // visibility app-wide.
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            'INSTRUMENTS I PLAY',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Wrap(
            key: const Key('instruments-multiselect'),
            spacing: AppSpacing.sm,
            children: [
              for (final slug in kSupportedInstrumentSlugs)
                FilterChip(
                  key: Key('instrument-chip-$slug'),
                  label: Text(instrumentDisplayName(slug)),
                  selected: instruments.contains(slug),
                  showCheckmark: true,
                  selectedColor: AppColors.orange,
                  backgroundColor: AppColors.peach,
                  labelStyle: TextStyle(
                    color: instruments.contains(slug)
                        ? AppColors.white
                        : AppColors.rust,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  onSelected: (selected) {
                    final notifier = ref.read(instrumentsProvider.notifier);
                    if (selected) {
                      notifier.add(slug);
                    } else {
                      // Min-one rule: removing the last instrument is a no-op.
                      notifier.remove(slug);
                    }
                  },
                ),
            ],
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
        const Divider(height: 1),
        // WATCH AN AD TO SUPPORT US (rewarded ad, mobile only). On web/desktop
        // the row is disabled with a caption, since AdMob has no web support.
        _buildWatchAdRow(),
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

  /// "Watch an ad to support us" row. Enabled on mobile (triggers a rewarded
  /// ad); disabled with a caption on web/desktop where AdMob is unsupported.
  Widget _buildWatchAdRow() {
    final adService = ref.watch(adServiceProvider);
    final supported = adService.isSupported;

    return ListTile(
      key: const Key('watch-ad-row'),
      enabled: supported,
      leading: Icon(
        PhosphorIconsFill.megaphone,
        color: supported ? AppColors.orange : AppColors.textDark,
      ),
      title: const Text(
        'WATCH AN AD TO SUPPORT US',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      subtitle: supported
          ? null
          : const Text(
              'Available on the mobile app',
              key: Key('watch-ad-web-note'),
            ),
      onTap: supported ? () => runWatchAdFlow(context, adService) : null,
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
