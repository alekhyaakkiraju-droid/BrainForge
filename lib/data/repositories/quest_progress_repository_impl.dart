import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/quest_progress_model.dart';
import '../../domain/repositories/quest_progress_repository.dart';
import 'firestore_provider.dart';

const _kCollection = 'questProgress';

/// Firestore implementation of [QuestProgressRepository].
///
/// Documents are stored at `questProgress/{profileId}_{questId}`.
class FirestoreQuestProgressRepository implements QuestProgressRepository {
  FirestoreQuestProgressRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<QuestProgressModel?> getProgress(
    String profileId,
    String questId,
  ) async {
    final docId = '${profileId}_$questId';
    final doc = await _db.collection(_kCollection).doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return QuestProgressModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<void> saveProgress(QuestProgressModel progress) =>
      _db.collection(_kCollection).doc(progress.docId).set(
            progress.toJson(),
            SetOptions(merge: true),
          );
}

/// Riverpod provider for [QuestProgressRepository].
final questProgressRepositoryProvider = Provider<QuestProgressRepository>(
  (ref) => FirestoreQuestProgressRepository(ref.watch(firestoreProvider)),
);
