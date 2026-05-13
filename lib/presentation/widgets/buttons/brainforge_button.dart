import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Button variant controls visual weight.
enum BrainForgeButtonVariant { filled, outlined, ghost }

/// ADHD-aware primary action button.
///
/// Enforces ≥48 dp touch target, icon-first layout, and a maximum of
/// one line of label text — no walls of text on interactive elements.
class BrainForgeButton extends StatelessWidget {
  const BrainForgeButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.variant = BrainForgeButtonVariant.filled,
    this.color,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BrainForgeButtonVariant variant;
  final Color? color;
  final bool isLoading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final child = _buildChild(context);

    return SizedBox(
      width: width,
      height: AppSpacing.minTouchTarget,
      child: switch (variant) {
        BrainForgeButtonVariant.filled => FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(backgroundColor: effectiveColor),
            child: child,
          ),
        BrainForgeButtonVariant.outlined => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: effectiveColor,
              side: BorderSide(color: effectiveColor, width: 2),
            ),
            child: child,
          ),
        BrainForgeButtonVariant.ghost => TextButton(
            onPressed: isLoading ? null : onPressed,
            style:
                TextButton.styleFrom(foregroundColor: effectiveColor),
            child: child,
          ),
      },
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
