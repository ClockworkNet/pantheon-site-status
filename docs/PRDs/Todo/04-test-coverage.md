# PRD 04 — Test Coverage for the Bug-Prone Paths

**Status:** Todo
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

## Acceptance Criteria

- [ ] `dart test` (in `evaluator/`) includes and passes the new plugin-evaluation tests.
- [ ] Reverting PRD 01's `sites.vue` fix locally causes the new frontend test to fail.
- [ ] Reverting PRD 01's `sites.js` fix locally causes the new frontend test to fail.
- [ ] A `test`/`lint:js`-equivalent script exists in `site/package.json` for running the new frontend tests, and it's wired into `site/.github/workflows/ci.yml` if that workflow runs on PRs.
