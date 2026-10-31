import 'package:flutter_test/flutter_test.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

/// Manual smoke test for the native playback engine.
///
/// Run on a real device/desktop with:
///   flutter test integration_test/playback_test.dart -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  fvp.registerWith();

  final streams = <String, String>{
    'mux-hls': 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    'iraqia-sports': 'https://imn-live.esite-lab.com/hls/iraqia-sports-1.m3u8',
    '30a-golf': 'https://30a-tv.com/feeds/vidaa/golf.m3u8',
    'acc-digital': 'https://raycom-accdn-firetv.amagi.tv/playlist.m3u8',
  };

  for (final entry in streams.entries) {
    testWidgets('plays ${entry.key}', (tester) async {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(entry.value),
        httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
      );

      try {
        await controller.initialize().timeout(const Duration(seconds: 40));
        await controller.play();
        await tester.pump(const Duration(seconds: 3));

        expect(controller.value.isInitialized, isTrue);
        expect(controller.value.hasError, isFalse);
        expect(controller.value.size.width, greaterThan(0));
      } finally {
        await controller.dispose();
      }
    });
  }
}
