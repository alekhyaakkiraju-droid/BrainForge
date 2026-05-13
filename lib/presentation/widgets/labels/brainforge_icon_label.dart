import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// Icon + short text pair — the atomic unit of ADHD-aware UI.
///
/// Never renders more than 2 lines of text. Icon is always present
/// so meaning is never conveyed by text alone.
class BrainForgeIconLabel extends StatelessWidget {
  const BrainForgeIconLabel({
    required this.icon,
    required this.label,
    super.key,
    this.color,
    this.iconSize = AppSpacing.iconSizeMd,
    this.axis = Axis.horizontal,
    this.textStyle,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final double iconSize;

  /// Horizontal = icon left of text. Vertical = icon above text.
  final Axis axis;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        color ?? Theme.of(context).colorScheme.primary;
    final resolvedStyle = (textStyle ??
            Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(color: color);

    final iconWidget = Icon(icon, size: iconSize, color: iconColor);
    final textWidget = Text(
      label,
      style: resolvedStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: textWidget),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: AppSpacing.xs),
        textWidget,
      ],
    );
  }
}
