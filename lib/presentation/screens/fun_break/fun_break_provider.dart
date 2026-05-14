import 'dart:async';

import 'package:brainforge/data/models/session_model.dart';
import 'package:brainforge/data/repositories/session_repository_impl.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Activities ─────────────────────────────────────────────────────────────

/// The two available break activities.
enum BreakActivity { breathing, dance }

// ── State ──────────────────────────────────────────────────────────────────

/// Minimum break duration before the child may return to quests.
const kBreakDurationSeconds = 3 * 60;

class FunBreakState {
  const FunBreakState({
    required this.activity,
    required this.remainingSeconds,
    required this.canReturn,
  });

  FunBreakState.initial()
      : activity = BreakActivity.breathing,
        remainingSeconds = kBreakDurationSeconds,
        canReturn = false;

  final BreakActivity activity;

  /// Seconds remaining until the child is allowed back to quests.
  final int remainingSeconds;

  /// True once the mandatory 3-minute break has elapsed.
  final bool canReturn;

  double get progress =>
      1.0 -
      remainingSeconds.clamp(0, kBreakDurationSeconds) / kBreakDurationSeconds;

  FunBreakState withActivity(BreakActivity a) =>
      FunBreakState(
        activity: a,
        remainingSeconds: remainingSeconds,
        canReturn: canReturn,
      );

  FunBreakState copyWith({int? remainingSeconds, bool? canReturn}) =>
      FunBreakState(
        activity: activity,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        canReturn: canReturn ?? this.canReturn,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class FunBreakNotifier extends AutoDisposeNotifier<FunBreakState> {
  Timer? _ticker;

  @override
  FunBreakState build() {
    ref.onDispose(() => _ticker?.cancel());
    _startTicker();
    return FunBreakState.initial();
  }

  /// Switches the active break activity.
  void selectActivity(BreakActivity activity) {
    state = state.withActivity(activity);
  }

  // ── private ──────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = state.remainingSeconds - 1;
    if (remaining <= 0) {
      _ticker?.cancel();
      state = state.copyWith(remainingSeconds: 0, canReturn: true);
      _recordBreakSession();
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  void _recordBreakSession() {
    final auth = ref.read(authStateProvider);
    final profileId = auth.uid ?? '';

    final sessionId =
        'break_${profileId}_${DateTime.now().millisecondsSinceEpoch}';
    final session = SessionModel(
      id: sessionId,
      profileId: profileId,
      startedAt:
          DateTime.now().subtract(const Duration(seconds: kBreakDurationSeconds)),
      endedAt: DateTime.now(),
      durationSeconds: kBreakDurationSeconds,
      wasCompleted: true,
    );

    // Fire-and-forget — record the break for parental reporting.
    ref.read(sessionRepositoryProvider).save(session).ignore();
  }
}

final funBreakProvider =
    AutoDisposeNotifierProvider<FunBreakNotifier, FunBreakState>(
  FunBreakNotifier.new,
);
