// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Aucorsa Córdoba';

  @override
  String get favorites => 'Favoritos';

  @override
  String get lines => 'Líneas';

  @override
  String get stops => 'Paradas';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Buscar parada o línea...';

  @override
  String get nextBus => 'Próximo';

  @override
  String get followingBus => 'Siguiente';

  @override
  String get noService => 'Sin servicio';

  @override
  String get lastUpdate => 'Actualizado';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get stopCode => 'Parada código';

  @override
  String get line => 'Línea';

  @override
  String get ida => 'Ida';

  @override
  String get vuelta => 'Vuelta';

  @override
  String get noEstimations => 'No hay estimaciones o servicios disponibles.';

  @override
  String get noStopsFound => 'No se encontraron paradas.';

  @override
  String get minutes => 'minutos';

  @override
  String get minute => 'minuto';

  @override
  String get now => 'ahora';

  @override
  String get serviceStatus => 'Estado';

  @override
  String get noServiceAlerts => 'No hay avisos de servicio.';

  @override
  String get viewMore => 'Ver más';
}
