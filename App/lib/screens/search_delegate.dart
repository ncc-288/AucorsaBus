import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class StopSearchDelegate extends SearchDelegate<BusStop?> {
  final ApiService apiService;
  
  // Debounce timer for search
  Timer? _debounceTimer;
  
  // Cached results to avoid redundant API calls
  String _lastQuery = '';
  List<BusStop> _cachedResults = [];

  StopSearchDelegate(this.apiService);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _cachedResults = [];
            _lastQuery = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        iconTheme: theme.iconTheme.copyWith(color: theme.colorScheme.primary),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
      onPressed: () {
        _debounceTimer?.cancel();
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // If user submits, directly go there
    if (query.isNotEmpty) {
       final stop = BusStop(id: query, label: "Parada $query");
       
       WidgetsBinding.instance.addPostFrameCallback((_) {
         close(context, stop);
       });
       return const Center(child: CircularProgressIndicator());
    }
    return const Center(child: Text("Introduce un ID o nombre"));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text("Escribe al menos 2 caracteres..."));
    }

    // Return cached results immediately if query matches
    if (query == _lastQuery && _cachedResults.isNotEmpty) {
      return _buildResultsList(_cachedResults);
    }

    // Use a stateful builder with debouncing
    return _DebouncedSearchResults(
      query: query,
      apiService: apiService,
      onResultsCached: (results, forQuery) {
        _cachedResults = results;
        _lastQuery = forQuery;
      },
    );
  }
  
  Widget _buildResultsList(List<BusStop> stops) {
    return ListView.builder(
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        return ListTile(
          leading: const Icon(Icons.place),
          title: Text(stop.label),
          subtitle: Text("ID: ${stop.id}"),
          onTap: () {
            close(context, stop);
          },
        );
      },
    );
  }
}

/// Stateful widget that handles debounced search with proper state management
class _DebouncedSearchResults extends StatefulWidget {
  final String query;
  final ApiService apiService;
  final void Function(List<BusStop>, String) onResultsCached;

  const _DebouncedSearchResults({
    required this.query,
    required this.apiService,
    required this.onResultsCached,
  });

  @override
  State<_DebouncedSearchResults> createState() => _DebouncedSearchResultsState();
}

class _DebouncedSearchResultsState extends State<_DebouncedSearchResults> {
  Timer? _debounceTimer;
  List<BusStop>? _results;
  bool _loading = true;
  String _searchedQuery = '';

  @override
  void initState() {
    super.initState();
    _startSearch();
  }

  @override
  void didUpdateWidget(_DebouncedSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _startSearch();
    }
  }

  void _startSearch() {
    setState(() => _loading = true);
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Debounce: wait 300ms before making API call
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      
      final results = await widget.apiService.searchStops(widget.query);
      
      if (mounted && widget.query == _searchedQuery || _searchedQuery.isEmpty) {
        _searchedQuery = widget.query;
        setState(() {
          _results = results;
          _loading = false;
        });
        widget.onResultsCached(results, widget.query);
      }
    });
    _searchedQuery = widget.query;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LinearProgressIndicator();
    }
    
    if (_results == null || _results!.isEmpty) {
      return const Center(child: Text("No se encontraron paradas"));
    }

    return ListView.builder(
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final stop = _results![index];
        return ListTile(
          leading: const Icon(Icons.place),
          title: Text(stop.label),
          subtitle: Text("ID: ${stop.id}"),
          onTap: () {
            Navigator.of(context).pop(stop);
          },
        );
      },
    );
  }
}
