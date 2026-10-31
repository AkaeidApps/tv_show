import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/channel_model.dart';
import '../../../shared/icons/app_icons.dart';
import '../../../shared/widgets/tab_header.dart';
import '../../channels/presentation/widgets/channel_grid.dart';
import '../../channels/presentation/widgets/channel_search_field.dart';
import '../../channels/providers/channels_provider.dart';

/// Sports tab: every channel tagged with a sport category.
class SportsScreen extends StatefulWidget {
  const SportsScreen({super.key});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChannelModel> _filter(List<ChannelModel> channels) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return channels;
    return channels
        .where(
          (channel) =>
              channel.name.toLowerCase().contains(query) ||
              channel.country.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChannelsProvider>();
    final sports = _filter(provider.sportsChannels);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TabHeader(
              title: 'Sports',
              subtitle: provider.sportsChannels.isEmpty
                  ? 'Live sports channels'
                  : '${sports.length} live sports channels',
              icon: AppIcons.sportsSoccer,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.live, AppTheme.primary],
              ),
            ),
            ChannelSearchField(
              controller: _searchController,
              hintText: 'Search sports channels',
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
            Expanded(child: _buildBody(provider, sports)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChannelsProvider provider, List<ChannelModel> sports) {
    if (provider.isLoading && !provider.hasChannels) {
      return const ChannelEmptyState(
        icon: AppIcons.sportsSoccer,
        message: 'Loading sports channels…',
        action: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (provider.error != null && !provider.hasChannels) {
      return ChannelEmptyState(
        icon: AppIcons.wifiOff,
        message: provider.error!,
        action: FilledButton.icon(
          onPressed: provider.loadChannels,
          icon: const AppIcon(AppIcons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    if (sports.isEmpty) {
      return ChannelEmptyState(
        icon: AppIcons.sportsSoccer,
        message: _query.isEmpty
            ? 'No sports channels are available right now.'
            : 'No sports channels match “$_query”.',
      );
    }

    return ChannelGrid(channels: sports, onRefresh: provider.refresh);
  }
}
