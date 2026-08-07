import sites from '~/data/sites.json'
import { buildPluginToSiteMap } from '~/utils/pluginAggregation'

export const state = () => ({
  list: sites
})

export const mutations = {
}

export const getters = {
  tags: state =>
    [...new Set(state.list.reduce((allTags, site) => allTags.concat(site.tags), []))],
  pluginToSiteMap: state => buildPluginToSiteMap(state.list)
}
