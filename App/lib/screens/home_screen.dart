import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/theme_service.dart';
import '../main.dart';
import 'line_detail_screen.dart';
import 'stop_detail_screen.dart';
import 'search_delegate.dart';
import '../services/line_color_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation Index: 0 = Lines, 1 = Favorites
  int _selectedIndex = 0;
  
  List<BusLine> _lines = [];
  List<BusStop> _favorites = [];
  bool _loading = true;
  String? _errorMessage;
  final FavoritesService _favService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _loadLines();
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
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close drawer
    if (index == 0) {
      _loadLines();
    } else {
      _loadFavorites();
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
    final title = _selectedIndex == 0 ? 'Aucorsa - ${l10n.lines}' : l10n.favorites;
    
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
            ListTile(
              leading: const Icon(Icons.list),
              title: Text(l10n.lines),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(l10n.favorites),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            const Divider(),
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
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : _selectedIndex == 0 
           ? _buildLinesList()
           : _buildFavoritesList(l10n),
    );
  }

  Widget _buildLinesList() {
    if (_lines.isEmpty && _errorMessage != null) {
       return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    return ListView.builder(
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final line = _lines[index];
        final displayId = line.label.split('ㅤ')[0].trim();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: LineColorService.getColor(displayId),
              foregroundColor: Colors.white,
              child: Text(
                displayId, 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              (line.label.contains('ㅤ') ? line.label.substring(line.label.indexOf('ㅤ') + 1) : line.label).trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LineDetailScreen(line: line)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(AppLocalizations l10n) {
    if (_favorites.isEmpty) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
             const SizedBox(height: 16),
             Text(l10n.noStopsFound),
           ],
         ),
       );
    }
    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final stop = _favorites[index];
        return Card(
           margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           child: ListTile(
             leading: const Icon(Icons.place, color: Colors.red),
             title: Text(stop.label),
             subtitle: Text("${l10n.stopCode}: ${stop.id}"),
             trailing: IconButton(
               icon: const Icon(Icons.delete_outline),
               onPressed: () async {
                 await _favService.removeFavorite(stop.id);
                 _loadFavorites(); // Refresh
               },
             ),
             onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StopDetailScreen(stop: stop)),
              );
             },
           ),
        );
      },
    );
  }
}
