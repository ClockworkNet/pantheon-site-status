import { describe, expect, it } from 'vitest'
import {
  buildSitesCsv,
  csvEscape,
  siteMatchesSearch,
  sitesCsvFilename
} from '../utils/sitesCsv'

describe('csvEscape', () => {
  it('returns empty string for nullish values', () => {
    expect(csvEscape(null)).toBe('')
    expect(csvEscape(undefined)).toBe('')
  })

  it('leaves simple values unquoted', () => {
    expect(csvEscape('alpha')).toBe('alpha')
    expect(csvEscape(3)).toBe('3')
  })

  it('quotes values that contain commas, quotes, or newlines', () => {
    expect(csvEscape('a, b')).toBe('"a, b"')
    expect(csvEscape('say "hi"')).toBe('"say ""hi"""')
    expect(csvEscape('line1\nline2')).toBe('"line1\nline2"')
  })
})

describe('siteMatchesSearch', () => {
  const site = {
    name: 'alpha-site',
    cms_version: '6.4.2',
    php_version: '8.1',
    issueCount: 2
  }

  it('matches when search is empty', () => {
    expect(siteMatchesSearch(site, '')).toBe(true)
    expect(siteMatchesSearch(site, '   ')).toBe(true)
  })

  it('matches against visible table fields', () => {
    expect(siteMatchesSearch(site, 'ALPHA')).toBe(true)
    expect(siteMatchesSearch(site, '6.4')).toBe(true)
    expect(siteMatchesSearch(site, '8.1')).toBe(true)
    expect(siteMatchesSearch(site, '2')).toBe(true)
  })

  it('rejects non-matching search', () => {
    expect(siteMatchesSearch(site, 'beta')).toBe(false)
  })
})

describe('buildSitesCsv', () => {
  const sites = [
    {
      name: 'alpha',
      url: 'https://alpha.example',
      cms: 'wordpress',
      is_multisite: false,
      cms_version: '6.4.2',
      cms_version_status: 'current',
      php_version: '8.1',
      php_version_status: 'supported',
      upstream_status: 'current',
      new_relic_status: 'enabled',
      pluginEntries: [{ slug: 'akismet' }, { slug: 'yoast' }],
      pluginUpgrades: [{ slug: 'akismet' }],
      issueCount: 1,
      issueSummary: 'yellow',
      issues: [{ description: 'PHP warning' }],
      tags: ['marketing'],
      dashboardLink: 'https://dashboard.pantheon.io/sites/abc'
    },
    {
      name: 'beta, site',
      url: 'https://beta.example',
      cms: 'wordpress_network',
      is_multisite: true,
      cms_version: '6.3.0',
      php_version: '8.2',
      pluginEntries: [],
      pluginUpgrades: [],
      issueCount: 0,
      issueSummary: 'green',
      issues: [],
      tags: []
    }
  ]

  it('writes a header and one row per matching site', () => {
    const csv = buildSitesCsv(sites)
    const lines = csv.split('\n')

    expect(lines[0]).toContain('Site')
    expect(lines[0]).toContain('WP Version')
    expect(lines).toHaveLength(3)
    expect(lines[1]).toContain('alpha')
    expect(lines[1]).toContain('warning')
    expect(lines[1]).toContain('PHP warning')
    expect(lines[2]).toContain('"beta, site"')
    expect(lines[2]).toContain('yes')
  })

  it('applies search the same way the table does', () => {
    const csv = buildSitesCsv(sites, { search: 'beta' })
    const lines = csv.split('\n')

    expect(lines).toHaveLength(2)
    expect(lines[1]).toContain('beta, site')
    expect(lines[1]).not.toContain('alpha')
  })

  it('handles a missing site list', () => {
    expect(buildSitesCsv(null).split('\n')).toHaveLength(1)
  })
})

describe('sitesCsvFilename', () => {
  it('uses the UTC date from generated_at', () => {
    expect(sitesCsvFilename('2026-08-20T06:00:00.000Z')).toBe('pantheon-sites-2026-08-20.csv')
  })

  it('falls back when the timestamp is invalid', () => {
    expect(sitesCsvFilename('not-a-date')).toBe('pantheon-sites.csv')
  })
})
