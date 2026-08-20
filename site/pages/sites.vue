<template>
  <v-row justify="center" dense>
    <v-col cols="12">
      <PagesSitesHeader
        :search="search"
        :selected-tags="selectedTags"
        @update:search="search = $event"
        @update:selectedTags="selectedTags = $event"
        @download-csv="downloadCsv"
      />
      <PagesSitesTable :search="search" :filters="filters" :sites="filtered" />

      <div class="sites-footer">
        <template>
          <v-expansion-panels>
            <v-expansion-panel
              :key="0"
            >
              <v-expansion-panel-header>
                Advanced Filters
              </v-expansion-panel-header>
              <v-expansion-panel-content>
                <v-row>
                  <v-col cols="4">
                    <v-select
                      v-model="filters['cms']"
                      flat
                      hide-details
                      small
                      multiple
                      clearable
                      label="Filter CMS"
                      :items="columnValueList('cms')"
                    >
                      <template #selection="{ index }">
                        <span v-if="index === 0" class="grey--text caption">
                          ({{ filters["cms"].length }} selected)
                        </span>
                      </template>
                    </v-select>
                  </v-col>
                  <v-col cols="4">
                    <v-select
                      v-model="filters['cms_version_status']"
                      flat
                      hide-details
                      small
                      multiple
                      clearable
                      label="CMS Status"
                      :items="columnValueList('cms_version_status')"
                    >
                      <template #selection="{ index }">
                        <span v-if="index === 0" class="grey--text caption">
                          ({{ filters["cms"].length }} selected)
                        </span>
                      </template>
                    </v-select>
                  </v-col>
                  <v-col cols="4">
                    <v-select
                      v-model="filters['php_version_status']"
                      flat
                      hide-details
                      small
                      multiple
                      clearable
                      label="PHP status"
                      :items="columnValueList('php_version_status')"
                    >
                      <template #selection="{ index }">
                        <span v-if="index === 0" class="grey--text caption">
                          ({{ filters["cms"].length }} selected)
                        </span>
                      </template>
                    </v-select>
                  </v-col>
                </v-row>
              </v-expansion-panel-content>
            </v-expansion-panel>
          </v-expansion-panels>
        </template>
      </div>
    </v-col>
  </v-row>
</template>

<script>
import { needsUpgrade } from '~/utils/pluginStatus'
import { buildSitesCsv, downloadSitesCsv, sitesCsvFilename } from '~/utils/sitesCsv'

export default {
  data () {
    return {
      search: '',
      selectedTags: '',
      filters: {
        cms: [],
        cms_version_status: [],
        php_version_status: []
      }
    }
  },
  computed: {
    sites () {
      return this.$store.state.sites.list.map((site) => {
        const newSite = { ...site }
        newSite.dashboardLink = `https://dashboard.pantheon.io/sites/${site.pantheon_id}`
        newSite.issueLevel = this.getOveralIssueLevel(site.issues)
        newSite.issueSummary = this.getOveralIssueColor(site.issues)
        const pluginEntries = site.plugins ? Object.values(site.plugins) : []
        newSite.pluginEntries = pluginEntries
        newSite.pluginUpgrades = site.plugins
          ? pluginEntries.filter(needsUpgrade)
          : []
        newSite.issueCount = site.issues.length
        newSite.issuePriority = '' + newSite.issueLevel + newSite.issueCount
        return newSite
      })
    },
    filtered () {
      console.info('filtered updated')
      return this.sites
        .filter(site => this.selectedTags && this.selectedTags.length > 0 ? site.tags.includes(this.selectedTags) : true)
        .filter((site) => {
          return Object.keys(this.filters).every((filter) => {
            return this.filters[filter].length < 1 || this.filters[filter].includes(site[filter])
          })
        })
    }
  },
  methods: {
    columnValueList (val) {
      return [
        ...new Set(
          this.$store.state.sites.list
            .filter(site => site[val] != null)
            .map(site => site[val])
        )
      ]
    },
    getOveralIssueLevel (issues) {
      return issues.find(issue => issue.level === 'alert')
        ? '10000'
        : issues.find(issue => issue.level === 'warning')
          ? '05000'
          : '00000'
    },
    getOveralIssueColor (issues) {
      return issues.find(issue => issue.level === 'alert')
        ? 'red'
        : issues.find(issue => issue.level === 'warning')
          ? 'yellow'
          : 'green'
    },
    downloadCsv () {
      const csv = buildSitesCsv(this.filtered, { search: this.search })
      downloadSitesCsv(csv, sitesCsvFilename(this.$store.state.sites.generatedAt))
    }
  }
}
</script>

<style scoped>
.uppercase {
  text-transform: uppercase;
}
.sites-footer {
  margin-top: 20px;
}
</style>
