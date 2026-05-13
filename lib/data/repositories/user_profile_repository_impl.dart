import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/user_profile_repository.dart';
import '../models/user_profile_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'userProfiles';

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<UserProfileModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<UserProfileModel>> getByParentUid(String parentUid) async {
    final snap = await _db
        .collection(_kCollection)
        .where('parentUid', isEqualTo: parentUid)
        .get();
    return snap.docs
        .map((d) => UserProfileModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> save(UserProfileModel profile) => _db
      .collection(_kCollection)
      .doc(profile.id)
      .set(profile.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();

  @override
  Stream<UserProfileModel?> watch(String id) => _db
      .collection(_kCollection)
      .doc(id)
      .snapshots()
      .map(
        (doc) => doc.exists && doc.data() != null
            ? UserProfileModel.fromJson({...doc.data()!, 'id': doc.id})
            : null,
      );
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) =>
    FirestoreUserProfileRepository(ref.watch(firestoreProvider)));
