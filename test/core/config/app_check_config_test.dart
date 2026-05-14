import 'package:brainforge/core/config/app_check_config.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // kDebugMode is always true when running `flutter test`, so all tests below
  // assert the debug-provider path.  The release-provider path is verified by
  // the typed signature of [initAppCheck] and integration tests on device.

  test('calls activator with debug providers when kDebugMode is true',
      () async {
    AndroidProvider? capturedAndroid;
    AppleProvider? capturedApple;

    await initAppCheck(
      activator: ({
        required androidProvider,
        required appleProvider,
        webProvider,
      }) async {
        capturedAndroid = androidProvider;
        capturedApple = appleProvider;
      },
    );

    expect(capturedAndroid, AndroidProvider.debug);
    expect(capturedApple, AppleProvider.debug);
  });

  test('activator is called exactly once per initAppCheck call', () async {
    var callCount = 0;

    await initAppCheck(
      activator: ({
        required androidProvider,
        required appleProvider,
        webProvider,
      }) async {
        callCount++;
      },
    );

    expect(callCount, 1);
  });

  test('initAppCheck propagates activator errors', () async {
    expect(
      () => initAppCheck(
        activator: ({
          required androidProvider,
          required appleProvider,
          webProvider,
        }) async {
          throw Exception('attestation failed');
        },
      ),
      throwsException,
    );
  });
}
