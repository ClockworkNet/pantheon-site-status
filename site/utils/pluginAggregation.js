import { needsUpgrade } from './pluginStatus'

/**
 * Build a cross-site map of plugin slug -> { name, sites, upgrades, latest }
 * from a list of sites (each with a `plugins` array, as serialized by the
 * evaluator).
 *
 * Keyed by plugin slug, not array position -- two different plugins that
 * happen to sit at the same index on different sites must not collide.
 */
export function buildPluginToSiteMap (sites) {
  const plugins = {}
  if (!sites) { return plugins }

  sites.forEach((site) => {
    if (!site.plugins) { return }
    site.plugins.forEach((plugin) => {
      const key = plugin.slug
      if (!plugins[key]) {
        plugins[key] = {
          name: plugin.slug,
          sites: [],
          upgrades: [],
          latest: plugin.available
        }
      }
      plugins[key].sites.push({ name: site.name, version: plugin.installed })
      if (needsUpgrade(plugin)) {
        plugins[key].upgrades.push(site.name)
      }
    })
  })

  return plugins
}
