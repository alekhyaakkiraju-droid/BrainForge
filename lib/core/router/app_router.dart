import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../presentation/home/home_screen.dart';
import '../../presentation/splash/splash_screen.dart';

part 'app_router.g.dart';

/// Named route paths — single source of truth for navigation.
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) => GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: false,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (BuildContext context, GoRouterState state) =>
              const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
      ],
    );
