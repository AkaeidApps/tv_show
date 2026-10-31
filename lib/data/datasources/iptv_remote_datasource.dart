import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/channel_model.dart';
import '../models/logo_model.dart';
import '../models/stream_model.dart';

/// Talks to the iptv-org REST API and joins channels with their streams and
/// logos.
class IptvRemoteDataSource {
  IptvRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Downloads the channel catalogue and keeps only channels that have a
  /// playable stream, sorted alphabetically.
  Future<List<ChannelModel>> fetchChannels() async {
    final responses = await Future.wait([
      _getJsonList(ApiConstants.channelsUrl),
      _getJsonList(ApiConstants.streamsUrl),
      _getJsonList(ApiConstants.logosUrl),
    ]);

    final channelsJson = responses[0];
    final streamsJson = responses[1];
    final logosJson = responses[2];

    final streamsByChannel = <String, List<StreamModel>>{};
    for (final raw in streamsJson) {
      final stream = StreamModel.fromJson(raw);
      if (!stream.isValid || !stream.isSupportedProtocol) continue;
      streamsByChannel.putIfAbsent(stream.channelId, () => []).add(stream);
    }

    for (final entry in streamsByChannel.entries) {
      final seen = <String>{};
      entry.value.removeWhere((stream) => !seen.add(stream.url));
      entry.value.sort((a, b) => _streamScore(b).compareTo(_streamScore(a)));
    }

    final logosByChannel = <String, List<LogoModel>>{};
    for (final raw in logosJson) {
      final logo = LogoModel.fromJson(raw);
      if (!logo.isValid || !logo.isUsable) continue;
      logosByChannel.putIfAbsent(logo.channelId, () => []).add(logo);
    }

    for (final entry in logosByChannel.entries) {
      final seen = <String>{};
      entry.value.removeWhere((logo) => !seen.add(logo.directUrl));
      entry.value.sort((a, b) {
        if (a.isBetterThan(b)) return -1;
        if (b.isBetterThan(a)) return 1;
        return 0;
      });
      // Keep a few variants so a dead URL can fall back to the next one.
      if (entry.value.length > 4) {
        entry.value.removeRange(4, entry.value.length);
      }
    }

    final channels = <ChannelModel>[];
    for (final raw in channelsJson) {
      var channel = ChannelModel.fromJson(raw);
      if (channel.id.isEmpty) continue;

      final streams = streamsByChannel[channel.id];
      if (streams == null || streams.isEmpty) continue;

      final logos = logosByChannel[channel.id];
      if (logos != null && logos.isNotEmpty) channel = channel.withLogos(logos);

      // Keep the best handful of sources; enough to fail over without
      // bloating the in-memory catalogue.
      channels.add(
        channel.withStreams(streams.take(12).toList(growable: false)),
      );
    }

    channels.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return channels;
  }

  Future<List<Map<String, dynamic>>> _getJsonList(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode != 200) {
        throw IptvException(
          'Request failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const IptvException('Unexpected response format.');
      }

      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    } on TimeoutException {
      throw const IptvException('The server took too long to respond.');
    } on http.ClientException {
      throw const IptvException(
        'No internet connection. Please check your network.',
      );
    } on FormatException {
      throw const IptvException('The server returned invalid data.');
    }
  }

  void dispose() => _client.close();

  /// Higher is better: quality first, then HTTPS, then streams that are
  /// neither geo-blocked nor limited to part of the day.
  int _streamScore(StreamModel stream) {
    var score = stream.qualityScore * 100;
    if (stream.isSecure) score += 40;
    if (!stream.isGeoBlocked) score += 20;
    if (!stream.isNot24x7) score += 10;
    return score;
  }
}

/// Domain level error with a message that can be shown directly in the UI.
class IptvException implements Exception {
  const IptvException(this.message);

  final String message;

  @override
  String toString() => message;
}
