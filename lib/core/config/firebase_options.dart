// Firebase options are selected at build time based on the active flavor
// passed via --dart-define=FLAVOR=dev|staging|prod.
//
// IMPORTANT: This file must NOT contain real API keys or app IDs.
// Real credentials are injected by CI (WO-003) or copied locally via
// scripts/setup_firebase_credentials.sh. See docs/firebase_setup.md.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Active build flavor — set via `--dart-define=FLAVOR=dev|staging|prod`.
/// Defaults to 'dev' so local runs without the flag hit the dev project.
const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not supported by BrainForge.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidOptions;
      case TargetPlatform.iOS:
        return _iosOptions;
      // ignore: no_default_cases
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform.',
        );
    }
  }

  static FirebaseOptions get _androidOptions => switch (_flavor) {
        'prod' => _androidProd,
        'staging' => _androidStaging,
        _ => _androidDev,
      };

  static FirebaseOptions get _iosOptions => switch (_flavor) {
        'prod' => _iosProd,
        'staging' => _iosStaging,
        _ => _iosDev,
      };

  // ── Dev ────────────────────────────────────────────────────────────────────
  // Values injected by CI secret FIREBASE_OPTIONS_ANDROID_DEV / IOS_DEV
  // or via scripts/setup_firebase_credentials.sh locally.
  static const FirebaseOptions _androidDev = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY_DEV'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID_DEV'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_ANDROID_SENDER_ID_DEV'),
    projectId: 'brainforge-dev',
    storageBucket: 'brainforge-dev.appspot.com',
  );

  static const FirebaseOptions _iosDev = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY_DEV'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID_DEV'),
    messagingSenderId: String.fromEnvironment('FIREBASE_IOS_SENDER_ID_DEV'),
    projectId: 'brainforge-dev',
    storageBucket: 'brainforge-dev.appspot.com',
    iosBundleId: 'com.brainforge.app.dev',
  );

  // ── Staging ────────────────────────────────────────────────────────────────
  static const FirebaseOptions _androidStaging = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY_STAGING'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID_STAGING'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_ANDROID_SENDER_ID_STAGING'),
    projectId: 'brainforge-staging',
    storageBucket: 'brainforge-staging.appspot.com',
  );

  static const FirebaseOptions _iosStaging = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY_STAGING'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID_STAGING'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_IOS_SENDER_ID_STAGING'),
    projectId: 'brainforge-staging',
    storageBucket: 'brainforge-staging.appspot.com',
    iosBundleId: 'com.brainforge.app.staging',
  );

  // ── Prod ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions _androidProd = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY_PROD'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID_PROD'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_ANDROID_SENDER_ID_PROD'),
    projectId: 'brainforge-prod',
    storageBucket: 'brainforge-prod.appspot.com',
  );

  static const FirebaseOptions _iosProd = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY_PROD'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID_PROD'),
    messagingSenderId: String.fromEnvironment('FIREBASE_IOS_SENDER_ID_PROD'),
    projectId: 'brainforge-prod',
    storageBucket: 'brainforge-prod.appspot.com',
    iosBundleId: 'com.brainforge.app',
  );
}
