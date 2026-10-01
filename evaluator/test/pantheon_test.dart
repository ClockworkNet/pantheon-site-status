import 'dart:io';

import 'package:sinfo/pantheon.dart';
import 'package:test/test.dart';

/// Fake terminus that returns [results] in order, one per call.
class _FakeTerminus {
  final List<ProcessResult> results;
  int calls = 0;

  _FakeTerminus(this.results);

  Future<ProcessResult> run(String executable, List<String> arguments) async =>
      results[calls++];
}

ProcessResult _result(int exitCode, String stdout) =>
    ProcessResult(0, exitCode, stdout, '');

Pantheon _pantheon(_FakeTerminus fake) => Pantheon(
      pantheonOrgId: 'org',
      retryDelay: Duration.zero,
      runProcess: fake.run,
    );

void main() {
  group('Pantheon terminus retries', () {
    test('a transient failure is retried and the later success is used',
        () async {
      // Regression coverage: Pantheon's SSH gateway intermittently answers
      // "The requested resource is locked" (exit 255). Without a retry, a
      // single blip left cms_version blank and flagged the CMS "unknown".
      final fake = _FakeTerminus([
        _result(255, 'channel 0: open failed: administratively prohibited'),
        _result(0, '7.1\n'),
      ]);

      final version = await _pantheon(fake).fetchWordPressVersion('site');

      expect(version, '7.1');
      expect(fake.calls, 2);
    });

    test(
        'a command that keeps failing gives up after maxAttempts and '
        'returns an empty value', () async {
      final fake = _FakeTerminus([
        _result(255, 'locked'),
        _result(255, 'locked'),
        _result(255, 'locked'),
      ]);

      final version = await _pantheon(fake).fetchWordPressVersion('site');

      expect(version, '');
      expect(fake.calls, 3);
    });

    test('a successful command is not retried', () async {
      final fake = _FakeTerminus([_result(0, '8.4')]);

      await _pantheon(fake).fetchPhpVersion('site');

      expect(fake.calls, 1);
    });

    test('the plugin fetch is retried too', () async {
      final fake = _FakeTerminus([
        _result(255, 'locked'),
        _result(0, '{"plugins":{"alerts":{}}}'),
      ]);

      final plugins = await _pantheon(fake).fetchWordPressPlugins('site');

      expect(plugins, isNotNull);
      expect(fake.calls, 2);
    });

    test('a plugin fetch that keeps failing returns null', () async {
      final fake = _FakeTerminus([
        _result(255, ''),
        _result(255, ''),
        _result(255, ''),
      ]);

      expect(await _pantheon(fake).fetchWordPressPlugins('site'), isNull);
    });
  });
}
