# PRD 01 — Correctness & Public-Exposure Fixes

**Status:** Done
**Priority:** P0 — do this iteration first, independent of everything else
**Depends on:** nothing
**Source:** [docs/RECOMMENDATIONS.md](../../RECOMMENDATIONS.md) §1 items 1-2

## Problem

Two live bugs make the dashboard's headline security signal (plugin vulnerabilities) actively wrong:

1. Every WordPress plugin on every site currently displays as "vulnerable" in the site detail modal, because [site/pages/sites.vue:114](../../../site/pages/sites.vue) filters on `plugin.vulnerable !== ""` when the real "not vulnerable" sentinel is the string `"None"`. This was correct once (git history, commit `0228fa6`) and regressed.
2. The Plugins page aggregates plugin data across sites keyed by array index instead of plugin slug ([site/store/sites.js:18-19](../../../site/store/sites.js)), so per-plugin site/upgrade counts are wrong whenever two sites list plugins in a different order.

A third item — the generated JSON being published to a public, unauthenticated S3/CloudFront bucket — was originally scoped here but has been split out into [PRD 06](06-restrict-public-dashboard-access.md), since it's an infrastructure/access-control decision rather than a code fix, and needs AWS access this repo/session doesn't have. Don't lose track of it: once real vulnerability detection is restored (see the follow-up task spawned below), that public bucket will start correctly and accurately publishing which client sites are exploitable.

## Goals

- Plugin vulnerability status and cross-site plugin counts are correct.

## Non-goals

- Redesigning the plugins/sites UI.
- Changing what data is collected — only how it's filtered/keyed/exposed.
- Restricting public access to the published dashboard — see [PRD 06](06-restrict-public-dashboard-access.md).

## Requirements

### R1 — Fix vulnerable-plugin filter
- Change the filter in `sites.vue` to treat `"None"` (not `""`) as "not vulnerable."
- Grep the codebase for any other place comparing `vulnerable`/`vulnerableDescription` against `""` and fix the same way (evaluator's own check at [evaluator/lib/evaluator.dart:96](../../../evaluator/lib/evaluator.dart) already uses `"None"` correctly — use it as the reference).
- **Update, found during real-data verification:** real `wp launchcheck plugins --format=json` output never actually includes a `vulnerable` key at all — confirmed against a live run against all 69 org sites. `Model.fieldAsString` defaults a missing field to `''`, not `'None'`. So both `evaluator.dart`'s own check (`== 'None'`) and the `sites.vue` fix above (`!== 'None'`) miss real data entirely — every plugin was being flagged as vulnerable in both the Dart-generated `issues` list and the frontend modal. Fixed by treating **both `''` and `'None'`** as "not vulnerable" in both `evaluator.dart` (`_evaluateWordPress`) and `sites.vue`. Verified against the real `site/data/sites.json` from that run: 0 of 1,727 real plugin records now falsely flagged, versus 1,727 (100%) before this follow-up fix.
- **Separate, not-yet-scoped problem:** the vulnerability-detection feature itself appears non-functional at the data source — `launchcheck` isn't returning any vulnerability info on any site right now, likely because the vulnerability-database component of the WP-CLI `launchcheck` package needs configuring/updating, or requires a separate API subscription. Fixing the empty/None handling stops the false positives, but doesn't restore real vulnerability detection. Worth its own investigation — flagged as follow-up, not blocking this PRD.

### R2 — Fix plugin aggregation keys
- In `pluginToSiteMap` ([site/store/sites.js](../../../site/store/sites.js)), key the map by `plugin.slug`, not by `Object.entries` array index.
- Verify the Plugins page's Sites/Upgrades counts against a hand-checked sample of `site/data/sites.json` after the fix.

## Acceptance Criteria

- [x] For a WordPress site with at least one plugin whose `vulnerable` field is a real description (not `"None"`/empty), the site detail modal shows exactly that plugin under "Vulnerable," and no others. *(Verified twice: first with synthetic data, then against real production data from a full 69-site evaluator run — see "What's done" below.)*
- [x] For a WordPress site where every plugin's `vulnerable` field is `"None"` or empty, the modal shows 0 vulnerable plugins. *(Verified against real data: 0 of 1,727 real plugin records flagged after the fix, confirmed live in-browser on `pimento-relief-services` — Vulnerable: 0, Upgrade Available: 9, Total: 16.)*
- [x] The Plugins page shows one row per distinct plugin slug across the whole org, with a Sites count matching a manual count from `sites.json`. *(Verified with synthetic data: two different plugins at the same array index across two sites now produce two separate slug-keyed entries instead of colliding.)*

## What's done / what's blocked

- **R1 (vulnerable-plugin filter):** fixed in `site/pages/sites.vue` and `evaluator/lib/evaluator.dart` — both now treat `''` and `'None'` as "not vulnerable." Initial fix (comparing only against `'None'`) turned out to be insufficient once verified against real data — see the R1 update note above. The real bug was bigger than the git-history regression it looked like: real `launchcheck` output never populates `vulnerable` at all, so it defaults to `''`, not `'None'`.
- **R2 (plugin aggregation keys):** fixed in `site/store/sites.js` — `pluginToSiteMap` now keys on `plugin.slug` instead of the `Object.entries` array index, and iterates `site.plugins` directly.
- Both fixes verified twice: first against synthetic data reproducing the original failure conditions, then against a real, full 69-site evaluator run (`site/data/sites.json`, 60 enriched sites, 1,727 plugin records) — confirmed live in the browser and via direct data inspection. The `fetchWordPressPlugins` JSON-parsing hardening (logged separately under PRD 02) was also exercised for real during that run — no parse-failure warnings after 59% (the point where the previous run had hit multiple garbled-JSON sites).
- No automated test coverage exists yet for either fix — that's PRD 04's job; this PRD's changes are a good candidate for the first tests written there.
- This PRD's changes were merged to `main` via PR #7.

## Out of scope / follow-up

- Terminus error handling, Drupal evaluation, performance, and test coverage are covered in later PRDs and should not be bundled into this one.
- Restricting public access to the published dashboard: split out into [PRD 06](06-restrict-public-dashboard-access.md) — it's an AWS/access-control decision, not a code fix, and shouldn't block or be blocked by this PRD.
- A separate, deeper problem was found and flagged (not blocking this PRD): the vulnerability-detection feature itself is non-functional at the data source — `launchcheck` never returns real vulnerability data on any site right now. This PRD stops the false positives; it doesn't restore real detection. A background investigation task was spawned for this during verification.
