import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // FVP (libmdk + FFmpeg) powers playback on every platform. It plays HLS,
  // MPEG-TS, RTSP-style sources and more, which the default Android/iOS
  // implementations frequently refuse to open.
  fvp.registerWith();

  runApp(const TvShowApp());
}
