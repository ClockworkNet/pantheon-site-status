<template>
  <v-row justify="center" align="center">
    <v-col md="3" sm="6">
      <v-card>
        <v-card-title class="subheading font-weight-bold"> CMSs </v-card-title>
        <v-divider></v-divider>
        <v-list dense>
          <v-list-item v-for="cms in cmsOptions" :key="cms">
            <v-list-item-content>{{ cms }}</v-list-item-content>
            <v-list-item-content class="align-end">
              {{ countByParam("cms", cms).length }}
            </v-list-item-content>
          </v-list-item>
        </v-list>
      </v-card>
    </v-col>

    <v-col md="3" sm="6">
      <v-card>
        <v-card-title class="subheading font-weight-bold">
          CMS Stability
        </v-card-title>
        <v-divider></v-divider>
        <v-list dense>
          <v-list-item
            v-for="item in optionsByParam('cms_version_stability')"
            :key="item"
          >
            <v-list-item-content>{{ item + "" }}</v-list-item-content>
            <v-list-item-content class="align-end">
              {{ countByParam("cms_version_stability", item).length }}
            </v-list-item-content>
          </v-list-item>
        </v-list>
      </v-card>
    </v-col>
  </v-row>
</template>

<script>
import { mapGetters } from "vuex";
export default {
  data() {
    return {};
  },
  computed: {
    sites() {
      return this.$store.state.sites.list;
    },
    cmsOptions() {
      return [...new Set(this.sites.map((site) => site.cms))];
    },
  },
  methods: {
    countByParam(param, name) {
      return this.sites.filter((site) => site[param] == name);
    },
    optionsByParam(param) {
      return [...new Set(this.sites.map((site) => site[param]))];
    },
  },
};
</script>
