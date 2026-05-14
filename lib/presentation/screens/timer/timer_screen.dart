import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import 'timer_provider.dart';

/// Entry point for the micro-session timer tab.
///
/// Presents a duration picker when idle, then shows an animated progress ring
/// while a session runs.  Navigates to the fun-break screen on expiry.
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  int _selectedDuration = kTimerDurations.first;

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerProvider);

    // Navigate to fun-break screen as soon as the timer expires.
    ref.listen<TimerState>(timerProvider, (_, next) {
      if (next.isExpired && mounted) {
        unawaited(context.push(AppRoutes.funBreak));
        ref.read(timerProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Focus Session'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: timer.isIdle
            ? _DurationPicker(
                selected: _selectedDuration,
                onSelect: (d) => setState(() => _selectedDuration = d),
                onStart: () =>
                    ref.read(timerProvider.notifier).start(_selectedDuration),
              )
            : _RunningTimer(timer: timer),
      ),
    );
  }
}

// ── Duration picker ──────────────────────────────────────────────────────────

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({
    required this.selected,
    required this.onSelect,
    required this.onStart,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconSizeXl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'How long will you focus?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final d in kTimerDurations)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: _DurationChip(
                        minutes: d,
                        isSelected: d == selected,
                        onTap: () => onSelect(d),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppSpacing.minTouchTarget + AppSpacing.sm,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                  child: Text(
                    'Start $selected min session  🚀',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.primary : AppColors.surface,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$minutes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            isSelected ? Colors.white : AppColors.onBackground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'min',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white70
                            : AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Running timer ────────────────────────────────────────────────────────────

class _RunningTimer extends ConsumerWidget {
  const _RunningTimer({required this.timer});

  final TimerState timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (timer.isPaused)
                _PausedBanner()
              else
                const SizedBox(height: 36),
              const SizedBox(height: AppSpacing.md),
              _ProgressRing(
                progress: timer.progress,
                remainingSeconds: timer.remainingSeconds,
                isPaused: timer.isPaused,
              ),
              const SizedBox(height: AppSpacing.xl),
              _ControlRow(timer: timer),
            ],
          ),
        ),
      );
}

class _PausedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_outline_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 6),
            Text(
              'Paused — resumes in 2 min',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.remainingSeconds,
    required this.isPaused,
  });

  final double progress;
  final int remainingSeconds;
  final bool isPaused;

  String get _timeLabel {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress,
            isPaused: isPaused,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel,
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPaused
                            ? AppColors.warning
                            : AppColors.onBackground,
                      ),
                ),
                Text(
                  isPaused ? 'paused' : 'remaining',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.isPaused});

  final double progress;
  final bool isPaused;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 18.0;

    // Background ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primaryLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc — sweeps clockwise from top.
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = isPaused ? AppColors.warning : AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isPaused != isPaused;
}

class _ControlRow extends ConsumerWidget {
  const _ControlRow({required this.timer});

  final TimerState timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timerProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause / Resume.
        _CircleButton(
          icon: timer.isPaused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          label: timer.isPaused ? 'Resume' : 'Pause',
          onTap: timer.isPaused ? notifier.resume : notifier.pause,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.lg),
        // End session early.
        _CircleButton(
          icon: Icons.stop_rounded,
          label: 'End',
          onTap: notifier.reset,
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: AppSpacing.minTouchTarget + AppSpacing.md,
              height: AppSpacing.minTouchTarget + AppSpacing.md,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(26),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      );
}
