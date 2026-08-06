# PRD 07 — Investigate `biomatrix-international` CMS Misclassification

**Status:** Todo — not started
**Priority:** P3 — affects one site's data, not the system as a whole
**Depends on:** nothing
**Source:** discovered live during PRD 03 verification (a real evaluator run against all 69 org sites)

## Problem

The Pantheon site `biomatrix-international` is classified as `cms: wordpress` in the evaluator's output (via `Site.fromPantheonJson`'s `framework` field mapping in [evaluator/lib/models/site.dart](../../../evaluator/lib/models/site.dart)), but its live environment has no actual WordPress installation. A real run produced:

```
Warning: `terminus wp -y biomatrix-international.live -- core version` failed for biomatrix-international (exit code 1). stderr:
Error: This does not seem to be a WordPress installation.
Pass --path=`path/to/wordpress` or run `wp core download`.

Warning: `terminus wp launchcheck plugins` failed for biomatrix-international (exit code 1). stderr:
Error: This does not seem to be a WordPress installation.
The used path is: /code/
```

Because of this, the dashboard can never show CMS version, CMS stability, or plugin data for this site — those fetches fail every single day, silently (well, now visibly in logs thanks to PRD 02, but still never actually populated). Whether this is a data problem, a stale/broken site, or an evaluator bug depends on findings below.

## Goals

- Understand why Pantheon reports this site's framework as WordPress when there's no WordPress at `/code/`.
- Fix whatever is actually wrong — either on the Pantheon site itself, or in the evaluator's framework-to-CMS mapping, depending on root cause.

## Non-goals

- Broad auditing of every site in the org for similar mismatches — this PRD is scoped to this one site unless the investigation reveals a systemic mapping bug that would obviously affect others (in which case, note it here and consider whether it needs its own follow-up).

## Requirements

### R1 — Diagnose the root cause
Investigate via `terminus site:info biomatrix-international` and `terminus env:info biomatrix-international.live` (or the Pantheon dashboard) which of these it is:
- **(a) Frozen/sandboxed site that should be excluded.** The evaluator's `Site.isActive` getter ([evaluator/lib/models/site.dart](../../../evaluator/lib/models/site.dart)) already excludes frozen sites and sandbox-plan sites — check whether this site should have been caught by that filter and isn't, or whether it's active but genuinely empty/decommissioned and needs a different exclusion.
- **(b) Genuinely broken/stale site on Pantheon's side** (e.g., code was never deployed, or was removed) that needs cleanup or reprovisioning outside this repo — not a code bug at all.
- **(c) A framework-reporting mismatch** — Pantheon's `framework` field says something that `Site.fromPantheonJson` maps to `'wordpress'` but shouldn't (e.g., a static site or custom docroot framework value being incorrectly bucketed as WordPress).

### R2 — Fix based on root cause
- If (a): confirm and fix the exclusion logic, or manually address the site's frozen/sandbox status in Pantheon.
- If (b): this is likely not a code change — flag to whoever manages the Clockwork Pantheon org for cleanup, and consider whether the evaluator should treat "no WordPress found" more gracefully regardless (e.g., surfacing it as a distinct "site has no CMS install" issue rather than a generic fetch-failure warning) so this class of problem is self-explanatory next time it happens on a different site.
- If (c): fix the `framework` → `cmsName` mapping in `Site.fromPantheonJson`.

## Acceptance Criteria

- [ ] Root cause identified and documented (which of a/b/c, with the actual `framework` value and site status from Pantheon).
- [ ] Either the underlying issue is fixed (code change, or the site itself corrected on Pantheon), or — if it's an external data/ops issue outside this repo's control — the evaluator degrades gracefully for this case (a clear "no CMS install found" signal rather than repeated generic fetch-failure warnings).
- [ ] A subsequent evaluator run no longer produces the "This does not seem to be a WordPress installation" warnings for this site (either because it's fixed, or because it's now correctly excluded/flagged instead of retried daily).
