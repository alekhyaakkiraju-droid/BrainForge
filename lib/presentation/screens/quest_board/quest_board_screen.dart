import 'dart:async';

import '../../../core/constants/app_spacing.dart';
import 'package:brainforge/core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quest_model.dart';
import 'quest_board_provider.dart';
import 'quest_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuestBoardScreen extends ConsumerWidget {
  const QuestBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questAsync = ref.watch(questBoardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Today's Quests"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: questAsync.when(
        loading: () => const _LoadingView(),
        error: (_, __) => const _ErrorView(),
        data: (quests) {
          if (quests.isEmpty) return const _EmptyView();
          return _QuestBoardContent(quests: quests);
        },
      ),
    );
  }
}

class _QuestBoardContent extends StatelessWidget {
  const _QuestBoardContent({required this.quests});

  final List<QuestModel> quests;

  @override
  Widget build(BuildContext context) {
    final groups = groupQuestsByTimeOfDay(quests);
    const sections = ['morning', 'afternoon', 'evening'];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        for (final section in sections)
          if ((groups[section] ?? []).isNotEmpty) ...[
            _SectionHeader(timeOfDay: section),
            const SizedBox(height: AppSpacing.sm),
            ...(groups[section] ?? []).map(
              (quest) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: QuestCard(
                  key: ValueKey(quest.id),
                  quest: quest,
                  onTap: quest.status == 'active'
                      ? () => unawaited(
                            context.push(
                              AppRoutes.questDetail,
                              extra: quest.id,
                            ),
                          )
                      : null,
                ),
              ),
            )),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.timeOfDay});

  final String timeOfDay;

  @override
  Widget build(BuildContext context) {
    final label =
        '${timeOfDay[0].toUpperCase()}${timeOfDay.substring(1)}';

    return Row(
      children: [
        Icon(
          SubjectTheme.iconForTimeOfDay(timeOfDay),
          color: AppColors.primary,
          size: AppSpacing.iconSizeMd,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading your quests…',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconSizeXl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No quests today!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Time to relax 🎉',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.onSurfaceVariant,
                size: AppSpacing.iconSizeXl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load quests.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Check your connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
