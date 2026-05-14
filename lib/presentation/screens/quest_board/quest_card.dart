import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quest_model.dart';
import 'quest_board_provider.dart';
import 'package:flutter/material.dart';

/// A visual quest card for the Quest Board.
///
/// Three visual states driven by [QuestModel.status]:
///   • active    — elevated card with glowing accent border
///   • completed — normal card with checkmark overlay
///   • pending   — card rendered at reduced opacity (dimmed)
///
/// Touch target is always ≥ 48dp (enforced by the inner [ConstrainedBox]).
class QuestCard extends StatelessWidget {
  const QuestCard({
    required this.quest,
    required this.onTap,
    super.key,
  });

  final QuestModel quest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subjectColor = SubjectTheme.colorFor(quest.subject);
    final isActive = quest.status == 'active';
    final isCompleted = quest.status == 'completed';

    final card = _CardContent(
      quest: quest,
      subjectColor: subjectColor,
      isActive: isActive,
      isCompleted: isCompleted,
      onTap: isActive ? onTap : null,
    );

    if (isActive) {
      // Glow effect via a layered DecoratedBox behind the card.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2),
          boxShadow: [
            BoxShadow(
              color: subjectColor.withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: card,
      );
    }

    if (!isCompleted) {
      // Pending / future quests are dimmed.
      return Opacity(opacity: 0.55, child: card);
    }

    return card;
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.quest,
    required this.subjectColor,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  final QuestModel quest;
  final Color subjectColor;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: isActive
            ? AppColors.surface
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        clipBehavior: Clip.antiAlias,
        elevation: isActive ? 4 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: IntrinsicHeight(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subject color stripe
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.cardRadius),
                          bottomLeft: Radius.circular(AppSpacing.cardRadius),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            // Subject icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: subjectColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.buttonRadius,
                                ),
                              ),
                              child: Icon(
                                SubjectTheme.iconFor(quest.subject),
                                color: subjectColor,
                                size: AppSpacing.iconSizeMd,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Title
                            Expanded(
                              child: Text(
                                quest.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // XP badge
                            _XpBadge(xp: quest.xpReward),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Completed checkmark overlay
                if (isCompleted)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: AppSpacing.iconSizeMd,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
}

class _XpBadge extends StatelessWidget {
  const _XpBadge({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.xpGold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: AppColors.xpGold.withOpacity(0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.xpGold, size: 14),
            const SizedBox(width: 2),
            Text(
              '+$xp',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.xpGold,
              ),
            ),
          ],
        ),
      );
}
