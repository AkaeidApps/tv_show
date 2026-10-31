import '../../data/models/channel_model.dart';

/// Pure helpers that narrow the full channel catalogue down to what the user
/// is looking for. Kept outside the provider so they are easy to unit test.
class CountryFilter {
  const CountryFilter._();

  /// Sentinel used by the UI for "no country filter".
  static const String allCountries = 'ALL';

  static List<ChannelModel> apply(
    List<ChannelModel> channels, {
    String countryCode = allCountries,
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCountry = countryCode.toUpperCase();

    return channels
        .where((channel) {
          final matchesCountry =
              normalizedCountry == allCountries ||
              channel.country.toUpperCase() == normalizedCountry;
          if (!matchesCountry) return false;

          if (normalizedQuery.isEmpty) return true;

          return channel.name.toLowerCase().contains(normalizedQuery) ||
              channel.country.toLowerCase().contains(normalizedQuery) ||
              channel.categories.any(
                (category) => category.toLowerCase().contains(normalizedQuery),
              );
        })
        .toList(growable: false);
  }

  /// Sorted list of country codes that actually have at least one channel.
  static List<String> availableCountries(List<ChannelModel> channels) {
    final codes = <String>{};
    for (final channel in channels) {
      final code = channel.country.trim().toUpperCase();
      if (code.isNotEmpty) codes.add(code);
    }
    return codes.toList()..sort();
  }
}
