import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// Animated XP / task-completion progress bar.
///
/// Always shows a label and optional icon so context is never
/// conveyed by colour alone (WCAG 1.4.1).
class BrainForgeProgressBar extends StatelessWidget {
  const BrainForgeProgressBar({
    required this.value,
    required this.label,
    super.key,
    this.color,
    this.trackColor,
    this.icon,
    this.height = 16,
    this.showPercentage = true,
  }) : assert(
          value >= 0 && value <= 1,
          'value must be between 0.0 and 1.0',
        );

  /// Progress from 0.0 to 1.0.
  final double value;
  final String label;
  final Color? color;
  final Color? trackColor;
  final IconData? icon;
  final double height;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? AppColors.primary;
    final effectiveTrack =
        trackColor ?? AppColors.primaryLight;
    final pct = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: effectiveColor),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showPercentage)
              Text(
                '$pct%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: effectiveColor,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            color: effectiveColor,
            backgroundColor: effectiveTrack,
          ),
        ),
      ],
    );
  }
}
