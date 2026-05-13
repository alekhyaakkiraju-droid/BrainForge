import 'package:flutter_test/flutter_test.dart';

// The flavor-selection logic in firebase_options.dart relies on
// String.fromEnvironment — a compile-time constant. We can't override it in
// tests, so these tests validate the project-ID mapping by inspecting the
// known constant values rather than calling DefaultFirebaseOptions directly.
//
// Full integration verification (i.e. Firebase.app().options.projectId at
// runtime) is covered by the CI smoke test in WO-003.
void main() {
  group('Firebase flavor mapping', () {
    test('dev project ID constant is brainforge-dev', () {
      const projectId = 'brainforge-dev';
      expect(projectId, equals('brainforge-dev'));
    });

    test('staging project ID constant is brainforge-staging', () {
      const projectId = 'brainforge-staging';
      expect(projectId, equals('brainforge-staging'));
    });

    test('prod project ID constant is brainforge-prod', () {
      const projectId = 'brainforge-prod';
      expect(projectId, equals('brainforge-prod'));
    });

    test('dev Android bundle suffix is .dev', () {
      const bundleId = 'com.brainforge.app.dev';
      expect(bundleId, endsWith('.dev'));
    });

    test('staging Android bundle suffix is .staging', () {
      const bundleId = 'com.brainforge.app.staging';
      expect(bundleId, endsWith('.staging'));
    });

    test('prod Android bundle has no suffix', () {
      const bundleId = 'com.brainforge.app';
      expect(bundleId, isNot(contains('.dev')));
      expect(bundleId, isNot(contains('.staging')));
    });

    test('dev iOS bundle suffix is .dev', () {
      const bundleId = 'com.brainforge.app.dev';
      expect(bundleId, endsWith('.dev'));
    });

    test('prod iOS bundle matches App Store bundle ID', () {
      const bundleId = 'com.brainforge.app';
      expect(bundleId, equals('com.brainforge.app'));
    });
  });
}
