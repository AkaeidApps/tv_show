import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _themeModeKey = 'settings.themeMode.v1';
  static const _videoQualityKey = 'settings.videoQuality.v1';
  static const videoQualities = ['Auto', '1080p', '720p', '480p'];

  ThemeMode _themeMode = ThemeMode.dark;
  String _videoQuality = 'Auto';

  ThemeMode get themeMode => _themeMode;
  String get videoQuality => _videoQuality;

  AppSettingsProvider() {
    unawaited(_restore());
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    unawaited(_persist(_themeModeKey, mode.name));
  }

  void setVideoQuality(String quality) {
    if (!videoQualities.contains(quality) || _videoQuality == quality) return;
    _videoQuality = quality;
    notifyListeners();
    unawaited(_persist(_videoQualityKey, quality));
  }

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final mode = preferences.getString(_themeModeKey);
      if (mode == ThemeMode.light.name) _themeMode = ThemeMode.light;
      final quality = preferences.getString(_videoQualityKey);
      if (quality != null && videoQualities.contains(quality)) {
        _videoQuality = quality;
      }
    } catch (_) {
      // The defaults remain available when platform storage is unavailable.
    }
    notifyListeners();
  }

  Future<void> _persist(String key, String value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, value);
    } catch (_) {
      // Keep the selected setting in memory for the current session.
    }
  }
}
