import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/quest_repository.dart';
import '../models/quest_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'quests';

class FirestoreQuestRepository implements QuestRepository {
  FirestoreQuestRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<QuestModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return QuestModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<QuestModel>> getByProfileId(
    String profileId, {
    String? status,
  }) async {
    var q = _db
        .collection(_kCollection)
        .where('assignedToProfileId', isEqualTo: profileId);
    if (status != null) q = q.where('status', isEqualTo: status);
    final snap = await q.get();
    return snap.docs
        .map((d) => QuestModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> save(QuestModel quest) => _db
      .collection(_kCollection)
      .doc(quest.id)
      .set(quest.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();

  @override
  Stream<List<QuestModel>> watchByProfileId(String profileId) => _db
      .collection(_kCollection)
      .where('assignedToProfileId', isEqualTo: profileId)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => QuestModel.fromJson({...d.data(), 'id': d.id}))
            .toList(),
      );
}

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  return FirestoreQuestRepository(ref.watch(firestoreProvider));
});
