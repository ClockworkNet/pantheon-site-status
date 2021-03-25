import 'model.dart';

/// This model contains information about a potential issue for a site.
class SiteIssue extends Model {
  /// The severity level for the issue.
  final String severity;

  /// The field/property of a site this issue is realated to.
  final String relatedField;

  /// A description of the issue.
  final String description;

  /// URL with additional info.
  final String referenceUrl;

  /// Default constructor.
  const SiteIssue({
    this.severity,
    this.relatedField,
    this.description,
    this.referenceUrl,
  });

  /// Convert an issue to JSON.
  Map<String, dynamic> toJson() => {
        'level': severity,
        'related_field': relatedField,
        'description': description,
        'url': referenceUrl,
      };
}
