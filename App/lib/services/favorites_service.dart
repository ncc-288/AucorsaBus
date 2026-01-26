import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_stops';
  
  // Cached SharedPreferences instance
  static SharedPreferences? _prefsInstance;
  
  Future<SharedPreferences> get _prefs async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }
  
  // Store favorites as a List of JSON Maps
  Future<List<BusStop>> getFavorites() async {
    final prefs = await _prefs;
    final List<String>? data = prefs.getStringList(_favoritesKey);
    
    if (data == null) return [];
    
    return data.map((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      return BusStop(
        id: jsonMap['id'].toString(), 
        label: jsonMap['label'].toString()
      );
    }).toList();
  }

  Future<void> addFavorite(BusStop stop) async {
    final prefs = await _prefs;
    final List<String> current = prefs.getStringList(_favoritesKey) ?? [];
    
    // Check duplication
    bool exists = current.any((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      return jsonMap['id'].toString() == stop.id;
    });

    if (!exists) {
      final jsonStr = json.encode({'id': stop.id, 'label': stop.label});
      current.add(jsonStr);
      await prefs.setStringList(_favoritesKey, current);
    }
  }

  Future<void> removeFavorite(String stopId) async {
    final prefs = await _prefs;
    final List<String> current = prefs.getStringList(_favoritesKey) ?? [];
    
    current.removeWhere((item) {
      final Map<String, dynamic> jsonMap = json.decode(item);
      return jsonMap['id'].toString() == stopId;
    });
    
    await prefs.setStringList(_favoritesKey, current);
  }

  Future<bool> isFavorite(String stopId) async {
     final prefs = await _prefs;
     final List<String>? data = prefs.getStringList(_favoritesKey);
     if (data == null) return false;
     
     return data.any((item) {
       final Map<String, dynamic> jsonMap = json.decode(item);
       return jsonMap['id'].toString() == stopId;
     });
  }
}
