class BusLine {
  final String id;
  final String label;

  BusLine({required this.id, required this.label});

  factory BusLine.fromJson(Map<String, dynamic> json) {
    return BusLine(
      id: json['id'].toString(),
      label: json['label'].toString(),
    );
  }
}

class BusStop {
  final String id;
  final String label;

  BusStop({required this.id, required this.label});
}

class Estimation {
  final String stopId;
  final String stopName;
  final String nextBus; // "6 minutos", "ahora"
  final String followingBus;
  final String? lineId;   
  final String? lineName;

  Estimation({
    required this.stopId,
    required this.stopName,
    required this.nextBus,
    required this.followingBus,
    this.lineId,
    this.lineName,
  });
}

class RouteDirection {
  final String directionLabel;
  final List<BusStop> stops;

  RouteDirection({required this.directionLabel, required this.stops});
}

/// Represents a favorite (Line, Stop) pair for the dashboard
class FavoriteItem {
  final String stopId;
  final String stopLabel;
  final String lineId;
  final String lineLabel;
  final String? customStopName;
  final String? customLineName;

  FavoriteItem({
    required this.stopId,
    required this.stopLabel,
    required this.lineId,
    required this.lineLabel,
    this.customStopName,
    this.customLineName,
  });

  /// Unique key for this favorite
  String get key => '${lineId}_$stopId';

  Map<String, dynamic> toJson() => {
    'stopId': stopId,
    'stopLabel': stopLabel,
    'lineId': lineId,
    'lineLabel': lineLabel,
    'customStopName': customStopName,
    'customLineName': customLineName,
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      stopId: json['stopId']?.toString() ?? '',
      stopLabel: json['stopLabel']?.toString() ?? '',
      lineId: json['lineId']?.toString() ?? '',
      lineLabel: json['lineLabel']?.toString() ?? '',
      customStopName: json['customStopName']?.toString(),
      customLineName: json['customLineName']?.toString(),
    );
  }
}

/// Represents a service alert/incident from AUCORSA
class ServiceAlert {
  final int id;
  final DateTime date;
  final String title;
  final String content;
  final String slug;
  final String link;

  ServiceAlert({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.slug,
    required this.link,
  });

  factory ServiceAlert.fromJson(Map<String, dynamic> json) {
    // Parse date from WordPress format (e.g., "2026-01-22T11:12:33")
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'] ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    // Extract strings from WordPress "rendered" format
    final titleObj = json['title'];
    String titleStr = (titleObj is Map) 
        ? (titleObj['rendered']?.toString() ?? '') 
        : (titleObj?.toString() ?? '');

    final contentObj = json['content'];
    String contentStr = (contentObj is Map) 
        ? (contentObj['rendered']?.toString() ?? '') 
        : (contentObj?.toString() ?? '');

    // Robust decoding and stripping
    String decode(String text) {
      return text
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&#038;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&#8211;', '–')
          .replaceAll('&#8212;', '—')
          .replaceAll('&#8216;', '‘')
          .replaceAll('&#8217;', '’')
          .replaceAll('&#8220;', '“')
          .replaceAll('&#8221;', '”')
          .replaceAll('&#8230;', '…')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Collapse triple+ newlines to double
          .replaceAll(RegExp(r' {2,}'), ' ')     // Collapse multiple spaces
          .trim();
    }

    return ServiceAlert(
      id: json['id'] ?? 0,
      date: parsedDate,
      title: decode(titleStr),
      content: decode(contentStr),
      slug: json['slug']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }
}
