<template>
  <div class="search-row">
    <v-row>
      <v-col cols="5">
        <h1>
          Sites
          <v-tooltip bottom>
            <template #activator="{ on, attrs }">
              <v-icon class="help_icon" color="black" size="x-small" v-bind="attrs" v-on="on">
                mdi-help
              </v-icon>
            </template>
            <span>Clockwork sites hosted on Pantheon</span>
          </v-tooltip>
        </h1>
        <p v-if="formattedGeneratedAt" class="caption grey--text mb-0 data-updated">
          Data updated on {{ formattedGeneratedAt }}
        </p>
      </v-col>
      <v-col cols="3">
        <v-text-field
          v-model="searchValue"
          append-icon="mdi-magnify"
          label="Search"
          single-line
          hide-details
          @change="searchChange"
        />
      </v-col>
      <v-col cols="2">
        <v-select
          v-model="selectedTagsValue"
          flat
          hide-details
          small
          clearable
          label="Team"
          :items="tagOptions"
        >
          <template #selection="{ item, index }">
            <span v-if="index === 0" class="grey--text">
              {{ item.value }}
            </span>
          </template>
        </v-select>
      </v-col>
      <v-col cols="2" class="d-flex align-center justify-end">
        <v-btn outlined small @click="$emit('download-csv')">
          <v-icon left small>
            mdi-download
          </v-icon>
          CSV
        </v-btn>
      </v-col>
    </v-row>
  </div>
</template>

<script>
import { formatGeneratedAt } from '~/utils/sitesPayload'

export default {
  props: [
    'search',
    'selectedTags'
  ],
  emits: [
    'update:search',
    'update:selectedTags',
    'download-csv'
  ],
  computed: {
    searchValue: {
      get () {
        return this.search
      },
      set (value) {
        this.$emit('update:search', value)
      }
    },
    selectedTagsValue: {
      get () {
        return this.selectedTags
      },
      set (value) {
        console.info(value)
        this.$emit('update:selectedTags', value)
      }
    },
    formattedGeneratedAt () {
      return formatGeneratedAt(this.$store.state.sites.generatedAt)
    },
    tags () { return this.$store.getters['sites/tags'] },
    tagOptions () {
      return this.tags.map((tagSlug) => {
        return {
          text: tagSlug.split(/[-_ ]/).map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()).join(' '),
          value: tagSlug
        }
      })
    }
  },
  methods: {
    searchChange (newValue) { this.searchValue = newValue }
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
