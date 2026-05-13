import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Shared placeholder used by every route until its real screen is built.
///
/// Includes a persistent counter to verify state is preserved across
/// navigation (acceptance criterion for WO-005).
class PlaceholderScreen extends ConsumerStatefulWidget {
  const PlaceholderScreen({
    required this.routeName,
    required this.icon,
    super.key,
    this.color,
  });

  final String routeName;
  final IconData icon;
  final Color? color;

  @override
  ConsumerState<PlaceholderScreen> createState() =>
      _PlaceholderScreenState();
}

class _PlaceholderScreenState extends ConsumerState<PlaceholderScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: AppSpacing.iconSizeXl, color: color),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.routeName,
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
              maxLines: 1,
            ),
            const SizedBox(height: AppSpacing.xl),
            // State-preservation counter
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  onPressed: () => setState(() => _counter--),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(AppSpacing.minTouchTarget),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _counter++),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(AppSpacing.minTouchTarget),
                    backgroundColor: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
