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
      const rootPage = LogoModel(
        channelId: 'Canal.br',
        url: 'https://luna.ink/',
      );
      const htmlFile = LogoModel(
        channelId: 'Canal.br',
        url: 'https://cdn.example.com/logo.html',
        format: 'HTML',
      );

      expect(rootPage.isUsable, isFalse);
      expect(htmlFile.isUsable, isFalse);
    });

    test('accepts extensionless URLs from image CDNs', () {
      const logo = LogoModel(
        channelId: 'A.bd',
        url: 'https://cdn.example.com/images/logo/12345',
      );

      expect(logo.isUsable, isTrue);
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
    test('supports network schemes handled by the FVP backend', () {
      const sources = [
        StreamModel(channelId: 'A.bd', url: 'https://a/live.m3u8'),
        StreamModel(channelId: 'A.bd', url: 'rtsp://a/live'),
        StreamModel(channelId: 'A.bd', url: 'rtmp://a/live'),
        StreamModel(channelId: 'A.bd', url: 'rtp://a/live'),
        StreamModel(channelId: 'A.bd', url: 'udp://a/live'),
        StreamModel(channelId: 'A.bd', url: 'srt://a/live'),
        StreamModel(channelId: 'A.bd', url: 'mmsh://a/live'),
      ];

      expect(sources.every((source) => source.isSupportedProtocol), isTrue);
    });

    test('rejects unsupported and malformed stream URLs', () {
      const localFile = StreamModel(
        channelId: 'A.bd',
        url: 'file:///tmp/live.m3u8',
      );
      const malformed = StreamModel(channelId: 'A.bd', url: 'https:');

      expect(localFile.isSupportedProtocol, isFalse);
      expect(malformed.isSupportedProtocol, isFalse);
    });
  });
}
