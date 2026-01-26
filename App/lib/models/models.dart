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
