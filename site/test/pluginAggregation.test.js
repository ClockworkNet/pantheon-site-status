import { describe, expect, it } from 'vitest'
import { buildPluginToSiteMap } from '../utils/pluginAggregation'

describe('buildPluginToSiteMap', () => {
  it('keys plugins by slug, not by array position', () => {
    // Regression coverage: two different plugins sitting at the same
    // array index on different sites used to collide under a shared
    // numeric-index key ("0"), corrupting the Plugins page's cross-site
    // counts. They must produce two separate entries.
    const sites = [
      {
        name: 'site-alpha',
        plugins: [
          { slug: 'akismet', installed: '1.0', available: '1.1', needs_update: '1', vulnerable: '' }
        ]
      },
      {
        name: 'site-beta',
        plugins: [
          { slug: 'yoast-seo', installed: '2.0', available: '2.0', needs_update: '0', vulnerable: '' }
        ]
      }
    ]

    const map = buildPluginToSiteMap(sites)

    expect(Object.keys(map).sort()).toEqual(['akismet', 'yoast-seo'])
    expect(map.akismet.sites).toEqual([{ name: 'site-alpha', version: '1.0' }])
    expect(map.akismet.upgrades).toEqual(['site-alpha'])
    expect(map['yoast-seo'].sites).toEqual([{ name: 'site-beta', version: '2.0' }])
    expect(map['yoast-seo'].upgrades).toEqual([])
  })

  it('aggregates the same plugin across multiple sites correctly', () => {
    const sites = [
      {
        name: 'site-a',
        plugins: [{ slug: 'clean-plugin', installed: '1.9', available: '2.0', needs_update: '1', vulnerable: '' }]
      },
      {
        name: 'site-b',
        plugins: [{ slug: 'clean-plugin', installed: '2.0', available: '2.0', needs_update: '0', vulnerable: '' }]
      }
    ]

    const map = buildPluginToSiteMap(sites)

    expect(Object.keys(map)).toEqual(['clean-plugin'])
    expect(map['clean-plugin'].sites).toHaveLength(2)
    expect(map['clean-plugin'].upgrades).toEqual(['site-a'])
    expect(map['clean-plugin'].latest).toBe('2.0')
  })

  it('handles sites with no plugins and an empty site list', () => {
    expect(buildPluginToSiteMap([{ name: 'no-plugins-site' }])).toEqual({})
    expect(buildPluginToSiteMap([])).toEqual({})
    expect(buildPluginToSiteMap(null)).toEqual({})
  })
})
