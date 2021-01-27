<template>
  <v-row justify="center" align="center">
    <v-col cols="12">
      <v-card>
        <v-card-title class="headline"> Pantheon Site Status </v-card-title>
        <v-card-text>
          <v-row align="end">
            <v-col cols="3">
              <v-text-field
                v-model="search"
                append-icon="mdi-magnify"
                label="Search"
                single-line
                hide-details
              ></v-text-field>
            </v-col>
            <v-col cols="3">
              <v-select
                flat
                hide-details
                small
                multiple
                clearable
                label="Filter CMS"
                :items="columnValueList('cms')"
                v-model="filters['cms']"
              >
                <template v-slot:selection="{ item, index }">
                  <span v-if="index === 0" class="grey--text caption">
                    ({{ filters["cms"].length }} selected)
                  </span>
                </template>
              </v-select>
            </v-col>
            <v-col cols="3">
              <v-select
                flat
                hide-details
                small
                multiple
                clearable
                label="CMS Status"
                :items="columnValueList('cms_version_stability')"
                v-model="filters['cms_version_stability']"
              >
                <template v-slot:selection="{ item, index }">
                  <span v-if="index === 0" class="grey--text caption">
                    ({{ filters["cms"].length }} selected)
                  </span>
                </template>
              </v-select>
            </v-col>
            <v-col cols="3">
              <v-select
                flat
                hide-details
                small
                multiple
                clearable
                label="PHP status"
                :items="columnValueList('php_version_stability')"
                v-model="filters['php_version_stability']"
              >
                <template v-slot:selection="{ item, index }">
                  <span v-if="index === 0" class="grey--text caption">
                    ({{ filters["cms"].length }} selected)
                  </span>
                </template>
              </v-select>
            </v-col>
          </v-row>
        </v-card-text>
        <v-data-table
          :headers="headers"
          :items="filtered"
          :search="search"
          :multi-sort="true"
          :expanded.sync="expanded"
          item-key="name"
          show-expand
        >
          <template v-slot:item.issueCount="{ item }">
            <v-icon small :color="item.issueSummary">{{
              getIcon(item.issueSummary)
            }}</v-icon
            ><span v-if="item.issueCount > 0"> ({{ item.issueCount }})</span>
          </template>
          <template v-slot:expanded-item="{ headers, item }">
            <td :colspan="headers.length">
              <v-row>
                <v-col><SiteIssuesCard :site="item" /></v-col>
                <v-col>
                  <v-card :elevation="0">
                    <v-list>
                      <v-subheader class="uppercase">Tools</v-subheader>
                      <v-list-item>
                        <v-list-item-content>Upstream</v-list-item-content>
                        <v-list-item-content class="align-end">
                          {{ item.upstream_status }}
                        </v-list-item-content>
                      </v-list-item>
                      <v-divider></v-divider>
                      <v-list-item>
                        <v-list-item-content>New Relic</v-list-item-content>
                        <v-list-item-content class="align-end">
                          {{ item.new_relic_status }}
                        </v-list-item-content>
                      </v-list-item>
                      <v-divider></v-divider>
                    </v-list>
                  </v-card>
                </v-col>
                <v-col>
                  <v-card :elevation="0">
                    <v-list>
                      <v-subheader class="uppercase">Plugin V/U/T</v-subheader>
                      <v-list-item>
                        <v-list-item-content>Vulnerable</v-list-item-content>
                        <v-list-item-content class="align-end">
                          {{ item.pluginVulnerabilities.length }}
                        </v-list-item-content>
                      </v-list-item>
                      <v-divider></v-divider>
                      <v-list-item>
                        <v-list-item-content>Upgrade</v-list-item-content>
                        <v-list-item-content class="align-end">
                          {{ item.pluginUpgrades.length }}
                        </v-list-item-content>
                      </v-list-item>
                      <v-divider></v-divider>
                      <v-list-item>
                        <v-list-item-content>Total</v-list-item-content>
                        <v-list-item-content class="align-end">
                          {{ item.pluginEntries.length }}
                        </v-list-item-content>
                      </v-list-item>
                      <v-divider></v-divider>
                    </v-list>
                  </v-card>
                </v-col>
              </v-row>
            </td>
          </template>
          <template v-slot:item.actions="{ item }">
            <v-menu bottom left>
              <template v-slot:activator="{ on, attrs }">
                <v-btn icon v-bind="attrs" v-on="on">
                  <v-icon>mdi-dots-vertical</v-icon>
                </v-btn>
              </template>

              <v-list light>
                <v-list-item v-bind:href="item.url" target="_blank">
                  <v-list-item-title>View Site</v-list-item-title>
                </v-list-item>
                <v-list-item v-bind:href="item.dashboardLink" target="_blank">
                  <v-list-item-title>View In Pantheon</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
          </template>
        </v-data-table>
        <v-card-actions> </v-card-actions>
      </v-card>
    </v-col>
  </v-row>
