import sites from '~/data/sites.json'
import { buildPluginToSiteMap } from '~/utils/pluginAggregation'
import { parseSitesPayload } from '~/utils/sitesPayload'

const payload = parseSitesPayload(sites)

export const state = () => ({
  list: payload.list,
  generatedAt: payload.generatedAt
})

export const mutations = {
}

export const getters = {
  tags: state =>
    [...new Set(state.list.reduce((allTags, site) => allTags.concat(site.tags), []))],
  pluginToSiteMap: state => buildPluginToSiteMap(state.list)
}
