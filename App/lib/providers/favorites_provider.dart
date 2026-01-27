import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Riverpod provider for favorites management
final favoritesProvider = NotifierProvider<FavoritesNotifier, List<FavoriteItem>>(() {
  return FavoritesNotifier();
});

/// Notifier that manages the favorites list reactively
class FavoritesNotifier extends Notifier<List<FavoriteItem>> {
  static const String _favoritesKey = 'favorite_line_stops';
  
  @override
  List<FavoriteItem> build() {
    _loadFavorites();
    return [];
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList(_favoritesKey);
    
    if (data == null) {
      state = [];
      return;
    }
    
    state = data.map((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      return FavoriteItem.fromJson(jsonMap);
    }).toList();
  }

  /// Add a favorite (Line, Stop) pair
  Future<void> addFavorite(FavoriteItem item) async {
    // Check if already exists
    if (state.any((f) => f.key == item.key)) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList(_favoritesKey) ?? [];
    current.add(json.encode(item.toJson()));
    await prefs.setStringList(_favoritesKey, current);
    
    // Update state reactively
    state = [...state, item];
  }

  /// Remove a favorite by lineId and stopId
  Future<void> removeFavorite(String lineId, String stopId) async {
    final targetKey = '${lineId}_$stopId';
    
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList(_favoritesKey) ?? [];
    current.removeWhere((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      final storedItem = FavoriteItem.fromJson(jsonMap);
      return storedItem.key == targetKey;
    });
    await prefs.setStringList(_favoritesKey, current);
    
    // Update state reactively
    state = state.where((f) => f.key != targetKey).toList();
  }

  /// Check if a specific (Line, Stop) pair is a favorite
  bool isFavorite(String lineId, String stopId) {
    final targetKey = '${lineId}_$stopId';
    return state.any((f) => f.key == targetKey);
  }
}
