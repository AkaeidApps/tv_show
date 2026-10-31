import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/iptv_repository.dart';
import '../features/channels/providers/channels_provider.dart';
import '../features/library/providers/library_provider.dart';
import 'router/app_router.dart';

/// Root widget: wires dependencies and hands navigation to [AppRouter].
class TvShowApp extends StatelessWidget {
  const TvShowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<IptvRepository>(
          create: (_) => IptvRepository(),
          dispose: (_, repository) => repository.dispose(),
        ),
        ChangeNotifierProvider<ChannelsProvider>(
          create: (context) =>
              ChannelsProvider(context.read<IptvRepository>())..loadChannels(),
        ),
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'TV Show',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
