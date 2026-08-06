# PRD 01 — Correctness & Public-Exposure Fixes

**Status:** Todo
**Priority:** P0 — do this iteration first, independent of everything else
**Depends on:** nothing
**Source:** [docs/RECOMMENDATIONS.md](../../RECOMMENDATIONS.md) §1 items 1-2, §3

## Problem

Two live bugs make the dashboard's headline security signal (plugin vulnerabilities) actively wrong, and the output containing that signal is published without access control:

1. Every WordPress plugin on every site currently displays as "vulnerable" in the site detail modal, because [site/pages/sites.vue:114](../../../site/pages/sites.vue) filters on `plugin.vulnerable !== ""` when the real "not vulnerable" sentinel is the string `"None"`. This was correct once (git history, commit `0228fa6`) and regressed.
2. The Plugins page aggregates plugin data across sites keyed by array index instead of plugin slug ([site/store/sites.js:18-19](../../../site/store/sites.js)), so per-plugin site/upgrade counts are wrong whenever two sites list plugins in a different order.
3. The generated JSON — including which sites have which vulnerable plugins — is synced to an S3 bucket with `--acl public-read` ([.github/workflows/update-sinfo.yml](../../../.github/workflows/update-sinfo.yml)) and served publicly via CloudFront, with no auth in front of it.

Item 3 matters more once items 1-2 are fixed: right now the public dashboard is *wrong*, which is bad, but once corrected it will be *accurate and public*, which is worse for a page whose whole purpose is "here's what's exploitable on our clients' sites."

## Goals

- Plugin vulnerability status and cross-site plugin counts are correct.
- The published dashboard is no longer readable by anyone on the internet.

## Non-goals

- Redesigning the plugins/sites UI.
- Changing what data is collected — only how it's filtered/keyed/exposed.

## Requirements

### R1 — Fix vulnerable-plugin filter
- Change the filter in `sites.vue` to treat `"None"` (not `""`) as "not vulnerable."
- Grep the codebase for any other place comparing `vulnerable`/`vulnerableDescription` against `""` and fix the same way (evaluator's own check at [evaluator/lib/evaluator.dart:96](../../../evaluator/lib/evaluator.dart) already uses `"None"` correctly — use it as the reference).

### R2 — Fix plugin aggregation keys
- In `pluginToSiteMap` ([site/store/sites.js](../../../site/store/sites.js)), key the map by `plugin.slug`, not by `Object.entries` array index.
- Verify the Plugins page's Sites/Upgrades counts against a hand-checked sample of `site/data/sites.json` after the fix.

### R3 — Restrict public access to the published dashboard
- Decide and implement an access-control mechanism for the S3/CloudFront-hosted site — options in rough order of effort: CloudFront signed URLs/cookies, an IP allowlist, putting it behind existing SSO, or moving it off public S3 entirely (e.g., an internal-only host). Pick whichever fits existing Clockwork infra with least new surface area.
- Remove `--acl public-read` once the replacement control is in place; do not leave a window where both are true.

## Acceptance Criteria

- [ ] For a WordPress site with at least one plugin whose `vulnerable` field is a real description (not `"None"`), the site detail modal shows exactly that plugin under "Vulnerable," and no others.
- [ ] For a WordPress site where every plugin's `vulnerable` field is `"None"`, the modal shows 0 vulnerable plugins.
- [ ] The Plugins page shows one row per distinct plugin slug across the whole org, with a Sites count matching a manual count from `sites.json`.
- [ ] Attempting to load the dashboard's public URL unauthenticated (fresh incognito session, no VPN/SSO) fails or is blocked.
- [ ] A follow-up daily pipeline run completes and the redeployed site still enforces the same access control (i.e., the S3 sync step doesn't silently re-apply `public-read`).

## Out of scope / follow-up

- Terminus error handling, Drupal evaluation, performance, and test coverage are covered in later PRDs and should not be bundled into this one — this PRD should ship fast and alone.
