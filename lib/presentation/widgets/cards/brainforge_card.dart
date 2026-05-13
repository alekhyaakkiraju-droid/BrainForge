import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// ADHD-aware content card.
///
/// Enforces ≥48 dp tap target when [onTap] is provided,
/// uses bold colour accent on the leading edge, and limits
/// child content to an uncluttered single-responsibility unit.
class BrainForgeCard extends StatelessWidget {
  const BrainForgeCard({
    required this.child,
    super.key,
    this.onTap,
    this.accentColor,
    this.padding,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Optional left-edge accent stripe colour.
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        Theme.of(context).colorScheme.surface;
    final effectivePadding =
        padding ?? const EdgeInsets.all(AppSpacing.md);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: ConstrainedBox(
          // Ensure tappable cards always meet the 48dp minimum height
          constraints: BoxConstraints(
            minHeight: onTap != null ? AppSpacing.minTouchTarget : 0,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (accentColor != null)
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.cardRadius),
                        bottomLeft:
                            Radius.circular(AppSpacing.cardRadius),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: effectivePadding,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
