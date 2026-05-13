import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/mood_entry_repository.dart';
import '../models/mood_entry_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'moodEntries';

class FirestoreMoodEntryRepository implements MoodEntryRepository {
  FirestoreMoodEntryRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<MoodEntryModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return MoodEntryModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<MoodEntryModel>> getByProfileId(
    String profileId, {
    int limit = 30,
  }) async {
    final snap = await _db
        .collection(_kCollection)
        .where('profileId', isEqualTo: profileId)
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => MoodEntryModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> save(MoodEntryModel entry) => _db
      .collection(_kCollection)
      .doc(entry.id)
      .set(entry.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();
}

final moodEntryRepositoryProvider = Provider<MoodEntryRepository>((ref) {
  return FirestoreMoodEntryRepository(ref.watch(firestoreProvider));
});
