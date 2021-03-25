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
}
