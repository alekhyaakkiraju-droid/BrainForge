import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/functions_service.dart';
import '../../../domain/auth/auth_state.dart';
import '../../widgets/brainforge_widgets.dart';

class ChildLoginScreen extends ConsumerStatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  ConsumerState<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends ConsumerState<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await ref.read(functionsServiceProvider).childSignIn(
            username: _usernameController.text.trim(),
            pin: _pinController.text,
          );

      await FirebaseAuth.instance.signInWithCustomToken(token);
      // AuthStateNotifier stream detects the new user; GoRouter redirects.
      await ref.read(authStateProvider.notifier).refresh();
    } on FirebaseFunctionsException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } on FirebaseAuthException {
      setState(() => _errorMessage = 'Sign-in failed. Please try again.');
    } on Exception {
      setState(() => _errorMessage = 'Something went wrong. Please retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String? code) => switch (code) {
        'not-found' => 'Username not found. Check your username.',
        'permission-denied' => 'Incorrect PIN. Please try again.',
        'invalid-argument' => 'Please enter your username and PIN.',
        _ => 'Sign-in failed. Please try again.',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primary,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: AppSpacing.iconSizeXl,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Welcome Back!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enter your username and PIN to continue.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    TextFormField(
                      controller: _usernameController,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon:
                            Icon(Icons.alternate_email_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your username.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: '4-digit PIN',
                        prefixIcon: Icon(Icons.pin_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => (v == null || v.length != 4)
                          ? 'Enter your 4-digit PIN.'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.errorLight),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    BrainForgeButton(
                      label: _loading ? 'Signing in…' : 'Sign in',
                      icon: Icons.login_rounded,
                      width: double.infinity,
                      color: Colors.white,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text(
                        'I\'m a parent — sign in here',
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
