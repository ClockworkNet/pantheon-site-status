import 'dart:convert';

import 'package:http/http.dart' as http;

/// A simple wrapper around functions for obtaining general information
/// about WordPress -- not site specific info.
class WordPress {
  /// The latest current version of WordPress.
  String _currentVersion = '';

  /// Map of versions of WordPress and their stability level.
  Map<String, String> _versions = const {};

  /// The in-flight request for [_versions], if one is already underway.
  /// Lets concurrent callers share a single fetch instead of each kicking
  /// off their own request before the first one has populated [_versions].
  Future<Map<String, String>>? _versionsRequest;

  /// Get the current stable version of WordPress.
  Future<String> fetchCurrentVersion() {
    if (_currentVersion.isNotEmpty) return Future(() => _currentVersion);
    var url = Uri.https('api.wordpress.org', '/core/version-check/1.7/');

    return http.get(url).then((response) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json.containsKey('offers') == false) return 'Unknown';
      _currentVersion = json['offers'][0]['current'];
      return _currentVersion;
    });
  }

  String _stability(String version) {
    if (_versions.isEmpty) return 'unknown';
    if (_versions.containsKey(version) == false) return 'unknown';
    return _versions[version] ?? '';
  }

  /// Get the stability level of [version].
  Future<String> fetchVersionStability(String version) {
    if (_versions.isNotEmpty) {
      return Future(() => _stability(version));
    }

    _versionsRequest ??= () {
      var url = Uri.https('api.wordpress.org', '/core/stable-check/1.0/');
      return http.get(url).then((response) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return _versions = Map<String, String>.from(json);
      });
    }();

    return _versionsRequest!.then((_) => _stability(version));
  }
}
