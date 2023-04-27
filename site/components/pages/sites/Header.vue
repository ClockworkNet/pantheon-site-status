<template>
  <div class="search-row">
    <v-row>
      <v-col cols="6">
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
          v-model="searchValue"
          v-on:change="searchChange"
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
          clearable
          label="Team"
          :items="tagOptions"
          v-model="selectedTagsValue"
        >
          <template v-slot:selection="{ item, index }">
            <span v-if="index === 0" class="grey--text">
              {{ item.value }}
            </span>
          </template>
        </v-select>
      </v-col>
    </v-row>
    </div>
</template>

<script>
export default {
  props: [
    'search',
    'selectedTags'
  ],
  emits: [
    'update:search',
    'update:selectedTags'
  ],
  methods: {
    searchChange(newValue) { console.info(newValue), this.searchValue = newValue },
  },
  computed: {
    searchValue: {
      get() {
        return this.search
      },
      set(value) {
        this.$emit('update:search', value)
      }
    },
    selectedTagsValue: {
      get() {
        return this.selectedTags
      },
      set(value) {
        console.info(value);
        this.$emit('update:selectedTags', value)
      }
    },
    tags() { return this.$store.getters['sites/tags'] },
    tagOptions() { return this.tags.map((tagSlug) => {
      return {
        text: tagSlug.split(/[-_ ]/).map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()).join(' '),
        value: tagSlug
      }
    }) }
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
