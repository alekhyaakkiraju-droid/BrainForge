import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/xp_record_repository.dart';
import '../models/xp_record_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'xpRecords';

class FirestoreXpRecordRepository implements XpRecordRepository {
  FirestoreXpRecordRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<XpRecordModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return XpRecordModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<XpRecordModel>> getByProfileId(String profileId) async {
    final snap = await _db
        .collection(_kCollection)
        .where('profileId', isEqualTo: profileId)
        .orderBy('earnedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => XpRecordModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> save(XpRecordModel record) => _db
      .collection(_kCollection)
      .doc(record.id)
      .set(record.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();
}

final xpRecordRepositoryProvider = Provider<XpRecordRepository>((ref) {
  return FirestoreXpRecordRepository(ref.watch(firestoreProvider));
});
