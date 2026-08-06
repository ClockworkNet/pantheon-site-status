import 'dart:convert';
import 'dart:io';

import 'models/site.dart';
import 'models/wordpress_plugin.dart';

/// This class provides easy access in Dart to Pantheon terminus commands.
class Pantheon {
  /// Pantheon's organization ID for the organization owning the sites.
  final String pantheonOrgId;

  /// Default constructor.
  Pantheon({required this.pantheonOrgId});

  /// Return true if Pantheon's terminus is installed.
  Future<bool> isTerminusInstalled() async {
    try {
      await Process.run('terminus', [
        '--version',
      ]);
    } on ProcessException catch (_) {
      return false;
    }
    return true;
  }

  /// Get the list of all sites from Pantheon.
  Future<Map<dynamic, dynamic>> fetchSitesJson() async {
    return Process.run('terminus', [
      'org:site:list',
      '--no-interaction',
      '--format=json',
      pantheonOrgId,
    ]).then((result) {
      return json.decode(result.stdout);
    });
  }

  /// Run a terminus command for [siteName] and log a warning to stderr if
  /// it exits non-zero. Returns the trimmed stdout either way (empty on
  /// failure), so callers get the same "blank" value they always did, but
  /// the failure itself is no longer silent.
  Future<String> _runTerminus(List<String> args, String siteName) {
    return Process.run('terminus', args).then((result) {
      final output = result.stdout.toString().trim();
      if (result.exitCode != 0) {
        stderr.writeln(
            'Warning: `terminus ${args.join(' ')}` failed for $siteName '
            '(exit code ${result.exitCode}). stderr:\n${result.stderr.toString().trim()}');
      }
      return output;
    });
  }

  /// Get a list of the non-frozen, non-sandbox sites from Pantheon.
  Future<List<Site>> fetchSites() {
    var sites = <Site>[];

    return fetchSitesJson().then((sitesJson) {
      for (var siteId in sitesJson.keys) {
        final site = Site.fromPantheonJson(sitesJson[siteId]);
        if (site.isFrozen == false) sites.add(site);
      }
      return sites;
    });
  }

  /// Get the PHP version used for the live environment of a site.
  Future<String> fetchPhpVersion(String siteName) {
    return _runTerminus(
        ['env:info', '$siteName.live', '--field=php_version'], siteName);
  }

  /// Get the URL to the live instance of the site.
  Future<String> fetchLiveUrl(String siteName) {
    return _runTerminus(['env:view', '$siteName.live', '--print'], siteName);
  }

  /// Get the setup status of New Relic for the site.
  /// A properly configured site will the status "active".
  /// example: terminus new-relic:info jb-group --field=state
  Future<String> fetchNewRelicStatus(String siteName) {
    return _runTerminus(['new-relic:info', siteName, '--field=state'],
            siteName)
        .then((status) => status.isEmpty ? 'unknown' : status);
  }

  /// Get Pantheon's associated upstream status for the site.
  Future<String> fetchUpstreamStatus(String siteName) {
    return _runTerminus(
        ['upstream:updates:status', '$siteName.live'], siteName);
  }

  /// Get the WordPress CMS version for the site.
  Future<String> fetchWordPressVersion(String siteName) {
    return _runTerminus(
        ['wp', '-y', '$siteName.live', '--', 'core', 'version'], siteName);
  }

  /// Get the information about the plugins for a WordPress site.
  /// example: terminus wp -y jb-group.live -- launchcheck plugins --format=json
  Future<List<WordPressPlugin>> fetchWordPressPlugins(String siteName) {
    return Process.run('terminus', [
      'wp',
      '-y',
      '$siteName.live',
      '--',
      'launchcheck',
      'plugins',
      '--format=json',
    ]).then((result) {
      if (result.exitCode == 1) {
        stderr.writeln(
            'Warning: `terminus wp launchcheck plugins` failed for $siteName '
            '(exit code 1). stderr:\n${result.stderr.toString().trim()}');
        return const [];
      }

      final output = result.stdout.toString();
      final jsonPayload = _extractJsonObject(output);
      if (jsonPayload == null) {
        stderr.writeln(
            'Warning: no JSON object found in `wp launchcheck plugins` output for $siteName. Raw output:\n${output.trim()}');
        return const [];
      }

      try {
        return WordPressPlugin.pluginsFromJson(json.decode(jsonPayload));
      } on FormatException {
        stderr.writeln(
            'Warning: could not parse `wp launchcheck plugins` JSON for $siteName. Raw output:\n${output.trim()}');
        return const [];
      }
    });
  }

  /// Extract the outermost JSON object from [raw], tolerating any
  /// non-JSON noise (e.g. PHP warnings written to the same stream) that
  /// may precede or follow it. Returns null if no `{...}` object is found.
  String? _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) return null;
    return raw.substring(start, end + 1);
  }
}
