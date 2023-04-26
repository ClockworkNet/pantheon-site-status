<template>
  <div class="search-row">
    <v-row>
      <v-col cols="9">
        <h1>
          Sites
          <v-tooltip bottom>
            <template v-slot:activator="{ on, attrs }">
              <v-icon class="help_icon" color="black" size="x-small" v-on="on" v-bind="attrs">mdi-help</v-icon>
            </template>
            <span>Clockwork sites hosted on Pantheon</span>
          </v-tooltip>
        </h1>
      </v-col>
      <v-col cols="3">
        <v-text-field
          v-model="value"
          v-on="$listeners"
          append-icon="mdi-magnify"
          label="Search"
          single-line
          hide-details
        ></v-text-field>
      </v-col>
    </v-row>
    </div>
</template>

<script>
export default {
  props: ['search'],
  emits: ['update:search'],
  computed: {
    value: {
      get() {
        return this.search
      },
      set(value) {
        this.$emit('update:search', value)
      }
    }
  }
}
</script>

<style scoped>
.search-row {
  margin-bottom: 20px;
}

.help_icon {
  background: #999;
  border-radius: 9999px;
  padding: 2px;
}
</style>
