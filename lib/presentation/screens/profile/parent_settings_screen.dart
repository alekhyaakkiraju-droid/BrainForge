import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/deletion_request_service.dart';
import '../../../domain/auth/auth_state.dart';
import '../../widgets/brainforge_widgets.dart';

class ParentSettingsScreen extends ConsumerStatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  ConsumerState<ParentSettingsScreen> createState() =>
      _ParentSettingsScreenState();
}

class _ParentSettingsScreenState
    extends ConsumerState<ParentSettingsScreen> {
  List<ChildProfile>? _children;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final auth = ref.read(authStateProvider);
    if (auth.uid == null) return;
    try {
      final service = ref.read(deletionRequestServiceProvider);
      final children = await service.fetchChildProfiles(auth.uid!);
      if (mounted) setState(() { _children = children; _loading = false; });
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _confirmAndDelete(ChildProfile child) async {
    final confirmed = await _showConfirmationDialog(child);
    if (!confirmed || !mounted) return;

    final auth = ref.read(authStateProvider);
    if (auth.uid == null) return;

    try {
      final service = ref.read(deletionRequestServiceProvider);
      await service.requestChildDataDeletion(
        parentUid: auth.uid!,
        childUid: child.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deletion request submitted. '
            'All data will be removed within 48 hours.',
          ),
        ),
      );
      await _loadChildren();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit deletion request. Please try again.'),
        ),
      );
    }
  }

  /// Shows a confirmation dialog requiring the parent to type the child's
  /// username before deletion is allowed, preventing accidental data loss.
  Future<bool> _showConfirmationDialog(ChildProfile child) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete Child Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete ALL data for '
                '"${child.username}", including quest progress, XP, '
                'mood entries, and their login account. '
                'This cannot be undone.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Type "${child.username}" to confirm:',
                style: Theme.of(ctx).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Child username',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: controller.text.trim() == child.username
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Delete permanently'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Parental Controls'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('Failed to load child profiles: $_error'),
      );
    }
    final children = _children ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Child Profiles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'As a parent you may permanently delete a child profile and '
            'all associated data at any time in accordance with COPPA.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (children.isEmpty)
            const Text('No child profiles found.')
          else
            ...children.map((child) => _ChildCard(
                  child: child,
                  onDelete: () => _confirmAndDelete(child),
                )),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.onDelete});

  final ChildProfile child;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  child.username.isNotEmpty
                      ? child.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.username,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Age range: ${child.ageRange}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              BrainForgeButton(
                label: 'Delete',
                onPressed: onDelete,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      );
}
