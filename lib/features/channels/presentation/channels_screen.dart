import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/country_filter.dart';
import '../../../shared/icons/app_icons.dart';
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
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TabHeader(
              title: 'Live TV',
              subtitle: provider.totalChannels == 0
                  ? 'Discover channels worldwide'
                  : '${provider.channels.length} of '
                        '${provider.totalChannels} channels',
              icon: AppIcons.liveTv,
              action: IconButton(
                onPressed: provider.isLoading ? null : provider.refresh,
                tooltip: 'Refresh channels',
                icon: const AppIcon(AppIcons.refresh),
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
            label: Text(code == CountryFilter.allCountries ? 'All' : code),
            selected: isSelected,
            onSelected: (_) => onSelected(code),
            showCheckmark: false,
            selectedColor: AppTheme.primary.withValues(alpha: 0.2),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primary
                  : Colors.white.withValues(alpha: 0.08),
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primary : Colors.white70,
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
