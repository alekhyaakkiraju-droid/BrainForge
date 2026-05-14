import '../../data/models/quest_step_model.dart';

/// Retrieves quest micro-steps from the data layer.
// ignore: one_member_abstracts
abstract interface class QuestStepRepository {
  /// Returns all steps for [questId] ordered by [QuestStepModel.stepNumber].
  Future<List<QuestStepModel>> getStepsForQuest(String questId);
}