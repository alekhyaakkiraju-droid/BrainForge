import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Placeholder home screen — replaced by the Quest Board in a later WO.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            'BrainForge',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.rocket_launch_rounded,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to BrainForge!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Quest Board coming in WO-004',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      );
}
