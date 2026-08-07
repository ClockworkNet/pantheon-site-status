import 'package:sinfo/evaluator.dart';
import 'package:sinfo/models/site.dart';
import 'package:sinfo/models/wordpress_plugin.dart';
import 'package:test/test.dart';

Site _wordpressSite({List<WordPressPlugin> plugins = const []}) {
  final site = Site(
    cmsName: 'wordpress',
    pantheonName: 'test-site',
    phpVersion: '8.2',
    phpStability: 'active',
    newRelicStatus: 'active',
    upstreamStatus: 'current',
    cmsStability: 'latest',
  );
  site.plugins = plugins;
  return site;
}

void main() {
  group('Evaluator._evaluateWordPress plugin handling', () {
    test('a plugin with vulnerableDescription "None" produces no issue', () {
      final site = _wordpressSite(plugins: [
        const WordPressPlugin(slug: 'clean-plugin', vulnerableDescription: 'None'),
      ]);

      Evaluator().evaluateSite(site);

      expect(site.issues.where((i) => i.relatedField == 'plugin'), isEmpty);
    });

    test('a plugin with an empty vulnerableDescription produces no issue', () {
      // Regression coverage: real `wp launchcheck plugins` output never
      // actually includes a `vulnerable` key, so WordPressPlugin.fromJson
      // defaults vulnerableDescription to '' (not 'None'). Both must be
      // treated as "not vulnerable" or every real plugin gets flagged.
      final site = _wordpressSite(plugins: [
        const WordPressPlugin(slug: 'clean-plugin', vulnerableDescription: ''),
      ]);

      Evaluator().evaluateSite(site);

      expect(site.issues.where((i) => i.relatedField == 'plugin'), isEmpty);
    });

    test('a plugin with a real vulnerability description produces exactly '
        'one alert-severity issue referencing that plugin', () {
      final site = _wordpressSite(plugins: [
        const WordPressPlugin(
          slug: 'vulnerable-plugin',
          vulnerableDescription: 'CVE-2024-1234: Unauthenticated file upload',
        ),
      ]);

      Evaluator().evaluateSite(site);

      final pluginIssues =
          site.issues.where((i) => i.relatedField == 'plugin').toList();
      expect(pluginIssues, hasLength(1));
      expect(pluginIssues.single.severity, 'alert');
      expect(pluginIssues.single.description, contains('vulnerable-plugin'));
    });

    test('a failed plugin fetch produces a visible warning, not a silent '
        '"zero plugins, all clear"', () {
      // Regression coverage: a site whose plugin fetch failed (e.g. a
      // WordPress Multisite install where `wp launchcheck plugins`
      // couldn't resolve the site) used to look identical to a site that
      // genuinely has zero plugins -- a green checkmark either way.
      final site = _wordpressSite(plugins: []);
      site.pluginFetchFailed = true;

      Evaluator().evaluateSite(site);

      final pluginIssues =
          site.issues.where((i) => i.relatedField == 'plugin').toList();
      expect(pluginIssues, hasLength(1));
      expect(pluginIssues.single.severity, 'warning');
    });

    test('a successful fetch with genuinely zero plugins produces no '
        'plugin issue', () {
      final site = _wordpressSite(plugins: []);
      site.pluginFetchFailed = false;

      Evaluator().evaluateSite(site);

      expect(site.issues.where((i) => i.relatedField == 'plugin'), isEmpty);
    });

    test('mixed plugins only flag the genuinely vulnerable ones', () {
      final site = _wordpressSite(plugins: [
        const WordPressPlugin(slug: 'clean-1', vulnerableDescription: ''),
        const WordPressPlugin(slug: 'clean-2', vulnerableDescription: 'None'),
        const WordPressPlugin(
          slug: 'bad-plugin',
          vulnerableDescription: 'Known SQL injection',
        ),
      ]);

      Evaluator().evaluateSite(site);

      final pluginIssues =
          site.issues.where((i) => i.relatedField == 'plugin').toList();
      expect(pluginIssues, hasLength(1));
      expect(pluginIssues.single.description, contains('bad-plugin'));
    });
  });

  group('Evaluator with WordPress Multisite sites', () {
    test('a wordpress_network site with a vulnerable plugin is evaluated '
        'just like a regular WordPress site', () {
      // Regression coverage: Pantheon reports Multisite installs with
      // cmsName "wordpress_network", not "wordpress". evaluateSite must
      // still run WordPress evaluation for these, not silently skip it.
      final site = Site(
        cmsName: 'wordpress_network',
        pantheonName: 'multisite-test',
        phpStability: 'active',
        newRelicStatus: 'active',
        upstreamStatus: 'current',
        cmsStability: 'insecure',
      );
      site.plugins = [
        const WordPressPlugin(
          slug: 'vulnerable-plugin',
          vulnerableDescription: 'CVE-2024-1234',
        ),
      ];

      Evaluator().evaluateSite(site);

      expect(
        site.issues.where((i) => i.relatedField == 'plugin'),
        hasLength(1),
      );
      expect(
        site.issues.where((i) => i.relatedField == 'cms_version_status'),
        hasLength(1),
      );
    });
  });

  group('Evaluator._evaluateDrupal', () {
    test('Drupal sites get an explicit "not evaluated" warning', () {
      final site = Site(cmsName: 'drupal', pantheonName: 'drupal-site');

      Evaluator().evaluateSite(site);

      final drupalIssues = site.issues
          .where((i) => i.description.contains('not yet evaluated'))
          .toList();
      expect(drupalIssues, hasLength(1));
      expect(drupalIssues.single.severity, 'warning');
    });
  });
}
