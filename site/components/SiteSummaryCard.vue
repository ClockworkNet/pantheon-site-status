<template>
  <v-card>
    <v-card-title class="subheading font-weight-bold">
      {{ label }}
    </v-card-title>
    <v-divider></v-divider>
    <v-list dense>
      <v-list-item v-for="item in optionsByParam(param)" :key="item">
        <v-list-item-content>{{ item + "" }}</v-list-item-content>
        <v-list-item-content class="align-end">
          {{ countByParam(param, item).length }}
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
  props: ["param", "label"],
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
      return [...new Set(this.sites.map((site) => site[param]))].sort(function (
        a,
        b
      ) {
        if (a < b) {
          return -1;
        }
        if (a > b) {
          return 1;
        }
        return 0;
      });
    },
  },
};
</script>
