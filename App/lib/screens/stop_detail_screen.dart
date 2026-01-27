import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/line_color_service.dart';
import '../services/name_override_service.dart';

class StopDetailScreen extends StatefulWidget {
  final BusStop stop;

  const StopDetailScreen({super.key, required this.stop});

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  String _stopName = "";
  List<Estimation> _estimations = [];
  bool _loading = true;
  bool _isFavorite = false;
  final FavoritesService _favService = FavoritesService();
  final NameOverrideService _nameService = NameOverrideService();
  DateTime? _lastUpdateTime;

  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  static const int _autoRefreshSeconds = 30;

  String get _cacheKey => 'stop_${widget.stop.id}';

  @override
  void initState() {
    super.initState();
    // Use name override if available
    _stopName = _nameService.getStopName(widget.stop.id, widget.stop.label);
    _checkFavorite();
    _loadEstimations();
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
      (_) {
        print("[StopDetailScreen] Auto-refresh timer fired at ${DateTime.now()}");
        _forceRefresh();
      },
    );
  }

  /// Force refresh bypassing cache
  Future<void> _forceRefresh() async {
    if (!mounted) return;
    
    final api = Provider.of<ApiService>(context, listen: false);
    // Use force refresh which bypasses cache check but updates cache
    final ests = await api.forceRefreshStopEstimations(widget.stop.id);
    
    if (mounted) {
      setState(() {
        _estimations = ests;
        _lastUpdateTime = api.getLastUpdateTime(_cacheKey);
        if (ests.isNotEmpty && ests.first.stopName.isNotEmpty && ests.first.stopName != "Parada ${widget.stop.id}") {
          // Apply local override if available
          _stopName = _nameService.getStopName(widget.stop.id, ests.first.stopName);
        }
      });
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favService.isFavorite(widget.stop.id);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _favService.removeFavorite(widget.stop.id);
    } else {
      await _favService.addFavorite(BusStop(id: widget.stop.id, label: _stopName));
    }
    _checkFavorite();
  }

  Future<void> _loadEstimations() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    final ests = await api.getStopEstimations(widget.stop.id);
    
    if (mounted) {
      setState(() {
        _estimations = ests;
        _loading = false;
        _lastUpdateTime = api.getLastUpdateTime(_cacheKey);
        if (ests.isNotEmpty && ests.first.stopName.isNotEmpty && ests.first.stopName != "Parada ${widget.stop.id}") {
            // Apply local override if available
            _stopName = _nameService.getStopName(widget.stop.id, ests.first.stopName);
        }
      });
    }
  }

  String _formatLastUpdate(AppLocalizations l10n) {
    if (_lastUpdateTime == null) return '';
    final h = _lastUpdateTime!.hour.toString().padLeft(2, '0');
    final m = _lastUpdateTime!.minute.toString().padLeft(2, '0');
    final s = _lastUpdateTime!.second.toString().padLeft(2, '0');
    return '${l10n.lastUpdate}: $h:$m:$s';
  }

  /// Fix line name encoding using local override
  String _fixLineName(String? lineName) {
    if (lineName == null) return "";
    return _nameService.getLineName(lineName, lineName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_stopName),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : Theme.of(context).colorScheme.primary,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).brightness == Brightness.light 
                ? const Color(0xFFF9F9F9) 
                : const Color(0xFF1E1E1E),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stopName, 
                  style: const TextStyle(
                    color: Color(0xFF2D2D2D), 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.stopCode}: ${widget.stop.id}",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                ),
                if (_lastUpdateTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatLastUpdate(l10n),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ]
              ],
            ),
          ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _estimations.isEmpty
                ? Center(child: Text(l10n.noEstimations))
                : RefreshIndicator(
                    onRefresh: _forceRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _estimations.length,
                      itemBuilder: (context, index) {
                        final est = _estimations[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                               backgroundColor: LineColorService.getColor(est.lineId),
                               foregroundColor: Colors.white,
                               child: Text(est.lineId ?? "?", style: const TextStyle(fontWeight: FontWeight.bold)), 
                            ),
                            title: Text(_fixLineName(est.lineName)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${l10n.nextBus}: ${est.nextBus}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("${l10n.followingBus}: ${est.followingBus}"),
                              ],
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
