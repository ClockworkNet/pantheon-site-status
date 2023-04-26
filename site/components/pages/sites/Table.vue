<template>
  <v-card>
    <v-data-table
      :headers="headers"
      :items="sites"
      :search="search"
      :multi-sort="false"
      :expanded.sync="expanded"
      item-key="name"
      show-expand
    >
      <template v-slot:item.issuePriority="{ item }">
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
</template>

<script>
export default {
  props: [
    'sites',
  ],
  data() {
    return {
      expanded: [],
      headers: [
        {
          text: "Site",
          align: "start",
          value: "name",
        },
        { text: "Issues", value: "issuePriority" },
        { text: "CMS", value: "cmsDisplay" },
        { text: "CMS Status", value: "cms_version_status" },
        { text: "Plugin V/U/T", value: "pluginDisplay" },
        { text: "PHP", value: "phpDisplay" },
        { text: "Actions", value: "actions", sortable: false, align: "end" },
      ]
    }
  },
  methods: {

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
  }
}
</script>
