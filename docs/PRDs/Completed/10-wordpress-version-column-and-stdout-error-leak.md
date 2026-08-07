# PRD 10 — WordPress Version Column, and a Stdout-Error-Leak Bug It Surfaced

**Status:** Done
**Priority:** P2 (UI feature) / P1 (the bug it surfaced — garbled text visibly rendered to users)
**Depends on:** nothing
**Source:** user request for a WordPress version column on the Sites table; adding it immediately surfaced a real display bug

## Problem

### Feature request
The Sites table had no at-a-glance column for each site's WordPress version — you had to open each site's detail modal individually to see it.

### Bug surfaced by the feature
Adding the column and sorting by it immediately showed garbled text for `biomatrix-international` (the site already flagged in [PRD 07](07-biomatrix-international-misclassification.md) for not actually having a WordPress install):

```
[31;1mError: [0m This does not seem to be a WordPress installation.
Pass --path=`path/to/wordpress` or run `wp core download`.
```

Root cause: `terminus wp -y biomatrix-international.live -- core version` exits with code 1, and WP-CLI writes its error message to **stdout** (with ANSI color codes), not stderr. `Pantheon._runTerminus` (added in PRD 02) checked the exit code only to decide whether to *log* a warning — it still returned `result.stdout.toString().trim()` unconditionally, so a failed command's stdout (in this case, literally the error message) got treated as if it were the real field value. This affects every field fetched through `_runTerminus`: PHP version, live URL, New Relic status, upstream status, and WordPress core version.

## Goals

- The Sites table shows each site's WordPress version.
- A failed Terminus command never has its stdout content mistaken for real data, regardless of which stream a given CLI tool happens to write its error to.

## Requirements

### R1 — Add a WordPress Version column
- `site/components/pages/sites/Table.vue`: added a `WP Version` header bound to the existing `cms_version` field (already present in the site JSON, already used in the detail modal) — no new data plumbing needed.

### R2 — Never trust stdout from a failed Terminus command
- `Pantheon._runTerminus` (`evaluator/lib/pantheon.dart`) now returns `''` whenever `exitCode != 0`, instead of returning whatever stdout contained. The failure is still logged to stderr with the site name, command, and real stderr content (unchanged from PRD 02).

## What's done

- R1 and R2 implemented and verified:
  - `dart analyze` clean; all 20 evaluator tests still pass (no test could directly exercise `_runTerminus`'s process-mocking without dependency injection not currently in place, so this was verified via direct live invocation instead — see below).
  - Verified directly against the real failing site: `pantheon.fetchWordPressVersion('biomatrix-international')` now returns `""` (length 0) instead of the garbled error text, with the failure still clearly logged to stderr.
  - `yarn lint` (0 errors) and browser verification confirmed the new column renders and sorts correctly against real production data (69 sites).
  - `site/data/sites.json` regenerated with a real full evaluator run to reflect both fixes together.

## Acceptance Criteria

- [x] The Sites table has a sortable WordPress Version column.
- [x] A site whose version fetch fails shows a blank version, never raw error text.
- [x] No other field fetched through `_runTerminus` can leak a failed command's stdout content either (fixed at the shared helper, not per-field).
