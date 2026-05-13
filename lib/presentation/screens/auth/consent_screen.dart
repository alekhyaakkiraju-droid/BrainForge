import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/functions_service.dart';
import '../../../domain/auth/auth_state.dart';
import '../../widgets/brainforge_widgets.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _checked = false;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_checked) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(functionsServiceProvider).recordConsent();
      // Refresh auth state — router will redirect to /auth/create-child.
      await ref.read(authStateProvider.notifier).refresh();
    } on FirebaseFunctionsException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Could not record consent.');
    } on Exception {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryLight,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: AppSpacing.iconSizeXl,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Parental Consent',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ConsentText(context: context),
                  const SizedBox(height: AppSpacing.lg),
                  CheckboxListTile(
                    value: _checked,
                    onChanged: (v) =>
                        setState(() => _checked = v ?? false),
                    title: const Text(
                      'I am the parent/guardian and I give consent for '
                      'my child to use BrainForge.',
                      maxLines: 3,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
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
                  const SizedBox(height: AppSpacing.lg),
                  BrainForgeButton(
                    label: _loading ? 'Saving consent…' : 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    width: double.infinity,
                    onPressed:
                        (_checked && !_loading) ? _submit : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ConsentText extends StatelessWidget {
  const _ConsentText({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) => Text(
        'BrainForge collects the following data for each child profile:\n'
        '• Username (chosen by you)\n'
        '• Age range (e.g., 8–10)\n'
        '• Avatar selection\n'
        '• Quest progress and XP points\n\n'
        'We do not collect real names, photos, precise birthdates, '
        'or location data. Data is stored securely and never sold '
        'to third parties. This record is stored with your account '
        'and timestamp (COPPA v1.0.0).',
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 20,
      );
}
