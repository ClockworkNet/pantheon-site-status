# PRD 04 — Test Coverage for the Bug-Prone Paths

**Status:** Done
**Priority:** P2
**Depends on:** PRD 01 (write tests against the corrected behavior, not the buggy one)
**Source:** [docs/RECOMMENDATIONS.md](../../RECOMMENDATIONS.md) §2 item 3

## Problem

The two confirmed bugs in PRD 01 both regressed silently — one was fixed once already (commit `0228fa6`) and reverted later with nothing to catch it. There's a Dart unit test on the `Site` model but no test covering plugin evaluation, plugin aggregation, or any Vue component logic. The exact two spots that broke in production are the exact two spots with zero test coverage.

## Goals

- The two previously-regressed behaviors (vulnerable-plugin filtering, plugin aggregation-by-slug) are locked in by tests that fail loudly if touched incorrectly again.
- A minimal but real frontend test setup exists so future Vue logic changes have somewhere to land tests.

## Non-goals

- Full test coverage of the entire codebase — this PRD targets the specific fragile paths identified, not a general coverage mandate.
- End-to-end/browser testing of the deployed site.

## Requirements

### R1 — Evaluator tests
- Add Dart tests covering `Evaluator._evaluateWordPress` / `evaluateSite`: a plugin with `vulnerableDescription == 'None'` produces no issue; any other value produces exactly one `alert`-severity issue referencing that plugin.
- Add a regression test asserting `WordPressPlugin.toJson()`'s `vulnerable` field round-trips as `"None"` for a non-vulnerable plugin (the exact value the frontend must match against).

### R2 — Frontend test setup + targeted tests
- Introduce a lightweight Vue test runner (e.g., Vitest or Jest, whichever integrates more easily with the existing Nuxt 2/Vue 2 toolchain — check for prior art before adding a second framework) since none currently exists in `site/`.
- Add a test for `pluginToSiteMap` in `site/store/sites.js` asserting: two different plugins at the same array index across two different sites produce two separate map entries keyed by slug, with correct per-plugin `sites`/`upgrades` counts.
- Add a test for the `sites.vue` `pluginVulnerabilities`/`pluginUpgrades` computed logic (extract into a testable pure function if needed) asserting `"None"` is treated as not-vulnerable and any other non-empty string is.

## What's done

- **`dart test` itself was broken all session** (unrelated to this PRD's actual scope, but blocking): the Homebrew-installed Dart 3.12.2 was missing `frontend_server.dart.snapshot`, a known community-reported issue caused by a stale transitive `frontend_server_client` dev-dependency (3.2.0, needed 4.0.0+). `brew reinstall dart` did *not* fix it (confirmed 3.12.2 is also the latest available, so upgrading wouldn't have helped either) — the actual fix was `dart pub upgrade` in `evaluator/`, which bumped `frontend_server_client` along with 49 other transitive deps. `dart test` now runs and passes cleanly.
- **R1**: added `evaluator/test/evaluator_test.dart` (5 tests covering `Evaluator._evaluateWordPress`/`evaluateSite`: `'None'` → no issue, `''` → no issue, a real vulnerability description → exactly one alert-severity issue naming the plugin, mixed plugins only flag the genuinely vulnerable one, and Drupal sites get the "not yet evaluated" warning from PRD 02) and `evaluator/test/models/wordpress_plugin_test.dart` (5 tests on `WordPressPlugin.fromJson`/`toJson`).
  - Deviated slightly from the PRD's literal wording on one point: rather than asserting `toJson()`'s `vulnerable` field round-trips as `"None"` for a non-vulnerable plugin (framed as *the* sentinel value), the tests cover **both** `'None'` and `''` explicitly, since the later real-data investigation (documented in PRD 01) found real evaluator input never actually produces `'None'` — missing data defaults to `''`. Testing only the `'None'` case would have missed the actual bug that shipped.
  - All 11 evaluator tests pass (`dart test`); `dart analyze` is clean.
