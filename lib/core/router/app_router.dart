import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth/auth_state.dart';
import '../../presentation/design_system/design_system_screen.dart';
import '../../presentation/screens/auth/child_login_screen.dart';
import '../../presentation/screens/auth/child_profile_creation_screen.dart';
import '../../presentation/screens/auth/consent_screen.dart';
import '../../presentation/screens/auth/email_verification_screen.dart';
import '../../presentation/screens/auth/parent_signup_screen.dart';
import '../../presentation/screens/badges/badges_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/mood/mood_checkin_screen.dart';
import '../../presentation/screens/placeholder_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/progress/progress_map_screen.dart';
import '../../presentation/screens/quest_board/quest_board_screen.dart';
import '../../presentation/screens/timer/timer_screen.dart';
import '../../presentation/shell/app_shell.dart';

/// All named route paths — single source of truth.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const parentSignup = '/auth/signup';
  static const verifyEmail = '/auth/verify-email';
  static const consent = '/auth/consent';
  static const createChild = '/auth/create-child';
  static const childLogin = '/auth/child-login';
  static const questBoard = '/quest-board';
  static const timer = '/timer';
  static const progressMap = '/progress-map';
  static const profile = '/profile';
  static const badges = '/badges';
  static const moodCheckin = '/mood-checkin';
  static const questDetail = '/quest-detail';

  // Debug only
  static const designSystem = '/design-system';

  static const _unauthAllowed = {login, parentSignup, childLogin};
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authNotifier.listenable,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.unknown:
          // Still resolving — do not redirect; avoid a flash.
          return null;

        case AuthStatus.unauthenticated:
          if (!AppRoutes._unauthAllowed.contains(loc)) {
            return AppRoutes.login;
          }
          return null;

        case AuthStatus.parentUnverified:
          return loc == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;

        case AuthStatus.parentNeedsConsent:
          return loc == AppRoutes.consent ? null : AppRoutes.consent;

        case AuthStatus.parentConsented:
          return loc == AppRoutes.createChild ? null : AppRoutes.createChild;

        case AuthStatus.authenticated:
          final onAuthRoute = AppRoutes._unauthAllowed.contains(loc) ||
              loc == AppRoutes.verifyEmail ||
              loc == AppRoutes.consent ||
              loc == AppRoutes.createChild;
          if (onAuthRoute) return AppRoutes.questBoard;
          return null;
      }
    },
    routes: [
      // ── Unauthenticated / onboarding ────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentSignup,
        builder: (context, state) => const ParentSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.childLogin,
        builder: (context, state) => const ChildLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.consent,
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.createChild,
        builder: (context, state) => const ChildProfileCreationScreen(),
      ),

      // ── Full-screen modal (outside shell) ────────────────────────────────
      GoRoute(
        path: AppRoutes.moodCheckin,
        builder: (context, state) => const MoodCheckinScreen(),
      ),
      GoRoute(
        path: AppRoutes.questDetail,
        builder: (context, state) => const PlaceholderScreen(
          routeName: 'Quest Detail',
          icon: Icons.assignment_rounded,
          color: Color(0xFF6C63FF),
        ),
      ),

      // ── Authenticated shell ───────────────────────────────────────────────
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
