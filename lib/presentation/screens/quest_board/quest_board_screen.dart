import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../placeholder_screen.dart';

class QuestBoardScreen extends StatelessWidget {
  const QuestBoardScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        routeName: 'Quest Board',
        icon: Icons.grid_view_rounded,
        color: AppColors.primary,
      );
}
