import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/country_display.dart';
import '../../core/utils/country_filter.dart';
import '../../features/channels/providers/channels_provider.dart';
import '../../shared/icons/app_icons.dart';

/// App shell with quick navigation and the app-wide drawer.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinationBranches = [0, 1, 2, 3, 4];

  void _onDestinationSelected(int index) {
    final branchIndex = _destinationBranches[index];
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final provider = context.watch<ChannelsProvider>();
    final selectedIndex =
        navigationShell.currentIndex < _destinationBranches.length
        ? navigationShell.currentIndex
        : 0;
    final flag = provider.selectedCountry == CountryFilter.allCountries
        ? '🌍'
        : CountryDisplay.flag(provider.selectedCountry);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Row(
                  children: [
                    const AppIcon(
                      AppIcons.brandMark,
                      size: 42,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'TV Show',
                      style: TextStyle(
                        color: AppTheme.foregroundFor(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _DrawerItem(
                icon: Icons.live_tv_outlined,
                title: 'Channels',
                onTap: () => _openBranch(context, 0),
              ),
              _DrawerItem(
                icon: Icons.favorite_border,
                title: 'Favorites',
                onTap: () => _openBranch(context, 5),
              ),
              _DrawerItem(
                icon: Icons.playlist_play,
                title: 'Playlist',
                onTap: () => _openBranch(context, 4),
              ),
              _DrawerItem(
                icon: Icons.history,
                title: 'Recent',
                onTap: () => _openBranch(context, 2),
              ),
              const Divider(),
              _DrawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  _showSettings(context);
                },
              ),
              _DrawerItem(
                icon: Icons.high_quality_outlined,
                title: 'Video quality · ${settings.videoQuality}',
                onTap: () {
                  Navigator.pop(context);
                  _showVideoQuality(context);
                },
              ),
              _DrawerItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  Navigator.pop(context);
                  _showAbout(context);
                },
              ),
              _DrawerItem(
                icon: Icons.exit_to_app,
                title: 'Exit',
                onTap: () {
                  Navigator.pop(context);
                  _confirmExit(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          border: Border(
            top: BorderSide(
              color: AppTheme.foregroundFor(context).withValues(alpha: 0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.45
                    : 0.08,
              ),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.18),
          destinations: [
            const NavigationDestination(
              icon: AppIcon(AppIcons.liveTvOutlined),
              selectedIcon: AppIcon(AppIcons.liveTv, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Text(flag, style: const TextStyle(fontSize: 20)),
              selectedIcon: Text(flag, style: const TextStyle(fontSize: 20)),
              label: 'Country',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history, color: AppTheme.primary),
              label: 'Recent',
            ),
            const NavigationDestination(
              icon: AppIcon(AppIcons.sportsSoccerOutlined),
              selectedIcon: AppIcon(
                AppIcons.sportsSoccer,
                color: AppTheme.live,
              ),
              label: 'Sports',
            ),
            const NavigationDestination(
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

  void _openBranch(BuildContext context, int branchIndex) {
    Navigator.pop(context);
    navigationShell.goBranch(branchIndex);
  }

  void _showSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Consumer<AppSettingsProvider>(
          builder: (context, currentSettings, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark theme'),
            value: currentSettings.themeMode == ThemeMode.dark,
            onChanged: (enabled) => currentSettings.setThemeMode(
              enabled ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showVideoQuality(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preferred video quality'),
        content: Consumer<AppSettingsProvider>(
          builder: (context, currentSettings, _) => RadioGroup<String>(
            groupValue: currentSettings.videoQuality,
            onChanged: (quality) {
              if (quality != null) currentSettings.setVideoQuality(quality);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final quality in AppSettingsProvider.videoQualities)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(quality),
                    value: quality,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TV Show',
      applicationVersion: '1.0.0',
      applicationIcon: const AppIcon(
        AppIcons.brandMark,
        size: 40,
        color: AppTheme.primary,
      ),
      children: const [Text('Watch live channels from around the world.')],
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit TV Show?'),
        content: const Text('Are you sure you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.primary),
    title: Text(
      title,
      style: TextStyle(color: AppTheme.foregroundFor(context)),
    ),
    onTap: onTap,
  );
}
