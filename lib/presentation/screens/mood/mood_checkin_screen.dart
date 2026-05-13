import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../placeholder_screen.dart';

class MoodCheckinScreen extends StatelessWidget {
  const MoodCheckinScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        routeName: 'Mood Check-in',
        icon: Icons.mood_rounded,
        color: AppColors.scienceSpark,
      );
}
