import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service to track which alerts have been read by the user.
/// Used to calculate the unread count for the notification badge.
class AlertReadService {
  static const String _readAlertsKey = 'read_alert_ids';
  
  // Cached SharedPreferences instance
  static SharedPreferences? _prefsInstance;
  
  Future<SharedPreferences> get _prefs async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }

  /// Get all read alert IDs
  Future<Set<int>> getReadAlertIds() async {
    final prefs = await _prefs;
    final List<String>? data = prefs.getStringList(_readAlertsKey);
    if (data == null) return {};
    return data.map((e) => int.tryParse(e) ?? 0).toSet();
  }

  /// Mark an alert as read
  Future<void> markAsRead(int alertId) async {
    final prefs = await _prefs;
    final readIds = await getReadAlertIds();
    readIds.add(alertId);
    await prefs.setStringList(
      _readAlertsKey,
      readIds.map((e) => e.toString()).toList(),
    );
  }

  /// Get the count of unread alerts
  Future<int> getUnreadCount(List<ServiceAlert> alerts) async {
    final readIds = await getReadAlertIds();
    return alerts.where((a) => !readIds.contains(a.id)).length;
  }

  /// Check if a specific alert is read
  Future<bool> isRead(int alertId) async {
    final readIds = await getReadAlertIds();
    return readIds.contains(alertId);
  }
}
