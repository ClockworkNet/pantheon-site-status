import 'dart:convert';

import 'package:sinfo/models/site.dart';
import 'package:sinfo/sinfo_manager.dart';
import 'package:test/test.dart';

void main() {
  group('resultsPayload', () {
    test('wraps sites with a UTC generated_at timestamp', () {
      final site = Site(pantheonName: 'alpha');
      final at = DateTime.utc(2026, 8, 20, 6);

      final payload = resultsPayload([site], generatedAt: at);

      expect(payload['generated_at'], '2026-08-20T06:00:00.000Z');
      expect(payload['sites'], hasLength(1));

      final decoded = json.decode(json.encode(payload)) as Map<String, dynamic>;
      expect(decoded['sites'][0]['name'], 'alpha');
    });

    test('converts a local generatedAt to UTC', () {
      final local = DateTime(2026, 8, 20, 1);
      final payload = resultsPayload(const [], generatedAt: local);

      expect(
        DateTime.parse(payload['generated_at'] as String).isUtc,
        isTrue,
      );
    });
  });
}
