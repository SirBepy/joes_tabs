import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'auth_form_validators.dart';

/// Sign Up (per `docs/design/screens/sign-up-page.md`). Real Supabase email +
/// password registration: validates the form, calls [AuthService.signUp]
/// (local confirmations are disabled so the session is immediate), shows
/// loading + friendly error states, and routes back to Home on success.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authServiceProvider)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not create your account. Try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              key: const Key('register-email'),
              controller: _emailController,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('register-password'),
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(hintText: 'Password'),
              validator: validatePassword,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('register-repeat'),
              controller: _repeatController,
              enabled: !_submitting,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Repeat password'),
              validator: (v) =>
                  validatePasswordRepeat(v, _passwordController.text),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                key: const Key('register-error'),
                style: const TextStyle(color: AppColors.rust),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Account'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _submitting ? null : () => context.go(AppRoutes.login),
              child: const Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
