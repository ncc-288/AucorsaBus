import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String? releaseUrl;
  final bool updateAvailable;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    this.releaseUrl,
    required this.updateAvailable,
  });
}

class UpdateService {
  static const String _repoOwner = 'ncc-288';
  static const String _repoName = 'AucorsaBus';

  /// Check for updates by comparing current version with latest GitHub release.
  Future<UpdateInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String? ?? '';
        final latestVersion = tagName.replaceFirst('v', '');
        // Direct download link for the APK
        final releaseUrl = 'https://github.com/$_repoOwner/$_repoName/releases/latest/download/AucorsaBus.apk';

        final updateAvailable = _isNewerVersion(currentVersion, latestVersion);

        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          releaseUrl: releaseUrl,
          updateAvailable: updateAvailable,
        );
      }
    } catch (e) {
      // Silently fail - network issues shouldn't block the app
    }

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      updateAvailable: false,
    );
  }

  /// Compare semantic versions (e.g., "1.0.0" vs "1.0.1")
  bool _isNewerVersion(String current, String latest) {
    if (latest.isEmpty) return false;

    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to same length
    while (currentParts.length < 3) {
      currentParts.add(0);
    }
    while (latestParts.length < 3) {
      latestParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
