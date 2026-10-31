import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/channel_model.dart';
import '../../features/channels/presentation/channels_screen.dart';
import '../../features/channels/presentation/countries_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/player/presentation/player_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/sports/presentation/sports_screen.dart';
import '../presentation/main_shell.dart';

/// Declarative navigation graph for the whole app.
class AppRouter {
  const AppRouter._();

  static const String splash = '/';
  static const String home = '/home';
  static const String favorites = '/favorites';
  static const String sports = '/sports';
  static const String saved = '/saved';
  static const String countries = '/countries';
  static const String recent = '/recent';
  static const String player = '/player';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: home,
                name: 'home',
                builder: (context, state) => const ChannelsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: countries,
                name: 'countries',
                builder: (context, state) => const CountriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: recent,
                name: 'recent',
                builder: (context, state) =>
                    const LibraryScreen(tab: LibraryTab.recent),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: sports,
                name: 'sports',
                builder: (context, state) => const SportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: saved,
                name: 'saved',
                builder: (context, state) =>
                    const LibraryScreen(tab: LibraryTab.saved),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: favorites,
                name: 'favorites',
                builder: (context, state) =>
                    const LibraryScreen(tab: LibraryTab.favorites),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: player,
        name: 'player',
        redirect: (context, state) => state.extra is ChannelModel ? null : home,
        builder: (context, state) {
          final channel = state.extra;
          if (channel is! ChannelModel) return const SizedBox.shrink();
          return PlayerScreen(channel: channel);
        },
      ),
    ],
  );
}
