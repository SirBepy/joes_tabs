import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Sign Up (per `docs/design/screens/sign-up-page.md`). Wireframe placeholder
/// form; Supabase auth wiring is deferred (accounts are optional in v1).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const TextField(decoration: InputDecoration(hintText: 'Email')),
          const SizedBox(height: AppSpacing.md),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: 'Password'),
          ),
          const SizedBox(height: AppSpacing.md),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: 'Repeat password'),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {}, // TODO(plan): wire to Supabase auth.
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