</template>

<script>
import SiteIssuesCard from "../components/SiteIssuesCard";
export default {
  data() {
    return {
      search: "",
      expanded: [],
      headers: [
        {
          text: "Site",
          align: "start",
          value: "name",
        },
        { text: "Issues", value: "issueCount" },
        { text: "CMS", value: "cmsDisplay" },
        { text: "CMS Status", value: "cms_version_stability" },
        { text: "Plugin V/U/T", value: "pluginDisplay" },
        { text: "PHP", value: "phpDisplay" },
        { text: "Actions", value: "actions", sortable: false, align: "end" },
      ],
      filters: {
        cms: [],
        cms_version_stability: [],
        php_version_stability: [],
      },
    };
  },
  computed: {
    sites() {
      return this.$store.state.sites.list.map((site) => {
        let newSite = { ...site };
        newSite.dashboardLink = `https://dashboard.pantheon.io/sites/${site.pantheon_id}`;
        newSite.cmsDisplay = `${site.cms} ${site.cms_version}`;
        newSite.phpDisplay = `${site.php_version} ${site.php_version_stability}`;
        newSite.issueSummary = this.getOveralIssueColor(site.issues);
        const pluginEntries = site.plugins ? Object.values(site.plugins) : [];
        newSite.pluginEntries = pluginEntries;
        newSite.pluginUpgrades = site.plugins
          ? pluginEntries.filter((plugin) => plugin.needs_update !== "0")
          : [];
        newSite.pluginVulnerabilities = site.plugins
          ? pluginEntries.filter((plugin) => {
              console.info(plugin);
              return plugin.vulnerable !== "None";
            })
          : [];
        newSite.pluginDisplay = `${newSite.pluginVulnerabilities.length} / ${newSite.pluginUpgrades.length} / ${pluginEntries.length}`;
        newSite.issueCount = site.issues.length;
        return newSite;
      });
    },
    filtered() {
      return this.sites.filter((d) => {
        return Object.keys(this.filters).every((f) => {
          return this.filters[f].length < 1 || this.filters[f].includes(d[f]);
        });
      });
    },
  },
  methods: {
    columnValueList(val) {
      return [
        ...new Set(
          this.$store.state.sites.list
            .filter((site) => site[val] != null)
            .map((site) => site[val])
        ),
      ];
    },
    getOveralIssueColor(issues) {
      return issues.find((issue) => issue.level == "alert")
        ? "red"
        : issues.find((issue) => issue.level == "warning")
        ? "yellow"
        : "green";
    },
    getIssueColor(level) {
      return level == "alert" ? "red" : level == "warning" ? "yellow" : "green";
    },
    getIcon(color) {
      switch (color) {
        case "green":
          return "mdi-check";
          break;
        case "yellow":
          return "mdi-alert";
          break;
        case "red":
          return "mdi-alert";
          break;
      }
    },
  },
  components: {
    SiteIssuesCard,
  },
};
</script>

<style scoped>
.uppercase {
  text-transform: uppercase;
}
</style>
