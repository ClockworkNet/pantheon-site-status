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

  /// Get the list of all sites from Pantheon, trying the cache first.
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

  /// Get a list of the non-frozen, non-sandbox sites from Pantheon,
  /// if there is cached data, it will be used.
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
    return Process.run('terminus', [
      'env:info',
      '$siteName.live',
      '--field=php_version',
    ]).then((result) {
      return result.stdout.toString().trim();
    });
  }

  /// Get the URL to the live instance of the site.
  Future<String> fetchLiveUrl(String siteName) {
    return Process.run('terminus', [
      'env:view',
      '$siteName.live',
      '--print',
    ]).then((result) {
      return result.stdout.toString().trim();
    });
  }

  /// Get the setup status of New Relic for the site.
  /// A properly configured site will the status "active".
  Future<String> fetchNewRelicStatus(String siteName) {
    return Process.run('terminus', [
      'new-relic:info',
      siteName,
      '--field=state',
    ]).then((result) {
      return result.stdout.toString().trim();
    });
  }

  /// Get Pantheon's associated upstream status for the site.
  Future<String> fetchUpstreamStatus(String siteName) {
    return Process.run('terminus', [
      'upstream:updates:status',
      '$siteName.live',
    ]).then((result) {
      return result.stdout.toString().trim();
    });
  }

  /// Get the WordPress CMS version for the site.
  Future<String> fetchWordPressVersion(String siteName) {
    return Process.run('terminus', [
      'wp',
      '-y',
      '$siteName.live',
      '--',
      'core',
      'version',
    ]).then((result) {
      return result.stdout.toString().trim();
    });
  }

  /// Get the information about the plugins for a WordPress site.
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
      if (result.exitCode == 1) return const [];
      return WordPressPlugin.pluginsFromJson(json.decode(result.stdout));
    });
  }
}
