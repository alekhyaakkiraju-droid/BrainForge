import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';
import '../models/child_profile_model.dart';

/// Offline-first implementation: reads from Hive cache first,
/// syncs to/from Firestore when connectivity is available.
class ChildProfileRepositoryImpl implements ChildProfileRepository {
  ChildProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required Box<ChildProfileModel> localBox,
  })  : _firestore = firestore,
        _localBox = localBox;

  final FirebaseFirestore _firestore;
  final Box<ChildProfileModel> _localBox;

  static const _collection = 'childProfiles';

  @override
  Future<Result<ChildProfile>> getProfile(String profileId) async {
    try {
      final cached = _localBox.get(profileId);
      if (cached != null) {
        return Success(cached.toDomain());
      }

      final doc =
          await _firestore.collection(_collection).doc(profileId).get();
      if (!doc.exists || doc.data() == null) {
        return const Err(ServerFailure('Profile not found.'));
      }

      final model = _fromFirestore(doc.id, doc.data()!);
      await _localBox.put(profileId, model);
      return Success(model.toDomain());
    } on FirebaseException catch (e, st) {
      appLogger.e('getProfile failed', error: e, stackTrace: st);
      return Err(ServerFailure(e.message ?? 'Firestore error.'));
    } catch (e, st) {
      appLogger.e('getProfile unexpected error', error: e, stackTrace: st);
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<List<ChildProfile>>> listProfiles(
    String parentAccountId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('parentAccountId', isEqualTo: parentAccountId)
          .get();

      final profiles = snapshot.docs
          .map((doc) => _fromFirestore(doc.id, doc.data()).toDomain())
          .toList();

      return Success(profiles);
    } on FirebaseException catch (e, st) {
      appLogger.e('listProfiles failed', error: e, stackTrace: st);
      return Err(ServerFailure(e.message ?? 'Firestore error.'));
    } catch (e, st) {
      appLogger.e('listProfiles unexpected error', error: e, stackTrace: st);
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<ChildProfile>> saveProfile(ChildProfile profile) async {
    try {
      final model = ChildProfileModel.fromDomain(profile);
      await _localBox.put(profile.id, model);

      await _firestore
          .collection(_collection)
          .doc(profile.id)
          .set(_toFirestore(model));

      return Success(profile);
    } on FirebaseException catch (e, st) {
      appLogger.e('saveProfile failed', error: e, stackTrace: st);
      return Err(ServerFailure(e.message ?? 'Firestore error.'));
    } catch (e, st) {
      appLogger.e('saveProfile unexpected error', error: e, stackTrace: st);
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> deleteProfile(String profileId) async {
    try {
      await _localBox.delete(profileId);
      await _firestore.collection(_collection).doc(profileId).delete();
      return const Success(null);
    } on FirebaseException catch (e, st) {
      appLogger.e('deleteProfile failed', error: e, stackTrace: st);
      return Err(ServerFailure(e.message ?? 'Firestore error.'));
    } catch (e, st) {
      appLogger.e('deleteProfile unexpected error', error: e, stackTrace: st);
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<Result<ChildProfile>> switchMode(
    String profileId,
    AppMode newMode,
  ) async {
    final current = await getProfile(profileId);
    return current.fold(
      onSuccess: (profile) => saveProfile(profile.copyWith(activeMode: newMode)),
      onError: Err.new,
    );
  }

  ChildProfileModel _fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) =>
      ChildProfileModel(
        id: id,
        displayName: data['displayName'] as String,
        ageRangeIndex: data['ageRangeIndex'] as int,
        activeModeIndex: data['activeModeIndex'] as int,
        totalXp: data['totalXp'] as int,
        avatarAssetPath: data['avatarAssetPath'] as String?,
      );

  Map<String, dynamic> _toFirestore(ChildProfileModel model) => {
        'displayName': model.displayName,
        'ageRangeIndex': model.ageRangeIndex,
        'activeModeIndex': model.activeModeIndex,
        'totalXp': model.totalXp,
        'avatarAssetPath': model.avatarAssetPath,
      };
}
