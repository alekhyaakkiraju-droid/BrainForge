import 'package:brainforge/data/models/quest_model.dart';
import 'package:brainforge/data/models/quest_progress_model.dart';
import 'package:brainforge/data/models/quest_step_model.dart';
import 'package:brainforge/data/repositories/quest_progress_repository_impl.dart';
import 'package:brainforge/data/repositories/quest_repository_impl.dart';
import 'package:brainforge/data/repositories/quest_step_repository_impl.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/domain/repositories/quest_progress_repository.dart';
import 'package:brainforge/domain/repositories/quest_repository.dart';
import 'package:brainforge/domain/repositories/quest_step_repository.dart';
import 'package:brainforge/presentation/screens/quest_detail/quest_detail_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

class MockQuestStepRepository extends Mock implements QuestStepRepository {}

class MockQuestProgressRepository extends Mock
    implements QuestProgressRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

QuestModel _quest({String status = 'active'}) => QuestModel(
      id: 'q1',
      assignedToProfileId: 'u1',
      title: 'Test Quest',
      description: 'desc',
      subject: 'math',
      durationMinutes: 10,
      xpReward: 50,
      status: status,
      timeOfDay: 'morning',
      createdAt: DateTime(2026),
    );

QuestStepModel _step(String id, {String? correctAnswer = 'A'}) =>
    QuestStepModel(
      id: id,
      questId: 'q1',
      stepNumber: 1,
      instruction: 'Do it',
      iconName: 'star',
      type: 'multiple_choice',
      options: const ['A', 'B'],
      correctAnswer: correctAnswer,
    );

QuestProgressModel _progress({List<int> completed = const []}) =>
    QuestProgressModel(
      profileId: 'u1',
      questId: 'q1',
      completedStepIndices: completed,
      updatedAt: DateTime(2026),
    );

ProviderContainer _container({
  required QuestRepository questRepo,
  required QuestStepRepository stepRepo,
  required QuestProgressRepository progressRepo,
}) {
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
      questRepositoryProvider.overrideWithValue(questRepo),
      questStepRepositoryProvider.overrideWithValue(stepRepo),
      questProgressRepositoryProvider.overrideWithValue(progressRepo),
    ],
  );
}

