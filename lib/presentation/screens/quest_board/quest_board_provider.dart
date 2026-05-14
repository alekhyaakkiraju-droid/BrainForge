import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/quest_model.dart';
import '../../../data/repositories/quest_repository_impl.dart';
import '../../../domain/auth/auth_state.dart';

/// Streams today's quests for the authenticated user and groups them into
/// morning / afternoon / evening sections for the Quest Board.
final questBoardProvider =
    StreamProvider.autoDispose<List<QuestModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.uid == null) return const Stream.empty();
  return ref.watch(questRepositoryProvider).watchByProfileId(auth.uid!);
});

/// Groups a flat list of quests by [QuestModel.timeOfDay].
///
/// Returns a map with exactly three keys in display order.  Empty sections
/// are represented as empty lists rather than omitted, so the UI can render
/// section headers unconditionally.
Map<String, List<QuestModel>> groupQuestsByTimeOfDay(
  List<QuestModel> quests,
) {
  final groups = <String, List<QuestModel>>{
    'morning': [],
    'afternoon': [],
    'evening': [],
  };
  for (final q in quests) {
    final key = q.timeOfDay.toLowerCase();
    (groups[key] ??= []).add(q);
  }
  return groups;
}

/// Subject name → accent color and icon mapping.
///
/// Extend this table as new subjects are added to the curriculum.
abstract final class SubjectTheme {
  /// Returns the brand accent color for [subject].
  static Color colorFor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
        return const Color(0xFF6C63FF); // primary
      case 'reading':
      case 'english':
        return const Color(0xFFFF6584); // secondary
      case 'science':
        return const Color(0xFF00C9A7); // scienceSpark
      case 'history':
      case 'social studies':
        return const Color(0xFFFFC107); // warning/amber
      case 'art':
        return const Color(0xFF4CAF50); // success/green
      case 'music':
        return const Color(0xFFFF9800); // orange
      default:
        return const Color(0xFF6C63FF);
    }
  }

  /// Returns the icon representing [subject].
  static IconData iconFor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
        return Icons.calculate_rounded;
      case 'reading':
      case 'english':
        return Icons.menu_book_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'history':
      case 'social studies':
        return Icons.public_rounded;
      case 'art':
        return Icons.palette_rounded;
      case 'music':
        return Icons.music_note_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  /// Returns the icon representing a [timeOfDay] section.
  static IconData iconForTimeOfDay(String timeOfDay) {
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'afternoon':
        return Icons.wb_cloudy_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}
