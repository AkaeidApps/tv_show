import 'package:flutter/foundation.dart';

import '../../../core/utils/country_filter.dart';
import '../../../data/models/channel_model.dart';
import '../../../data/repositories/iptv_repository.dart';

/// Owns the channel catalogue plus the active search/country filters.
class ChannelsProvider extends ChangeNotifier {
  ChannelsProvider(this._repository);

  final IptvRepository _repository;

  List<ChannelModel> _allChannels = const [];
  List<ChannelModel> _visibleChannels = const [];
  List<ChannelModel> _sportsChannels = const [];
  Map<String, ChannelModel> _byId = const {};
  List<String> _countries = const [];
  String _selectedCountry = CountryFilter.allCountries;
  String _query = '';
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  List<ChannelModel> get channels => _visibleChannels;
  List<ChannelModel> get allChannels => _allChannels;
  List<ChannelModel> get sportsChannels => _sportsChannels;
  List<String> get countries => _countries;
  String get selectedCountry => _selectedCountry;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasChannels => _allChannels.isNotEmpty;
  int get totalChannels => _allChannels.length;

  /// Channels matching [ids], preserving the order of [ids].
  List<ChannelModel> channelsForIds(Iterable<String> ids) {
    final result = <ChannelModel>[];
    for (final id in ids) {
      final channel = _byId[id];
      if (channel != null) result.add(channel);
    }
    return result;
  }

  ChannelModel? channelById(String id) => _byId[id];

  Future<void> loadChannels({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _notify();

    try {
      final channels = await _repository.getChannels(
        forceRefresh: forceRefresh,
      );

      _allChannels = channels;
      _byId = {for (final channel in channels) channel.id: channel};
      _sportsChannels = channels
          .where((channel) => channel.isSports)
          .toList(growable: false);
      _countries = CountryFilter.availableCountries(channels);

      if (_selectedCountry != CountryFilter.allCountries &&
          !_countries.contains(_selectedCountry)) {
        _selectedCountry = CountryFilter.allCountries;
      }

      _applyFilters();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void selectCountry(String countryCode) {
    if (_selectedCountry == countryCode) return;
    _selectedCountry = countryCode;
    _applyFilters();
    _notify();
  }

  void search(String query) {
    if (_query == query) return;
    _query = query;
    _applyFilters();
    _notify();
  }

  void clearSearch() => search('');

  Future<void> refresh() => loadChannels(forceRefresh: true);

  void _applyFilters() {
    _visibleChannels = CountryFilter.apply(
      _allChannels,
      countryCode: _selectedCountry,
      query: _query,
    );
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
