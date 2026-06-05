import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Log In (per `docs/design/screens/log-in-page.md`). Wireframe placeholder
/// form; Supabase auth wiring is deferred (accounts are optional in v1).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // TODO(design): replace with the orange ukulele mascot illustration.
          const Center(
            child: Icon(
              PhosphorIconsFill.guitar,
              size: 96,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TextField(decoration: InputDecoration(hintText: 'Email')),
          const SizedBox(height: AppSpacing.md),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: 'Password'),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {}, // TODO(plan): wire to Supabase auth.
            child: const Text('Log In'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {}, // TODO(plan): forgot-password flow.
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}
