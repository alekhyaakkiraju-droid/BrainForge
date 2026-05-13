import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../placeholder_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        routeName: 'Schedule',
        icon: Icons.calendar_today_rounded,
        color: AppColors.secondary,
      );
}
