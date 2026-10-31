import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_settings_provider.dart';
import '../../../data/models/channel_model.dart';
import '../../../data/models/stream_model.dart';
import '../../../features/library/providers/library_provider.dart';
import '../../../shared/icons/app_icons.dart';
import '../../../shared/widgets/channel_logo.dart';

/// Full screen player with YouTube style controls and automatic failover
/// between every known stream of the channel.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.channel});

  final ChannelModel channel;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  // Community IPTV servers can take tens of seconds before the first frame.
  static const Duration _sourceTimeout = Duration(seconds: 40);
  static const Duration _retryDelay = Duration(milliseconds: 350);

  /// Many IPTV servers reject the default ExoPlayer user agent, so a common
  /// browser agent is used whenever the stream does not specify one.
  static const String _defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  late final List<StreamModel> _sources;

  VideoPlayerController? _controller;
  int _sourceIndex = 0;
  int _requestId = 0;
  bool _failoverScheduled = false;

  bool _isLoading = true;
  bool _isFullscreen = false;
  bool _controlsVisible = true;
  bool _muted = false;
  bool _wasBuffering = false;
  String? _error;

  Timer? _hideControlsTimer;
  Timer? _bufferingWatchdog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final preferredQuality = context.read<AppSettingsProvider>().videoQuality;
    _sources = widget.channel.streams.toList();
    if (preferredQuality != 'Auto') {
      final qualityNumber = preferredQuality.replaceAll(RegExp(r'[^0-9]'), '');
      _sources.sort((first, second) {
        final firstMatches = first.quality?.contains(qualityNumber) ?? false;
        final secondMatches = second.quality?.contains(qualityNumber) ?? false;
        if (firstMatches == secondMatches) return 0;
        return firstMatches ? -1 : 1;
      });
    }

    unawaited(WakelockPlus.enable().catchError((Object _) {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryProvider>().recordWatched(widget.channel.id);
    });

    if (_sources.isEmpty) {
      _isLoading = false;
      _error = 'This channel has no playable stream right now.';
    } else {
      _playSource(0);
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _bufferingWatchdog?.cancel();
    _requestId++;
    WidgetsBinding.instance.removeObserver(this);

    final controller = _controller;
    _controller = null;
    controller?.removeListener(_onControllerValueChanged);
    controller?.dispose();

    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    unawaited(
      SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]),
    );
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.pause();
      unawaited(WakelockPlus.disable().catchError((Object _) {}));
    } else if (state == AppLifecycleState.resumed) {
      unawaited(WakelockPlus.enable().catchError((Object _) {}));
    }
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  Future<void> _playSource(int index, {bool isRetry = false}) async {
    final requestId = ++_requestId;

    if (!mounted) return;

    _bufferingWatchdog?.cancel();
    _bufferingWatchdog = null;
    _wasBuffering = false;
    _failoverScheduled = false;

    if (index >= _sources.length) {
      setState(() {
        _isLoading = false;
        _error = _sources.isEmpty
            ? 'This channel has no playable stream right now.'
            : 'All ${_sources.length} sources for this channel are offline. '
                  'Try another channel or tap retry later.';
        _controlsVisible = true;
      });
      return;
    }

    setState(() {
      _sourceIndex = index;
      _isLoading = true;
      _error = null;
    });

    final previous = _controller;
    _controller = null;
    await _disposeController(previous);
    if (!mounted || requestId != _requestId) return;

    final source = _sources[index];
    VideoPlayerController controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(source.url),
        httpHeaders: _headersFor(source),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
    } catch (_) {
      await _playSource(index + 1);
      return;
    }

    final initialization = controller.initialize();
    // Swallow a late failure that arrives after the timeout below.
    unawaited(initialization.catchError((Object _) {}));
    final stopwatch = Stopwatch()..start();

    try {
      await initialization.timeout(_sourceTimeout);
      if (!mounted || requestId != _requestId) {
        await _disposeController(controller);
        return;
      }

      // Some backends (FVP/MDK) surface open failures through the value
      // instead of throwing, so verify the controller really is ready.
      if (controller.value.hasError || !controller.value.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (controller.value.hasError || !controller.value.isInitialized) {
        throw StateError(
          controller.value.errorDescription ?? 'Stream is unavailable.',
        );
      }

      final isLive = _isLiveValue(controller.value);
      await controller.setLooping(!isLive);
      await controller.setVolume(_muted ? 0 : 1);
      await controller.play();

      if (!mounted || requestId != _requestId) {
        await _disposeController(controller);
        return;
      }
      if (controller.value.hasError) {
        throw StateError(
          controller.value.errorDescription ?? 'Stream is unavailable.',
        );
      }

      controller.addListener(_onControllerValueChanged);
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
      _onControllerValueChanged();
      _scheduleHideControls();
    } catch (_) {
      await _disposeController(controller);
      if (!mounted || requestId != _requestId) return;

      // Give fast failures one more chance: transient DNS/TLS hiccups are
      // common. Timeouts are not retried so failover stays quick.
      if (!isRetry && stopwatch.elapsed < const Duration(seconds: 4)) {
        await Future<void>.delayed(_retryDelay);
        if (!mounted || requestId != _requestId) return;
        await _playSource(index, isRetry: true);
        return;
      }

      // Dead source: move on to the next one automatically.
      await _playSource(index + 1);
    }
  }

  Map<String, String> _headersFor(StreamModel source) {
    final headers = <String, String>{};
    final userAgent = source.userAgent;
    final referrer = source.httpReferrer;

    headers['User-Agent'] = (userAgent != null && userAgent.isNotEmpty)
        ? userAgent
        : _defaultUserAgent;
    if (referrer != null && referrer.isNotEmpty) {
      headers['Referer'] = referrer;
    }
    return headers;
  }

  Future<void> _disposeController(VideoPlayerController? controller) async {
    if (controller == null) return;
    controller.removeListener(_onControllerValueChanged);
    try {
      await controller.dispose();
    } catch (_) {
      // Already disposed.
    }
  }

  void _onControllerValueChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;

    if (controller.value.hasError) {
      _wasBuffering = false;
      _bufferingWatchdog?.cancel();
      _bufferingWatchdog = null;
    } else if (controller.value.isBuffering && !_wasBuffering) {
      _wasBuffering = true;
      _startBufferingWatchdog(controller);
    } else if (!controller.value.isBuffering) {
      _wasBuffering = false;
      _bufferingWatchdog?.cancel();
      _bufferingWatchdog = null;
    }

    if (!controller.value.hasError || _error != null) return;

    // A live stream can die mid-playback; silently hop to the next source.
    if (_sourceIndex + 1 < _sources.length && !_failoverScheduled) {
      _failoverScheduled = true;
      unawaited(_playSource(_sourceIndex + 1));
      return;
    }

    _hideControlsTimer?.cancel();
    setState(() {
      _error =
          controller.value.errorDescription ?? 'This stream stopped playing.';
      _isLoading = false;
      _controlsVisible = true;
    });
  }

  void _startBufferingWatchdog(VideoPlayerController controller) {
    _bufferingWatchdog?.cancel();
    _bufferingWatchdog = Timer(const Duration(seconds: 20), () {
      if (!mounted ||
          !identical(_controller, controller) ||
          !controller.value.isBuffering) {
        return;
      }

      _bufferingWatchdog = null;
      if (_sourceIndex + 1 < _sources.length && !_failoverScheduled) {
        _failoverScheduled = true;
        unawaited(_playSource(_sourceIndex + 1));
        return;
      }

      setState(() {
        _error = 'This stream is still buffering. Try another source.';
        _isLoading = false;
        _controlsVisible = true;
      });
    });
  }

  void _retry() => _playSource(0);

  void _playNext() {
    if (_sources.isEmpty) return;
    _playSource((_sourceIndex + 1) % _sources.length);
  }

  // ---------------------------------------------------------------------------
  // Library
  // ---------------------------------------------------------------------------

  void _toggleFavorite() {
    final library = context.read<LibraryProvider>();
    final added = library.toggleFavorite(widget.channel.id);
    _showMessage(added ? 'Added to favourites' : 'Removed from favourites');
  }

  void _toggleSaved() {
    final library = context.read<LibraryProvider>();
    final added = library.toggleSaved(widget.channel.id);
    _showMessage(added ? 'Saved to your library' : 'Removed from saved');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(duration: const Duration(seconds: 2), content: Text(message)),
      );
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (_controller?.value.isPlaying != true) return;

    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_isLoading || _error != null) return;

    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHideControls();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
      _hideControlsTimer?.cancel();
      if (mounted) setState(() => _controlsVisible = true);
    } else {
      await controller.play();
      _scheduleHideControls();
    }
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;

    final muted = !_muted;
    await controller.setVolume(muted ? 0 : 1);
    if (!mounted) return;
    setState(() => _muted = muted);
    _scheduleHideControls();
  }

  Future<void> _setFullscreen(bool value) async {
    if (_isFullscreen == value) return;

    setState(() {
      _isFullscreen = value;
      _controlsVisible = true;
    });
    _hideControlsTimer?.cancel();

    if (value) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _scheduleHideControls();
    } else {
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _handleBack() {
    if (_isFullscreen) {
      _setFullscreen(false);
    } else {
      context.pop();
    }
  }

  Future<void> _showSourcePicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    AppIcon(AppIcons.playlistPlay, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Choose a source',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sources.length,
                  itemBuilder: (context, index) {
                    final source = _sources[index];
                    final current = index == _sourceIndex;
                    return ListTile(
                      selected: current,
                      leading: AppIcon(
                        current
                            ? AppIcons.playCircle
                            : AppIcons.playCircleOutline,
                        color: current ? AppTheme.primary : Colors.white54,
                      ),
                      title: Text(
                        source.quality ?? 'Auto quality',
                        style: TextStyle(
                          color: current ? AppTheme.primary : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _sourceLabel(source),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                      trailing: current
                          ? const AppIcon(AppIcons.equalizer, size: 18)
                          : null,
                      onTap: () => Navigator.of(context).pop(index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != _sourceIndex) {
      await _playSource(selected);
    }
  }

  String _sourceLabel(StreamModel source) {
    final uri = Uri.tryParse(source.url);
    final host = uri?.host ?? source.url;
    final extras = <String>[
      if (source.isSecure) 'HTTPS',
      if (source.isGeoBlocked) 'Geo-blocked',
      if (source.isNot24x7) 'Not 24/7',
    ];
    return extras.isEmpty ? host : '$host • ${extras.join(' • ')}';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: !_isFullscreen,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _setFullscreen(false);
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildVideo(),
                if (_isLoading) _buildLoadingOverlay(),
                if (_error != null) _buildErrorOverlay(),
                if (!_isLoading && _error == null) _buildBufferingOverlay(),
                if (!_isLoading && _error == null) _buildCenterPlayButton(),
                _buildTopBar(),
                if (!_isLoading && _error == null) _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }

    final size = controller.value.size;
    final width = size.width > 0 ? size.width : 1920.0;
    final height = size.height > 0 ? size.height : 1080.0;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: width,
            height: height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _loadingLabel(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            if (_sources.length > 1) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _playNext,
                child: const Text('Skip to next source'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _loadingLabel() {
    if (_sources.length <= 1) return 'Tuning in…';
    final quality = _sources[_sourceIndex].quality;
    final suffix = quality == null ? '' : ' • $quality';
    return 'Tuning in…\nSource ${_sourceIndex + 1} of ${_sources.length}$suffix';
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              AppIcons.tvOff,
              size: 64,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (_sources.length > 1)
              FilledButton.icon(
                onPressed: _showSourcePicker,
                icon: const AppIcon(AppIcons.playlistPlay),
                label: const Text('Choose a source'),
              )
            else
              FilledButton.icon(
                onPressed: _retry,
                icon: const AppIcon(AppIcons.refresh),
                label: const Text('Try again'),
              ),
            const SizedBox(height: 8),
            TextButton(onPressed: _retry, child: const Text('Start over')),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingOverlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isBuffering) return const SizedBox.shrink();
        return const IgnorePointer(
          child: Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterPlayButton() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.isPlaying) return const SizedBox.shrink();
        return Center(child: _BigPlayButton(onPressed: _togglePlay));
      },
    );
  }

  Widget _buildTopBar() {
    final visible = _controlsVisible || _isLoading || _error != null;
    final padding = MediaQuery.paddingOf(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.fromLTRB(8, padding.top + 8, 12, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _handleBack,
                  tooltip: 'Back',
                  icon: const AppIcon(AppIcons.arrowBack),
                ),
                const SizedBox(width: 4),
                ChannelLogoBadge(channel: widget.channel, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<LibraryProvider>(
                  builder: (context, library, _) {
                    final favorite = library.isFavorite(widget.channel.id);
                    final saved = library.isSaved(widget.channel.id);
                    return Row(
                      children: [
                        IconButton(
                          onPressed: _toggleFavorite,
                          tooltip: favorite
                              ? 'Remove from favourites'
                              : 'Add to favourites',
                          icon: AppIcon(
                            favorite
                                ? AppIcons.favorite
                                : AppIcons.favoriteBorder,
                            color: favorite ? AppTheme.accent : Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleSaved,
                          tooltip: saved ? 'Remove from saved' : 'Save',
                          icon: AppIcon(
                            saved ? AppIcons.bookmark : AppIcons.bookmarkBorder,
                            color: saved ? AppTheme.primary : Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const _LiveBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[
      if (widget.channel.country.isNotEmpty)
        widget.channel.country.toUpperCase(),
      'LIVE',
      if (_sources.isNotEmpty &&
          (_sources[_sourceIndex].quality ?? '').isNotEmpty)
        _sources[_sourceIndex].quality!,
      if (_sources.length > 1) '${_sources.length} sources',
    ];
    return parts.join(' • ');
  }

  Widget _buildBottomBar() {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    final padding = MediaQuery.paddingOf(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.fromLTRB(8, 36, 8, padding.bottom + 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final live = _isLiveValue(value);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!live && value.isInitialized)
                      VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        colors: VideoProgressColors(
                          playedColor: AppTheme.primary,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _togglePlay,
                          tooltip: value.isPlaying ? 'Pause' : 'Play',
                          iconSize: 26,
                          icon: AppIcon(
                            value.isPlaying
                                ? AppIcons.pause
                                : AppIcons.playArrow,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleMute,
                          tooltip: _muted ? 'Unmute' : 'Mute',
                          iconSize: 22,
                          icon: AppIcon(
                            _muted ? AppIcons.volumeOff : AppIcons.volumeUp,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (live)
                          const _LiveBadge()
                        else
                          Text(
                            '${_formatDuration(value.position)} / '
                            '${_formatDuration(value.duration)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const Spacer(),
                        if (_sources.length > 1)
                          IconButton(
                            onPressed: _showSourcePicker,
                            tooltip: 'Choose source',
                            iconSize: 24,
                            icon: const AppIcon(AppIcons.playlistPlay),
                          ),
                        if (_sources.length > 1)
                          IconButton(
                            onPressed: _playNext,
                            tooltip: 'Next source',
                            iconSize: 24,
                            icon: const AppIcon(AppIcons.skipNext),
                          ),
                        IconButton(
                          onPressed: () => _setFullscreen(!_isFullscreen),
                          tooltip: _isFullscreen
                              ? 'Exit full screen'
                              : 'Full screen',
                          iconSize: 26,
                          icon: AppIcon(
                            _isFullscreen
                                ? AppIcons.fullscreenExit
                                : AppIcons.fullscreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _isLiveValue(VideoPlayerValue value) {
    if (!value.isInitialized) return true;
    final duration = value.duration;
    return duration <= Duration.zero || duration > const Duration(hours: 6);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: AppIcon(AppIcons.playArrow, size: 42, color: Colors.white),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.live.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.live.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.live,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.live,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
