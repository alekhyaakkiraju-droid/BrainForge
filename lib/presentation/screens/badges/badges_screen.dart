import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../placeholder_screen.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        routeName: 'Badges',
        icon: Icons.emoji_events_rounded,
        color: AppColors.xpGold,
      );
}
