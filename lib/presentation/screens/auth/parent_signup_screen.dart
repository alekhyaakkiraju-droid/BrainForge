import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/brainforge_widgets.dart';

class ParentSignupScreen extends ConsumerStatefulWidget {
  const ParentSignupScreen({super.key});

  @override
  ConsumerState<ParentSignupScreen> createState() =>
      _ParentSignupScreenState();
}

class _ParentSignupScreenState extends ConsumerState<ParentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await credential.user?.sendEmailVerification();

      // AuthStateNotifier stream picks up the new user and routes to
      // /auth/verify-email automatically.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) => switch (code) {
        'email-already-in-use' =>
          'An account with this email already exists.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Password must be at least 6 characters.',
        _ => 'Sign-up failed. Please try again.',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primary,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.family_restroom_rounded,
                      size: AppSpacing.iconSizeXl,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Create Parent Account',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "You'll verify your email before creating child "
                      'profiles.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _EmailField(controller: _emailController),
                    const SizedBox(height: AppSpacing.md),
                    _PasswordField(
                      controller: _passwordController,
                      label: 'Password',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PasswordField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    BrainForgeButton(
                      label: _loading ? 'Creating account…' : 'Create account',
                      icon: Icons.check_rounded,
                      width: double.infinity,
                      color: Colors.white,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text(
                        'Already have an account? Sign in',
                        style: TextStyle(color: Colors.white70),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Email address',
          prefixIcon: Icon(Icons.email_outlined),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email is required.';
          if (!v.contains('@')) return 'Enter a valid email.';
          return null;
        },
      );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator ??
            (v) {
              if (v == null || v.length < 6) {
                return 'Password must be at least 6 characters.';
              }
              return null;
            },
      );
}
