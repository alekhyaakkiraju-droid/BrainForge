import 'package:brainforge/data/models/quest_model.dart';
import 'package:brainforge/data/models/quest_progress_model.dart';
import 'package:brainforge/data/models/quest_step_model.dart';
import 'package:brainforge/data/repositories/quest_progress_repository_impl.dart';
import 'package:brainforge/data/repositories/quest_repository_impl.dart';
import 'package:brainforge/data/repositories/quest_step_repository_impl.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The loaded quest detail state — null until initialise() completes.
class QuestDetailState {
  const QuestDetailState({
    required this.quest,
    required this.steps,
    required this.progress,
  });

  final QuestModel quest;
  final List<QuestStepModel> steps;
  final QuestProgressModel progress;

  /// 0-based index of the step currently shown to the child.
  int get currentStepIndex => progress.nextStepIndex;

  bool get isComplete => currentStepIndex >= steps.length;

  QuestDetailState withProgress(QuestProgressModel updated) =>
      QuestDetailState(quest: quest, steps: steps, progress: updated);
}

/// Manages loading quest data, tracking step progress, and saving to Firestore.
class QuestDetailNotifier extends AutoDisposeNotifier<AsyncValue<QuestDetailState>> {
  @override
  AsyncValue<QuestDetailState> build() => const AsyncValue.loading();

  /// Loads the quest, its steps, and saved progress from Firestore.
  Future<void> initialise(String questId) async {
    state = const AsyncValue.loading();
    try {
      final auth = ref.read(authStateProvider);
      final profileId = auth.uid ?? '';

      final questRepo = ref.read(questRepositoryProvider);
      final stepRepo = ref.read(questStepRepositoryProvider);
      final progressRepo = ref.read(questProgressRepositoryProvider);

      final quest = await questRepo.getById(questId);
      if (quest == null) throw StateError('Quest $questId not found.');

      final steps = await stepRepo.getStepsForQuest(questId);

      final existingProgress = await progressRepo.getProgress(
        profileId,
        questId,
      );

      final progress = existingProgress ??
          QuestProgressModel(
            profileId: profileId,
            questId: questId,
            completedStepIndices: const [],
            updatedAt: DateTime.now(),
          );

      state = AsyncValue.data(
        QuestDetailState(quest: quest, steps: steps, progress: progress),
      );
    } on Exception catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Records a step completion and persists it to Firestore.
  ///
  /// Does nothing if the quest is already complete or the step index is
  /// out of bounds.
  Future<void> completeStep(int stepIndex) async {
    final current = state.valueOrNull;
    if (current == null || stepIndex >= current.steps.length) return;
    if (current.progress.completedStepIndices.contains(stepIndex)) return;

    final updated = current.progress.withStepCompleted(stepIndex);
    state = AsyncValue.data(current.withProgress(updated));

    try {
      await ref.read(questProgressRepositoryProvider).saveProgress(updated);
    } on Exception {
      // Progress failed to save; keep local state as-is and retry on next
      // completion so partial progress is not lost.
    }
  }

  /// Marks the parent quest document as completed in Firestore.
  Future<void> markQuestComplete() async {
    final current = state.valueOrNull;
    if (current == null) return;

    try {
      final completed = QuestModel(
        id: current.quest.id,
        assignedToProfileId: current.quest.assignedToProfileId,
        title: current.quest.title,
        description: current.quest.description,
        subject: current.quest.subject,
        durationMinutes: current.quest.durationMinutes,
        xpReward: current.quest.xpReward,
        status: 'completed',
        timeOfDay: current.quest.timeOfDay,
        scheduledFor: current.quest.scheduledFor,
        completedAt: DateTime.now(),
        createdAt: current.quest.createdAt,
      );
      await ref.read(questRepositoryProvider).save(completed);
    } on Exception {
      // Best-effort — XP calculation will re-validate status on the server.
    }
  }
}

/// The provider used by [QuestDetailScreen].
final questDetailProvider = AutoDisposeNotifierProvider<
    QuestDetailNotifier, AsyncValue<QuestDetailState>>(
  QuestDetailNotifier.new,
);
