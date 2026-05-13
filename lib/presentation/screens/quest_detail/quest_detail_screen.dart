import 'dart:async';

import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/router/app_router.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/data/models/quest_step_model.dart';
import 'package:brainforge/presentation/screens/quest_detail/quest_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuestDetailScreen extends ConsumerStatefulWidget {
  const QuestDetailScreen({required this.questId, super.key});

  final String questId;

  @override
  ConsumerState<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends ConsumerState<QuestDetailScreen>
    with TickerProviderStateMixin {
  bool _showingCelebration = false;
  bool _questCompleted = false;
  String? _errorMessage;

  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationScale;
  late final Animation<double> _celebrationFade;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationScale = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.elasticOut,
      ),
    );
    _celebrationFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.6, 1, curve: Curves.easeIn),
      ),
    );
    unawaited(
      Future.microtask(
        () => ref.read(questDetailProvider.notifier).initialise(widget.questId),
      ),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _onStepSubmit(
    QuestStepModel step,
    String answer,
    int stepIndex,
  ) async {
    if (!step.isCorrect(answer)) {
      setState(() => _errorMessage = "Not quite — give it another try! 🌟");
      return;
    }

    setState(() {
      _errorMessage = null;
      _showingCelebration = true;
    });

    _celebrationController.reset();
    await _celebrationController.forward();

    if (!mounted) return;

    await ref.read(questDetailProvider.notifier).completeStep(stepIndex);

    final current = ref.read(questDetailProvider).valueOrNull;

    setState(() => _showingCelebration = false);

    if (current != null && current.isComplete) {
      setState(() => _questCompleted = true);
      await ref.read(questDetailProvider.notifier).markQuestComplete();
    }
  }

  void _navigateToQuestBoard() {
    unawaited(context.push(AppRoutes.questBoard));
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(questDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quest'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Back button is always available — progress is saved automatically.
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ErrorView(),
        data: (state) {
          if (_questCompleted) {
            return _QuestCompleteView(
              questTitle: state.quest.title,
              xpReward: state.quest.xpReward,
              onReturn: _navigateToQuestBoard,
            );
          }
          if (state.steps.isEmpty) {
            return const _NoStepsView();
          }
          final step = state.steps[state.currentStepIndex];
          return Stack(
            children: [
              _StepContent(
                step: step,
                currentIndex: state.currentStepIndex,
                totalSteps: state.steps.length,
                errorMessage: _errorMessage,
                onSubmit: (answer) =>
                    _onStepSubmit(step, answer, state.currentStepIndex),
              ),
              if (_showingCelebration)
                _MicroCelebration(
                  scale: _celebrationScale,
                  fade: _celebrationFade,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StepContent extends StatefulWidget {
  const _StepContent({
    required this.step,
    required this.currentIndex,
    required this.totalSteps,
    required this.onSubmit,
    this.errorMessage,
  });

  final QuestStepModel step;
  final int currentIndex;
  final int totalSteps;
  final ValueChanged<String> onSubmit;
  final String? errorMessage;

  @override
  State<_StepContent> createState() => _StepContentState();
}

class _StepContentState extends State<_StepContent> {
  final _textController = TextEditingController();
  String? _selectedOption;

  @override
  void didUpdateWidget(_StepContent old) {
    super.didUpdateWidget(old);
    if (old.step.id != widget.step.id) {
      _textController.clear();
      _selectedOption = null;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepProgressHeader(
              current: widget.currentIndex + 1,
              total: widget.totalSteps,
            ),
            const SizedBox(height: AppSpacing.xl),
            _StepInstruction(step: widget.step),
            const SizedBox(height: AppSpacing.xl),
            if (widget.step.type == 'multiple_choice')
              _MultipleChoiceInput(
                options: widget.step.options,
                selected: _selectedOption,
                onSelect: (opt) => setState(() => _selectedOption = opt),
              )
            else if (widget.step.type == 'text_input')
              _TextInput(controller: _textController)
            else
              const _InteractionInput(),
            const SizedBox(height: AppSpacing.md),
            if (widget.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  widget.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            _SubmitButton(
              stepType: widget.step.type,
              selectedOption: _selectedOption,
              textController: _textController,
              onSubmit: widget.onSubmit,
            ),
          ],
        ),
      );
}

class _StepProgressHeader extends StatelessWidget {
  const _StepProgressHeader({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $current of $total',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < current
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      );
}

class _StepInstruction extends StatelessWidget {
  const _StepInstruction({required this.step});

  final QuestStepModel step;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(
            _iconForStep(step.iconName),
            color: AppColors.primary,
            size: AppSpacing.iconSizeXl,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            step.instruction,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackground,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  static IconData _iconForStep(String iconName) {
    switch (iconName) {
      case 'calculate':
        return Icons.calculate_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'edit':
        return Icons.edit_rounded;
      case 'check':
        return Icons.check_circle_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

class _MultipleChoiceInput extends StatelessWidget {
  const _MultipleChoiceInput({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final opt in options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OptionButton(
                label: opt,
                isSelected: selected == opt,
                onTap: () => onSelect(opt),
              ),
            ),
        ],
      );
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
              ),
            ),
          ),
        ),
      );
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Type your answer',
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        textCapitalization: TextCapitalization.none,
      );
}

class _InteractionInput extends StatelessWidget {
  const _InteractionInput();

  @override
  Widget build(BuildContext context) => Text(
        'Tap "Done" when you\'re ready!',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
      );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.stepType,
    required this.selectedOption,
    required this.textController,
    required this.onSubmit,
  });

  final String stepType;
  final String? selectedOption;
  final TextEditingController textController;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final canSubmit = _canSubmit();
    return SizedBox(
      height: AppSpacing.minTouchTarget + AppSpacing.sm,
      child: ElevatedButton(
        onPressed: canSubmit
            ? () => onSubmit(_currentAnswer())
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        child: Text(
          stepType == 'interaction' ? 'Done! ✓' : 'Check Answer',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (stepType == 'multiple_choice') return selectedOption != null;
    if (stepType == 'text_input') return textController.text.trim().isNotEmpty;
    return true;
  }

  String _currentAnswer() {
    if (stepType == 'multiple_choice') return selectedOption ?? '';
    if (stepType == 'text_input') return textController.text.trim();
    return 'done';
  }
}

class _MicroCelebration extends StatelessWidget {
  const _MicroCelebration({required this.scale, required this.fade});

  final Animation<double> scale;
  final Animation<double> fade;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.xpGold,
                  size: AppSpacing.iconSizeXl,
                ),
              ),
            ),
          ),
        ),
      );
}

class _QuestCompleteView extends StatelessWidget {
  const _QuestCompleteView({
    required this.questTitle,
    required this.xpReward,
    required this.onReturn,
  });

  final String questTitle;
  final int xpReward;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.xpGold,
                size: AppSpacing.iconSizeXl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Quest Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                questTitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.xpGold),
                  const SizedBox(width: 4),
                  Text(
                    '+$xpReward XP',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.xpGold,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppSpacing.minTouchTarget + AppSpacing.sm,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                  child: Text(
                    'Back to Quest Board',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _NoStepsView extends StatelessWidget {
  const _NoStepsView();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'This quest has no steps yet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: AppSpacing.iconSizeXl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load quest.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