- **R2**: added Vitest (`site/utils` + `site/test`) — no prior test framework existed in `site/`, and Vitest needed no additional Nuxt/webpack integration since the two fragile pieces of logic were extracted into small dependency-free pure functions:
  - `site/utils/pluginStatus.js`: `isVulnerable(plugin)` and `needsUpgrade(plugin)`, extracted out of `sites.vue`'s inline computed filters (same real-world `''`-vs-`'None'` nuance as the Dart side).
  - `site/utils/pluginAggregation.js`: `buildPluginToSiteMap(sites)`, extracted out of `store/sites.js`'s `pluginToSiteMap` getter, keyed by plugin slug (not array index).
  - Both `sites.vue` and `store/sites.js` now import and use these instead of duplicating the logic inline — this also means there's only one place each behavior lives, not two copies that could drift.
  - `site/test/pluginStatus.test.js` (5 tests) and `site/test/pluginAggregation.test.js` (4 tests): 9 tests total, all passing (`yarn test`).
  - Explicitly verified the regression-catching property required by this PRD: reverted `isVulnerable` to the old buggy `!== ''` check and confirmed the "None" test failed; reverted `buildPluginToSiteMap`'s key to array index and confirmed both aggregation tests failed. Then restored the real fix and confirmed all tests pass again.
  - Verified live in the browser against real production data (60 sites) after the refactor: Plugins page renders 680 distinct plugins with sensible aggregate counts (e.g. `wordpress-seo`: 49 sites, 41 upgrades), no console errors, no behavior change from the refactor.
- **Found and fixed along the way**: `site/.github/workflows/ci.yml`'s Node version (pinned to 14) didn't match `package.json`'s own `engines` field (`>=18.16.0`) and predates what Vitest requires — bumped to Node 18 in CI.
- **Found, then fixed after all (scope expanded mid-PRD at the user's request)**: verified via a clean `git worktree` checkout of `main` that `yarn lint` failed with ~398 pre-existing errors, entirely unrelated to this PRD's original scope — the configured ESLint style rules (no semicolons, no trailing commas, specific indentation) didn't match the actual code style anywhere in the repo, meaning the lint step in CI had likely never passed. This directly affected this PRD's CI wiring: since a failed step skips the rest of its job, the new `test` step would never have run if left sequential after the already-broken `lint` step — restructured `ci.yml` into two independent jobs (`lint`, `test`) for that reason regardless of what happened next.
  - Ran `eslint --fix`, which auto-corrected the vast majority (398 → 40 remaining problems, all real code issues rather than style).
  - Fixed the remaining 23 errors by hand: `==` → `===` (`eqeqeq`) in five files; removed unreachable `break` statements after `return` in two `switch` statements (`IssueIcon.vue`, `Table.vue`); removed a stray `console.info(...)`-via-comma-operator debug leftover in `Header.vue`'s `searchChange`; removed an unused destructured `item` from three `v-select` slot templates in `sites.vue`.
  - Found and worked around a real `eslint-plugin-vue` false positive: Vuetify's data-table dotted dynamic slot names (`v-slot:item.issuePriority`, `v-slot:item.actions`) are valid, documented Vuetify syntax, but the `vue/valid-v-slot`/`vue/v-slot-style` rules misparse the dot as an invalid modifier — added scoped `eslint-disable`/`eslint-enable` comments around just those two lines rather than disabling the rule project-wide or (worse) breaking the actual slot functionality to satisfy the linter.
  - Left the remaining 16 *warnings* as-is (missing prop-type declarations, a few more `console.info` calls) — they don't fail CI and most already overlap with PRD 05's scope.
  - Reviewed every file `--fix` touched (including ones with no reported errors, just reformatting) via `git diff` to confirm all changes were style-only with no functional differences.
  - Verified end-to-end after all lint fixes: `yarn lint` exits 0, `yarn test` still passes (8/8), `dart analyze`/`dart test` unaffected (18/18), and manually re-verified in the browser that the two edited Vuetify slot templates (Issues column, Actions menu) still render and function correctly against real data.
  - Dismissed the background task originally spawned for this, since it's now handled directly instead of deferred.

## Acceptance Criteria

- [x] `dart test` (in `evaluator/`) includes and passes the new plugin-evaluation tests. *(11/11 passing, including the pre-existing `Site` model test.)*
- [x] Reverting PRD 01's `sites.vue`-equivalent fix (now in `site/utils/pluginStatus.js`) locally causes the new frontend test to fail. *(Verified directly — see "What's done".)*
- [x] Reverting PRD 01's `sites.js`-equivalent fix (now in `site/utils/pluginAggregation.js`) locally causes the new frontend test to fail. *(Verified directly — see "What's done".)*
- [x] A `test` script exists in `site/package.json` (`vitest run`) and is wired into `site/.github/workflows/ci.yml` as its own job (not a step gated behind the pre-existing, unrelated `lint` failure).
