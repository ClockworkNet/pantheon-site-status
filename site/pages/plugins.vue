<template>
  <v-row justify="center" align="center">
    <v-col cols="12">
      <v-card>
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
          </v-row>
        </v-card-text>
        <v-data-table
          :headers="headers"
          :items="plugins"
          :search="search"
          :multi-sort="true"
          :expanded.sync="expanded"
          item-key="name"
          show-expand
          :sort-by="['sitesCount', 'name']"
          :sort-desc="[true, false]"
        >
          <template v-slot:expanded-item="{ headers, item }">
            <td :colspan="headers.length">
              <v-row>
                <v-col>
                  <v-card :elevation="0">
                    <v-list>
                      <v-subheader class="uppercase">Sites</v-subheader>
                      <template v-for="site in item.sites">
                        <v-list-item :key="site.name">
                          <v-list-item-content>{{
                            site.name
                          }}</v-list-item-content>
                          <v-list-item-content class="align-end">
                            {{ site.version }}
                          </v-list-item-content>
                        </v-list-item>
                        <v-divider :key="site.name"></v-divider>
                      </template>
                    </v-list>
                  </v-card>
                </v-col>
              </v-row>
            </td>
          </template>
        </v-data-table>
        <v-card-actions> </v-card-actions>
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
          text: "Plugin",
          align: "start",
          value: "name",
        },
        { text: "Sites", value: "sitesCount" },
        { text: "Upgrades", value: "upgradesCount" },
        { text: "Latest", value: "latest" },
      ],
    };
  },
  computed: {
    ...mapGetters("sites", ["pluginToSiteMap"]),
    plugins() {
      return Object.values(this.pluginToSiteMap).map((plugin) => {
        let newPlugin = { ...plugin };
        newPlugin.sitesCount = plugin.sites.length;
        newPlugin.upgradesCount = plugin.upgrades.length;
        return newPlugin;
      });
    },
  },
  methods: {},
  components: {},
};
</script>

<style scoped>
.uppercase {
  text-transform: uppercase;
}
</style>
