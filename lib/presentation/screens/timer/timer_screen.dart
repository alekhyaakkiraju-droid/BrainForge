import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../placeholder_screen.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        routeName: 'Focus Timer',
        icon: Icons.timer_rounded,
        color: AppColors.secondary,
      );
}
