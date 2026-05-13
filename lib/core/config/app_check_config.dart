import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Signature matching [FirebaseAppCheck.activate] so the activator can be
/// swapped in tests without initializing a real Firebase instance.
typedef AppCheckActivator = Future<void> Function({
  required AndroidProvider androidProvider,
  required AppleProvider appleProvider,
  WebProvider? webProvider,
});

/// Activates Firebase App Check with platform-appropriate attestation.
///
/// Debug builds use the [DebugProvider] so emulators and simulators continue
/// to work without real attestation hardware.
/// Release/profile builds use Play Integrity (Android) and DeviceCheck (iOS),
/// which require enrollment in the respective attestation programmes.
///
/// [activator] is only set in unit tests to inject a fake activation function.
Future<void> initAppCheck({AppCheckActivator? activator}) async {
  final activate = activator ?? FirebaseAppCheck.instance.activate;
  await activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );
}
