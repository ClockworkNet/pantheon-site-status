import 'model.dart';

/// This model contains site data gathered from a variety of sources,
/// including: Pantheon, WordPress CLI, and Wordpress.org.
class WordPressPlugin extends Model {
  /// The slug for the plugin.
  final String slug;

  /// The installed version of the plugin.
  final String installedVersion;

  /// The newest available version of the plugin.
  final String availableVersion;

  /// True if the plugin needs an update.
  final bool needsUpdate;

  /// Description of any vulnerability. "None" if there are none.
  final String vulnerableDescription;

  /// Default constructor.
  const WordPressPlugin({
    this.slug = '',
    this.installedVersion = '',
    this.availableVersion = '',
    this.needsUpdate = false,
    this.vulnerableDescription = '',
  });

  /// Create the model from JSON.
  factory WordPressPlugin.fromJson(Map<String, dynamic> json) {
    return WordPressPlugin(
      slug: Model.fieldAsString(json, 'slug'),
      installedVersion: Model.fieldAsString(json, 'installed'),
      availableVersion: Model.fieldAsString(json, 'available'),
      needsUpdate: Model.fieldAsBool(json, 'needsUpdate'),
      vulnerableDescription: Model.fieldAsString(json, 'vulnerable'),
    );
  }

  /// Get a list of plugins from Panteon's plugin JSON.
  static List<WordPressPlugin> pluginsFromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return [];
    if (json.containsKey('plugins') != true) return [];
    if (json['plugins'].containsKey('alerts') != true) return [];

    var plugins = <WordPressPlugin>[];
    json['plugins']['alerts'].values.forEach((pluginJson) {
      plugins.add(WordPressPlugin.fromJson(pluginJson));
    });

    return plugins;
  }

  /// Convert a plugin to JSON.
  Map<String, dynamic> toJson() => {
        'slug': slug,
        'installed': installedVersion,
        'available': availableVersion,
        'needs_update': needsUpdate ? "1" : "0",
        'vulnerable': vulnerableDescription,
      };
}
