<template>
  <v-app dark>
    <v-navigation-drawer
      v-model="drawer"
      :mini-variant="miniVariant"
      :clipped="clipped"
      fixed
      app
    >
      <v-layout column justify-space-between fill-height>
        <v-list>
          <v-list-item
            v-for="(item, i) in items"
            :key="i"
            :to="item.to"
            router
            exact
          >
            <v-list-item-action>
              <v-icon>{{ item.icon }}</v-icon>
            </v-list-item-action>
            <v-list-item-content>
              <v-list-item-title v-text="item.title" />
            </v-list-item-content>
          </v-list-item>
        </v-list>
        <div class="d-flex justify-end">
          <v-btn icon @click.stop="miniVariant = !miniVariant">
            <v-icon
              >mdi-{{ `chevron-${miniVariant ? "right" : "left"}` }}</v-icon
            >
          </v-btn>
        </div>
      </v-layout>
    </v-navigation-drawer>
    <v-main>
      <v-container class="flex-grow-1">
        <nuxt />
      </v-container>
    </v-main>
    <!-- <v-navigation-drawer v-model="rightDrawer" :right="right" temporary fixed>
      <v-list>
        <v-list-item @click.native="right = !right">
          <v-list-item-action>
            <v-icon light> mdi-repeat </v-icon>
          </v-list-item-action>
          <v-list-item-title>Switch drawer (click me)</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer> -->
    <v-footer class="justify-end">
        &copy; {{ new Date().getFullYear() }} Clockwork
    </v-footer>
  </v-app>
</template>

<script>
export default {
  data() {
    return {
      clipped: true,
      drawer: false,
      fixed: true,
      items: [
        {
          icon: "mdi-chart-bubble",
          title: "Sites",
          to: "/",
        },
        {
          icon: "mdi-puzzle",
          title: "Plugin Use",
          to: "/plugins",
        },
        {
          icon: "mdi-apps",
          title: "Pantheon Overview",
          to: "/overview",
        },
      ],
      miniVariant: false,
      right: true,
      rightDrawer: false,
      title: "Clockwork's Pantheon Site Status",
    };
  },
};
</script>
