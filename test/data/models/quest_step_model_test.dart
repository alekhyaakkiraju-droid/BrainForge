import 'package:brainforge/data/models/quest_step_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QuestStepModel _make({
    String id = 's1',
    String type = 'multiple_choice',
    List<String> options = const ['A', 'B', 'C'],
    String? correctAnswer = 'A',
  }) =>
      QuestStepModel(
        id: id,
        questId: 'q1',
        stepNumber: 1,
        instruction: 'Pick one',
        iconName: 'star',
        type: type,
        options: options,
        correctAnswer: correctAnswer,
      );

  group('QuestStepModel.fromJson', () {
    test('deserialises all required fields', () {
      final step = QuestStepModel.fromJson({
        'id': 's1',
        'questId': 'q1',
        'stepNumber': 1,
        'instruction': 'Do it',
        'type': 'text_input',
      });

      expect(step.id, 's1');
      expect(step.questId, 'q1');
      expect(step.instruction, 'Do it');
      expect(step.iconName, 'star');
      expect(step.options, isEmpty);
      expect(step.correctAnswer, isNull);
    });

    test('deserialises options list when present', () {
      final step = QuestStepModel.fromJson({
        'id': 's1',
        'questId': 'q1',
        'stepNumber': 2,
        'instruction': 'Pick',
        'type': 'multiple_choice',
        'options': ['X', 'Y', 'Z'],
        'correctAnswer': 'X',
      });

      expect(step.options, ['X', 'Y', 'Z']);
      expect(step.correctAnswer, 'X');
    });
  });

  group('QuestStepModel.toJson', () {
    test('round-trips through fromJson', () {
      final original = _make();
      final roundTripped = QuestStepModel.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.type, original.type);
      expect(roundTripped.options, original.options);
      expect(roundTripped.correctAnswer, original.correctAnswer);
    });
  });

  group('QuestStepModel.isCorrect', () {
    test('returns true when answer matches correctAnswer case-insensitively',
        () {
      final step = _make(correctAnswer: 'Paris');
      expect(step.isCorrect('paris'), isTrue);
      expect(step.isCorrect('PARIS'), isTrue);
      expect(step.isCorrect(' Paris '), isTrue);
    });

    test('returns false for a wrong answer', () {
      final step = _make(correctAnswer: 'Paris');
      expect(step.isCorrect('London'), isFalse);
    });

    test('returns true for any answer when correctAnswer is null', () {
      final step = _make(correctAnswer: null);
      expect(step.isCorrect('anything'), isTrue);
      expect(step.isCorrect(''), isTrue);
    });
  });
}
