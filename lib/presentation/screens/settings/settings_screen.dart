import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../placeholder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        routeName: 'Settings',
        icon: Icons.settings_rounded,
        color: AppColors.onSurfaceVariant,
      );
}
