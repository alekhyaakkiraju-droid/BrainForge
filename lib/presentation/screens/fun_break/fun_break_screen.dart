import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import 'fun_break_provider.dart';

/// Full-screen mandatory fun break — shown after every timed session.
///
/// The child must stay for at least [kBreakDurationSeconds] seconds before
/// the "Back to Quests" button becomes active.
class FunBreakScreen extends ConsumerWidget {
  const FunBreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakState = ref.watch(funBreakProvider);

    return Scaffold(
      backgroundColor: AppColors.scienceSparkLight,
      body: SafeArea(
        child: Column(
          children: [
            _BreakHeader(breakState: breakState),
            const SizedBox(height: AppSpacing.lg),
            _ActivityTabs(
              selected: breakState.activity,
              onSelect: ref.read(funBreakProvider.notifier).selectActivity,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: breakState.activity == BreakActivity.breathing
                  ? const _BreathingActivity()
                  : const _DanceActivity(),
            ),
            _ReturnButton(canReturn: breakState.canReturn),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _BreakHeader extends StatelessWidget {
  const _BreakHeader({required this.breakState});

  final FunBreakState breakState;

  String get _timeLabel {
    final m = breakState.remainingSeconds ~/ 60;
    final s = breakState.remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              breakState.canReturn
                  ? 'Great work! 🎉'
                  : 'Time for a break!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
              textAlign: TextAlign.center,
            ),
            if (!breakState.canReturn) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Break ends in $_timeLabel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.scienceSpark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(
                value: breakState.progress,
                backgroundColor: AppColors.outline,
                color: AppColors.scienceSpark,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      );
}

// ── Activity tabs ───────────────────────────────────────────────────────────

class _ActivityTabs extends StatelessWidget {
  const _ActivityTabs({required this.selected, required this.onSelect});

  final BreakActivity selected;
  final ValueChanged<BreakActivity> onSelect;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TabButton(
            label: '🫁  Breathe',
            isSelected: selected == BreakActivity.breathing,
            onTap: () => onSelect(BreakActivity.breathing),
          ),
          const SizedBox(width: AppSpacing.md),
          _TabButton(
            label: '💃  Dance',
            isSelected: selected == BreakActivity.dance,
            onTap: () => onSelect(BreakActivity.dance),
          ),
        ],
      );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          constraints:
              const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.scienceSpark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(
              color: isSelected ? AppColors.scienceSpark : AppColors.outline,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
}

// ── Breathing exercise ──────────────────────────────────────────────────────

/// Animated circle guides the child through 4-4 breathing.
class _BreathingActivity extends StatefulWidget {
  const _BreathingActivity();

  @override
  State<_BreathingActivity> createState() => _BreathingActivityState();
}

class _BreathingActivityState extends State<_BreathingActivity>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  static const _phases = ['Breathe in…', 'Hold…', 'Breathe out…', 'Hold…'];
  int _phase = 0;
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener(_onStatus);
    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _phase = (_phase + 1) % _phases.length);
      // Alternate between expanding and contracting.
      if (_phase.isEven) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse(from: 1);
      }
    } else if (status == AnimationStatus.dismissed) {
      setState(() => _phase = (_phase + 1) % _phases.length);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scale,
              builder: (context, _) => Container(
                width: 200 * _scale.value,
                height: 200 * _scale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.scienceSpark.withAlpha(
                    (77 + 77 * _scale.value).toInt(),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.scienceSpark.withAlpha(51),
                      blurRadius: 40 * _scale.value,
                      spreadRadius: 8 * _scale.value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _phases[_phase],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.scienceSparkDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Follow the circle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
}

// ── Dance prompt ────────────────────────────────────────────────────────────

const _kDancePrompts = [
  '🕺  Do your best robot dance!',
  '💃  Spin around 3 times!',
  '🙆  Reach for the sky — stretch!',
  '🐸  Jump like a frog!',
  '🦩  Balance on one foot for 10 seconds!',
  '🤸  Touch your toes!',
  '🥳  Do a happy dance!',
];

class _DanceActivity extends StatefulWidget {
  const _DanceActivity();

  @override
  State<_DanceActivity> createState() => _DanceActivityState();
}

class _DanceActivityState extends State<_DanceActivity>
    with SingleTickerProviderStateMixin {
  int _promptIndex = 0;
  late final AnimationController _bounceController;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _nextPrompt() {
    setState(
      () => _promptIndex = (_promptIndex + 1) % _kDancePrompts.length,
    );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _bounce.value),
                  child: child,
                ),
                child: Text(
                  _kDancePrompts[_promptIndex].split('  ').first,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _kDancePrompts[_promptIndex].split('  ').last,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppSpacing.minTouchTarget,
                child: TextButton(
                  onPressed: _nextPrompt,
                  child: Text(
                    'Next move →',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.scienceSpark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Return button ───────────────────────────────────────────────────────────

class _ReturnButton extends ConsumerWidget {
  const _ReturnButton({required this.canReturn});

  final bool canReturn;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: SizedBox(
          height: AppSpacing.minTouchTarget + AppSpacing.sm,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canReturn
                ? () {
                    ref.invalidate(funBreakProvider);
                    context.go(AppRoutes.questBoard);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.scienceSpark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.outline,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: Text(
              canReturn ? 'Back to Quests! 🚀' : 'Almost there…',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: canReturn
                        ? Colors.white
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      );
}

