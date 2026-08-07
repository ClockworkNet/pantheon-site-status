# PRD 08 — WordPress Multisite Sites Silently Unevaluated

**Status:** Done
**Priority:** P1 — same class of issue as PRD 02's Drupal gap (false "clean" status), affecting live sites right now
**Depends on:** nothing
**Source:** discovered live while reviewing a real site's detail modal (user noticed a WordPress Multisite site showing a green checkmark for CMS despite `cms_version_status: "unknown"`)

## Problem

Pantheon reports WordPress Multisite installs with `framework: wordpress_network`, not `wordpress`. Both `evaluator.dart`'s `evaluateSite` and `sinfo_manager.dart`'s `_enrichSite` gated all WordPress-specific work behind an exact-match check: `site.cmsName == 'wordpress'`. Since multisite sites' `cmsName` is `wordpress_network`, they silently skipped:

- The WordPress core version fetch (`cms_version` stayed `""`)
- The version-stability check against wordpress.org (`cms_version_status` stayed `"unknown"`, never even reaching the `wordpressAlerts` lookup that would've flagged an unrecognized status as a `warning` — because `_evaluateWordPress` was never called at all)
- The plugin fetch and vulnerability evaluation (`plugins: []`, always)

The result: a WordPress Multisite site with an unknown CMS version and zero plugin data displayed a **green checkmark**, identical to a genuinely healthy site. This is the same class of bug fixed for Drupal in PRD 02 (silently-clean-looking unevaluated sites) — just for a Pantheon framework variant nobody had accounted for. Confirmed against real data: 2 of 60 currently active sites (`sugar-multisite`, `biw-main`) were affected.

## Goals

- WordPress Multisite sites get the same version/plugin/vulnerability evaluation as regular WordPress sites.
- The GUI makes it clear when a site is a multisite install, rather than only showing the raw `wordpress_network` framework string.

## Non-goals

- Handling any other exotic Pantheon `framework` values speculatively — only `wordpress_network` was observed in real data. If another variant surfaces later, extend `Site.isWordPress` then.
- Per-subsite plugin lists — R3 below fixes the *network's primary site* resolving correctly (so `wp` commands succeed at all on networks where a custom domain was set as `DOMAIN_CURRENT_SITE`), not enumerating every individual subsite in the network.

## Requirements

### R1 — Recognize wordpress_network as WordPress for evaluation purposes
- Added `Site.isWordPress` getter (`evaluator/lib/models/site.dart`): true for `cmsName == 'wordpress'` or `'wordpress_network'`.
- `evaluator.dart`'s `evaluateSite` and `sinfo_manager.dart`'s `_enrichSite` now check `site.isWordPress` instead of the exact-match string comparison.

### R2 — Indicate multisite status in the GUI
- Added `Site.isMultisite` getter and `is_multisite` boolean to `Site.toJson()`.
- `site/components/pages/sites/Table.vue`'s site detail modal now appends `(Multisite)` next to the CMS name when `site.is_multisite` is true.

### R3 — Resolve the network's real primary domain, and stop hiding fetch failures as "zero plugins"
Found live during manual review after R1/R2 shipped: some multisite networks have a custom domain set as `DOMAIN_CURRENT_SITE` rather than the Pantheon platform URL, so any `wp` command needing to bootstrap WordPress against the site's own live URL fails with `Site '<url>' not found. Verify DOMAIN_CURRENT_SITE matches an existing site or use --url=<url> to override` — `wp core version` still succeeds (it doesn't need to resolve a specific blog), but `wp launchcheck plugins` doesn't, so plugin data silently came back empty and looked identical to a genuinely plugin-free site.
- Added `Pantheon.fetchMultisitePrimaryDomain` (`evaluator/lib/pantheon.dart`): runs `wp db query "SELECT domain FROM wp_blogs WHERE blog_id = 1" --skip-column-names` directly against the database, bypassing WP-CLI's URL-based site resolution entirely (a raw DB query doesn't need to resolve a "current site" by incoming host), and returns the network's actual registered primary domain.
- `fetchWordPressVersion` and `fetchWordPressPlugins` now accept an optional `url` param, passed as `--url=<domain>` when present. `sinfo_manager.dart`'s `_enrichSite` resolves this domain (only for `isMultisite` sites) before calling either.
- `fetchWordPressPlugins` now returns `List<WordPressPlugin>?` instead of always returning `[]` on failure — `null` means "the fetch failed," a real `[]` means "fetched successfully, genuinely zero plugins." Added `Site.pluginFetchFailed` (not serialized directly) and `_evaluateWordPress` now emits a `warning`-severity `plugin` issue when it's true, so a failed fetch is visibly distinct from a clean site instead of both showing the same green checkmark.