void main() {
  late MockQuestRepository mockQuestRepo;
  late MockQuestStepRepository mockStepRepo;
  late MockQuestProgressRepository mockProgressRepo;

  setUp(() {
    mockQuestRepo = MockQuestRepository();
    mockStepRepo = MockQuestStepRepository();
    mockProgressRepo = MockQuestProgressRepository();
  });

  group('QuestDetailNotifier.initialise', () {
    test('loads quest, steps, and existing progress', () async {
      when(() => mockQuestRepo.getById('q1'))
          .thenAnswer((_) async => _quest());
      when(() => mockStepRepo.getStepsForQuest('q1'))
          .thenAnswer((_) async => [_step('s1'), _step('s2')]);
      when(() => mockProgressRepo.getProgress('u1', 'q1'))
          .thenAnswer((_) async => _progress(completed: [0]));

      final container = _container(
        questRepo: mockQuestRepo,
        stepRepo: mockStepRepo,
        progressRepo: mockProgressRepo,
      );
      addTearDown(container.dispose);

      await container.read(questDetailProvider.notifier).initialise('q1');

      final state = container.read(questDetailProvider).valueOrNull;
      expect(state, isNotNull);
      expect(state!.quest.title, 'Test Quest');
      expect(state.steps, hasLength(2));
      expect(state.progress.completedStepIndices, [0]);
    });

    test('creates blank progress when none exists in Firestore', () async {
      when(() => mockQuestRepo.getById('q1'))
          .thenAnswer((_) async => _quest());
      when(() => mockStepRepo.getStepsForQuest('q1'))
          .thenAnswer((_) async => [_step('s1')]);
      when(() => mockProgressRepo.getProgress('u1', 'q1'))
          .thenAnswer((_) async => null);

      final container = _container(
        questRepo: mockQuestRepo,
        stepRepo: mockStepRepo,
        progressRepo: mockProgressRepo,
      );
      addTearDown(container.dispose);

      await container.read(questDetailProvider.notifier).initialise('q1');

      final state = container.read(questDetailProvider).valueOrNull;
      expect(state?.progress.completedStepIndices, isEmpty);
    });

    test('emits error state when quest is not found', () async {
      when(() => mockQuestRepo.getById('q1')).thenAnswer((_) async => null);

      final container = _container(
        questRepo: mockQuestRepo,
        stepRepo: mockStepRepo,
        progressRepo: mockProgressRepo,
      );
      addTearDown(container.dispose);

      await container.read(questDetailProvider.notifier).initialise('q1');

      expect(container.read(questDetailProvider).hasError, isTrue);
    });
  });

  group('QuestDetailNotifier.completeStep', () {
    test('advances progress and persists to Firestore', () async {
      when(() => mockQuestRepo.getById('q1'))
          .thenAnswer((_) async => _quest());
      when(() => mockStepRepo.getStepsForQuest('q1'))
          .thenAnswer((_) async => [_step('s1'), _step('s2')]);
      when(() => mockProgressRepo.getProgress('u1', 'q1'))
          .thenAnswer((_) async => _progress());
      when(() => mockProgressRepo.saveProgress(any()))
          .thenAnswer((_) async {});

      final container = _container(
        questRepo: mockQuestRepo,
        stepRepo: mockStepRepo,
        progressRepo: mockProgressRepo,
      );
      addTearDown(container.dispose);

      await container.read(questDetailProvider.notifier).initialise('q1');
      await container.read(questDetailProvider.notifier).completeStep(0);

      final progress =
          container.read(questDetailProvider).valueOrNull!.progress;
      expect(progress.completedStepIndices, contains(0));
      verify(() => mockProgressRepo.saveProgress(any())).called(1);
    });

    test('ignores duplicate completeStep calls for same index', () async {
      when(() => mockQuestRepo.getById('q1'))
          .thenAnswer((_) async => _quest());
      when(() => mockStepRepo.getStepsForQuest('q1'))
          .thenAnswer((_) async => [_step('s1'), _step('s2')]);
      when(() => mockProgressRepo.getProgress('u1', 'q1'))
          .thenAnswer((_) async => _progress());
      when(() => mockProgressRepo.saveProgress(any()))
          .thenAnswer((_) async {});

      final container = _container(
        questRepo: mockQuestRepo,
        stepRepo: mockStepRepo,
        progressRepo: mockProgressRepo,
      );
      addTearDown(container.dispose);

      await container.read(questDetailProvider.notifier).initialise('q1');
      await container.read(questDetailProvider.notifier).completeStep(0);
      await container.read(questDetailProvider.notifier).completeStep(0);

      final progress =
          container.read(questDetailProvider).valueOrNull!.progress;
      expect(progress.completedStepIndices.where((i) => i == 0), hasLength(1));
    });
  });

  group('QuestDetailState', () {
    test('isComplete is true when all steps are completed', () {
      final state = QuestDetailState(
        quest: _quest(),
        steps: [_step('s1'), _step('s2')],
        progress: _progress(completed: [0, 1]),
      );
      expect(state.isComplete, isTrue);
    });

    test('isComplete is false while steps remain', () {
      final state = QuestDetailState(
        quest: _quest(),
        steps: [_step('s1'), _step('s2')],
        progress: _progress(completed: [0]),
      );
      expect(state.isComplete, isFalse);
    });

    test('currentStepIndex equals number of completed steps', () {
      final state = QuestDetailState(
        quest: _quest(),
        steps: [_step('s1'), _step('s2'), _step('s3')],
        progress: _progress(completed: [0, 1]),
      );
      expect(state.currentStepIndex, 2);
    });
  });
}
