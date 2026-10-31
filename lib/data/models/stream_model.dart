/// A single playable stream belonging to a [ChannelModel].
///
/// Mirrors an entry of `streams.json` from the iptv-org API.
class StreamModel {
  const StreamModel({
    required this.channelId,
    required this.url,
    this.quality,
    this.label,
    this.labels = const [],
    this.title,
    this.httpReferrer,
    this.userAgent,
  });

  final String channelId;
  final String url;
  final String? quality;

  /// Legacy single label field kept for backwards compatibility.
  final String? label;

  /// Reasons why the stream may not work everywhere, e.g. `Geo-blocked`.
  final List<String> labels;
  final String? title;
  final String? httpReferrer;
  final String? userAgent;

  bool get isValid => channelId.isNotEmpty && url.isNotEmpty;

  /// `video_player` only understands HTTP(S) sources (HLS/DASH/MP4).
  bool get isSupportedProtocol {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  bool get isSecure => url.toLowerCase().startsWith('https://');

  bool get isGeoBlocked =>
      labels.any((label) => label.toLowerCase().contains('geo'));

  bool get isNot24x7 =>
      labels.any((label) => label.toLowerCase().contains('not 24'));

  /// 2160p → 5 … unknown → 0.
  int get qualityScore {
    switch (quality) {
      case '2160p':
        return 5;
      case '1440p':
        return 4;
      case '1080p':
        return 3;
      case '720p':
        return 2;
      case '480p':
        return 1;
      default:
        return 0;
    }
  }

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      channelId: json['channel'] as String? ?? '',
      url: json['url'] as String? ?? '',
      quality: json['quality'] as String?,
      label: json['label'] as String?,
      labels: _stringList(json['labels']),
      title: json['title'] as String?,
      httpReferrer:
          json['referrer'] as String? ?? json['http_referrer'] as String?,
      userAgent: json['user_agent'] as String?,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }
}
