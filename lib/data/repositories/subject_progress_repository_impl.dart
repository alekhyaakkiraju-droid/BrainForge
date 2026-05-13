import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/subject_progress_repository.dart';
import '../models/subject_progress_model.dart';
import 'firestore_provider.dart';

const _kCollection = 'subjectProgress';

class FirestoreSubjectProgressRepository
    implements SubjectProgressRepository {
  FirestoreSubjectProgressRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<SubjectProgressModel?> getById(String id) async {
    final doc = await _db.collection(_kCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SubjectProgressModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<List<SubjectProgressModel>> getByProfileId(
    String profileId,
  ) async {
    final snap = await _db
        .collection(_kCollection)
        .where('profileId', isEqualTo: profileId)
        .get();
    return snap.docs
        .map(
          (d) => SubjectProgressModel.fromJson({...d.data(), 'id': d.id}),
        )
        .toList();
  }

  @override
  Future<SubjectProgressModel?> getByProfileAndSubject(
    String profileId,
    String subject,
  ) async {
    final snap = await _db
        .collection(_kCollection)
        .where('profileId', isEqualTo: profileId)
        .where('subject', isEqualTo: subject)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return SubjectProgressModel.fromJson({...d.data(), 'id': d.id});
  }

  @override
  Future<void> save(SubjectProgressModel progress) => _db
      .collection(_kCollection)
      .doc(progress.id)
      .set(progress.toJson(), SetOptions(merge: true));

  @override
  Future<void> delete(String id) =>
      _db.collection(_kCollection).doc(id).delete();

  @override
  Stream<List<SubjectProgressModel>> watchByProfileId(
    String profileId,
  ) =>
      _db
          .collection(_kCollection)
          .where('profileId', isEqualTo: profileId)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(
                  (d) => SubjectProgressModel.fromJson(
                    {...d.data(), 'id': d.id},
                  ),
                )
                .toList(),
          );
}

final subjectProgressRepositoryProvider =
    Provider<SubjectProgressRepository>((ref) =>
    FirestoreSubjectProgressRepository(ref.watch(firestoreProvider)));
