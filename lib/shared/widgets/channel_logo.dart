import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/logo_url.dart';
import '../../data/models/channel_model.dart';

/// Displays a channel's real logo.
///
/// Tries every known iptv-org logo variant (best first), falls back to the
/// official website's favicon, and finally to a generated monogram so every
/// tile has artwork.
class ChannelLogo extends StatefulWidget {
  const ChannelLogo({super.key, required this.channel});

  final ChannelModel channel;

  @override
  State<ChannelLogo> createState() => _ChannelLogoState();
}

class _ChannelLogoState extends State<ChannelLogo> {
  int _sourceIndex = 0;
  bool _advanceScheduled = false;

  List<_LogoSource> get _sources {
    final channel = widget.channel;
    final sources = <_LogoSource>[];
    final seen = <String>{};

    for (final logo in channel.logos) {
      final url = logo.directUrl;
      if (!seen.add(url)) continue;
      sources.add(_LogoSource(url: url, isSvg: logo.isSvg));
    }

    final favicon = LogoUrl.faviconFor(channel.website);
    if (favicon != null && seen.add(favicon)) {
      sources.add(_LogoSource(url: favicon, isSvg: false));
    }

    return sources;
  }

  void _useNextSource() {
    if (_advanceScheduled) return;
    _advanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _sourceIndex++;
        _advanceScheduled = false;
      });
    });
  }

  @override
  void didUpdateWidget(ChannelLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.id != widget.channel.id) {
      _sourceIndex = 0;
      _advanceScheduled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    if (_sourceIndex >= sources.length) {
      return _MonogramLogo(channel: widget.channel);
    }

    final source = sources[_sourceIndex];
    if (source.isSvg) {
      return SvgPicture.network(
        source.url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const _LogoLoader(),
        errorBuilder: (context, error, stackTrace) {
          _useNextSource();
          return const SizedBox.shrink();
        },
      );
    }

    return Image.network(
      source.url,
      fit: BoxFit.contain,
      cacheWidth: 320,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        _useNextSource();
        return const SizedBox.shrink();
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _LogoLoader();
      },
    );
  }
}

class _LogoSource {
  const _LogoSource({required this.url, required this.isSvg});

  final String url;
  final bool isSvg;
}

class _LogoLoader extends StatelessWidget {
  const _LogoLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// Monogram shown only when neither the database nor the website has a logo.
class _MonogramLogo extends StatelessWidget {
  const _MonogramLogo({required this.channel});

  final ChannelModel channel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest.shortestSide;
        final side = (available.isFinite ? available.clamp(16.0, 64.0) : 56.0)
            .toDouble();

        return Center(
          child: Container(
            width: side,
            height: side,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(side * 0.28),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(side * 0.16),
                child: Text(
                  channel.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small badge that mirrors the primary logo, used where a compact artwork is
/// needed (player header, list rows).
class ChannelLogoBadge extends StatelessWidget {
  const ChannelLogoBadge({super.key, required this.channel, this.size = 36});

  final ChannelModel channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ChannelLogo(channel: channel),
    );
  }
}
