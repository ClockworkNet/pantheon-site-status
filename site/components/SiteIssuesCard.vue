<template>
  <v-card :elevation="0">
    <v-list>
      <v-subheader class="uppercase">Issues</v-subheader>
      <v-list-item v-for="issue in site.issues" :key="issue.description">
        <v-list-item-icon>
          <v-icon small :color="getIssueColor(issue.level)">{{
            getIcon(getIssueColor(issue.level))
          }}</v-icon>
        </v-list-item-icon>
        <v-list-item-content>
          <v-list-item-title>{{ issue.description }}</v-list-item-title>
        </v-list-item-content>
      </v-list-item>
    </v-list>
  </v-card>
</template>

<script>
export default {
  data() {
    return {};
  },
  props: ["site"],
  computed: {
    sites() {
      return this.$store.state.sites.list;
    },
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
  },
};
</script>
