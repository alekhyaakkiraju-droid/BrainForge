import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Navigation destination descriptor.
class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _navItems = [
  _NavItem(
    route: AppRoutes.questBoard,
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    label: 'Quests',
  ),
  _NavItem(
    route: AppRoutes.timer,
    icon: Icons.timer_outlined,
    selectedIcon: Icons.timer_rounded,
    label: 'Focus',
  ),
  _NavItem(
    route: AppRoutes.progressMap,
    icon: Icons.map_outlined,
    selectedIcon: Icons.map_rounded,
    label: 'Progress',
  ),
  _NavItem(
    route: AppRoutes.badges,
    icon: Icons.emoji_events_outlined,
    selectedIcon: Icons.emoji_events_rounded,
    label: 'Badges',
  ),
  _NavItem(
    route: AppRoutes.profile,
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Me',
  ),
];

/// Adaptive navigation shell.
///
/// On wide tablets (≥600 dp) a [NavigationRail] is shown on the left.
/// On narrower screens a [NavigationBar] is shown at the bottom.
/// All tap targets are ≥48 dp per ADHD-UX constraints.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexFor(location);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(selectedIndex: selectedIndex),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomBar(selectedIndex: selectedIndex),
    );
  }

  static int _indexFor(String location) {
    final idx = _navItems.indexWhere((i) => i.route == location);
    return idx < 0 ? 0 : idx;
  }
}

// ── Side rail (tablet wide) ──────────────────────────────────────────────────

class _SideRail extends StatelessWidget {
  const _SideRail({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) => NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_navItems[i].route),
        labelType: NavigationRailLabelType.all,
        minWidth: AppSpacing.minTouchTarget + AppSpacing.md,
        destinations: _navItems
            .map(
              (item) => NavigationRailDestination(
                icon: Icon(item.icon, size: AppSpacing.iconSizeMd),
                selectedIcon:
                    Icon(item.selectedIcon, size: AppSpacing.iconSizeMd),
                label: Text(item.label, maxLines: 1),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
              ),
            )
            .toList(),
        indicatorColor: AppColors.primaryLight,
        selectedIconTheme:
            const IconThemeData(color: AppColors.primaryDark),
        unselectedIconTheme:
            const IconThemeData(color: AppColors.onSurfaceVariant),
      );
}

// ── Bottom bar (phone / narrow tablet) ──────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_navItems[i].route),
        height: AppSpacing.minTouchTarget + AppSpacing.lg,
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      );
}
