import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Every icon shipped with the app lives as a bundled SVG in `assets/icons`.
///
/// Using SVG assets instead of the Material icon font keeps the iconography
/// identical on every platform, every screen density and every text scale.
abstract final class AppIcons {
  static const String _dir = 'assets/icons';

  static const String arrowBack = '$_dir/arrow_back.svg';
  static const String bookmark = '$_dir/bookmark.svg';
  static const String bookmarkBorder = '$_dir/bookmark_border.svg';
  static const String close = '$_dir/close.svg';
  static const String equalizer = '$_dir/equalizer.svg';
  static const String explore = '$_dir/explore.svg';
  static const String favorite = '$_dir/favorite.svg';
  static const String favoriteBorder = '$_dir/favorite_border.svg';
  static const String fullscreen = '$_dir/fullscreen.svg';
  static const String fullscreenExit = '$_dir/fullscreen_exit.svg';
  static const String liveTv = '$_dir/live_tv.svg';
  static const String liveTvOutlined = '$_dir/live_tv_outlined.svg';
  static const String pause = '$_dir/pause.svg';
  static const String playArrow = '$_dir/play_arrow.svg';
  static const String playCircle = '$_dir/play_circle.svg';
  static const String playCircleOutline = '$_dir/play_circle_outline.svg';
  static const String playlistPlay = '$_dir/playlist_play.svg';
  static const String refresh = '$_dir/refresh.svg';
  static const String search = '$_dir/search.svg';
  static const String searchOff = '$_dir/search_off.svg';
  static const String skipNext = '$_dir/skip_next.svg';
  static const String sportsSoccer = '$_dir/sports_soccer.svg';
  static const String sportsSoccerOutlined = '$_dir/sports_soccer_outlined.svg';
  static const String tvOff = '$_dir/tv_off.svg';
  static const String volumeOff = '$_dir/volume_off.svg';
  static const String volumeUp = '$_dir/volume_up.svg';
  static const String wifiOff = '$_dir/wifi_off.svg';

  /// The brand mark used by the splash screen.
  static const String brandMark = 'assets/branding/brand_mark.svg';

  static const List<String> all = [
    arrowBack,
    bookmark,
    bookmarkBorder,
    close,
    equalizer,
    explore,
    favorite,
    favoriteBorder,
    fullscreen,
    fullscreenExit,
    liveTv,
    liveTvOutlined,
    pause,
    playArrow,
    playCircle,
    playCircleOutline,
    playlistPlay,
    refresh,
    search,
    searchOff,
    skipNext,
    sportsSoccer,
    sportsSoccerOutlined,
    tvOff,
    volumeOff,
    volumeUp,
    wifiOff,
    brandMark,
  ];
}

/// Renders an [AppIcons] asset exactly like a Material [Icon] would: it picks
/// up the surrounding [IconTheme] for size and colour, and is tinted with the
/// resolved colour so a single SVG works on light and dark surfaces.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final String asset;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor =
        color ??
        iconTheme.color ??
        Theme.of(context).iconTheme.color ??
        Colors.white;

    return SvgPicture.asset(
      asset,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
