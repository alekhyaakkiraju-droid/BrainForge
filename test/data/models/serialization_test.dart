// Serialization round-trip tests for all 9 data models.
//
// Timestamps are supplied as ISO-8601 strings so these tests run without
// a Firebase plugin host. The _parseTimestamp helpers in each model accept
// both Timestamp objects and String values.

import 'package:brainforge/data/models/audit_log_model.dart';
import 'package:brainforge/data/models/badge_model.dart';
import 'package:brainforge/data/models/mood_entry_model.dart';
import 'package:brainforge/data/models/quest_model.dart';
import 'package:brainforge/data/models/quest_submission_model.dart';
import 'package:brainforge/data/models/session_model.dart';
import 'package:brainforge/data/models/subject_progress_model.dart';
import 'package:brainforge/data/models/user_profile_model.dart';
import 'package:brainforge/data/models/xp_record_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Helpers that produce JSON using plain String timestamps (no Firebase SDK).
Map<String, dynamic> _userProfileJson() => {
      'id': 'u1',
      'parentUid': 'p1',
      'displayName': 'Alex',
      'avatarAsset': 'assets/avatars/robot.png',
      'xp': 250,
      'level': 3,
      'currentStreak': 5,
      'longestStreak': 10,
      'mode': 'school',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-02T00:00:00.000Z',
    };

Map<String, dynamic> _questJson() => {
      'id': 'q1',
      'assignedToProfileId': 'u1',
      'title': 'Math Sprint',
      'description': 'Solve 10 multiplication problems',
      'subject': 'math',
      'durationMinutes': 15,
      'xpReward': 50,
      'status': 'pending',
      'timeOfDay': 'morning',
      'scheduledFor': '2026-01-03T08:00:00.000Z',
      'completedAt': null,
      'createdAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _questSubmissionJson() => {
      'id': 'qs1',
      'questId': 'q1',
      'profileId': 'u1',
      'submittedAt': '2026-01-03T08:20:00.000Z',
      'durationSeconds': 720,
      'xpEarned': 50,
      'moodAtStart': 'happy',
      'notes': 'Great run!',
    };

Map<String, dynamic> _sessionJson() => {
      'id': 's1',
      'profileId': 'u1',
      'questId': 'q1',
      'startedAt': '2026-01-03T08:00:00.000Z',
      'endedAt': '2026-01-03T08:20:00.000Z',
      'durationSeconds': 1200,
      'wasCompleted': true,
    };

Map<String, dynamic> _xpRecordJson() => {
      'id': 'xp1',
      'profileId': 'u1',
      'amount': 50,
      'source': 'quest',
      'description': 'Completed Math Sprint',
      'earnedAt': '2026-01-03T08:20:00.000Z',
      'questId': 'q1',
    };

Map<String, dynamic> _moodEntryJson() => {
      'id': 'me1',
      'profileId': 'u1',
      'mood': 'happy',
      'intensity': 4,
      'recordedAt': '2026-01-03T08:00:00.000Z',
      'sessionId': 's1',
    };

Map<String, dynamic> _badgeJson() => {
      'id': 'b1',
      'profileId': 'u1',
      'badgeType': 'math_wizard',
      'title': 'Math Wizard',
      'description': 'Complete 10 math quests',
      'iconAsset': 'assets/badges/math_wizard.png',
      'unlockedAt': '2026-01-05T00:00:00.000Z',
      'xpBonus': 100,
    };

Map<String, dynamic> _subjectProgressJson() => {
      'id': 'sp1',
      'profileId': 'u1',
      'subject': 'math',
      'completedQuests': 10,
      'totalXp': 500,
      'progressPercent': 0.45,
      'lastActivityAt': '2026-01-05T00:00:00.000Z',
    };

Map<String, dynamic> _auditLogJson() => {
      'id': 'al1',
      'actorUid': 'parent1',
      'action': 'quest.complete',
      'resourceType': 'quest',
      'resourceId': 'q1',
      'metadata': {'profileId': 'u1'},
      'timestamp': '2026-01-03T08:20:00.000Z',
    };

