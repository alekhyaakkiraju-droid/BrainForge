import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/auth/auth_state.dart';
import '../../widgets/brainforge_widgets.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _pollTimer;
  bool _resendCooldown = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Poll Firebase every 4 seconds until the email is verified.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    // Guard against test environments where Firebase is not initialized.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
        _pollTimer?.cancel();
        await ref.read(authStateProvider.notifier).refresh();
      }
    } on FirebaseException {
      return;
    }
  }

  Future<void> _resend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _resendCooldown = true);
    try {
      await user.sendEmailVerification();
      setState(() => _message = 'Verification email sent!');
    } on FirebaseAuthException {
      setState(() => _message = 'Could not resend email. Try again later.');
    } finally {
      // 30-second cooldown to avoid spam.
      await Future<void>.delayed(const Duration(seconds: 30));
      if (mounted) setState(() => _resendCooldown = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read current user from the auth notifier state so no Firebase singleton
    // call is needed in build (avoids crash in test environments).
    final auth = ref.watch(authStateProvider);
    final email = auth.displayName ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_unread_rounded,
                  size: AppSpacing.iconSizeXl,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Check your inbox',
                  style: Theme.of(context).textTheme.headlineMedium,
                  maxLines: 1,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We sent a verification link to $email. '
                  'Open it to continue.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.xl),
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Waiting for verification…',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                ),
                if (_message != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _message!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.success),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                BrainForgeButton(
                  label: _resendCooldown
                      ? 'Email sent!'
                      : 'Resend verification email',
                  icon: Icons.send_rounded,
                  width: double.infinity,
                  onPressed: _resendCooldown ? null : _resend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
