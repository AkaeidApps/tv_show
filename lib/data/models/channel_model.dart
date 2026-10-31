import 'logo_model.dart';
import 'stream_model.dart';

/// A TV channel from the iptv-org database, joined with every known
/// [StreamModel] and its [LogoModel] variants.
class ChannelModel {
  const ChannelModel({
    required this.id,
    required this.name,
    this.altNames = const [],
    this.network,
    this.country = '',
    this.categories = const [],
    this.logos = const [],
    this.website,
    this.streams = const [],
  });

  final String id;
  final String name;
  final List<String> altNames;
  final String? network;

  /// ISO 3166-1 alpha-2 country code, e.g. `US` or `BD`.
  final String country;
  final List<String> categories;

  /// Every usable logo, best variant first.
  final List<LogoModel> logos;
  final String? website;

  /// All playable streams, best source first.
  final List<StreamModel> streams;

  StreamModel? get primaryStream => streams.isEmpty ? null : streams.first;

  bool get isPlayable => streams.isNotEmpty;

  String? get streamUrl => primaryStream?.url;
  String? get streamQuality => primaryStream?.quality;
  String? get httpReferrer => primaryStream?.httpReferrer;
  String? get userAgent => primaryStream?.userAgent;

  /// Primary logo URL (kept for backwards compatibility).
  String? get logo => logos.isEmpty ? null : logos.first.directUrl;

  /// Format of [logo] (`PNG`, `SVG`, …) when known.
  String? get logoFormat => logos.isEmpty ? null : logos.first.format;

  /// True when [logo] must be rendered with an SVG renderer.
  bool get isLogoVector {
    if (logos.isEmpty) return false;
    if ((logoFormat ?? '').toUpperCase() == 'SVG') return true;
    final path = Uri.tryParse(logo ?? '')?.path.toLowerCase() ?? '';
    return path.endsWith('.svg');
  }

  bool get isSports =>
      categories.any((category) => category.toLowerCase().contains('sport'));

  /// Two letter fallback used when a channel has no logo.
  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    if (words.isEmpty) return 'TV';
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown channel',
      altNames: _stringList(json['alt_names']),
      network: json['network'] as String?,
      country: json['country'] as String? ?? '',
      categories: _stringList(json['categories']),
      website: json['website'] as String?,
    );
  }

  ChannelModel withLogos(List<LogoModel> logos) {
    return ChannelModel(
      id: id,
      name: name,
      altNames: altNames,
      network: network,
      country: country,
      categories: categories,
      logos: logos,
      website: website,
      streams: streams,
    );
  }

  ChannelModel withStreams(List<StreamModel> streams) {
    return ChannelModel(
      id: id,
      name: name,
      altNames: altNames,
      network: network,
      country: country,
      categories: categories,
      logos: logos,
      website: website,
      streams: streams,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }
}
