import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../ads/ad_service.dart';
import '../ads/watch_ad_action.dart';
import '../router/app_routes.dart';
import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/brand_mascot.dart';

/// Settings (per `docs/design/screens/settings*.md`).
///
/// A list of rows that share one label style ([_labelStyle]): an expandable
/// Font Settings group (size stepper), a 3-way Theme selector on the same line
/// as its label (System / Light / Dark, bound to [themeModeProvider]), Maximal
/// Chords, My Tags (placeholder), the optional rewarded ad, and last the
/// Account section, whose Log Out opens a mascot confirmation dialog, plus,
/// while signed in, a Delete Account row that opens the same kind of dialog.
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
    final maximalChords = ref.watch(maximalChordsProvider);
    final user = ref.watch(currentUserProvider);
    final palette = context.palette;

    return ListView(
      children: [
        // FONT SETTINGS (expandable).
        _Row(
          label: 'FONT SETTINGS',
          trailing: Icon(
            _fontExpanded
                ? PhosphorIconsFill.caretDown
                : PhosphorIconsFill.caretRight,
            color: context.palette.accent,
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
        // THEME (System / Light / Dark), beside its label. Text-only segments:
        // with icons the three no longer fit next to the label on a phone.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(child: Text('THEME', style: _labelStyle(context))),
              SegmentedButton<ThemeMode>(
                key: const Key('theme-mode-selector'),
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeMode},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        SwitchListTile(
          key: const Key('maximal-chords-switch'),
          value: maximalChords,
          activeThumbColor: AppColors.rust,
          title: Text('MAXIMAL CHORDS', style: _labelStyle(context)),
          subtitle: const Text(
            'Show advanced chord types (9ths, 11ths, altered, etc.)',
          ),
          onChanged: (v) => ref.read(maximalChordsProvider.notifier).set(v),
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
        // WATCH AN AD TO SUPPORT US (rewarded ad, optional, mobile only). On
        // web/desktop the row is disabled with a caption, since AdMob has no
        // web support.
        _buildWatchAdRow(),
        const Divider(height: 1),
        const _AccountSection(),
        // Log out lives in the Account section; only deletion is below it.
        if (user != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Divider(height: 1, color: palette.divider),
          // Google Play requires in-app deletion for apps that create accounts.
          _Row(
            key: const Key('delete-account-row'),
            label: 'DELETE ACCOUNT',
            trailing: Icon(
              PhosphorIconsFill.caretRight,
              color: context.palette.accent,
            ),
            onTap: () => _confirmDeleteAccount(context),
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
    final palette = context.palette;

    return ListTile(
      key: const Key('watch-ad-row'),
      enabled: supported,
      leading: Icon(
        PhosphorIconsFill.megaphone,
        color: supported ? palette.accent : palette.mutedInk,
      ),
      title: Text('WATCH AN AD TO SUPPORT US', style: _labelStyle(context)),
      subtitle: supported
          ? null
          : const Text(
              'Available on the mobile app',
              key: Key('watch-ad-web-note'),
            ),
      onTap: supported ? () => runWatchAdFlow(context, adService) : null,
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    // Captured before the dialog's await so the snackbar never reads a stale
    // context.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmDialog(
        message:
            'Delete your account? This permanently removes your account and '
            'saved favorites from our servers. Favorites on this device stay.',
        confirmLabel: 'DELETE ACCOUNT',
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
      messenger.showSnackBar(const SnackBar(content: Text('Account deleted.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't delete your account. Check your connection and try "
            'again.',
          ),
        ),
      );
    }
  }
}

/// Asks before signing out, so a stray tap on Log Out never drops the session.
Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  // Captured before the dialog's await so the snackbar never reads a stale
  // context.
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _ConfirmDialog(
      message: 'Are you sure you want to log out?',
      confirmLabel: 'LOG OUT',
    ),
  );
  if (confirmed != true) return;
  await ref.read(authServiceProvider).signOut();
  messenger.showSnackBar(const SnackBar(content: Text('Signed out.')));
}

/// Account entry points: Log In and Register while signed out, the email and a
/// Log Out button while signed in.
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACCOUNT', style: _labelStyle(context)),
          const SizedBox(height: AppSpacing.sm),
          if (user == null)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('account-log-in'),
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text('Log In'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('account-register'),
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('Register'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.email ?? 'Signed in',
                    key: const Key('account-email'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('account-log-out'),
                  onPressed: () => _confirmLogout(context, ref),
                  child: const Text('Log Out'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.label, this.trailing, this.onTap});

  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: _labelStyle(context)),
      trailing: trailing,
    );
  }
}

/// Every Settings row label: the list-tile title size, bold, in ink. Labels
/// outside a ListTile (Theme, Account) would otherwise inherit the smaller body
/// size.
TextStyle? _labelStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .bodyLarge
    ?.copyWith(fontWeight: FontWeight.w700, color: context.palette.ink);

/// Confirmation dialog in the log-out style of
/// `docs/design/screens/settings-1.md`: mascot, [message], a plain
/// [confirmLabel] confirm and an orange NOPE! cancel. Pops true on confirm.
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.message, required this.confirmLabel});

  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Dialog(
      backgroundColor: palette.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMascot(size: 96, icon: PhosphorIconsFill.smiley),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.ink),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                // White with forced dark text stays readable on both themes.
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.textDark,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.rust,
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
