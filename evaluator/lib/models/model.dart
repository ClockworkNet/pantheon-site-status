/// Base class for Convey models.
class Model {
  /// Default constructor.
  const Model();

  /// Safely convert a JSON field to a String.
  static String fieldAsString(Map<String, dynamic> json, String fieldName) {
    var rawValue = json[fieldName] ?? '';
    if (rawValue == null) return '';

    final stringValue = rawValue is String ? rawValue : rawValue.toString();
    if (stringValue.isEmpty) return '';
    return stringValue;
  }

  /// Safely process a JSON field and convert it into a number.
  static num? fieldAsNum(Map<String, dynamic> json, String fieldName) {
    final value = fieldAsString(json, fieldName);

    /// Overriding linting rule to allow null. This method is used to parse
    /// dollar amount fields. In that case an unexpected null is important
    /// to differenciate from $0 (free).
    // ignore: avoid_returning_null
    if (value.isEmpty) return null;
    try {
      return num.parse(value);
    } on Exception catch (_) {
      return 0;
    }
  }

  /// Safely process a JSON boolean field and convert to a bool.
  static bool fieldAsBool(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    final asString = Model.fieldAsString(json, fieldName);
    if (asString.isEmpty) return false;
    if (asString == '1' || asString.toLowerCase() == 'true') return true;
    return false;
  }

  /// Safely process a JSON timestamp field and convert it into a DateTime.
  static DateTime? fieldAsDateTime(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    try {
      final asNum = fieldAsNum(json, fieldName);
      if (asNum == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(asNum.toInt() * 1000);
    } on Exception catch (_) {
      return null;
    }
  }
}
