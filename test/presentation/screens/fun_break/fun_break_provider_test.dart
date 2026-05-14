import 'package:brainforge/data/repositories/session_repository_impl.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/domain/repositories/session_repository.dart';
import 'package:brainforge/presentation/screens/fun_break/fun_break_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

ProviderContainer _makeContainer(MockSessionRepository sessionRepo) {
  final mockAuth = MockFirebaseAuth();
  final mockFirestore = MockFirebaseFirestore();
  // ignore: unnecessary_lambdas
  when(() => mockAuth.authStateChanges())
      .thenAnswer((_) => const Stream.empty());
  final authNotifier = AuthStateNotifier(mockAuth, mockFirestore)
    ..state = const AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.student,
      uid: 'u1',
    );

  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((_) => authNotifier),
      sessionRepositoryProvider.overrideWithValue(sessionRepo),
    ],
  );
}

void main() {
  late MockSessionRepository mockSessionRepo;

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    when(() => mockSessionRepo.save(any())).thenAnswer((_) async {});
  });

  group('FunBreakState', () {
    test('initialises with breathing activity and full countdown', () {
      final state = FunBreakState.initial();
      expect(state.activity, BreakActivity.breathing);
      expect(state.remainingSeconds, kBreakDurationSeconds);
      expect(state.canReturn, isFalse);
    });

    test('progress is 0 at start', () {
      final state = FunBreakState.initial();
      expect(state.progress, 0.0);
    });

    test('progress is 1 when countdown reaches 0', () {
      const state = FunBreakState(
        activity: BreakActivity.breathing,
        remainingSeconds: 0,
        canReturn: true,
      );
      expect(state.progress, 1.0);
    });

    test('withActivity returns new state with changed activity', () {
      final state = FunBreakState.initial().withActivity(BreakActivity.dance);
      expect(state.activity, BreakActivity.dance);
      expect(state.remainingSeconds, kBreakDurationSeconds);
    });
  });

  group('FunBreakNotifier', () {
    test('starts countdown immediately on build', () {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      expect(
        container.read(funBreakProvider).remainingSeconds,
        kBreakDurationSeconds,
      );
    });

    test('canReturn is false during countdown', () {
      fakeAsync((fake) {
        final container = _makeContainer(mockSessionRepo);
        addTearDown(container.dispose);

        fake.elapse(const Duration(seconds: 30));

        expect(container.read(funBreakProvider).canReturn, isFalse);
      });
    });

    test('canReturn becomes true after 3 minutes', () {
      fakeAsync((fake) {
        final container = _makeContainer(mockSessionRepo);
        addTearDown(container.dispose);

        fake.elapse(const Duration(seconds: kBreakDurationSeconds + 1));

        expect(container.read(funBreakProvider).canReturn, isTrue);
      });
    });

    test('records break session after countdown', () {
      fakeAsync((fake) {
        final container = _makeContainer(mockSessionRepo);
        addTearDown(container.dispose);

        fake.elapse(const Duration(seconds: kBreakDurationSeconds + 1));

        verify(() => mockSessionRepo.save(any())).called(greaterThan(0));
      });
    });

    test('selectActivity changes the active activity', () {
      final container = _makeContainer(mockSessionRepo);
      addTearDown(container.dispose);

      container
          .read(funBreakProvider.notifier)
          .selectActivity(BreakActivity.dance);

      expect(container.read(funBreakProvider).activity, BreakActivity.dance);
    });
  });
}
