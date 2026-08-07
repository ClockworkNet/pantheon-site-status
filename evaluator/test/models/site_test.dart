import 'package:sinfo/models/site.dart';
import 'package:test/test.dart';

void main() {
  test('Converting to JSON', () {
    final site = Site(
      cmsName: 'cms',
      created: DateTime(2020, 5, 23),
      isFrozen: true,
      pantheonId: 'p-id',
      pantheonName: 'p-name',
      pantheonPlanName: 'p-plan',
      pantheonTags: ['tag-1', 'tag-2'],
      phpVersion: '7.0',
    );

    final result = site.toJson();

    expect(result['name'], 'p-name');
    expect(result['cms'], 'cms');
    expect(result['created'], '2020-May-23');
    expect(result['pantheon_id'], 'p-id');
    expect(result['name'], 'p-name');
    expect(result['pantheon_plan'], 'p-plan');
    expect(result['tags'][1], 'tag-2');
    expect(result['php_version'], '7.0');
  });

  group('isWordPress', () {
    // Regression coverage: Pantheon reports WordPress Multisite installs
    // with framework/cmsName "wordpress_network", not "wordpress". An
    // exact-match check on cmsName previously caused these sites to
    // silently skip all WordPress evaluation (no version/plugin fetch,
    // no vulnerability check) while still displaying as clean.
    test('is true for a regular WordPress site', () {
      expect(Site(cmsName: 'wordpress').isWordPress, isTrue);
    });

    test('is true for a WordPress Multisite install', () {
      expect(Site(cmsName: 'wordpress_network').isWordPress, isTrue);
    });

    test('is false for a non-WordPress site', () {
      expect(Site(cmsName: 'drupal').isWordPress, isFalse);
    });
  });

  group('isMultisite', () {
    test('is true only for wordpress_network', () {
      expect(Site(cmsName: 'wordpress_network').isMultisite, isTrue);
      expect(Site(cmsName: 'wordpress').isMultisite, isFalse);
    });

    test('toJson includes is_multisite', () {
      expect(Site(cmsName: 'wordpress_network').toJson()['is_multisite'], isTrue);
      expect(Site(cmsName: 'wordpress').toJson()['is_multisite'], isFalse);
    });
  });
}
