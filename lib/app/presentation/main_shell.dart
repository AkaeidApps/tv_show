import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/icons/app_icons.dart';

/// Bottom navigation shell hosting the four main tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.18),
          destinations: const [
            NavigationDestination(
              icon: AppIcon(AppIcons.liveTvOutlined),
              selectedIcon: AppIcon(
                AppIcons.liveTv,
                color: AppTheme.primary,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: AppIcon(AppIcons.favoriteBorder),
              selectedIcon: AppIcon(
                AppIcons.favorite,
                color: AppTheme.accent,
              ),
              label: 'Favorite',
            ),
            NavigationDestination(
              icon: AppIcon(AppIcons.sportsSoccerOutlined),
              selectedIcon: AppIcon(
                AppIcons.sportsSoccer,
                color: AppTheme.live,
              ),
              label: 'Sports',
            ),
            NavigationDestination(
              icon: AppIcon(AppIcons.bookmarkBorder),
              selectedIcon: AppIcon(
                AppIcons.bookmark,
                color: AppTheme.secondary,
              ),
              label: 'Saved',
            ),
          ],
        ),
      ),
    );
  }
}
