import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/session_model.dart';
import '../../../data/repositories/session_repository_impl.dart';
import '../../../domain/auth/auth_state.dart';

// ── Available durations ────────────────────────────────────────────────────

/// Allowed session durations in minutes. Hard-capped at 20.
const kTimerDurations = [15, 18, 20];

// ── State ──────────────────────────────────────────────────────────────────

/// The phase of the timer lifecycle.
enum TimerStatus { idle, running, paused, expired }

/// Immutable snapshot of timer state.
class TimerState {
  const TimerState({
    required this.status,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.sessionId,
    this.pausedAt,
  });

  const TimerState.idle()
      : status = TimerStatus.idle,
        totalSeconds = 15 * 60,
        remainingSeconds = 15 * 60,
        sessionId = null,
        pausedAt = null;

  final TimerStatus status;

  /// The originally selected duration in seconds.
  final int totalSeconds;

  /// Seconds remaining until expiry.
  final int remainingSeconds;

  /// Firestore document ID for the in-progress session record.
  final String? sessionId;

  /// When the current pause began — used for auto-resume after 2 minutes.
  final DateTime? pausedAt;

  /// Progress fraction in [0.0, 1.0]. 0 = just started, 1 = expired.
  double get progress =>
      1.0 - remainingSeconds.clamp(0, totalSeconds) / totalSeconds;

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isIdle => status == TimerStatus.idle;
  bool get isExpired => status == TimerStatus.expired;

  TimerState copyWith({
    TimerStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
    String? sessionId,
    DateTime? pausedAt,
    bool clearPausedAt = false,
  }) =>
      TimerState(
        status: status ?? this.status,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        sessionId: sessionId ?? this.sessionId,
        pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

/// Maximum allowed pause duration before auto-resume.
const _kAutoResumePauseDuration = Duration(minutes: 2);

class TimerNotifier extends AutoDisposeNotifier<TimerState> {
  Timer? _ticker;
  Timer? _autoResumeTimer;

  @override
  TimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _autoResumeTimer?.cancel();
    });
    return const TimerState.idle();
  }

  /// Starts a new session with [durationMinutes] (must be one of
  /// [kTimerDurations]). Silently clamps to 20 minutes if the caller somehow
  /// passes a higher value.
  Future<void> start(int durationMinutes) async {
    final clamped = durationMinutes.clamp(1, 20);
    final total = clamped * 60;

    final auth = ref.read(authStateProvider);
    final profileId = auth.uid ?? '';
    final sessionId =
        '${profileId}_${DateTime.now().millisecondsSinceEpoch}';

    // Persist session start to Firestore.
    final session = SessionModel(
      id: sessionId,
      profileId: profileId,
      startedAt: DateTime.now(),
      durationSeconds: total,
      wasCompleted: false,
    );
    await _saveSession(session);

    state = TimerState(
      status: TimerStatus.running,
      totalSeconds: total,
      remainingSeconds: total,
      sessionId: sessionId,
    );

    _startTicker();
  }

  /// Pauses the timer and schedules auto-resume after 2 minutes.
  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    _autoResumeTimer?.cancel();

    state = state.copyWith(
      status: TimerStatus.paused,
      pausedAt: DateTime.now(),
    );

    _autoResumeTimer = Timer(_kAutoResumePauseDuration, resume);
  }

  /// Resumes the timer from paused state.
  void resume() {
    if (!state.isPaused) return;
    _autoResumeTimer?.cancel();
    state = state.copyWith(
      status: TimerStatus.running,
      clearPausedAt: true,
    );
    _startTicker();
  }

  /// Cancels the timer and discards the current session.
  void reset() {
    _ticker?.cancel();
    _autoResumeTimer?.cancel();
    state = const TimerState.idle();
  }

  // ── private ────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = state.remainingSeconds - 1;
    if (remaining <= 0) {
      _ticker?.cancel();
      _expire();
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  Future<void> _expire() async {
    state = state.copyWith(
      status: TimerStatus.expired,
      remainingSeconds: 0,
    );

    await _persistCompletion(wasCompleted: true);
  }

  Future<void> _saveSession(SessionModel session) async {
    try {
      await ref.read(sessionRepositoryProvider).save(session);
    } on Exception {
      // Session record is best-effort — timer still functions without it.
    }
  }

  Future<void> _persistCompletion({required bool wasCompleted}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    final auth = ref.read(authStateProvider);
    final profileId = auth.uid ?? '';

    final updated = SessionModel(
      id: sessionId,
      profileId: profileId,
      startedAt: DateTime.now().subtract(
        Duration(seconds: state.totalSeconds - state.remainingSeconds),
      ),
      endedAt: DateTime.now(),
      durationSeconds: state.totalSeconds - state.remainingSeconds,
      wasCompleted: wasCompleted,
    );
    await _saveSession(updated);
  }
}

final timerProvider =
    AutoDisposeNotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
