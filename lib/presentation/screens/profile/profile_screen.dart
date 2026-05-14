import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isParent = auth.role == UserRole.parent;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (auth.displayName != null)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  auth.displayName![0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              title: Text(
                auth.displayName!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                isParent ? 'Parent account' : 'Student account',
              ),
            ),
          const Divider(height: AppSpacing.xl),
          if (isParent)
            ListTile(
              leading: const Icon(
                Icons.family_restroom_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Parental Controls'),
              subtitle: const Text(
                'Manage child profiles and data deletion',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.parentSettings),
            ),
        ],
      ),
    );
  }
}
