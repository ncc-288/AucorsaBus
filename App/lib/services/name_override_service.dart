import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Service that provides local name overrides for stops and lines
/// to fix encoding issues from the API.
class NameOverrideService {
  static final NameOverrideService _instance = NameOverrideService._internal();
  factory NameOverrideService() => _instance;
  NameOverrideService._internal();

  Map<String, String> _stopNames = {};
  Map<String, String> _lineNames = {};
  bool _initialized = false;

  /// Initialize the service by loading JSON files from assets.
  /// Call this once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Load stops.json
      final stopsJson = await rootBundle.loadString('assets/data/stops.json');
      _stopNames = Map<String, String>.from(json.decode(stopsJson));
      
      // Load lines.json
      final linesJson = await rootBundle.loadString('assets/data/lines.json');
      _lineNames = Map<String, String>.from(json.decode(linesJson));
      
      _initialized = true;
    } catch (e) {
      // If files don't exist or fail to load, continue with empty maps
      _initialized = true;
    }
  }

  /// Get the corrected stop name for a given stop ID.
  /// Returns [fallback] if no override exists.
  String getStopName(String stopId, String fallback) {
    return _stopNames[stopId] ?? fallback;
  }

  /// Get the corrected line/route name.
  /// Returns [fallback] if no override exists.
  String getLineName(String lineName, String fallback) {
    return _lineNames[lineName] ?? _lineNames[fallback] ?? fallback;
  }

  /// Check if the service is initialized
  bool get isInitialized => _initialized;
}
