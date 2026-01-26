import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/line_color_service.dart';
import 'stop_detail_screen.dart';

class LineDetailScreen extends StatefulWidget {
  final BusLine line;

  const LineDetailScreen({super.key, required this.line});

  @override
  State<LineDetailScreen> createState() => _LineDetailScreenState();
}

class _LineDetailScreenState extends State<LineDetailScreen> {
  List<RouteDirection> _directions = [];
  bool _loading = true;
  int _selectedDirIndex = 0;
  
  // Cache estimations per direction index to avoid refetching
  Map<int, Map<String, Estimation?>> _estimationsByDirection = {};
  
  Map<String, Estimation?> get _estimations => 
      _estimationsByDirection[_selectedDirIndex] ?? {};
  
  final FavoritesService _favService = FavoritesService();
  Set<String> _favoriteIds = {};

  bool _canRefresh = true;
  Timer? _cooldownTimer;
  Timer? _autoRefreshTimer;
  int _secondsRemaining = 0;
  DateTime? _lastRefreshTime;
  static const int _cooldownSeconds = 30;
  static const int _autoRefreshSeconds = 60;

  @override
  void initState() {
    super.initState();
    _loadStops();
    _loadFavorites();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
  
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: _autoRefreshSeconds), 
      (_) => _refreshAllEstimations()
    );
  }
  
  /// Force refresh all directions (clears cache)
  Future<void> _refreshAllEstimations() async {
    if (!_canRefresh) return;
    
    // Clear cache
    _estimationsByDirection.clear();
    
    // Start cooldown
    _startCooldown();
    
    // Record refresh time
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
    
    // Reload all
    if (_directions.isNotEmpty) {
      final api = Provider.of<ApiService>(context, listen: false);
      await _preloadAllDirections(api, _directions);
    }
  }

  Future<void> _loadFavorites() async {
    final favs = await _favService.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteIds = favs.map((f) => f.id).toSet();
      });
    }
  }

  Future<void> _toggleFavorite(BusStop stop) async {
    if (_favoriteIds.contains(stop.id)) {
      await _favService.removeFavorite(stop.id);
      setState(() {
        _favoriteIds.remove(stop.id);
      });
    } else {
      await _favService.addFavorite(stop);
      setState(() {
        _favoriteIds.add(stop.id);
      });
    }
  }

  Future<void> _loadStops() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final dirs = await api.fetchLineStops(widget.line.id);
    
    if (mounted) {
      setState(() {
        _directions = dirs;
        _loading = false;
      });
      
      // PERFORMANCE: Preload estimations for ALL directions in parallel
      if (dirs.isNotEmpty) {
        _preloadAllDirections(api, dirs);
      }
    }
  }
  
  /// Fetches estimations for all directions in parallel for instant tab switching
  Future<void> _preloadAllDirections(ApiService api, List<RouteDirection> dirs) async {
    // Create futures for all directions
    final futures = <Future<void>>[];
    
    for (int dirIndex = 0; dirIndex < dirs.length; dirIndex++) {
      futures.add(_fetchEstimationsForDirection(api, dirIndex, dirs[dirIndex].stops));
    }
    
    // Fetch all in parallel
    await Future.wait(futures);
  }
  
  /// Fetches estimations for a specific direction
  Future<void> _fetchEstimationsForDirection(ApiService api, int dirIndex, List<BusStop> stops) async {
    // Skip if already cached
    if (_estimationsByDirection.containsKey(dirIndex) && 
        _estimationsByDirection[dirIndex]!.isNotEmpty) {
      return;
    }
    
    final List<Future<Estimation?>> futures = stops.map((stop) => 
        api.fetchEstimation(stop.id, widget.line.id, stop.label)).toList();

    final results = await Future.wait(futures);
    
    if (mounted) {
      final newEstimations = <String, Estimation?>{};
      for (var est in results) {
        if (est != null) {
          newEstimations[est.stopId] = est;
        }
      }
      setState(() {
        _estimationsByDirection[dirIndex] = newEstimations;
      });
    }
  }
  
  Future<void> _fetchEstimationsForCurrentDirection({bool forceRefresh = false}) async {
    // Check if we already have estimations for this direction
    final hasCachedData = _estimationsByDirection.containsKey(_selectedDirIndex) && 
        _estimationsByDirection[_selectedDirIndex]!.isNotEmpty;
    
    // For automatic fetches (direction switch), use cache if available
    if (hasCachedData && !forceRefresh) {
      return;
    }
    
    // For manual refresh, check cooldown
    if (!_canRefresh) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Espera $_secondsRemaining segundos para actualizar."))
      );
      return;
    }

    // Start cooldown for new network request
    _startCooldown();

    if (_directions.isEmpty) return;
    
    final stops = _directions[_selectedDirIndex].stops;
    final api = Provider.of<ApiService>(context, listen: false);
    
    final List<Future<Estimation?>> futures = stops.map((stop) => 
        api.fetchEstimation(stop.id, widget.line.id, stop.label)).toList();

    final results = await Future.wait(futures);
    
    if (mounted) {
      final newEstimations = <String, Estimation?>{};
      for (var est in results) {
        if (est != null) {
          newEstimations[est.stopId] = est;
        }
      }
      setState(() {
        _estimationsByDirection[_selectedDirIndex] = newEstimations;
      });
    }
  }

  void _startCooldown() {
    // Cancel any existing timer first to prevent leaks
    _cooldownTimer?.cancel();
    
    setState(() {
      _canRefresh = false;
      _secondsRemaining = _cooldownSeconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() {
          _canRefresh = true;
        });
      }
    });
  }

  String _getLastRefreshText() {
    if (_lastRefreshTime == null) return '';
    final diff = DateTime.now().difference(_lastRefreshTime!);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}min';
    return 'hace ${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Línea ${widget.line.label}"),
        elevation: 0,
        centerTitle: true,
        actions: [
            if (_lastRefreshTime != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Text(
                    _getLastRefreshText(),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _canRefresh 
                ? IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshAllEstimations,
                  )
                : Center(child: Text("$_secondsRemaining", style: const TextStyle(fontWeight: FontWeight.bold))),
            )
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _directions.isEmpty 
          ? const Center(child: Text("No se encontraron paradas."))
          : Column(
              children: [
                if (_directions.length > 1) 
                  Container(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _directions.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedDirIndex == index;
                        final dir = _directions[index];
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ChoiceChip(
                            label: Text(dir.directionLabel),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedDirIndex = index;
                                });
                                // Always call - the function handles caching and cooldown internally
                                _fetchEstimationsForCurrentDirection();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshAllEstimations,
                    child: ListView.builder(
                      itemCount: _directions[_selectedDirIndex].stops.length,
                      itemBuilder: (context, index) {
                      final stop = _directions[_selectedDirIndex].stops[index];
                      final est = _estimations[stop.id];
                      final isFav = _favoriteIds.contains(stop.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => StopDetailScreen(stop: stop)),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: LineColorService.getColor(widget.line.label.split('ㅤ')[0].trim()),
                            foregroundColor: Colors.white,
                            child: Text(stop.id, style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                          title: Text(stop.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: est == null 
                            ? const Text("...", style: TextStyle(color: Colors.grey))
                            : Row(
                                children: [
                                  Text(
                                    est.nextBus, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: est.nextBus == "Sin servicio" ? Colors.red : 
                                             (est.nextBus.contains("min") || est.nextBus == "ahora") ? Colors.green[700] : Colors.black,
                                    )
                                  ),
                                  if (est.followingBus != '-') 
                                     Text("  /  ${est.followingBus}", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                          trailing: IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                            color: isFav ? Colors.red : Colors.grey,
                            onPressed: () => _toggleFavorite(stop),
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
