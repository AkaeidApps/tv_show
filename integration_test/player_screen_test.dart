import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:tv_show/core/theme/app_theme.dart';
import 'package:tv_show/data/models/channel_model.dart';
import 'package:tv_show/data/models/stream_model.dart';
import 'package:tv_show/features/library/providers/library_provider.dart';
import 'package:tv_show/features/player/presentation/player_screen.dart';

/// End-to-end check of the real player screen against live IPTV sources.
///
/// Run on a device/desktop with:
///   flutter test integration_test/player_screen_test.dart -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  fvp.registerWith();

  Future<void> waitUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 45),
    String? reason,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (condition()) return;
    }
    fail(reason ?? 'Condition was not met in time');
  }

  const channel = ChannelModel(
    id: 'al-iraqia-sport.iq',
    name: 'Al Iraqia Sport',
    country: 'IQ',
    categories: ['sports'],
    streams: [
      StreamModel(
        channelId: 'al-iraqia-sport.iq',
        url: 'https://imn-live.esite-lab.com/hls/iraqia-sports-1.m3u8',
        quality: '720p',
      ),
    ],
  );

  testWidgets('player screen plays a live sports channel', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LibraryProvider>(
        create: (_) => LibraryProvider(),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const PlayerScreen(channel: channel),
        ),
      ),
    );

    await waitUntil(
      tester,
      () => find.byType(VideoPlayer).evaluate().isNotEmpty,
      reason: 'The player never started a video surface',
    );

    // Let playback run for a moment, then confirm it is actually progressing.
    await tester.pump(const Duration(seconds: 3));

    final player = tester.widget<VideoPlayer>(find.byType(VideoPlayer));
    final value = player.controller.value;

    expect(value.isInitialized, isTrue);
    expect(value.hasError, isFalse, reason: value.errorDescription);
    expect(value.isPlaying, isTrue);
    expect(value.size.width, greaterThan(0));
    expect(value.position, greaterThan(Duration.zero));

    expect(find.textContaining('offline'), findsNothing);
    expect(find.textContaining('Tuning in'), findsNothing);
  });
}
