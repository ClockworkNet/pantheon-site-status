<template>
  <v-icon small :color="getIssueColor(issue?.level)">{{
    getIcon(getIssueColor(issue?.level))
  }}</v-icon>
</template>
<script>
export default {
  props: ["issue"],
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
}
</script>
