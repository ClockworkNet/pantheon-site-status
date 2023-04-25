<template>
  <v-row justify="center" align="center">
    <v-col md="3" sm="6">
      <SiteSummaryCard param="cms" label="CMS" />
    </v-col>
    <v-col md="3" sm="6">
      <SiteSummaryCard param="cms_version_status" label="CMS Stability" />
    </v-col>
    <v-col md="3" sm="6">
      <SiteSummaryCard param="php_version" label="PHP Versions" />
    </v-col>
    <v-col md="3" sm="6">
      <SiteSummaryCard param="upstream_status" label="Upstreams" />
    </v-col>
    <v-col md="3" sm="6">
      <SiteSummaryCard param="new_relic_status" label="New Relic" />
    </v-col>
  </v-row>
</template>

<script>
import SiteSummaryCard from "../components/SiteSummaryCard";
export default {
  data() {
    return {};
  },
  computed: {
    sites() {
      return this.$store.state.sites.list;
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
  components: {
    SiteSummaryCard,
  },
};
</script>
