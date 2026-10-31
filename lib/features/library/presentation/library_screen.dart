import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/channel_model.dart';
import '../../../shared/icons/app_icons.dart';
import '../../../shared/widgets/tab_header.dart';
import '../../channels/presentation/widgets/channel_grid.dart';
import '../../channels/providers/channels_provider.dart';
import '../providers/library_provider.dart';

/// Which persisted list the screen renders.
enum LibraryTab { favorites, saved, recent }

/// Favourites and Saved tabs, both backed by [LibraryProvider].
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.tab});

  final LibraryTab tab;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final catalogue = context.watch<ChannelsProvider>();

    final ids = switch (tab) {
      LibraryTab.favorites => library.favoriteIds,
      LibraryTab.saved => library.savedIds,
      LibraryTab.recent => library.recentIds,
    };
    final channels = catalogue.channelsForIds(ids);

    final isFavorites = tab == LibraryTab.favorites;
    final isRecent = tab == LibraryTab.recent;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradientFor(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TabHeader(
              title: isFavorites
                  ? 'Favourites'
                  : isRecent
                  ? 'Recently watched'
                  : 'Saved',
              subtitle: _subtitle(
                channels.length,
                catalogue,
                isFavorites,
                isRecent,
              ),
              icon: isFavorites
                  ? AppIcons.favorite
                  : isRecent
                  ? AppIcons.playCircle
                  : AppIcons.bookmark,
              gradient: isFavorites
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.accent, AppTheme.secondary],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
            ),
            Expanded(
              child: _buildBody(context, channels, catalogue, isFavorites),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(
    int count,
    ChannelsProvider catalogue,
    bool isFavorites,
    bool isRecent,
  ) {
    if (catalogue.isLoading && !catalogue.hasChannels) {
      return 'Loading your channels…';
    }
    if (count == 0) {
      if (isFavorites) return 'Tap the heart on any channel';
      return isRecent
          ? 'Channels you watch appear here'
          : 'Channels you open are saved here';
    }
    return '$count ${count == 1 ? 'channel' : 'channels'}';
  }

  Widget _buildBody(
    BuildContext context,
    List<ChannelModel> channels,
    ChannelsProvider catalogue,
    bool isFavorites,
  ) {
    if (catalogue.isLoading && !catalogue.hasChannels) {
      return const ChannelEmptyState(
        icon: AppIcons.liveTv,
        message: 'Loading channels…',
        action: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (channels.isEmpty) {
      final isRecent = tab == LibraryTab.recent;
      return ChannelEmptyState(
        icon: isFavorites
            ? AppIcons.favoriteBorder
            : isRecent
            ? AppIcons.playCircleOutline
            : AppIcons.bookmarkBorder,
        message: isFavorites
            ? 'No favourites yet.\nTap the heart on a channel to keep it here.'
            : isRecent
            ? 'No recent channels yet.\nStart watching a channel to see it here.'
            : 'No saved channels yet.\nLong-press any channel to save it, '
                  'or simply watch it once.',
        action: FilledButton.icon(
          onPressed: () => context.go(AppRouter.home),
          icon: const AppIcon(AppIcons.explore),
          label: const Text('Browse channels'),
        ),
      );
    }

    return ChannelGrid(channels: channels);
  }
}
