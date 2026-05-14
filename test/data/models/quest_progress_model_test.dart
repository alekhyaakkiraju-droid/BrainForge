import 'package:brainforge/data/models/quest_progress_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QuestProgressModel make({
    String profileId = 'u1',
    String questId = 'q1',
    List<int> completed = const [],
  }) =>
      QuestProgressModel(
        profileId: profileId,
        questId: questId,
        completedStepIndices: completed,
        updatedAt: DateTime(2026),
      );

  group('QuestProgressModel.docId', () {
    test('combines profileId and questId with underscore', () {
      expect(make(profileId: 'abc', questId: 'xyz').docId, 'abc_xyz');
    });
  });

  group('QuestProgressModel.nextStepIndex', () {
    test('is 0 when no steps completed', () {
      expect(make().nextStepIndex, 0);
    });

    test('equals the number of completed steps', () {
      expect(make(completed: [0, 1, 2]).nextStepIndex, 3);
    });
  });

  group('QuestProgressModel.withStepCompleted', () {
    test('appends the step index', () {
      final updated = make(completed: [0]).withStepCompleted(1);
      expect(updated.completedStepIndices, [0, 1]);
    });

    test('preserves profileId and questId', () {
      final base = make(profileId: 'p', questId: 'q');
      final updated = base.withStepCompleted(0);
      expect(updated.profileId, 'p');
      expect(updated.questId, 'q');
    });
  });

  group('QuestProgressModel serialisation', () {
    test('fromJson parses completedStepIndices correctly', () {
      final m = QuestProgressModel.fromJson({
        'profileId': 'p',
        'questId': 'q',
        'completedStepIndices': [0, 1, 2],
        'updatedAt': '2026-01-01T00:00:00.000',
      });
      expect(m.completedStepIndices, [0, 1, 2]);
    });

    test('fromJson defaults to empty list when field missing', () {
      final m = QuestProgressModel.fromJson({
        'profileId': 'p',
        'questId': 'q',
        'updatedAt': '2026-01-01T00:00:00.000',
      });
      expect(m.completedStepIndices, isEmpty);
    });
  });
}
