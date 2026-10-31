import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/channel_model.dart';
import '../../../../shared/icons/app_icons.dart';
import 'channel_card.dart';

/// Responsive grid of [ChannelCard]s shared by every tab.
class ChannelGrid extends StatelessWidget {
  const ChannelGrid({
    super.key,
    required this.channels,
    this.onRefresh,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.emptyState,
  });

  final List<ChannelModel> channels;
  final Future<void> Function()? onRefresh;
  final EdgeInsets padding;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return emptyState ?? const SizedBox.shrink();
    }

    final grid = GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return ChannelCard(
          channel: channel,
          onTap: () => context.push(AppRouter.player, extra: channel),
        );
      },
    );

    final refresh = onRefresh;
    if (refresh == null) return grid;

    return RefreshIndicator(
      onRefresh: refresh,
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: grid,
    );
  }
}

/// Consistent empty/error panel used across tabs.
class ChannelEmptyState extends StatelessWidget {
  const ChannelEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final String icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon,
              size: 48,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