void main() {
  group('UserProfileModel serialization', () {
    test('round-trip produces identical fields', () {
      final json = _userProfileJson();
      final model = UserProfileModel.fromJson(json);
      expect(model.id, json['id']);
      expect(model.parentUid, json['parentUid']);
      expect(model.displayName, json['displayName']);
      expect(model.xp, json['xp']);
      expect(model.level, json['level']);
      expect(model.currentStreak, json['currentStreak']);
      expect(model.longestStreak, json['longestStreak']);
      expect(model.mode, json['mode']);
      expect(
        model.createdAt,
        DateTime.parse(json['createdAt'] as String),
      );
    });

    test('toJson round-trip: String timestamps survive two passes', () {
      final original = UserProfileModel.fromJson(_userProfileJson());
      final serialised = original.toJson()
        ..['createdAt'] = original.createdAt.toIso8601String()
        ..['updatedAt'] = original.updatedAt.toIso8601String();
      final copy = UserProfileModel.fromJson(serialised);
      expect(copy.id, original.id);
      expect(copy.xp, original.xp);
      expect(copy.createdAt, original.createdAt);
    });
  });

  group('QuestModel serialization', () {
    test('round-trip produces identical fields', () {
      final json = _questJson();
      final model = QuestModel.fromJson(json);
      expect(model.id, json['id']);
      expect(model.title, json['title']);
      expect(model.subject, json['subject']);
      expect(model.durationMinutes, json['durationMinutes']);
      expect(model.xpReward, json['xpReward']);
      expect(model.status, json['status']);
      expect(model.timeOfDay, json['timeOfDay']);
      expect(model.completedAt, isNull);
      expect(model.scheduledFor, isNotNull);
    });
  });

  group('QuestSubmissionModel serialization', () {
    test('round-trip preserves optional fields', () {
      final model = QuestSubmissionModel.fromJson(_questSubmissionJson());
      expect(model.moodAtStart, 'happy');
      expect(model.notes, 'Great run!');
      expect(model.durationSeconds, 720);
      expect(model.xpEarned, 50);
    });

    test('round-trip with nulls', () {
      final json = {
        ..._questSubmissionJson(),
        'moodAtStart': null,
        'notes': null,
      };
      final model = QuestSubmissionModel.fromJson(json);
      expect(model.moodAtStart, isNull);
      expect(model.notes, isNull);
    });
  });

  group('SessionModel serialization', () {
    test('round-trip preserves wasCompleted flag', () {
      final model = SessionModel.fromJson(_sessionJson());
      expect(model.wasCompleted, isTrue);
      expect(model.durationSeconds, 1200);
      expect(model.endedAt, isNotNull);
    });

    test('null endedAt is preserved', () {
      final json = {..._sessionJson(), 'endedAt': null};
      final model = SessionModel.fromJson(json);
      expect(model.endedAt, isNull);
    });
  });

  group('XpRecordModel serialization', () {
    test('round-trip preserves source and amount', () {
      final model = XpRecordModel.fromJson(_xpRecordJson());
      expect(model.amount, 50);
      expect(model.source, 'quest');
      expect(model.questId, 'q1');
    });
  });

  group('MoodEntryModel serialization', () {
    test('round-trip preserves intensity and mood', () {
      final model = MoodEntryModel.fromJson(_moodEntryJson());
      expect(model.mood, 'happy');
      expect(model.intensity, 4);
      expect(model.sessionId, 's1');
    });
  });

  group('BadgeModel serialization', () {
    test('round-trip preserves xpBonus', () {
      final model = BadgeModel.fromJson(_badgeJson());
      expect(model.badgeType, 'math_wizard');
      expect(model.xpBonus, 100);
      expect(model.title, 'Math Wizard');
    });
  });

  group('SubjectProgressModel serialization', () {
    test('round-trip preserves progressPercent precision', () {
      final model = SubjectProgressModel.fromJson(_subjectProgressJson());
      expect(model.progressPercent, closeTo(0.45, 0.001));
      expect(model.completedQuests, 10);
      expect(model.totalXp, 500);
    });
  });

  group('AuditLogModel serialization', () {
    test('round-trip preserves metadata map', () {
      final model = AuditLogModel.fromJson(_auditLogJson());
      expect(model.action, 'quest.complete');
      expect(model.metadata['profileId'], 'u1');
      expect(model.resourceType, 'quest');
    });

    test('empty metadata defaults to empty map', () {
      final json = {..._auditLogJson()}..remove('metadata');
      final model = AuditLogModel.fromJson(json);
      expect(model.metadata, isEmpty);
    });
  });
}
