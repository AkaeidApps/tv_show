import 'package:flutter_test/flutter_test.dart';
import 'package:tv_show/data/models/channel_model.dart';
import 'package:tv_show/data/models/logo_model.dart';
import 'package:tv_show/data/models/stream_model.dart';

void main() {
  group('LogoModel', () {
    test('rewrites imgur gallery links to the image CDN', () {
      const logo = LogoModel(
        channelId: 'ArenaSport.ba',
        url: 'https://imgur.com/csv6YsL',
      );

      expect(logo.directUrl, 'https://i.imgur.com/csv6YsL.png');
      expect(logo.isUsable, isTrue);
    });

    test('rejects HTML pages that are not images', () {
      const logo = LogoModel(channelId: 'Canal.br', url: 'https://luna.ink/');

      expect(logo.isUsable, isFalse);
    });

    test('accepts image URLs even without a format field', () {
      const logo = LogoModel(
        channelId: 'A.bd',
        url: 'https://cdn.example.com/logo.png',
      );

      expect(logo.isUsable, isTrue);
      expect(logo.isRaster, isTrue);
    });

    test('prefers in-use raster logos over vectors', () {
      const raster = LogoModel(
        channelId: 'A.bd',
        url: 'https://cdn.example.com/logo.png',
        format: 'PNG',
      );
      const vector = LogoModel(
        channelId: 'A.bd',
        url: 'https://cdn.example.com/logo.svg',
        format: 'SVG',
      );

      expect(raster.isBetterThan(vector), isTrue);
      expect(vector.isSvg, isTrue);
    });
  });

  group('ChannelModel', () {
    test('detects sports channels from their categories', () {
      const channel = ChannelModel(
        id: 'A.bd',
        name: 'A Sports',
        categories: ['sports', 'general'],
      );

      expect(channel.isSports, isTrue);
      expect(channel.isPlayable, isFalse);
    });

    test('keeps every stream and exposes the best one', () {
      const channel = ChannelModel(
        id: 'A.bd',
        name: 'A',
        streams: [
          StreamModel(
            channelId: 'A.bd',
            url: 'https://a/1.m3u8',
            quality: '1080p',
          ),
          StreamModel(
            channelId: 'A.bd',
            url: 'https://a/2.m3u8',
            quality: '720p',
          ),
        ],
      );

      expect(channel.streams, hasLength(2));
      expect(channel.isPlayable, isTrue);
      expect(channel.streamUrl, 'https://a/1.m3u8');
      expect(channel.streamQuality, '1080p');
    });
  });

  group('StreamModel', () {
    test('only supports http(s) sources', () {
      const hls = StreamModel(channelId: 'A.bd', url: 'https://a/live.m3u8');
      const rtmp = StreamModel(channelId: 'A.bd', url: 'rtmp://a/live');

      expect(hls.isSupportedProtocol, isTrue);
      expect(rtmp.isSupportedProtocol, isFalse);
    });
  });
}
