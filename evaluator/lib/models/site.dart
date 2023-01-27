import 'package:intl/intl.dart';

import 'model.dart';
import 'site_issue.dart';
import 'wordpress_plugin.dart';

/// This model contains site data gathered from a variety of sources,
/// including: Pantheon, WordPress CLI, and Wordpress.org.
class Site extends Model {
  /// Name of the site.
  final String pantheonName;

  /// The Pantheon site ID.
  final String pantheonId;

  /// The name of the Pantheon plan associated with the site.
  final String pantheonPlanName;

  /// wordpress | drupal
  final String cmsName;

  /// Date the site was created in Pantheon.
  final DateTime? created;

  /// Pantheon tags associated with the site.
  final List<String> pantheonTags;

  /// True if the site has been frozen by Pantheon.
  final bool isFrozen;

  /// Version used by the site's live environment.
  String phpVersion;

  /// URL of the live Pantheon instance.
  String liveUrl;

  /// The status of the site's New Relic configuration.
  /// A properly configured site will the status "active".
  String newRelicStatus;

  /// The status of Pantheon's upstream associated with the site.
  String upstreamStatus;

  /// The version of the CMS install on the live site.
  String cmsVersion;

  /// The stability level of the site's PHP version.
  String phpStability;

  /// The stability level of the CMS's version.
  String cmsStability;

  /// Plugins currently installed on the site.
  List<WordPressPlugin> plugins;

  /// Potential issues found on the site.
  List<SiteIssue> issues;

  /// Default constructor.
  Site({
    this.created,
    this.cmsName = '',
    this.isFrozen = false,
    this.pantheonId = '',
    this.pantheonName = '',
    this.pantheonPlanName = '',
    this.pantheonTags = const [],
    this.phpVersion = '',
    this.phpStability = '',
    this.liveUrl = '',
    this.newRelicStatus = '',
    this.upstreamStatus = '',
    this.cmsVersion = '',
    this.cmsStability = '',
  })  : issues = [],
        plugins = [];

  /// Return true if the site is not frozen and not a sandbox site.
  bool get isActive {
    if (isFrozen) return false;
    if (pantheonPlanName.toLowerCase() == 'sandbox') return false;
    return true;
  }

  /// Convert a site to JSON.
  Map<String, dynamic> toJson() => {
        'name': pantheonName,
        'pantheon_id': pantheonId,
        'created':
            created == null ? '' : DateFormat('yyyy-MMM-dd').format(created!),
        'cms': cmsName,
        'cms_version': cmsVersion,
        'cms_version_status': cmsStability,
        'pantheon_plan': pantheonPlanName,
        'php_version': phpVersion,
        'php_version_status': phpStability,
        'upstream_status': upstreamStatus,
        'new_relic_status': newRelicStatus,
        'tags': pantheonTags,
        'url': liveUrl,
        'issues': issues,
        'plugins': plugins,
      };

  /// Create the model from JSON.
  factory Site.fromPantheonJson(Map<String, dynamic> json) {
    final framework = Model.fieldAsString(json, 'framework');
    final cmsName = framework == 'drupal8' ? 'drupal' : framework;

    final tagsString = Model.fieldAsString(json, 'tags');
    var tags = const <String>[];
    if (tagsString.isNotEmpty) {
      tags = tagsString.split(',');
    }

    return Site(
      created: Model.fieldAsDateTime(json, 'created'),
      cmsName: cmsName,
      isFrozen: Model.fieldAsBool(json, 'frozen'),
      pantheonId: Model.fieldAsString(json, 'id'),
      pantheonName: Model.fieldAsString(json, 'name'),
      pantheonPlanName: Model.fieldAsString(json, 'plan_name'),
      pantheonTags: tags,
    );
  }
}
