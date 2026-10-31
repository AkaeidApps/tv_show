import '../datasources/iptv_remote_datasource.dart';
import '../models/channel_model.dart';

/// Single entry point the presentation layer uses to obtain channel data.
class IptvRepository {
  IptvRepository({IptvRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? IptvRemoteDataSource();

  final IptvRemoteDataSource _remoteDataSource;

  List<ChannelModel>? _cache;

  Future<List<ChannelModel>> getChannels({bool forceRefresh = false}) async {
    final cached = _cache;
    if (!forceRefresh && cached != null) return cached;

    final channels = await _remoteDataSource.fetchChannels();
    _cache = channels;
    return channels;
  }

  Future<ChannelModel?> getChannelById(String id) async {
    final channels = await getChannels();
    for (final channel in channels) {
      if (channel.id == id) return channel;
    }
    return null;
  }

  void clearCache() => _cache = null;

  void dispose() {
    _cache = null;
    _remoteDataSource.dispose();
  }
}
