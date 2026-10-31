import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/country_display.dart';
import '../../../core/utils/country_filter.dart';
import '../../../shared/widgets/tab_header.dart';
import '../providers/channels_provider.dart';

class CountriesScreen extends StatefulWidget {
  const CountriesScreen({super.key});

  @override
  State<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends State<CountriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChannelsProvider>();
    final countries = provider.countries
        .where(
          (code) =>
              CountryDisplay.name(code)
                  .toLowerCase()
                  .contains(_query.toLowerCase()) ||
              code.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradientFor(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TabHeader(
              title: 'Choose a country',
              subtitle: '${provider.countries.length} countries available',
              icon: 'assets/icons/explore.svg',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search countries',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.surfaceFor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading && !provider.hasChannels
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        _CountryTile(
                          code: CountryFilter.allCountries,
                          name: 'All countries',
                          selected:
                              provider.selectedCountry ==
                              CountryFilter.allCountries,
                          onTap: () => _selectCountry(
                            context,
                            provider,
                            CountryFilter.allCountries,
                          ),
                        ),
                        for (final code in countries)
                          _CountryTile(
                            code: code,
                            name: CountryDisplay.name(code),
                            selected: provider.selectedCountry == code,
                            onTap: () =>
                                _selectCountry(context, provider, code),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCountry(
    BuildContext context,
    ChannelsProvider provider,
    String code,
  ) {
    provider.selectCountry(code);
    provider.selectCategory('Discover');
    context.go(AppRouter.home);
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = AppTheme.foregroundFor(context);
    return Card(
      color: AppTheme.surfaceFor(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Text(
          code == CountryFilter.allCountries ? '🌍' : CountryDisplay.flag(code),
          style: const TextStyle(fontSize: 26),
        ),
        title: Text(
          name,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        ),
        subtitle: code == CountryFilter.allCountries
            ? null
            : Text(
                code,
                style: TextStyle(color: AppTheme.mutedForegroundFor(context)),
              ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppTheme.primary)
            : Icon(
                Icons.chevron_right,
                color: AppTheme.mutedForegroundFor(context),
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