## What's done

- All of R1 and R2 implemented and verified:
  - `dart analyze` clean.
  - Added regression tests: `evaluator/test/models/site_test.dart` (`isWordPress`/`isMultisite`/`toJson` groups) and `evaluator/test/evaluator_test.dart` (a `wordpress_network` site with a vulnerable plugin now produces both a `plugin` issue and a `cms_version_status` issue). All 18 evaluator tests pass.
  - Verified live against a real affected site (`sugar-multisite`) with a standalone script: before the fix this site fetched 0 plugins and `cmsVersion: ''`; after the fix it correctly fetches `cmsVersion: '7.0.2'` (→ `insecure`, matching wordpress.org's real stable-check data) and 17 real plugins, and `evaluateSite` now produces the expected `alert`-level `cms_version_status` issue.
  - Verified the GUI change live in the browser (with a temporary synthetic patch to local dev data, since a full evaluator run takes ~10 minutes): the site detail modal correctly shows `wordpress_network (Multisite)` with a red alert icon, version, and status, replacing the previous false-clean green checkmark.
  - `site/data/sites.json` (gitignored, not committed) was regenerated with a real full evaluator run after R1/R2 to reflect accurate data for local dev — confirmed both affected sites now correctly show `is_multisite: true`, real `cms_version`/`cms_version_status` (both `7.0.2` → `insecure`). That run is what surfaced the R3 gap (`biw-main` still showed 0 plugins despite the CMS fix working).
- **R3** implemented and verified directly against the real, live sites (not just synthetic data):
  - `terminus wp -y biw-main.live -- db query "SELECT domain, path FROM wp_blogs WHERE blog_id = 1"` → `www.biworldwide.com` (one of ~38 custom domains on that network, none marked "primary" in `terminus domain:list` — confirming this couldn't have been guessed or hardcoded).
  - Confirmed the same query against `sugar-multisite` (the site that already worked) returns its own platform URL unchanged — proving this fix doesn't alter behavior for networks that didn't need it.
  - With the resolved domain passed as `--url`, `biw-main`'s plugin fetch went from failing (`pluginFetchFailed`) to **46 real plugins** fetched successfully; `sugar-multisite` stayed at 17 (unchanged).
  - Added `evaluator_test.dart` cases: a failed fetch (`pluginFetchFailed = true`) produces exactly one `warning`-severity `plugin` issue; a successful fetch with genuinely zero plugins produces no issue at all (the two cases that used to be indistinguishable). All 20 evaluator tests pass; `dart analyze` clean.
  - `site/data/sites.json` was regenerated again after this fix to reflect real, complete plugin data for `biw-main`.

## Acceptance Criteria

- [x] A WordPress Multisite site's CMS version, version status, and plugin list are fetched and evaluated exactly like a regular WordPress site's — including on networks where the platform URL doesn't match the registered `DOMAIN_CURRENT_SITE`.
- [x] A WordPress Multisite site with a real plugin vulnerability or outdated core version shows the correct alert/warning indicator, not a false-clean green checkmark.
- [x] A failed plugin fetch (for any reason) shows a visible warning, distinct from a genuinely plugin-free site.
- [x] The site detail modal visibly distinguishes a multisite install from a regular WordPress site.
- [x] Regression tests exist covering the evaluation-gating fix, the new `is_multisite` field, and the fetch-failure-vs-genuinely-empty distinction.
