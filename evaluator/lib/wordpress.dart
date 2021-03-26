import 'dart:convert';

import 'package:http/http.dart' as http;

/// A simple wrapper around functions for obtaining general information
/// about WordPress -- not site specific info.
class WordPress {
  /// The latest current version of WordPress.
  String _currentVersion;

  /// Map of versions of WordPress and their stability level.
  Map<String, String> _versions;

  /// Get the current stable version of WordPress.
  Future<String> fetchCurrentVersion() {
    if (_currentVersion != null) return Future(() => _currentVersion);
    var url =
        Uri.https('https://api.wordpress.org', '/core/version-check/1.7/');

    return http.get(url).then((response) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json.containsKey('offers') == false) return 'Unknown';
      _currentVersion = json['offers'][0]['current'];
      return _currentVersion;
    });
  }

  String _stability(String version) {
    if (_versions == null) return 'unknown';
    if (_versions.containsKey(version) == false) return 'unknown';
    return _versions[version];
  }

  /// Get the stability level of [version].
  Future<String> fetchVersionStability(String version) {
    if (_versions != null) {
      return Future(() => _stability(version));
    }

    var url = Uri.https('https://api.wordpress.org', '/core/stable-check/1.0/');

    return http.get(url).then((response) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      _versions = Map<String, String>.from(json);
      return _stability(version);
    });
  }
}
