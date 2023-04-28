import 'models/site.dart';
import 'models/site_issue.dart';

/// Evaluate a site based on it's values and determine warnings / issues.
class Evaluator {
  /// Map of PHP versions to their current status.
  final _phpVersions = {
    '5.5': 'end of life',
    '5.6': 'end of life',
    '7.0': 'end of life',
    '7.1': 'end of life',
    '7.2': 'end of life',
    '7.3': 'end of life',
    '7.4': 'end of life',
    '8.0': 'security fixes only',
    '8.1': 'active',
    '8.2': 'active',
  };

  /// Mapping of PHP status values to their alert level.
  final phpAlerts = {
    'active': 'okay',
    'security fixes only': 'warning',
    'end of life': 'alert',
  };

  /// Mapping of New Relic status values to their alert level.
  final newRelicAlerts = {
    'active': 'okay',
    'pending': 'warning',
    'unknown': 'warning',
  };

  /// Mapping of Pantheon Upstream status values to their alert level.
  final upstreamAlerts = {
    'current': 'okay',
    'outdated': 'warning',
  };

  /// Mapping of WordPress version status values to their alert level.
  final wordpressAlerts = {
    'latest': 'okay',
    'outdated': 'warning',
    'insecure': 'alert',
  };

  /// The the status of a PHP version.
  String phpStability(String phpVersion) =>
      _phpVersions[phpVersion] ?? 'Unknown';

  /// Review the information about a site, and add issues to the site.
  void evaluateSite(Site site) {
    final phpAlert = phpAlerts[site.phpStability] ?? 'warning';
    if (phpAlert != 'okay') {
      site.issues.add(SiteIssue(
        severity: phpAlert,
        relatedField: 'php_version_status',
        description: 'PHP Version',
      ));
    }

    final upstreamAlert = upstreamAlerts[site.upstreamStatus] ?? 'warning';
    if (upstreamAlert != 'okay') {
      site.issues.add(SiteIssue(
        severity: upstreamAlert,
        relatedField: 'upstream_status',
        description: 'Pantheon Updates',
      ));
    }

    final newRelicAlert = newRelicAlerts[site.newRelicStatus] ?? 'warning';
    if (newRelicAlert != 'okay') {
      site.issues.add(SiteIssue(
        severity: newRelicAlert,
        relatedField: 'new_relic_status',
        description: 'New Relic Setup',
      ));
    }

    if (site.cmsName == 'wordpress') _evaluateWordPress(site);
    if (site.cmsName == 'drupal') _evaluateDrupal(site);
  }

  /// Evaluate a WordPress site and record issues in [site].
  void _evaluateWordPress(Site site) {
    final alert = wordpressAlerts[site.cmsStability] ?? 'warning';
    if (alert != 'okay') {
      site.issues.add(SiteIssue(
        severity: alert,
        relatedField: 'cms_version_status',
        description: 'CMS Version',
      ));
    }

    for (var plugin in site.plugins) {
      if (plugin.vulnerableDescription == 'None') continue;

      site.issues.add(SiteIssue(
        severity: 'alert',
        relatedField: 'plugin',
        description: 'Vulnerable plugin: ${plugin.slug}',
        referenceUrl: plugin.vulnerableDescription,
      ));
    }
  }

  /// Evaluate a Drupal site and record issues in [site].
  void _evaluateDrupal(Site site) {}
}
