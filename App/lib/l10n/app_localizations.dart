import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Aucorsa Córdoba'**
  String get appTitle;

  /// No description provided for @favorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favorites;

  /// No description provided for @lines.
  ///
  /// In es, this message translates to:
  /// **'Líneas'**
  String get lines;

  /// No description provided for @stops.
  ///
  /// In es, this message translates to:
  /// **'Paradas'**
  String get stops;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar parada...'**
  String get searchHint;

  /// No description provided for @nextBus.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get nextBus;

  /// No description provided for @followingBus.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get followingBus;

  /// No description provided for @noService.
  ///
  /// In es, this message translates to:
  /// **'Sin servicio'**
  String get noService;

  /// No description provided for @lastUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualizado'**
  String get lastUpdate;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @stopCode.
  ///
  /// In es, this message translates to:
  /// **'Parada código'**
  String get stopCode;

  /// No description provided for @line.
  ///
  /// In es, this message translates to:
  /// **'Línea'**
  String get line;

  /// No description provided for @ida.
  ///
  /// In es, this message translates to:
  /// **'Ida'**
  String get ida;

  /// No description provided for @vuelta.
  ///
  /// In es, this message translates to:
  /// **'Vuelta'**
  String get vuelta;

  /// No description provided for @noEstimations.
  ///
  /// In es, this message translates to:
  /// **'No hay estimaciones o servicios disponibles.'**
  String get noEstimations;

  /// No description provided for @noStopsFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron paradas.'**
  String get noStopsFound;

  /// No description provided for @minutes.
  ///
  /// In es, this message translates to:
  /// **'minutos'**
  String get minutes;

  /// No description provided for @minute.
  ///
  /// In es, this message translates to:
  /// **'minuto'**
  String get minute;

  /// No description provided for @now.
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get now;

  /// No description provided for @serviceStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get serviceStatus;

  /// No description provided for @noServiceAlerts.
  ///
  /// In es, this message translates to:
  /// **'No hay avisos de servicio.'**
  String get noServiceAlerts;

  /// No description provided for @viewMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get viewMore;

  /// No description provided for @newVersionAvailable.
  ///
  /// In es, this message translates to:
  /// **'Nueva versión disponible'**
  String get newVersionAvailable;

  /// No description provided for @download.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get download;

  /// No description provided for @editFavorite.
  ///
  /// In es, this message translates to:
  /// **'Editar Favorito'**
  String get editFavorite;

  /// No description provided for @stopName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de Parada'**
  String get stopName;

  /// No description provided for @lineName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de Línea'**
  String get lineName;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
