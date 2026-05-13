import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/auth/auth_state.dart';
import '../../widgets/brainforge_widgets.dart';

/// Placeholder login screen — real auth implemented in a later WO.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    size: AppSpacing.iconSizeXl,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'BrainForge',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: Colors.white),
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sign in to start your quests',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white70),
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  BrainForgeButton(
                    label: 'Sign In (Demo)',
                    icon: Icons.login_rounded,
                    width: double.infinity,
                    color: Colors.white,
                    onPressed: () {
                      ref.read(authStateProvider.notifier).signIn();
                      context.go(AppRoutes.questBoard);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
