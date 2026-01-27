import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';
import 'services/name_override_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize name override service
  await NameOverrideService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
      ],
      child: const AucorsaApp(),
    ),
  );
}

/// Service to manage the app's locale with persistence
class LocaleService extends ChangeNotifier {
  Locale _locale = const Locale('es');
  
  LocaleService() {
    _loadLocale();
  }
  
  Locale get locale => _locale;
  
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'es';
    _locale = Locale(langCode);
    notifyListeners();
  }
  
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }
}

class AucorsaApp extends StatelessWidget {
  const AucorsaApp({super.key});

  // Professional teal/green as primary accent
  static const Color _primaryColor = Color(0xFF00A99D); 

  @override
  Widget build(BuildContext context) {
    // Watch theme and locale changes
    final themeService = context.watch<ThemeService>();
    final localeService = context.watch<LocaleService>();
    
    return MaterialApp(
      title: 'Aucorsa Córdoba',
      
      // Localization config
      locale: localeService.locale,
      supportedLocales: const [
        Locale('es'), // Spanish
        Locale('en'), // English
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Light Theme - Strictly White and Professional
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
          primary: _primaryColor,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF2D2D2D), // Soft black
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        dividerColor: const Color(0xFFEEEEEE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: _primaryColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: _primaryColor),
          titleTextStyle: TextStyle(
            color: _primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
      ),
      
      // Dark Theme - Clean and High Contrast
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
          primary: _primaryColor,
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: _primaryColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: _primaryColor),
          titleTextStyle: TextStyle(
            color: _primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      themeMode: themeService.themeMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
