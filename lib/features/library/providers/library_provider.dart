import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the channels the user cares about: favourites (explicit heart) and
/// saved channels (opened at least once, or bookmarked manually).
///
/// Persistence failures are swallowed so the app still works in environments
/// where the platform store is unavailable (widget tests, desktop previews).
class LibraryProvider extends ChangeNotifier {
  LibraryProvider() {
    unawaited(_restore());
  }

  static const String _favoritesKey = 'library.favorites.v1';
  static const String _savedKey = 'library.saved.v1';
  static const int _maxSaved = 100;

  final List<String> _favoriteIds = [];
  final List<String> _savedIds = [];
  bool _restored = false;

  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);
  List<String> get savedIds => List.unmodifiable(_savedIds);
  int get favoriteCount => _favoriteIds.length;
  int get savedCount => _savedIds.length;
  bool get isReady => _restored;

  bool isFavorite(String channelId) => _favoriteIds.contains(channelId);
  bool isSaved(String channelId) => _savedIds.contains(channelId);

  /// Returns the new favourite state.
  bool toggleFavorite(String channelId) {
    final added = !_favoriteIds.remove(channelId);
    if (added) _favoriteIds.insert(0, channelId);
    _persist();
    notifyListeners();
    return added;
  }

  /// Returns the new saved state.
  bool toggleSaved(String channelId) {
    final added = !_savedIds.remove(channelId);
    if (added) _savedIds.insert(0, channelId);
    _trimSaved();
    _persist();
    notifyListeners();
    return added;
  }

  /// Records that a channel was opened. Saved channels are ordered by recency.
  void recordWatched(String channelId) {
    if (_savedIds.isNotEmpty && _savedIds.first == channelId) return;

    _savedIds.remove(channelId);
    _savedIds.insert(0, channelId);
    _trimSaved();
    _persist();
    notifyListeners();
  }

  void removeSaved(String channelId) {
    if (!_savedIds.remove(channelId)) return;
    _persist();
    notifyListeners();
  }

  void removeFavorite(String channelId) {
    if (!_favoriteIds.remove(channelId)) return;
    _persist();
    notifyListeners();
  }

  void _trimSaved() {
    if (_savedIds.length > _maxSaved) {
      _savedIds.removeRange(_maxSaved, _savedIds.length);
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favoriteIds
        ..clear()
        ..addAll(prefs.getStringList(_favoritesKey) ?? const []);
      _savedIds
        ..clear()
        ..addAll(prefs.getStringList(_savedKey) ?? const []);
      _trimSaved();
    } catch (_) {
      // No platform store available: keep the in-memory state only.
    } finally {
      _restored = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteIds);
      await prefs.setStringList(_savedKey, _savedIds);
    } catch (_) {
      // Ignore: the in-memory lists are still correct for this session.
    }
  }
}
