import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/session_repository.dart';
import '../models/session_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'sessions';

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<SessionModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SessionModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<SessionModel>> getByProfileId(String profileId) async {
    final snap = await _db
        .collection(_kCollection)
        .where('profileId', isEqualTo: profileId)
        .orderBy('startedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => SessionModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> save(SessionModel session) => _db
      .collection(_kCollection)
      .doc(session.id)
      .set(session.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();

  @override
  Stream<List<SessionModel>> watchByProfileId(String profileId) => _db
      .collection(_kCollection)
      .where('profileId', isEqualTo: profileId)
      .orderBy('startedAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => SessionModel.fromJson({...d.data(), 'id': d.id}))
            .toList(),
      );
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) =>
    FirestoreSessionRepository(ref.watch(firestoreProvider)));
