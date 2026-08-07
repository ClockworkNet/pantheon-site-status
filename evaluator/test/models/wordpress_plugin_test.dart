import 'package:sinfo/models/wordpress_plugin.dart';
import 'package:test/test.dart';

void main() {
  group('WordPressPlugin.fromJson', () {
    test('defaults vulnerableDescription to an empty string when the '
        '"vulnerable" key is absent', () {
      // Regression coverage: real `wp launchcheck plugins --format=json`
      // output never actually includes a "vulnerable" key on any alert
      // entry. This is the root cause behind every plugin once being
      // falsely flagged as vulnerable -- code must not assume a missing
      // field defaults to the string "None".
      final plugin = WordPressPlugin.fromJson({
        'slug': 'some-plugin',
        'installed': '1.0',
        'available': '1.1',
        'needs_update': '1',
      });

      expect(plugin.vulnerableDescription, '');
    });

    test('reads a real vulnerability description when present', () {
      final plugin = WordPressPlugin.fromJson({
        'slug': 'bad-plugin',
        'vulnerable': 'CVE-2024-1234',
      });

      expect(plugin.vulnerableDescription, 'CVE-2024-1234');
    });
  });

  group('WordPressPlugin.toJson', () {
    test('round-trips the vulnerable field for a plugin explicitly marked '
        '"None"', () {
      const plugin = WordPressPlugin(
        slug: 'clean-plugin',
        vulnerableDescription: 'None',
      );

      expect(plugin.toJson()['vulnerable'], 'None');
    });

    test('round-trips an empty vulnerable field as an empty string, not '
        '"None"', () {
      const plugin = WordPressPlugin(slug: 'clean-plugin');

      expect(plugin.toJson()['vulnerable'], '');
    });

    test('needs_update serializes as "1"/"0" strings', () {
      const needsUpdate = WordPressPlugin(needsUpdate: true);
      const upToDate = WordPressPlugin(needsUpdate: false);

      expect(needsUpdate.toJson()['needs_update'], '1');
      expect(upToDate.toJson()['needs_update'], '0');
    });
  });
}
