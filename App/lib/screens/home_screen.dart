// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/theme_service.dart';
import '../main.dart';
import 'stop_detail_screen.dart';
import 'search_delegate.dart';
import '../services/update_service.dart';
import '../widgets/lines_list.dart';
import '../widgets/favorites_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation Index: 0 = Lines, 1 = Favorites, 2 = Status
  int _selectedIndex = 0;
  
  List<BusLine> _lines = [];
  List<FavoriteItem> _favorites = [];
  Map<String, Estimation?> _favEstimations = {};
  List<ServiceAlert> _serviceAlerts = [];
  bool _loading = true;
  String? _errorMessage;
  final FavoritesService _favService = FavoritesService();
  
  // Auto-refresh timer for favorites
  Timer? _autoRefreshTimer;
  static const int _autoRefreshSeconds = 30;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _loadLines();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdate();
    
    if (updateInfo.updateAvailable && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.newVersionAvailable ?? "New version available"}: ${updateInfo.latestVersion}'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: l10n?.download ?? 'Download',
            onPressed: () async {
              if (updateInfo.releaseUrl != null) {
                final uri = Uri.parse(updateInfo.releaseUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: _autoRefreshSeconds),
      (_) => _refreshFavoriteEstimations(),
    );
  }

  Future<void> _loadLines() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final lines = await api.fetchLines();
      if (mounted) {
        setState(() {
          _lines = lines;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Error: $e");
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    final favs = await _favService.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favs;
        _loading = false;
      });
      // Load estimations for all favorites
      _refreshFavoriteEstimations();
      _startAutoRefresh();
    }
  }

  Future<void> _refreshFavoriteEstimations() async {
    if (_favorites.isEmpty) return;
    
    final api = Provider.of<ApiService>(context, listen: false);
    final Map<String, Estimation?> newEstimations = {};
    
    // Fetch estimations in parallel
    final futures = _favorites.map((fav) async {
      final est = await api.fetchEstimation(fav.stopId, fav.lineId, fav.stopLabel);
      return MapEntry(fav.key, est);
    });
    
    final results = await Future.wait(futures);
    for (var entry in results) {
      newEstimations[entry.key] = entry.value;
    }
    
    if (mounted) {
      setState(() {
        _favEstimations = newEstimations;
        _lastUpdateTime = DateTime.now();
      });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    _autoRefreshTimer?.cancel();
    setState(() {
      _selectedIndex = index;
      _loading = true;
    });
    if (index == 0) {
      _loadLines();
    } else if (index == 1) {
      _loadFavorites();
    } else {
      _loadServiceAlerts();
    }
  }

  Future<void> _loadServiceAlerts() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final alerts = await api.fetchServiceAlerts();
      if (mounted) {
        setState(() {
          _serviceAlerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error: $e";
          _loading = false;
        });
      }
    }
  }

  Future<void> _openSearch() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final result = await showSearch(
      context: context,
      delegate: StopSearchDelegate(api),
    );

    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StopDetailScreen(stop: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = ['Aucorsa - ${l10n.lines}', l10n.favorites, l10n.serviceStatus];
    final title = titles[_selectedIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: l10n.search,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
             DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light 
                    ? Colors.white 
                    : const Color(0xFF1E1E1E),
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Image.asset(
                     'assets/images/logo.png',
                     height: 60,
                   ),
                   const SizedBox(height: 10),
                   Text(
                     l10n.appTitle, 
                     style: const TextStyle(
                       color: Color(0xFF00A99D), 
                       fontSize: 22, 
                       fontWeight: FontWeight.bold
                     )
                   ),
                ],
              ),
            ),
            // Settings Section
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return ListTile(
                  leading: Icon(themeService.themeModeIcon),
                  title: Text(l10n.settings),
                  subtitle: Text(themeService.themeModeLabel),
                  onTap: () {
                    themeService.toggleTheme();
                  },
                );
              },
            ),
            const Divider(),
            // Language selector
            Consumer<LocaleService>(
              builder: (context, localeService, child) {
                final currentLang = localeService.locale.languageCode;
                return ExpansionTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  children: [
                    RadioListTile<String>(
                      value: 'es',
                      groupValue: currentLang,
                      title: Text(l10n.spanish),
                      onChanged: (value) {
                        if (value != null) {
                          localeService.setLocale(Locale(value));
                        }
                      },
                    ),
                    RadioListTile<String>(
                      value: 'en',
                      groupValue: currentLang,
                      title: Text(l10n.english),
                      onChanged: (value) {
                        if (value != null) {
                          localeService.setLocale(Locale(value));
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const Divider(),
            // GitHub Repository Link
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              subtitle: const Text('ncc-288/AucorsaBus'),
              onTap: () async {
                final uri = Uri.parse('https://github.com/ncc-288/AucorsaBus');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : _selectedIndex == 0 
           ? LinesList(lines: _lines, errorMessage: _errorMessage)
           : _selectedIndex == 1
              ? FavoritesDashboard(
                  favorites: _favorites,
                  estimations: _favEstimations,
                  lastUpdateTime: _lastUpdateTime,
                  onRefresh: _refreshFavoriteEstimations,
                  onRemove: (lineId, stopId) async {
                    await _favService.removeFavorite(lineId, stopId);
                    _loadFavorites();
                  },
                )
              : _buildStatusTab(l10n),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_bus),
            label: l10n.lines,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: l10n.favorites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            label: l10n.serviceStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(AppLocalizations l10n) {
    if (_serviceAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(l10n.noServiceAlerts),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final api = Provider.of<ApiService>(context, listen: false);
        final alerts = await api.fetchServiceAlerts(forceRefresh: true);
        if (mounted) {
          setState(() => _serviceAlerts = alerts);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: _serviceAlerts.length,
        itemBuilder: (context, index) {
          final alert = _serviceAlerts[index];
          final formattedDate = DateFormat('dd MMM yyyy', l10n.localeName).format(alert.date);
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                alert.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedAlignment: Alignment.topLeft,
              children: [
                if (alert.content.isNotEmpty)
                  Text(
                    alert.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  )
                else
                  Text(
                    l10n.noServiceAlerts,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
