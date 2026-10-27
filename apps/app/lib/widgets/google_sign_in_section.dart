import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/google_sign_in_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "Continue with Google" button plus an "or" divider, shown above the email
/// form on Log In and Register. Renders nothing where Google sign-in is not
/// available on this platform/build.
class GoogleSignInSection extends ConsumerStatefulWidget {
  const GoogleSignInSection({
    super.key,
    required this.enabled,
    required this.onSignedIn,
    required this.onError,
  });

  /// False while the surrounding email form is submitting.
  final bool enabled;

  final VoidCallback onSignedIn;

  /// Receives a user-facing message; null clears a previous error.
  final ValueChanged<String?> onError;

  @override
  ConsumerState<GoogleSignInSection> createState() =>
      _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends ConsumerState<GoogleSignInSection> {
  bool _busy = false;

  /// Shown after any cancel. Google reports a rejected app config (e.g. an
  /// unregistered signing key) as a cancel too, so a cancel cannot be told
  /// apart from a real back-out; a muted hint stays harmless for the latter.
  bool _showCancelHint = false;

  Future<void> _signIn() async {
    widget.onError(null);
    setState(() {
      _busy = true;
      _showCancelHint = false;
    });
    try {
      final result = await ref.read(googleSignInFlowProvider).signIn();
      if (!mounted) return;
      if (result == GoogleSignInResult.signedIn) {
        widget.onSignedIn();
      } else if (result == GoogleSignInResult.cancelled) {
        setState(() => _showCancelHint = true);
      }
    } on AuthException catch (e) {
      // The parent's onError is a setState, so a failure landing after the
      // user backed out of the screen must not call it.
      if (mounted) widget.onError(e.message);
    } catch (_) {
      if (mounted) widget.onError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(googleSignInAvailableProvider)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('google-sign-in'),
          onPressed: widget.enabled && !_busy ? _signIn : null,
          icon: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(PhosphorIconsBold.googleLogo),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.orange,
            side: const BorderSide(color: AppColors.orange, width: 2),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: const StadiumBorder(),
          ),
        ),
        if (_showCancelHint) ...[
          const SizedBox(height: AppSpacing.sm),
          // onSurface at reduced alpha rather than AppColors.textMuted, which
          // is too dark to read on the dark theme's background.
          Text(
            'Sign-in did not complete. Try again or use email.',
            key: const Key('google-cancel-hint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('or'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
