import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../models/models.dart';

class ApiService {
  static const String _baseUrl = 'https://aucorsa.es/wp-json/aucorsa/v1';
  
  String get _proxyUrl => kIsWeb ? 'https://corsproxy.io/?' : '';

  String? _nonce = "3483e74fbd"; // Start with hardcoded, update dynamically
  DateTime? _nonceTimestamp = DateTime.now();
  static const Duration _nonceMaxAge = Duration(hours: 1);

  void _log(String message) {
    developer.log(message, name: 'ApiService');
    if (kDebugMode) print("[ApiService] $message");
  }

  bool _isNonceExpired() {
    if (_nonceTimestamp == null) return true;
    return DateTime.now().difference(_nonceTimestamp!) > _nonceMaxAge;
  }

  Future<void> _initializeSession({bool force = false}) async {
    // Skip if nonce is valid and not forced
    if (_nonce != null && !force && !_isNonceExpired()) return;

    try {
      final targetUrl = 'https://aucorsa.es/';
      final url = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetUrl)}') 
          : Uri.parse(targetUrl);
      
      _log("Initializing session via: $url");
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final body = response.body;
        final nonceMatch = RegExp(r'"ajax_nonce":"(.*?)"').firstMatch(body);
        if (nonceMatch != null) {
          _nonce = nonceMatch.group(1);
          _nonceTimestamp = DateTime.now();
          _log("Got Nonce: $_nonce");
        }
      }
    } catch (e) {
      _log("Error initializing session: $e");
    }
  }

  // Cache for lines list (session-level)
  List<BusLine>? _cachedLines;
  
  Future<List<BusLine>> fetchLines({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (_cachedLines != null && !forceRefresh) {
      return _cachedLines!;
    }
    
    if (_nonce == null) await _initializeSession();
    if (_nonce == null) return _cachedLines ?? [];

    try {
      final targetUrl = '$_baseUrl/autocompletion/line?term=&_wpnonce=$_nonce';
      final url = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetUrl)}')
          : Uri.parse(targetUrl);

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedLines = data.map((json) => BusLine.fromJson(json)).toList();
        return _cachedLines!;
      }
    } catch (e) {
      _log("Error fetching lines: $e");
    }
    return _cachedLines ?? [];
  }

  Future<List<RouteDirection>> fetchLineStops(String lineId) async {
    await _initializeSession();
    if (_nonce == null) return [];

    try {
      final targetMapUrl = '$_baseUrl/map/nodes?line_id=$lineId&mode=complete&_wpnonce=$_nonce';
      final mapUri = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetMapUrl)}')
          : Uri.parse(targetMapUrl);

      final targetStopsUrl = '$_baseUrl/autocompletion/stop?post_id=$lineId&_wpnonce=$_nonce';
      final stopsUri = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetStopsUrl)}')
          : Uri.parse(targetStopsUrl);

      final results = await Future.wait([
        http.get(mapUri),
        http.get(stopsUri),
      ]);

      final mapResponse = results[0];
      final stopsResponse = results[1];

      final Map<String, String> stopNames = {};
      if (stopsResponse.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(stopsResponse.body);
          for (var item in data) {
            stopNames[item['id'].toString()] = item['label'].toString();
          }
        } catch (e) {
          _log("Error parsing stop names: $e");
        }
      }

      if (mapResponse.statusCode == 200) {
        final List<dynamic> collections = json.decode(mapResponse.body);
        
        List<RouteDirection> dirResults = [];
        for (int i = 0; i < collections.length; i++) {
          final coll = collections[i];
          final features = coll['features'] as List<dynamic>;
          
          List<BusStop> stops = [];
          for (var f in features) {
            if (f['geometry']?['type'] == 'Point') {
              final id = f['id']?.toString() ?? '';
              
              String name = stopNames[id] ?? f['properties']?['name']?.toString() ?? 'Parada $id';
              
              if (id.isNotEmpty) {
                stops.add(BusStop(id: id, label: name));
              }
            }
          }

          String dirLabel = (i == 0) ? 'Ida' : 'Vuelta';
          final routeLabel = coll['routeLabel']?.toString();
          if (routeLabel != null) {
            final labelMatch = RegExp(r'→\s*(.+?)<').firstMatch(routeLabel);
            if (labelMatch != null) {
              dirLabel = 'Hacia ${labelMatch.group(1)!}';
            }
          }

          if (stops.isNotEmpty) {
            dirResults.add(RouteDirection(directionLabel: dirLabel, stops: stops));
          }
        }
        
        if (dirResults.isNotEmpty) return dirResults;
      }
    } catch (e) {
      _log("Map fetch failed for line $lineId: $e");
    }

    try {
      final targetUrl = '$_baseUrl/autocompletion/stop?post_id=$lineId&_wpnonce=$_nonce';
      final stopUri = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetUrl)}')
          : Uri.parse(targetUrl);
          
      final stopResponse = await http.get(stopUri);
      
      if (stopResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(stopResponse.body);
        final stops = data.map((json) => BusStop(
          id: json['id']?.toString() ?? '', 
          label: json['label']?.toString() ?? ''
        )).toList();

        return [RouteDirection(directionLabel: 'Todas las paradas', stops: stops)];
      }
    } catch (e) {
      _log("Fallback fetch failed: $e");
    }
    
    return [];
  }

  Future<Estimation?> fetchEstimation(String stopId, String lineId, String stopName) async {
    try {
      final targetUrl = '$_baseUrl/estimations/stop?line=$lineId&current_line=$lineId&stop_id=$stopId&_wpnonce=$_nonce';
      final uri = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetUrl)}')
          : Uri.parse(targetUrl);
      
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        String body = response.body;

        try {
          if (body.startsWith('"') || body.startsWith("'")) {
             final decoded = json.decode(body);
             if (decoded is String) body = decoded;
          }
        } catch (_) {}
        
        if (body.contains('ppp-no-estimations') || body.contains('Sin estimaci')) {
           return Estimation(stopId: stopId, stopName: stopName, nextBus: 'Sin servicio', followingBus: '-');
        }

        String next = 'Sin servicio';
        String follow = '-';

        // Use dotAll regex here too for consistency
        final nextMatch = RegExp(r'Pr&oacute;ximo autob&uacute;s: <strong[^>]*>([^<]+)<', dotAll: true).firstMatch(body);
        if (nextMatch != null) next = nextMatch.group(1)!.trim();

        final followMatch = RegExp(r'Siguiente autob&uacute;s: <strong[^>]*>([^<]+)<', dotAll: true).firstMatch(body);
        if (followMatch != null) follow = followMatch.group(1)!.trim();
        
        if (next != 'Sin servicio') {
          return Estimation(stopId: stopId, stopName: stopName, nextBus: next, followingBus: follow);
        }
      }
    } catch (_) {
    }
    return null;
  }

  Future<List<Estimation>> fetchAllEstimationsForStop(String stopId) async {
    await _initializeSession();
    if (_nonce == null) return [];

    try {
      final targetUrl = '$_baseUrl/estimations/stop?line=&current_line=&stop_id=$stopId&_wpnonce=$_nonce';
      final uri = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetUrl)}')
          : Uri.parse(targetUrl);

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        String body = response.body;

        try {
          if (body.startsWith('"') || body.startsWith("'")) {
             final decoded = json.decode(body);
             if (decoded is String) body = decoded;
          }
        } catch (e) {
          _log("Body decoding failed: $e");
        }

        if (body.contains('ppp-no-estimations') || body.contains('Sin estimaci')) {
           return [];
        }

        List<Estimation> projections = [];
        
        final lineMatches = RegExp(r'<div class="ppp-line-number"[^>]*>(.*?)</div>', dotAll: true).allMatches(body);
        final routeMatches = RegExp(r'<div class="ppp-line-route"[^>]*>(.*?)</div>', dotAll: true).allMatches(body).toList();
        final nextMatches = RegExp(r'Pr&oacute;ximo autob&uacute;s: <strong[^>]*>([^<]+)<', dotAll: true).allMatches(body).toList();
        final followMatches = RegExp(r'Siguiente autob&uacute;s: <strong[^>]*>([^<]+)<', dotAll: true).allMatches(body).toList();

        // Extract Stop Name from Header if available
        String stopName = "Parada $stopId";
        final stopNameMatch = RegExp(r'class="ppp-stop-label">([^<]+)<', dotAll: true).firstMatch(body);
        if (stopNameMatch != null) {
          stopName = stopNameMatch.group(1)!.trim();
          // Remove "Parada XXX: " prefix for cleaner UI?
          // Usually valid name is "Parada 210: Pintor..."
          // Let's keep it as is but fixed case.
        }

        int index = 0;
        for (var match in lineMatches) {
           String lineId = match.group(1)?.trim() ?? "?";
           String lineName = (index < routeMatches.length) ? (routeMatches[index].group(1)?.trim() ?? "") : "";
           String nextBus = (index < nextMatches.length) ? (nextMatches[index].group(1)?.trim() ?? "Sin servicio") : "Sin servicio";
           String followBus = (index < followMatches.length) ? (followMatches[index].group(1)?.trim() ?? "-") : "-";
           
           projections.add(Estimation(
              stopId: stopId, 
              stopName: stopName, 
              nextBus: nextBus, 
              followingBus: followBus,
              lineId: lineId,
              lineName: lineName
           ));
           index++;
        }
        
        return projections; 
      }
    } catch (e) {
      _log("Error fetching stop estimations: $e");
    }
    return [];
  }

  Future<List<BusStop>> searchStops(String query) async {
    await _initializeSession();
    if (_nonce == null) return [];

    try {
      // 1. Always search via API first to get proper names, even for numbers
      // URL-encode query for safety
      final encodedQuery = Uri.encodeComponent(query);
      final targetUrl = '$_baseUrl/autocompletion/stop?term=$encodedQuery&_wpnonce=$_nonce';
      final uri = kIsWeb 
          ? Uri.parse('$_proxyUrl${Uri.encodeComponent(targetUrl)}')
          : Uri.parse(targetUrl);

      final response = await http.get(uri);
      List<BusStop> results = [];

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        results = data.map((json) => BusStop(
          id: json['id']?.toString() ?? '', 
          label: json['label']?.toString() ?? ''
        )).toList();
      }

      // 2. If query is numeric and NOT in results, append generic option as fallback.
      // E.g. Stop 9 might exist but not return in autocomplete? (Unlikely, but possible).
      // Or if Autocomplete fails.
      if (int.tryParse(query) != null) {
        // Check if we already have this ID in results
        bool exists = results.any((stop) => stop.id == query);
        if (!exists) {
           // Append generic option at the end
           results.insert(0, BusStop(id: query, label: "Parada $query (Buscar por ID)"));
        }
      }
      
      return results;

    } catch (e) {
      _log("Search failed: $e");
      // Fallback for numeric
      if (int.tryParse(query) != null) {
        return [BusStop(id: query, label: "Parada $query")];
      }
    }
    return [];
  }
}
