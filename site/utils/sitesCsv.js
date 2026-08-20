export const SITES_CSV_COLUMNS = [
  { key: 'name', label: 'Site' },
  { key: 'url', label: 'URL' },
  { key: 'cms', label: 'CMS' },
  { key: 'is_multisite', label: 'Multisite' },
  { key: 'cms_version', label: 'WP Version' },
  { key: 'cms_version_status', label: 'CMS Status' },
  { key: 'php_version', label: 'PHP Version' },
  { key: 'php_version_status', label: 'PHP Status' },
  { key: 'upstream_status', label: 'Upstream' },
  { key: 'new_relic_status', label: 'New Relic' },
  { key: 'plugin_upgrades', label: 'Plugin Upgrades' },
  { key: 'plugin_total', label: 'Plugin Total' },
  { key: 'issue_count', label: 'Issues' },
  { key: 'issue_level', label: 'Issue Level' },
  { key: 'issue_descriptions', label: 'Issue Details' },
  { key: 'tags', label: 'Team' },
  { key: 'dashboard_link', label: 'Pantheon Dashboard' }
]

export function csvEscape (value) {
  if (value == null) {
    return ''
  }

  const string = String(value)
  if (/[",\n\r]/.test(string)) {
    return `"${string.replace(/"/g, '""')}"`
  }

  return string
}

export function issueLevelLabel (issueSummary) {
  switch (issueSummary) {
    case 'red':
      return 'alert'
    case 'yellow':
      return 'warning'
    default:
      return 'ok'
  }
}

export function siteMatchesSearch (site, search) {
  if (!search || !String(search).trim()) {
    return true
  }

  const query = String(search).trim().toLowerCase()
  const fields = [
    site.name,
    site.cms_version,
    site.php_version,
    site.issueCount
  ]

  return fields.some(value =>
    value != null && String(value).toLowerCase().includes(query)
  )
}

export function siteToCsvRow (site) {
  const issues = Array.isArray(site.issues) ? site.issues : []
  const tags = Array.isArray(site.tags) ? site.tags : []
  const pluginEntries = Array.isArray(site.pluginEntries) ? site.pluginEntries : []
  const pluginUpgrades = Array.isArray(site.pluginUpgrades) ? site.pluginUpgrades : []

  return {
    name: site.name || '',
    url: site.url || '',
    cms: site.cms || '',
    is_multisite: site.is_multisite ? 'yes' : 'no',
    cms_version: site.cms_version || '',
    cms_version_status: site.cms_version_status || '',
    php_version: site.php_version || '',
    php_version_status: site.php_version_status || '',
    upstream_status: site.upstream_status || '',
    new_relic_status: site.new_relic_status || '',
    plugin_upgrades: pluginUpgrades.length,
    plugin_total: pluginEntries.length,
    issue_count: site.issueCount != null ? site.issueCount : issues.length,
    issue_level: issueLevelLabel(site.issueSummary),
    issue_descriptions: issues.map(issue => issue.description).filter(Boolean).join('; '),
    tags: tags.join(', '),
    dashboard_link: site.dashboardLink || ''
  }
}

export function buildSitesCsv (sites, { search } = {}) {
  const matching = (Array.isArray(sites) ? sites : []).filter(site =>
    siteMatchesSearch(site, search)
  )
  const header = SITES_CSV_COLUMNS.map(column => csvEscape(column.label)).join(',')
  const rows = matching.map((site) => {
    const row = siteToCsvRow(site)
    return SITES_CSV_COLUMNS.map(column => csvEscape(row[column.key])).join(',')
  })

  return [header, ...rows].join('\n')
}

export function sitesCsvFilename (generatedAt) {
  const date = generatedAt ? new Date(generatedAt) : new Date()
  if (Number.isNaN(date.getTime())) {
    return 'pantheon-sites.csv'
  }

  const year = date.getUTCFullYear()
  const month = String(date.getUTCMonth() + 1).padStart(2, '0')
  const day = String(date.getUTCDate()).padStart(2, '0')
  return `pantheon-sites-${year}-${month}-${day}.csv`
}

export function downloadSitesCsv (csv, filename) {
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}
