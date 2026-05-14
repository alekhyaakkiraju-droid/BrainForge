/// A single micro-step within a quest.
///
/// Steps are stored in the `quests/{questId}/steps/` Firestore sub-collection
/// and presented one at a time on the Quest Detail screen.
class QuestStepModel {
  const QuestStepModel({
    required this.id,
    required this.questId,
    required this.stepNumber,
    required this.instruction,
    required this.iconName,
    required this.type,
    this.options = const [],
    this.correctAnswer,
  });

  factory QuestStepModel.fromJson(Map<String, dynamic> json) => QuestStepModel(
        id: json['id'] as String,
        questId: json['questId'] as String,
        stepNumber: (json['stepNumber'] as num).toInt(),
        instruction: json['instruction'] as String,
        iconName: json['iconName'] as String? ?? 'star',
        type: json['type'] as String,
        options: (json['options'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        correctAnswer: json['correctAnswer'] as String?,
      );

  final String id;
  final String questId;

  /// 1-based display index shown to the child.
  final int stepNumber;

  /// Short instruction shown to the child — must be ≤ 10 words.
  final String instruction;

  /// Key used to look up the step icon in [StepIconResolver].
  final String iconName;

  /// One of: multiple_choice | text_input | interaction.
  final String type;

  /// Answer options for [type] == 'multiple_choice'.
  final List<String> options;

  /// Expected correct answer; `null` means any response is accepted.
  final String? correctAnswer;

  Map<String, dynamic> toJson() => {
        'id': id,
        'questId': questId,
        'stepNumber': stepNumber,
        'instruction': instruction,
        'iconName': iconName,
        'type': type,
        'options': options,
        'correctAnswer': correctAnswer,
      };

  /// Returns true when [answer] matches [correctAnswer] (case-insensitive).
  ///
  /// If [correctAnswer] is null every response is treated as correct so
  /// that interaction-type steps (no right or wrong answer) always advance.
  bool isCorrect(String answer) =>
      correctAnswer == null ||
      answer.trim().toLowerCase() ==
          correctAnswer!.trim().toLowerCase();
}
