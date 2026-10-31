import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tv_show/core/constants/api_constants.dart';
import 'package:tv_show/data/datasources/iptv_remote_datasource.dart';

void main() {
  test('retains all playable source alternatives for a channel', () async {
    final streams = [
      for (var index = 0; index < 15; index++)
        {
          'channel': 'Test.tv',
          'url': 'https://stream.example.com/live-$index.m3u8',
        },
      {'channel': 'Test.tv', 'url': 'rtmp://stream.example.com/live'},
    ];
    final responses = <String, Object>{
      ApiConstants.channelsUrl: [
        {'id': 'Test.tv', 'name': 'Test TV'},
      ],
      ApiConstants.streamsUrl: streams,
      ApiConstants.logosUrl: <Object>[],
    };
    final client = MockClient((request) async {
      final body = responses[request.url.toString()];
      return http.Response(jsonEncode(body), 200);
    });
    final dataSource = IptvRemoteDataSource(client: client);
    addTearDown(dataSource.dispose);

    final channels = await dataSource.fetchChannels();

    expect(channels, hasLength(1));
    expect(channels.single.streams, hasLength(16));
    expect(
      channels.single.streams.any((stream) => stream.url.startsWith('rtmp:')),
      isTrue,
    );
  });
}
