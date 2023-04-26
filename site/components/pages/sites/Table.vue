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
            <v-col>
              <v-card :elevation="0">
                <v-list>
                  <v-list-item>
                    <v-list-item-icon>
                      <PagesSitesIssueIconForField fieldName="plugin" :site="item"></PagesSitesIssueIconForField>
                    </v-list-item-icon>
                    <v-list-item-content>
                      Plugins
                    </v-list-item-content>
                    <v-list-item-content class="align-end">
                      Vulnerable: {{ item.pluginVulnerabilities.length }}<br>
                      Upgrade: {{ item.pluginUpgrades.length }}<br>
                      Total: {{ item.pluginEntries.length }}<br>
                    </v-list-item-content>
                  </v-list-item>
                  <v-divider></v-divider>
                  <v-list-item>
                    <v-list-item-icon>
                      <PagesSitesIssueIconForField fieldName="cms_version_status" :site="item"></PagesSitesIssueIconForField>
                    </v-list-item-icon>
                    <v-list-item-content>
                      CMS
                    </v-list-item-content>
                    <v-list-item-content class="align-end">
                      {{ item.cms }}<br>
                      {{ item.cms_version }}<br>
                      {{ item.cms_version_status }}
                    </v-list-item-content>
                  </v-list-item>
                  <v-divider></v-divider>
                  <v-list-item>
                    <v-list-item-icon>
                      <PagesSitesIssueIconForField fieldName="upstream_status" :site="item"></PagesSitesIssueIconForField>
                    </v-list-item-icon>
                    <v-list-item-content>Upstream</v-list-item-content>
                    <v-list-item-content class="align-end">
                      {{ item.upstream_status }}
                    </v-list-item-content>
                  </v-list-item>
                  <v-divider></v-divider>
                  <v-list-item>
                    <v-list-item-icon>
                      <PagesSitesIssueIconForField fieldName="php_version_status" :site="item"></PagesSitesIssueIconForField>
                    </v-list-item-icon>
                    <v-list-item-content>PHP</v-list-item-content>
                    <v-list-item-content class="align-end">
                      {{ item.php_version }}<br>
                      {{ item.php_version_status }}
                    </v-list-item-content>
                  </v-list-item>
                  <v-divider></v-divider>
                  <v-list-item>
                    <v-list-item-icon>
                      <PagesSitesIssueIconForField fieldName="new_relic_status" :site="item"></PagesSitesIssueIconForField>
                    </v-list-item-icon>
                    <v-list-item-content>New Relic</v-list-item-content>
                    <v-list-item-content class="align-end">
                      {{ item.new_relic_status }}
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
    'search',
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
        { text: "Issues", value: "issuePriority", width: 100 },
        { text: "Actions", value: "actions", sortable: false, align: "end", width: 75 },
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

<style scoped>
.v-list-item__icon {
  align-self: auto;
}
</style>
