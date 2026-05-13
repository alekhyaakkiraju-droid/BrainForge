import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/router/app_router.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

/// Duration of the Start Ritual animation before automatic navigation.
///
/// Must match the Lottie asset duration (210 frames at 60 fps = 3.5 s).
const _kRitualDuration = Duration(milliseconds: 3500);

/// Injects a custom [AudioPlayer] instance — used in tests to skip audio.
final ritualAudioPlayerProvider = Provider<AudioPlayer>(
  (_) => AudioPlayer(),
  // Dispose the player when the provider is removed from scope.
);

/// Full-screen animated transition played when a child taps an active quest.
///
/// The ritual:
///  1. Fills the screen with the brand-primary colour.
///  2. Plays the Lottie "start_ritual.json" animation (star + glow ring).
///  3. Attempts to play `assets/sounds/start_ritual.mp3`; failures are silent.
///  4. After [_kRitualDuration] (or if the user taps to skip) navigates to
///     the quest timer/detail screen.
///
/// Accepts the target [questId] via GoRouter's `extra` parameter so the
/// downstream screen knows which quest to load.
class StartRitualScreen extends ConsumerStatefulWidget {
  const StartRitualScreen({required this.questId, super.key});

  /// The Firestore document ID of the quest being started.
  final String questId;

  @override
  ConsumerState<StartRitualScreen> createState() => _StartRitualScreenState();
}

class _StartRitualScreenState extends ConsumerState<StartRitualScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: _kRitualDuration,
    );

    // Fallback: navigate even if Lottie fails to complete.
    _fallbackTimer = Timer(_kRitualDuration, _navigateToQuest);

    unawaited(_playSound());
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _playSound() async {
    try {
      final player = ref.read(ritualAudioPlayerProvider);
      // Volume is controlled by the device volume and mute switch — no
      // override here so the system setting is respected.
      await player.play(AssetSource('sounds/start_ritual.mp3'));
    } on Exception {
      // Audio is a nice-to-have; a missing or unsupported file must not
      // break the ritual flow.
    }
  }

  void _navigateToQuest() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _lottieController.stop();
    _fallbackTimer?.cancel();
    context.go(AppRoutes.questDetail, extra: widget.questId);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _navigateToQuest,
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Lottie.asset(
                'assets/animations/start_ritual.json',
                controller: _lottieController,
                onLoaded: (composition) {
                  _lottieController
                    ..duration = composition.duration
                    ..forward().whenComplete(_navigateToQuest);
                },
                // If the asset fails to load (CI, missing file), show the
                // brand icon so the screen isn't blank.
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: AppSpacing.iconSizeXl,
                ),
              ),
            ),
          ),
        ),
      );
}
