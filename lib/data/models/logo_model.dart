/// A logo variant for a channel, as returned by `logos.json` from the
/// iptv-org API. Channels can have several variants (white, horizontal, SVG…).
class LogoModel {
  const LogoModel({
    required this.channelId,
    required this.url,
    this.format,
    this.width = 0,
    this.height = 0,
    this.inUse = true,
  });

  final String channelId;
  final String url;

  /// `PNG`, `JPEG`, `SVG`, `WebP`, `GIF`, `AVIF`, `APNG` or null.
  final String? format;
  final int width;
  final int height;
  final bool inUse;

  bool get isValid => channelId.isNotEmpty && url.isNotEmpty;

  /// True for a known image format or a non-root URL on an extensionless CDN.
  /// Invalid HTML responses are handled by the logo widget's error fallback.
  bool get isUsable {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    if (_format.isNotEmpty && !_imageFormats.contains(_format)) return false;
    if (_imageFormats.contains(_format) ||
        _imageExtensions.contains(_extension)) {
      return true;
    }
    return uri.pathSegments.any((segment) => segment.isNotEmpty);
  }

  /// Direct image URL. Imgur gallery links are rewritten to the image CDN so
  /// the logo actually loads.
  String get directUrl {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final host = uri.host.toLowerCase();
    if ((host == 'imgur.com' || host == 'www.imgur.com') &&
        uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      if (id.isNotEmpty && !id.contains('.')) {
        return 'https://i.imgur.com/$id.png';
      }
    }
    return url;
  }

  bool get isSvg => _format == 'SVG' || _extension == 'svg';

  bool get isRaster {
    switch (_format) {
      case 'PNG':
      case 'JPEG':
      case 'JPG':
      case 'WEBP':
      case 'AVIF':
      case 'GIF':
      case 'APNG':
        return true;
    }
    return const {
      'png',
      'jpg',
      'jpeg',
      'webp',
      'avif',
      'gif',
      'apng',
    }.contains(_extension);
  }

  /// Higher is better. Prefers logos currently in use, then transparent
  /// raster formats, then JPEG, then vectors.
  int get score {
    final formatScore = switch (_format) {
      'PNG' || 'WEBP' || 'GIF' || 'APNG' => 4,
      'JPEG' || 'JPG' => 3,
      'SVG' => 2,
      'AVIF' => 1,
      _ => isRaster ? 4 : (isSvg ? 2 : 0),
    };
    final sizeScore = width >= 128 && height >= 128 ? 1 : 0;
    return (inUse ? 10 : 0) + formatScore + sizeScore;
  }

  bool isBetterThan(LogoModel other) {
    if (score != other.score) return score > other.score;
    return width * height > other.width * other.height;
  }

  static const _imageFormats = {
    'PNG',
    'JPEG',
    'JPG',
    'SVG',
    'WEBP',
    'AVIF',
    'GIF',
    'APNG',
  };

  static const _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'svg',
    'webp',
    'avif',
    'gif',
    'apng',
  };

  String get _format => (format ?? '').trim().toUpperCase();

  String get _extension {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  factory LogoModel.fromJson(Map<String, dynamic> json) {
    return LogoModel(
      channelId: json['channel'] as String? ?? '',
      url: json['url'] as String? ?? '',
      format: json['format'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      inUse: json['in_use'] as bool? ?? true,
    );
  }
}
