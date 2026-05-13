import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/design_system/design_system_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/splash/splash_screen.dart';

/// Named route paths — single source of truth for navigation.
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';

  /// Debug-only design system showcase.
  static const designSystem = '/design-system';
}

/// GoRouter instance exposed as a Riverpod provider.
///
/// Using a provider makes the router testable and allows auth-state
/// redirects to be injected via ref.watch() in future WOs.
final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // Design-system showcase only available in debug builds
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.designSystem,
          builder: (context, state) => const DesignSystemScreen(),
        ),
    ],
  ),
);
