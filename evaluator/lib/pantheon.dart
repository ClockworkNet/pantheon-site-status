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
  /// it exits non-zero. Returns the trimmed stdout on success, or '' on
  /// failure -- never the raw stdout content of a failed command, since
  /// some WP-CLI errors (e.g. "This does not seem to be a WordPress
  /// installation") get written to stdout rather than stderr, and would
  /// otherwise get treated as if they were the real field value.
  Future<String> _runTerminus(List<String> args, String siteName) {
    return Process.run('terminus', args).then((result) {
      if (result.exitCode != 0) {
        stderr.writeln(
            'Warning: `terminus ${args.join(' ')}` failed for $siteName '
            '(exit code ${result.exitCode}). stderr:\n${result.stderr.toString().trim()}');
        return '';
      }
      return result.stdout.toString().trim();
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

  /// Get the domain of a WordPress Multisite network's primary (blog_id 1)
  /// site, read directly from the database. This deliberately bypasses
  /// WP-CLI's usual URL-based site resolution: on some networks, a custom
  /// domain was set as the registered site rather than the Pantheon
  /// platform URL, so passing the platform URL to a normal `wp` command
  /// fails with "Site ... not found. Verify DOMAIN_CURRENT_SITE...".
  /// A raw `db query` doesn't need to resolve a site by URL at all, so it
  /// works regardless of that mismatch, and gives us the real domain to
  /// pass as `--url` to subsequent commands. Returns '' if it fails.
  Future<String> fetchMultisitePrimaryDomain(String siteName) {
    return _runTerminus([
      'wp',
      '-y',
      '$siteName.live',
      '--',
      'db',
      'query',
      'SELECT domain FROM wp_blogs WHERE blog_id = 1',
      '--skip-column-names',
    ], siteName);
  }

  /// Get the WordPress CMS version for the site. [url] should be provided
  /// for WordPress Multisite installs (see [fetchMultisitePrimaryDomain])
  /// where the site's own live URL may not resolve.
  Future<String> fetchWordPressVersion(String siteName, {String? url}) {
    final args = ['wp', '-y', '$siteName.live', '--', 'core', 'version'];
    if (url != null && url.isNotEmpty) args.add('--url=$url');
    return _runTerminus(args, siteName);
  }

  /// Get the information about the plugins for a WordPress site, or null
  /// if the fetch failed -- callers must not treat null the same as "the
  /// site genuinely has zero plugins". [url] should be provided for
  /// WordPress Multisite installs (see [fetchMultisitePrimaryDomain]).
  /// example: terminus wp -y jb-group.live -- launchcheck plugins --format=json
  Future<List<WordPressPlugin>?> fetchWordPressPlugins(String siteName,
      {String? url}) {
    final args = [
      'wp',
      '-y',
      '$siteName.live',
      '--',
      'launchcheck',
      'plugins',
      '--format=json',
    ];
    if (url != null && url.isNotEmpty) args.add('--url=$url');

    return Process.run('terminus', args).then((result) {
      if (result.exitCode == 1) {
        stderr.writeln(
            'Warning: `terminus wp launchcheck plugins` failed for $siteName '
            '(exit code 1). stderr:\n${result.stderr.toString().trim()}');
        return null;
      }

      final output = result.stdout.toString();
      final jsonPayload = _extractJsonObject(output);
      if (jsonPayload == null) {
        stderr.writeln(
            'Warning: no JSON object found in `wp launchcheck plugins` output for $siteName. Raw output:\n${output.trim()}');
        return null;
      }

      try {
        return WordPressPlugin.pluginsFromJson(json.decode(jsonPayload));
      } on FormatException {
        stderr.writeln(
            'Warning: could not parse `wp launchcheck plugins` JSON for $siteName. Raw output:\n${output.trim()}');
        return null;
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
