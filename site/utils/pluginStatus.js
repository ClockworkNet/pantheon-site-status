// Pure predicate for a plugin record as serialized by the evaluator
// (evaluator/lib/models/wordpress_plugin.dart's toJson()). Kept separate
// from the components/store that use it so the exact condition that
// regressed once (see git history around the plugin-aggregation key bug)
// can be unit tested directly.

/** True if a plugin has a newer version available. */
export function needsUpgrade (plugin) {
  return plugin.needs_update !== '0'
}
