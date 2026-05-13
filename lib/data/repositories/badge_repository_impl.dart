import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/badge_repository.dart';
import '../models/badge_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'badges';

class FirestoreBadgeRepository implements BadgeRepository {
  FirestoreBadgeRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<BadgeModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return BadgeModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<BadgeModel>> getByProfileId(String profileId) async {
    final snap = await _db
        .collection(_kCollection)
        .where('profileId', isEqualTo: profileId)
        .orderBy('unlockedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => BadgeModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> save(BadgeModel badge) => _db
      .collection(_kCollection)
      .doc(badge.id)
      .set(badge.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();
}

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) =>
    FirestoreBadgeRepository(ref.watch(firestoreProvider)));
