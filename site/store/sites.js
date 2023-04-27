import sites from '~/data/sites.json';

export const state = () => ({
    list: sites
})

export const mutations = {
}

export const getters = {
    tags: (state) =>
      [...new Set(state.list.reduce((allTags, site) => allTags.concat(site.tags), []))],
    pluginToSiteMap: (state) => {
        let plugins = {};
        if (!state.list) return plugins;
        state.list.forEach((site, siteIndex) => {
            if (!site.plugins) return;
            Object.entries(site.plugins).forEach((entry, index) => {
                const key = entry[0];
                const plugin = entry[1];
                if (!plugins[key]) plugins[key] = {
                    name: plugin.slug,
                    sites: [],
                    upgrades: [],
                    latest: plugin.available
                };
                plugins[key].sites.push({ name: site.name, version: plugin.installed });
                if (plugin.needs_update !== '0') {
                    plugins[key].upgrades.push(site.name);
                }
            });
        });
        return plugins;
    }
}
