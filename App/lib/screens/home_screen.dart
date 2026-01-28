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
import '../services/alert_read_service.dart';
import '../main.dart';
import 'stop_detail_screen.dart';
import 'search_delegate.dart';
import '../services/update_service.dart';
import '../widgets/lines_list.dart';
import '../widgets/favorites_dashboard.dart';
import '../widgets/floating_search_bar.dart';

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
  final AlertReadService _alertReadService = AlertReadService();
  
  // Unread alerts count for badge
  int _unreadAlertCount = 0;
  Set<int> _readAlertIds = {};
  
  // Auto-refresh timer for favorites
  Timer? _autoRefreshTimer;
  static const int _autoRefreshSeconds = 30;
  DateTime? _lastUpdateTime;

  // Periodic alert refresh timer (60 minutes)
  Timer? _alertRefreshTimer;
  static const int _alertRefreshMinutes = 60;

  // GlobalKey for Scaffold to control drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadLines();
    _loadServiceAlerts(); // Load alerts immediately to show badge
    _startAlertRefreshTimer(); // Start periodic alert refresh
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
    _alertRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAlertRefreshTimer() {
    _alertRefreshTimer = Timer.periodic(
      Duration(minutes: _alertRefreshMinutes),
      (_) => _loadServiceAlerts(),
    );
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
    // Only set loading state if we're on the Status tab
    final isStatusTab = _selectedIndex == 2;
    if (isStatusTab) {
      setState(() => _loading = true);
    }
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final alerts = await api.fetchServiceAlerts();
      if (mounted) {
        // Calculate unread count
        final unreadCount = await _alertReadService.getUnreadCount(alerts);
        final readIds = await _alertReadService.getReadAlertIds();
        setState(() {
          _serviceAlerts = alerts;
          _unreadAlertCount = unreadCount;
          _readAlertIds = readIds;
          if (isStatusTab) {
            _loading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error: $e";
          if (isStatusTab) {
            _loading = false;
          }
        });
      }
    }
  }

  Future<void> _updateUnreadCount() async {
    final unreadCount = await _alertReadService.getUnreadCount(_serviceAlerts);
    if (mounted) {
      setState(() => _unreadAlertCount = unreadCount);
    }
  }

  Future<void> _markAlertAsRead(int alertId) async {
    await _alertReadService.markAsRead(alertId);
    setState(() {
      _readAlertIds.add(alertId);
    });
    await _updateUnreadCount();
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
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(l10n),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Search Bar (Gmail-style)
            FloatingSearchBar(
              onTap: _openSearch,
              onLeadingTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            // Main Content
            Expanded(
              child: _loading 
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
                          onUpdate: (item) async {
                            await _favService.updateFavorite(item);
                            _loadFavorites();
                          },
                        )
                      : _buildStatusTab(l10n),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.directions_bus_outlined),
            selectedIcon: const Icon(Icons.directions_bus),
            label: l10n.lines,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            selectedIcon: const Icon(Icons.favorite),
            label: l10n.favorites,
          ),
          NavigationDestination(
            icon: _buildBadgedIcon(Icons.info_outline, _unreadAlertCount),
            selectedIcon: _buildBadgedIcon(Icons.info, _unreadAlertCount),
            label: l10n.serviceStatus,
          ),
        ],
      ),
    );
  }

  /// Custom responsive badge to avoid clipping and ensure compact size
  Widget _buildBadgedIcon(IconData iconData, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData),
        if (count > 0)
          Positioned(
            right: -8, // Push slightly outside to the right
            top: -4,   // Push slightly up
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB3261E), // Material 3 Error
                borderRadius: BorderRadius.circular(10), // Pill shape
              ),
              constraints: const BoxConstraints(
                minWidth: 16, // Ensure a nice circle for single digits
                minHeight: 16,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0, // Tight line height
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer(AppLocalizations l10n) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Text(
                l10n.appTitle,
                style: const TextStyle(
                  color: Color(0xFFB3261E), // Red color like Gmail
                  fontSize: 22,
                  fontWeight: FontWeight.w500, // Medium weight
                ),
              ),
            ),
          ),
          const Divider(indent: 0, endIndent: 0, height: 1),
          const SizedBox(height: 8),
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
          final unreadCount = await _alertReadService.getUnreadCount(alerts);
          final readIds = await _alertReadService.getReadAlertIds();
          setState(() {
            _serviceAlerts = alerts;
            _unreadAlertCount = unreadCount;
            _readAlertIds = readIds;
          });
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
                style: TextStyle(
                  fontWeight: _readAlertIds.contains(alert.id) ? FontWeight.normal : FontWeight.w800,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedAlignment: Alignment.topLeft,
              onExpansionChanged: (expanded) {
                if (expanded) {
                  _markAlertAsRead(alert.id);
                }
              },
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
