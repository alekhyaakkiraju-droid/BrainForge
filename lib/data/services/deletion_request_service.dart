import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides [DeletionRequestService] as a Riverpod singleton.
final deletionRequestServiceProvider = Provider<DeletionRequestService>(
  (ref) => DeletionRequestService(FirebaseFirestore.instance),
);

/// Writes deletion-request documents to Firestore.
///
/// The actual data purge is performed by the [processDataDeletion] Cloud
/// Function that listens to `deletion_requests/` document creation.
class DeletionRequestService {
  const DeletionRequestService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Creates a pending deletion request for [childUid].
  ///
  /// Returns the generated request document ID so callers can track status.
  Future<String> requestChildDataDeletion({
    required String parentUid,
    required String childUid,
  }) async {
    final ref = _firestore.collection('deletion_requests').doc();
    await ref.set({
      'parentUid': parentUid,
      'childUid': childUid,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    return ref.id;
  }

  /// Fetches all child profiles linked to [parentUid].
  Future<List<ChildProfile>> fetchChildProfiles(String parentUid) async {
    final snap = await _firestore
        .collection('users')
        .where('parentId', isEqualTo: parentUid)
        .where('role', isEqualTo: 'student')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return ChildProfile(
        uid: doc.id,
        username: data['username'] as String? ?? '',
        avatarId: data['avatarId'] as String? ?? '',
        ageRange: data['ageRange'] as String? ?? '',
      );
    }).toList();
  }
}

/// Minimal child profile data needed for the deletion confirmation UI.
class ChildProfile {
  const ChildProfile({
    required this.uid,
    required this.username,
    required this.avatarId,
    required this.ageRange,
  });

  final String uid;
  final String username;
  final String avatarId;
  final String ageRange;
}
