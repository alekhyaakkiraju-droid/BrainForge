import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/quest_step_model.dart';
import '../../domain/repositories/quest_step_repository.dart';
import 'firestore_provider.dart';

/// Firestore implementation of [QuestStepRepository].
///
/// Steps live in the `quests/{questId}/steps/` sub-collection, ordered by
/// the `stepNumber` field so the first step is always returned first.
class FirestoreQuestStepRepository implements QuestStepRepository {
  FirestoreQuestStepRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<List<QuestStepModel>> getStepsForQuest(String questId) async {
    final snap = await _db
        .collection('quests')
        .doc(questId)
        .collection('steps')
        .orderBy('stepNumber')
        .get();

    return snap.docs
        .map(
          (d) => QuestStepModel.fromJson({...d.data(), 'id': d.id}),
        )
        .toList();
  }
}

/// Riverpod provider for [QuestStepRepository].
final questStepRepositoryProvider = Provider<QuestStepRepository>(
  (ref) => FirestoreQuestStepRepository(ref.watch(firestoreProvider)),
);
