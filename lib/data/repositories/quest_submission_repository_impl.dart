import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/quest_submission_repository.dart';
import '../models/quest_submission_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'questSubmissions';

class FirestoreQuestSubmissionRepository
    implements QuestSubmissionRepository {
  FirestoreQuestSubmissionRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<QuestSubmissionModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return QuestSubmissionModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<QuestSubmissionModel>> getByProfileId(
    String profileId,
  ) async {
    final snap = await _db
        .collection(_kCollection)
        .where('profileId', isEqualTo: profileId)
        .orderBy('submittedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => QuestSubmissionModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<List<QuestSubmissionModel>> getByQuestId(String questId) async {
    final snap = await _db
        .collection(_kCollection)
        .where('questId', isEqualTo: questId)
        .get();
    return snap.docs
        .map((d) => QuestSubmissionModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> save(QuestSubmissionModel submission) => _db
      .collection(_kCollection)
      .doc(submission.id)
      .set(submission.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();
}

final questSubmissionRepositoryProvider =
    Provider<QuestSubmissionRepository>((ref) {
  return FirestoreQuestSubmissionRepository(ref.watch(firestoreProvider));
});
