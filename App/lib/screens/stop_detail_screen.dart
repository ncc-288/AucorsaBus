import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/line_color_service.dart';

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
    _stopName = widget.stop.label;
    _checkFavorite();
    _loadEstimations();
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
      (_) => _refreshEstimations()
    );
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

  /// Force refresh estimations with cooldown
  Future<void> _refreshEstimations() async {
    if (!mounted) return;
    
    if (!_canRefresh) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Espera $_secondsRemaining segundos para actualizar."))
      );
      return;
    }

    _startCooldown();
    
    setState(() {
      _loading = true;
      _lastRefreshTime = DateTime.now();
    });

    final api = Provider.of<ApiService>(context, listen: false);
    final ests = await api.fetchAllEstimationsForStop(widget.stop.id);
    
    if (mounted) {
      setState(() {
        _estimations = ests;
        _loading = false;
        if (ests.isNotEmpty && ests.first.stopName.isNotEmpty && ests.first.stopName != "Parada ${widget.stop.id}") {
            _stopName = ests.first.stopName;
        }
      });
    }
  }

  /// Initial load (no cooldown)
  Future<void> _loadEstimations() async {
    if (!mounted) return;

    setState(() => _loading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    final ests = await api.fetchAllEstimationsForStop(widget.stop.id);
    
    if (mounted) {
      setState(() {
        _estimations = ests;
        _loading = false;
        _lastRefreshTime = DateTime.now();
        if (ests.isNotEmpty && ests.first.stopName.isNotEmpty && ests.first.stopName != "Parada ${widget.stop.id}") {
            _stopName = ests.first.stopName;
        }
      });
    }
  }

  void _startCooldown() {
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
        title: Text(_stopName),
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
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : Theme.of(context).colorScheme.primary,
            onPressed: _toggleFavorite,
          ),
          _canRefresh 
            ? IconButton(
                icon: const Icon(Icons.refresh),
                color: Theme.of(context).colorScheme.primary,
                onPressed: _refreshEstimations,
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text("$_secondsRemaining", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
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
                  "Parada código: ${widget.stop.id}",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _estimations.isEmpty
                ? const Center(child: Text("No hay estimaciones o servicios disponibles."))
                : RefreshIndicator(
                    onRefresh: _refreshEstimations,
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
                            title: Text(est.lineName ?? "Línea"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Próximo: ${est.nextBus}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("Siguiente: ${est.followingBus}"),
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
  
  Color _getLineColor(String? lineId) {
     return LineColorService.getColor(lineId);
  }
}
