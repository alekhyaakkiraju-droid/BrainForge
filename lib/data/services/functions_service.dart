import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps Firebase callable functions related to the parental-consent
/// and child-account flows.
class FunctionsService {
  const FunctionsService(this._functions);

  final FirebaseFunctions _functions;

  /// Records parental consent. Idempotent — safe to call more than once.
  Future<void> recordConsent() async {
    await _functions.httpsCallable('recordConsent').call<void>();
  }

  /// Creates a child account linked to the currently-authenticated parent.
  ///
  /// Returns the new child's UID.
  Future<String> createChildAccount({
    required String username,
    required String ageRange,
    required String avatarId,
    required String pin,
  }) async {
    final result = await _functions
        .httpsCallable('createChildAccount')
        .call<Map<String, dynamic>>({
      'username': username,
      'ageRange': ageRange,
      'avatarId': avatarId,
      'pin': pin,
    });
    return result.data['childUid'] as String;
  }

  /// Authenticates a child by username + PIN and returns a custom token
  /// suitable for [FirebaseAuth.signInWithCustomToken].
  Future<String> childSignIn({
    required String username,
    required String pin,
  }) async {
    final result = await _functions
        .httpsCallable('childSignIn')
        .call<Map<String, dynamic>>({
      'username': username,
      'pin': pin,
    });
    return result.data['customToken'] as String;
  }
}

final functionsServiceProvider = Provider<FunctionsService>(
  (ref) => FunctionsService(FirebaseFunctions.instance),
);
