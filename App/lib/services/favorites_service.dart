import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_line_stops'; // New key for new format
  
  // Cached SharedPreferences instance
  static SharedPreferences? _prefsInstance;
  
  Future<SharedPreferences> get _prefs async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }
  
  /// Get all favorites as FavoriteItem list
  Future<List<FavoriteItem>> getFavorites() async {
    final prefs = await _prefs;
    final List<String>? data = prefs.getStringList(_favoritesKey);
    
    if (data == null) return [];
    
    return data.map((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      return FavoriteItem.fromJson(jsonMap);
    }).toList();
  }

  /// Add a favorite (Line, Stop) pair
  Future<void> addFavorite(FavoriteItem item) async {
    final prefs = await _prefs;
    final List<String> current = prefs.getStringList(_favoritesKey) ?? [];
    
    // Check duplication by unique key
    bool exists = current.any((stored) {
      final Map<String, dynamic> jsonMap = json.decode(stored);
      final storedItem = FavoriteItem.fromJson(jsonMap);
      return storedItem.key == item.key;
    });

    if (!exists) {
      final jsonStr = json.encode(item.toJson());
      current.add(jsonStr);
      await prefs.setStringList(_favoritesKey, current);
    }
  }

  /// Update an existing favorite (e.g. rename)
  Future<void> updateFavorite(FavoriteItem updatedItem) async {
    final prefs = await _prefs;
    final List<String> current = prefs.getStringList(_favoritesKey) ?? [];
    
    final index = current.indexWhere((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      final storedItem = FavoriteItem.fromJson(jsonMap);
      return storedItem.key == updatedItem.key;
    });

    if (index != -1) {
      current[index] = json.encode(updatedItem.toJson());
      await prefs.setStringList(_favoritesKey, current);
    }
  }

  /// Remove a favorite by lineId and stopId
  Future<void> removeFavorite(String lineId, String stopId) async {
    final prefs = await _prefs;
    final List<String> current = prefs.getStringList(_favoritesKey) ?? [];
    final targetKey = '${lineId}_$stopId';
    
    current.removeWhere((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      final storedItem = FavoriteItem.fromJson(jsonMap);
      return storedItem.key == targetKey;
    });
    
    await prefs.setStringList(_favoritesKey, current);
  }

  /// Check if a specific (Line, Stop) pair is a favorite
  Future<bool> isFavorite(String lineId, String stopId) async {
    final prefs = await _prefs;
    final List<String>? data = prefs.getStringList(_favoritesKey);
    if (data == null) return false;
    
    final targetKey = '${lineId}_$stopId';
    
    return data.any((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      final storedItem = FavoriteItem.fromJson(jsonMap);
      return storedItem.key == targetKey;
    });
  }
}
