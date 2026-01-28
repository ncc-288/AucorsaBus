import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';
import 'services/name_override_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Allow runtime font fetching for Android reliability
  GoogleFonts.config.allowRuntimeFetching = true;
  
  // Initialize name override service
  await NameOverrideService().initialize();
  
  runApp(
    ProviderScope(
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.Provider(create: (_) => ApiService()),
          legacy_provider.ChangeNotifierProvider(create: (_) => ThemeService()),
          legacy_provider.ChangeNotifierProvider(create: (_) => LocaleService()),
        ],
        child: const AucorsaApp(),
      ),
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
  
  // Helper to apply medium weight to a TextTheme
  static TextTheme _applyMediumWeight(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w500),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w500),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w500),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w500),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w500),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    );
  } 

  @override
  Widget build(BuildContext context) {
    // Watch theme and locale changes
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final localeService = legacy_provider.Provider.of<LocaleService>(context);
    
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
        textTheme: _applyMediumWeight(GoogleFonts.openSansTextTheme()),
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
        textTheme: _applyMediumWeight(GoogleFonts.openSansTextTheme(ThemeData.dark().textTheme)),
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
