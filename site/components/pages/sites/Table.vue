<template>
  <v-card class="sites-modal-table">
    <v-data-table
      :headers="headers"
      :items="sites"
      :search="search"
      :multi-sort="false"
      item-key="name"
      :items-per-page="20"
      :fixed-header="true"
      sort-by="issuePriority"
      item-class="site-row"
      @click:row="rowClicked"
    >
      <!-- eslint-disable vue/valid-v-slot, vue/v-slot-style -- Vuetify's
           data-table uses dotted dynamic slot names (`item.<column>`) that
           eslint-plugin-vue's v-slot rules don't recognize and misparse as
           an invalid modifier; this is valid, documented Vuetify syntax. -->
      <template v-slot:item.cms_version="{ item }">
        <span :class="{ 'red--text': item.cms_version_status === 'insecure' }">{{ item.cms_version }}</span>
      </template>
      <template v-slot:item.issuePriority="{ item }">
        <v-icon small :color="item.issueSummary">
          {{
            getIcon(item.issueSummary)
          }}
        </v-icon><span v-if="item.issueCount > 0"> {{ item.issueCount }}</span>
      </template>
      <template v-slot:item.actions="{ item }">
        <!-- eslint-enable vue/valid-v-slot, vue/v-slot-style -->
        <v-menu bottom left>
          <template #activator="{ on, attrs }">
            <v-btn icon v-bind="attrs" v-on="on">
              <v-icon>mdi-dots-vertical</v-icon>
            </v-btn>
          </template>

          <v-list light>
            <v-list-item :href="item.url" target="_blank">
              <v-list-item-title>View Site</v-list-item-title>
            </v-list-item>
            <v-list-item :href="item.dashboardLink" target="_blank">
              <v-list-item-title>View In Pantheon</v-list-item-title>
            </v-list-item>
          </v-list>
        </v-menu>
      </template>
    </v-data-table>

    <div class="text-center">
      <v-dialog
        v-model="dialog"
        :overlay-opacity=".95"
        overlay-color="#333"
        width="500"
      >
        <v-card v-if="!!site">
          <v-card-title class="text-h5">
            {{ site.name }}
          </v-card-title>

          <v-card-text>
            <v-list>
              <v-list-item>
                <v-list-item-icon>
                  <PagesSitesIssueIconForField field-name="plugin" :site="site" />
                </v-list-item-icon>
                <v-list-item-content>
                  <span>
                    Plugins
                    <v-tooltip bottom>
                      <template #activator="{ on, attrs }">
                        <v-icon class="help_icon" color="black" size="x-small" v-bind="attrs" v-on="on">mdi-help</v-icon>
                      </template>
                      <span>CMS plugins installed on this site.</span>
                    </v-tooltip>
                  </span>
                </v-list-item-content>
                <v-list-item-content class="align-end">
                  Upgrade Available: {{ site.pluginUpgrades.length }}<br>
                  Total: {{ site.pluginEntries.length }}<br>
                </v-list-item-content>
              </v-list-item>
              <v-divider />
              <v-list-item>
                <v-list-item-icon>
                  <PagesSitesIssueIconForField field-name="cms_version_status" :site="site" />
                </v-list-item-icon>
                <v-list-item-content>
                  <span>
                    CMS
                    <v-tooltip bottom>
                      <template #activator="{ on, attrs }">
                        <v-icon class="help_icon" color="black" size="x-small" v-bind="attrs" v-on="on">mdi-help</v-icon>
                      </template>
                      <span>Content Management System powering this site.</span>
                    </v-tooltip>
                  </span>
                </v-list-item-content>
                <v-list-item-content class="align-end">
                  {{ site.cms }}<span v-if="site.is_multisite"> (Multisite)</span><br>
                  {{ site.cms_version }}<br>
                  {{ site.cms_version_status }}
                </v-list-item-content>
              </v-list-item>
              <v-divider />
              <v-list-item>
                <v-list-item-icon>
                  <PagesSitesIssueIconForField field-name="upstream_status" :site="site" />
                </v-list-item-icon>
                <v-list-item-content>
                  <span>
                    Upstream
                    <v-tooltip bottom>
                      <template #activator="{ on, attrs }">
                        <v-icon class="help_icon" color="black" size="x-small" v-bind="attrs" v-on="on">mdi-help</v-icon>
                      </template>
                      <span>CMS upgrades and updates from Pantheon available to install.</span>
                    </v-tooltip>
                  </span>
                </v-list-item-content>
                <v-list-item-content class="align-end">
                  {{ site.upstream_status }}
                </v-list-item-content>
              </v-list-item>
              <v-divider />
              <v-list-item>
                <v-list-item-icon>
                  <PagesSitesIssueIconForField field-name="php_version_status" :site="site" />
                </v-list-item-icon>
                <v-list-item-content>
                  <span>
                    PHP
                    <v-tooltip bottom>
                      <template #activator="{ on, attrs }">
                        <v-icon class="help_icon" color="black" size="x-small" v-bind="attrs" v-on="on">mdi-help</v-icon>
                      </template>
                      <span>Status of the back-end programming language that runs the CMS.</span>
                    </v-tooltip>
                  </span>
                </v-list-item-content>
                <v-list-item-content class="align-end">
                  {{ site.php_version }}<br>
                  {{ site.php_version_status }}
                </v-list-item-content>
              </v-list-item>
              <v-divider />
              <v-list-item>
                <v-list-item-icon>
                  <PagesSitesIssueIconForField field-name="new_relic_status" :site="site" />
                </v-list-item-icon>
                <v-list-item-content>
                  <span>
                    New Relic
                    <v-tooltip bottom>
                      <template #activator="{ on, attrs }">
                        <v-icon class="help_icon" color="black" size="x-small" v-bind="attrs" v-on="on">mdi-help</v-icon>
                      </template>
                      <span>A tool that developers use to troubleshoot issues with PHP, CMS code, slow sites, databases, down time, etc.</span>
                    </v-tooltip>
                  </span>
                </v-list-item-content>
                <v-list-item-content class="align-end">
                  {{ site.new_relic_status }}
                </v-list-item-content>
              </v-list-item>
            </v-list>
          </v-card-text>

          <v-divider />

          <v-card-actions>
            <v-spacer />
            <v-btn color="primary" text @click="dialog = false">
              Close
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </div>
  </v-card>
</template>

<script>
export default {
  props: [
    'search',
    'sites'
  ],
  data () {
    return {
      dialog: false,
      site: null,
      headers: [
        {
          text: 'Site',
          align: 'start',
          value: 'name'
        },
        { text: 'WP Version', value: 'cms_version', width: 120 },
        { text: 'Issues', value: 'issuePriority', width: 100 },
        { text: 'Actions', value: 'actions', sortable: false, align: 'end', width: 75 }
      ]
    }
  },
  methods: {

    getIssueColor (level) {
      return level === 'alert' ? 'red' : level === 'warning' ? 'yellow' : 'green'
    },
    getIcon (color) {
      switch (color) {
        case 'green':
          return 'mdi-check'
        case 'yellow':
          return 'mdi-alert'
        case 'red':
          return 'mdi-alert'
      }
    },
    rowClicked (site) {
      console.info(event)
      this.dialog = !this.dialog
      this.site = site
    }
  }
}
</script>

<style scoped>
.v-list-item__icon {
  align-self: auto;
}

.help_icon {
  background: #999;
  border-radius: 9999px;
  padding: 2px;
  display: inline-block;
}
</style>

<style>
.sites-modal-table tbody td {
  cursor: pointer;
}
</style>
