import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/line_color_service.dart';
import '../services/name_override_service.dart';
import '../widgets/premium_arrows.dart';
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
  
  // Cache estimations per direction index
  final Map<int, Map<String, Estimation?>> _estimationsByDirection = {};
  final Map<int, DateTime?> _lastUpdateTimeByDirection = {};
  
  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  static const int _autoRefreshSeconds = 30;
  
  // Name override service
  final NameOverrideService _nameService = NameOverrideService();
  
  Map<String, Estimation?> get _estimations => 
      _estimationsByDirection[_selectedDirIndex] ?? {};
  
  DateTime? get _lastUpdateTime => _lastUpdateTimeByDirection[_selectedDirIndex];
  
  final FavoritesService _favService = FavoritesService();
  Set<String> _favoriteIds = {};

  String _getCacheKey(int dirIndex) => 'line_${widget.line.id}_dir_$dirIndex';

  @override
  void initState() {
    super.initState();
    _loadStops();
    _loadFavorites();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: _autoRefreshSeconds),
      (_) => _forceRefreshCurrentDirection(),
    );
  }

  /// Force refresh bypassing cache
  Future<void> _forceRefreshCurrentDirection() async {
    if (_directions.isEmpty || _selectedDirIndex >= _directions.length) return;
    
    final api = Provider.of<ApiService>(context, listen: false);
    final stops = _directions[_selectedDirIndex].stops;
    
    // Use force refresh which bypasses cache check but updates cache
    final estimations = await api.forceRefreshLineEstimations(widget.line.id, _selectedDirIndex, stops);
    
    if (mounted) {
      setState(() {
        _estimationsByDirection[_selectedDirIndex] = estimations;
        _lastUpdateTimeByDirection[_selectedDirIndex] = api.getLastUpdateTime(_getCacheKey(_selectedDirIndex));
      });
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
      
      // Preload estimations for the first direction using smart caching
      if (dirs.isNotEmpty) {
        _loadEstimationsForDirection(0);
      }
    }
  }
  
  Future<void> _loadEstimationsForDirection(int dirIndex) async {
    if (_directions.isEmpty || dirIndex >= _directions.length) return;
    
    final api = Provider.of<ApiService>(context, listen: false);
    final stops = _directions[dirIndex].stops;
    
    // Use the smart caching method with direction index
    final estimations = await api.getLineEstimations(widget.line.id, dirIndex, stops);
    
    if (mounted) {
      setState(() {
        _estimationsByDirection[dirIndex] = estimations;
        _lastUpdateTimeByDirection[dirIndex] = api.getLastUpdateTime(_getCacheKey(dirIndex));
      });
    }
  }

  String _formatLastUpdate(AppLocalizations l10n) {
    final updateTime = _lastUpdateTime;
    if (updateTime == null) return '';
    final h = updateTime.hour.toString().padLeft(2, '0');
    final m = updateTime.minute.toString().padLeft(2, '0');
    final s = updateTime.second.toString().padLeft(2, '0');
    return '${l10n.lastUpdate}: $h:$m:$s';
  }

  // Removed _getDirectionIcon - now using DirectionChip widget

  /// Fix line name encoding using local override
  String _fixLineName(String name) {
    return _nameService.getLineName(name, name);
  }

  /// Fix stop name using local override
  String _fixStopName(String stopId, String fallback) {
    return _nameService.getStopName(stopId, fallback);
  }

  /// Get localized direction label
  String _getDirectionLabel(AppLocalizations l10n, int index) {
    if (index == 0) return l10n.ida;
    return l10n.vuelta;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lineColor = LineColorService.getColor(widget.line.label.split('ㅤ')[0].trim());
    
    // Fix the line title for encoding issues
    final lineTitle = _fixLineName(widget.line.label);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("${l10n.line} $lineTitle"),
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _directions.isEmpty 
          ? Center(child: Text(l10n.noStopsFound))
          : Column(
              children: [
                // Direction Selector with Visual Indicators
                if (_directions.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light 
                          ? const Color(0xFFF5F5F5) 
                          : const Color(0xFF2A2A2A),
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Row(
                      children: List.generate(_directions.length, (index) {
                        final isSelected = _selectedDirIndex == index;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: DirectionChip(
                              isSelected: isSelected,
                              isOutbound: index == 0,
                              label: _getDirectionLabel(l10n, index),
                              activeColor: lineColor,
                              onTap: () {
                                if (!isSelected) {
                                  setState(() => _selectedDirIndex = index);
                                  _loadEstimationsForDirection(index);
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                // Last update time banner
                if (_lastUpdateTime != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Theme.of(context).brightness == Brightness.light 
                        ? const Color(0xFFE8F5E9) 
                        : const Color(0xFF1B5E20),
                    child: Center(
                      child: Text(
                        _formatLastUpdate(l10n),
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF2E7D32)
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _forceRefreshCurrentDirection,
                    child: ListView.builder(
                      itemCount: _directions[_selectedDirIndex].stops.length,
                      itemBuilder: (context, index) {
                        final stops = _directions[_selectedDirIndex].stops;
                        final stop = stops[index];
                        final est = _estimations[stop.id];
                        final isFav = _favoriteIds.contains(stop.id);
                        final isLast = index == stops.length - 1;

                        // Apply name override if available
                        final displayStopName = _fixStopName(stop.id, stop.label);

                        return Column(
                          children: [
                            Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => StopDetailScreen(stop: stop)),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: lineColor,
                                  foregroundColor: Colors.white,
                                  child: Text(stop.id, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                ),
                                title: Text(displayStopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: est == null 
                                  ? const Text("...", style: TextStyle(color: Colors.grey))
                                  : Row(
                                      children: [
                                        Text(
                                          est.nextBus, 
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            color: est.nextBus == l10n.noService ? Colors.red : 
                                                   (est.nextBus.contains("min") || est.nextBus == "ahora" || est.nextBus == "now") ? Colors.green[700] : Colors.black,
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
                            ),
                            // Premium vertical connector (except for last stop)
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: VerticalStopConnector(color: lineColor),
                              ),
                          ],
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
