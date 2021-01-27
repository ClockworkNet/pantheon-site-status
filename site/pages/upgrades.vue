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
          <template v-slot:item.issueSummary="{ item }">
            <v-icon small :color="item.issueSummary">{{
              getIcon(item.issueSummary)
            }}</v-icon>
          </template>
          <template v-slot:expanded-item="{ headers, item }">
            <td :colspan="headers.length">
              <h3>Issues</h3>
              <ul>
                <li v-for="issue in item.issues" :key="issue">
                  <v-icon small color="red" v-if="issue.red">mdi-alert</v-icon>
                  <v-icon small color="yellow" v-if="issue.yellow"
                    >mdi-alert</v-icon
                  >
                  {{ issue.red }}{{ issue.yellow }}
                </li>
              </ul>
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
        <v-card-actions>
          <v-spacer />
          <v-btn
            color="primary"
            href="https://dashboard.pantheon.io/organizations/fffc93bd-ab50-42e2-8219-676ac29837d0#sites/sites"
            target="_blank"
            >Pantheon</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-col>
  </v-row>
</template>

<script>
import { mapGetters } from "vuex";
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
        { text: "Issues", value: "issueSummary" },
        { text: "CMS", value: "cms" },
        { text: "CMS Version", value: "cms_version" },
        { text: "CMS Status", value: "cms_version_stability" },
        { text: "PHP", value: "php_version" },
        { text: "PHP Status", value: "php_version_stability" },
        { text: "Upstream", value: "upstream_status" },
        { text: "New Relic", value: "new_relic_status" },
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
        // newSite.cms = `${site.cms} ${site.cms_version}`;
        newSite.dashboardLink = `https://dashboard.pantheon.io/sites/${site.pantheon_id}`;
        newSite.issueSummary = site.issues.find((issue) => issue["red"])
          ? "red"
          : site.issues.find((issue) => issue["yellow"])
          ? "yellow"
          : "green";
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
};
</script>
