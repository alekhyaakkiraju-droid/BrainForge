import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/functions_service.dart';
import '../../../domain/auth/auth_state.dart';
import '../../widgets/brainforge_widgets.dart';

const _ageRanges = ['5-7', '8-10', '11-13'];

const _avatars = <String, IconData>{
  'avatar_1': Icons.face_rounded,
  'avatar_2': Icons.face_2_rounded,
  'avatar_3': Icons.face_3_rounded,
  'avatar_4': Icons.face_4_rounded,
  'avatar_5': Icons.face_5_rounded,
  'avatar_6': Icons.face_6_rounded,
};

class ChildProfileCreationScreen extends ConsumerStatefulWidget {
  const ChildProfileCreationScreen({super.key});

  @override
  ConsumerState<ChildProfileCreationScreen> createState() =>
      _ChildProfileCreationScreenState();
}

class _ChildProfileCreationScreenState
    extends ConsumerState<ChildProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();

  String _selectedAgeRange = _ageRanges[1];
  String _selectedAvatar = _avatars.keys.first;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(functionsServiceProvider).createChildAccount(
            username: _usernameController.text.trim(),
            ageRange: _selectedAgeRange,
            avatarId: _selectedAvatar,
            pin: _pinController.text,
          );
      // Advance auth state — router redirects to /quest-board.
      await ref.read(authStateProvider.notifier).refresh();
    } on FirebaseFunctionsException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code, e.message));
    } on Exception {
      setState(
        () => _errorMessage = 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String? code, String? message) => switch (code) {
        'already-exists' => 'That username is taken. Try another.',
        'invalid-argument' => message ?? 'Invalid input. Check your entries.',
        'permission-denied' => 'Parental consent is required first.',
        _ => 'Could not create profile. Please try again.',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryLight,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      const Icon(
                        Icons.child_care_rounded,
                        size: AppSpacing.iconSizeXl,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Create Child Profile',
                        style:
                            Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon:
                              Icon(Icons.alternate_email_rounded),
                          helperText:
                              '3–20 characters, letters, numbers, _',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Username is required.';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$')
                              .hasMatch(v)) {
                            return 'Letters, numbers, _ only (3–20 chars).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Age range
                      DropdownButtonFormField<String>(
                        value: _selectedAgeRange,
                        decoration: const InputDecoration(
                          labelText: 'Age range',
                          prefixIcon: Icon(Icons.cake_rounded),
                        ),
                        items: _ageRanges
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedAgeRange = v);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Avatar picker
                      Text(
                        'Choose an avatar',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _AvatarGrid(
                        selected: _selectedAvatar,
                        onSelect: (id) =>
                            setState(() => _selectedAvatar = id),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // PIN
                      TextFormField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: '4-digit PIN',
                          prefixIcon: Icon(Icons.pin_rounded),
                        ),
                        validator: (v) {
                          if (v == null ||
                              !RegExp(r'^\d{4}$').hasMatch(v)) {
                            return 'PIN must be exactly 4 digits.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _pinConfirmController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: 'Confirm PIN',
                          prefixIcon: Icon(Icons.pin_rounded),
                        ),
                        validator: (v) {
                          if (v != _pinController.text) {
                            return 'PINs do not match.';
                          }
                          return null;
                        },
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
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
                        label: _loading
                            ? 'Creating profile…'
                            : 'Create profile',
                        icon: Icons.rocket_launch_rounded,
                        width: double.infinity,
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        children: _avatars.entries.map((entry) {
          final isSelected = entry.key == selected;
          return GestureDetector(
            onTap: () => onSelect(entry.key),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDark
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                entry.value,
                color:
                    isSelected ? Colors.white : AppColors.primary,
                size: AppSpacing.iconSizeMd,
              ),
            ),
          );
        }).toList(),
      );
}
