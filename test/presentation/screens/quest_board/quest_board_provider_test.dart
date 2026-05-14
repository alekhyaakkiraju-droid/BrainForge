import 'package:brainforge/data/models/quest_model.dart';
import 'package:brainforge/presentation/screens/quest_board/quest_board_provider.dart';
import 'package:flutter_test/flutter_test.dart';

QuestModel _quest(String id, String timeOfDay, String status) => QuestModel(
      id: id,
      assignedToProfileId: 'child-1',
      title: 'Test quest $id',
      description: 'desc',
      subject: 'math',
      durationMinutes: 10,
      xpReward: 50,
      status: status,
      timeOfDay: timeOfDay,
      createdAt: DateTime(2026),
    );

void main() {
  group('groupQuestsByTimeOfDay', () {
    test('returns empty lists for each section when input is empty', () {
      final result = groupQuestsByTimeOfDay([]);
      expect(result.keys, containsAll(['morning', 'afternoon', 'evening']));
      expect(result['morning'], isEmpty);
      expect(result['afternoon'], isEmpty);
      expect(result['evening'], isEmpty);
    });

    test('places quests in correct sections', () {
      final quests = [
        _quest('m1', 'morning', 'active'),
        _quest('a1', 'afternoon', 'pending'),
        _quest('e1', 'evening', 'completed'),
        _quest('m2', 'morning', 'pending'),
      ];
      final result = groupQuestsByTimeOfDay(quests);

      expect(result['morning'], hasLength(2));
      expect(result['afternoon'], hasLength(1));
      expect(result['evening'], hasLength(1));
    });

    test('is case-insensitive for timeOfDay values', () {
      final quests = [
        _quest('q1', 'Morning', 'active'),
        _quest('q2', 'EVENING', 'pending'),
      ];
      final result = groupQuestsByTimeOfDay(quests);

      expect(result['morning'], hasLength(1));
      expect(result['evening'], hasLength(1));
    });

    test('unknown timeOfDay creates a new key rather than crashing', () {
      final quests = [_quest('q1', 'midnight', 'active')];
      final result = groupQuestsByTimeOfDay(quests);

      expect(result['midnight'], hasLength(1));
    });
  });

  group('SubjectTheme.colorFor', () {
    test('returns distinct colors for known subjects', () {
      final colors = [
        SubjectTheme.colorFor('math'),
        SubjectTheme.colorFor('science'),
        SubjectTheme.colorFor('reading'),
      ];
      expect(colors.toSet().length, greaterThanOrEqualTo(2));
    });

    test('returns a fallback color for unknown subject', () {
      expect(
        () => SubjectTheme.colorFor('underwater basket weaving'),
        returnsNormally,
      );
    });
  });

  group('SubjectTheme.iconFor', () {
    test('returns an icon for every known subject', () {
      for (final s in ['math', 'reading', 'science', 'history', 'art']) {
        expect(() => SubjectTheme.iconFor(s), returnsNormally);
      }
    });
  });

  group('SubjectTheme.iconForTimeOfDay', () {
    test('returns icons for all three sections', () {
      for (final t in ['morning', 'afternoon', 'evening']) {
        expect(() => SubjectTheme.iconForTimeOfDay(t), returnsNormally);
      }
    });
  });
}
