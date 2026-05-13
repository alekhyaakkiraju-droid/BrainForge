import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth/auth_state.dart';
import '../../presentation/design_system/design_system_screen.dart';
import '../../presentation/screens/badges/badges_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/mood/mood_checkin_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/progress/progress_map_screen.dart';
import '../../presentation/screens/quest_board/quest_board_screen.dart';
import '../../presentation/screens/schedule/schedule_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/timer/timer_screen.dart';
import '../../presentation/shell/app_shell.dart';

/// All named route paths — single source of truth.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const questBoard = '/quest-board';
  static const timer = '/timer';
  static const progressMap = '/progress-map';
  static const profile = '/profile';
  static const badges = '/badges';
  static const schedule = '/schedule';
  static const settings = '/settings';
  static const moodCheckin = '/mood-checkin';

  // Debug only
  static const designSystem = '/design-system';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.questBoard,
    refreshListenable: authNotifier.listenable,
    redirect: (context, state) {
      final isLoggedIn =
          ref.read(authStateProvider) == AuthStatus.authenticated;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !goingToLogin) return AppRoutes.login;
      if (isLoggedIn && goingToLogin) return AppRoutes.questBoard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Mood check-in is a full-screen modal outside the shell
      GoRoute(
        path: AppRoutes.moodCheckin,
        builder: (context, state) => const MoodCheckinScreen(),
      ),

      // StatefulShellRoute preserves each branch's widget state so the
      // counter on placeholder screens survives tab switches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.questBoard,
              builder: (context, state) => const QuestBoardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.timer,
              builder: (context, state) => const TimerScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progressMap,
              builder: (context, state) => const ProgressMapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.badges,
              builder: (context, state) => const BadgesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      if (kDebugMode)
        GoRoute(
          path: AppRoutes.designSystem,
          builder: (context, state) => const DesignSystemScreen(),
        ),
    ],
  );
});
