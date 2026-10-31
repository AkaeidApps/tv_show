import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/country_display.dart';
import '../../../core/utils/country_filter.dart';
import '../../../data/models/channel_model.dart';
import '../../../shared/icons/app_icons.dart';
import '../../../shared/widgets/channel_logo.dart';
import '../../../shared/widgets/tab_header.dart';
import '../providers/channels_provider.dart';
import 'widgets/channel_grid.dart';
import 'widgets/channel_search_field.dart';

/// Home tab: the full catalogue with search and country filters.
class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  static const _categories = [
    'Cricket',
    'Football',
    'News',
    'Cartoon',
    'Discover',
    'Live TV',
  ];

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChannelsProvider>();
      if (!provider.isLoading &&
          !provider.hasChannels &&
          provider.error == null) {
        provider.loadChannels();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChannelsProvider>();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradientFor(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TabHeader(
              title: 'TV Show',
              subtitle: provider.totalChannels == 0
                  ? 'Discover live channels worldwide'
                  : '${provider.channels.length} of '
                        '${provider.totalChannels} channels',
              icon: AppIcons.brandMark,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Open menu',
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  IconButton(
                    onPressed: provider.isLoading ? null : provider.refresh,
                    tooltip: 'Refresh channels',
                    icon: const AppIcon(AppIcons.refresh),
                  ),
                ],
              ),
            ),
            ChannelSearchField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                provider.search(value);
              },
              onClear: () {
                _searchController.clear();
                setState(() {});
                provider.clearSearch();
              },
            ),
            if (provider.countries.isNotEmpty)
              _CountryBar(
                countries: provider.countries,
                selected: provider.selectedCountry,
                onSelected: provider.selectCountry,
              ),
            _CategoryBar(
              categories: _categories,
              selected: provider.selectedCategory,
              onSelected: provider.selectCategory,
            ),
            if (provider.hasChannels && provider.channels.isNotEmpty)
              _LiveChannelSlider(
                channels: provider.channels.take(8).toList(growable: false),
                onViewAll: () => provider.selectCategory('Live TV'),
              ),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChannelsProvider provider) {
    if (provider.isLoading && !provider.hasChannels) {
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

    if (provider.channels.isEmpty) {
      return ChannelEmptyState(
        icon: AppIcons.searchOff,
        message: provider.query.isEmpty
            ? 'No channels available for this country yet.'
            : 'No channels match “${provider.query}”.',
        action: OutlinedButton(
          onPressed: () {
            _searchController.clear();
            provider.clearSearch();
            provider.selectCountry(CountryFilter.allCountries);
            provider.selectCategory('Discover');
          },
          child: const Text('Clear filters'),
        ),
      );
    }

    return ChannelGrid(
      channels: provider.channels,
      onRefresh: provider.refresh,
    );
  }
}

class _CountryBar extends StatelessWidget {
  const _CountryBar({
    required this.countries,
    required this.selected,
    required this.onSelected,
  });

  final List<String> countries;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [CountryFilter.allCountries, ...countries];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final code = items[index];
          final isSelected = code == selected;

          return ChoiceChip(
            label: Text(
              code == CountryFilter.allCountries
                  ? '🌍 All'
                  : '${CountryDisplay.flag(code)} $code',
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(code),
            showCheckmark: false,
            selectedColor: AppTheme.primary.withValues(alpha: 0.2),
            backgroundColor: AppTheme.surfaceFor(context),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.foregroundFor(context).withValues(alpha: 0.08),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.mutedForegroundFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category == selected;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onSelected(category),
          showCheckmark: false,
          selectedColor: AppTheme.primary.withValues(alpha: 0.18),
          backgroundColor: AppTheme.surfaceFor(context),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.foregroundFor(context).withValues(alpha: 0.08),
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.foregroundFor(context).withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        );
      },
    ),
  );
}

class _LiveChannelSlider extends StatelessWidget {
  const _LiveChannelSlider({required this.channels, required this.onViewAll});

  final List<ChannelModel> channels;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Live TV',
                  style: TextStyle(
                    color: AppTheme.foregroundFor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('See all')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: channels.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _LiveChannelTile(channel: channels[index]),
          ),
        ),
      ],
    ),
  );
}

class _LiveChannelTile extends StatelessWidget {
  const _LiveChannelTile({required this.channel});

  final ChannelModel channel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 116,
    child: Material(
      color: AppTheme.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRouter.player, extra: channel),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(child: ChannelLogo(channel: channel)),
              ),
              Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.foregroundFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                channel.country.isEmpty
                    ? '🌍 LIVE'
                    : '${CountryDisplay.flag(channel.country)} LIVE',
                style: const TextStyle(
                  color: AppTheme.live,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
