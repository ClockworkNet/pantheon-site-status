# PRD 11 — Stale PHP Version Support Map

**Status:** Done
**Priority:** P2 — incorrect data, but "warning" rather than a false-clean green check
**Depends on:** nothing
**Source:** user noticed PHP 8.3 showing "Unknown" with a warning icon in a site detail modal

## Problem

`Evaluator._phpVersions` (`evaluator/lib/evaluator.dart`) is a manually-maintained map from PHP version string to support status, sourced from https://www.php.net/supported-versions.php — exactly as documented in the root README's "Updating Supported PHP Versions" playbook. It had drifted stale:

```dart
'8.0': 'security fixes only',
'8.1': 'active',
'8.2': 'active',
```

As of today (2026-08-06), per php.net's actual support schedule:
- PHP 8.0 and 8.1: fully end of life (security support ended Nov 2023 / Dec 2025)
- PHP 8.2 and 8.3: security fixes only (security support until Dec 2026 / Dec 2027 respectively) — **8.3 wasn't in the map at all**
- PHP 8.4 and 8.5: active support

Because 8.3 had no entry, `phpStability('8.3')` fell through to the `?? 'Unknown'` default, which isn't a recognized key in `phpAlerts` either, so it further defaulted to a `warning` severity — a real site running PHP 8.3 (actually just in the unremarkable "security fixes only" phase, not urgent) showed the same generic warning icon as a site on a truly unrecognized/misconfigured PHP version, with no useful information in the tooltip either way.

## Goals

- PHP version support status reflects the real, current php.net schedule.
- The three most common "wrong data" failure modes for this map (missing entry, stale status, and the display collapsing distinct problems into one generic warning) are covered by a test, so the next time this drifts, a test fails instead of a user noticing a wrong badge.

## Non-goals

- Automating this against php.net's schedule (e.g. scraping or an API) — the map is small and this is an existing documented manual playbook; automating it is a reasonable future idea but a separate, bigger change not requested here.

## Requirements

### R1 — Update the PHP version map
- Updated `_phpVersions` in `evaluator/lib/evaluator.dart` to match php.net's current schedule as of 2026-08-06: 8.0/8.1 → `end of life`, 8.2/8.3 → `security fixes only`, 8.4/8.5 → `active` (8.3, 8.4, 8.5 added; 8.0/8.1 corrected).
- Added a source-of-truth comment pointing at php.net's supported-versions page and the README playbook.

### R2 — Lock in current expectations with a test
- Added `Evaluator.phpStability` test group in `evaluator/test/evaluator_test.dart`: currently-active versions (8.4, 8.5), security-only versions (8.2, 8.3), end-of-life versions (8.1, 7.4), and the `'Unknown'` fallback for an unrecognized version.

## What's done

- Verified php.net's official supported-versions page directly (not just a secondary source) and cross-checked the dates by computing today's status manually from the listed active/security end dates, since the fetched page's own "Status" column for 8.3 looked inconsistent with its own listed dates.
- All 24 evaluator tests pass; `dart analyze` clean.
- `site/data/sites.json` regenerated with a real full evaluator run to reflect the corrected PHP statuses.
- Verified live in the browser against real sites on PHP 8.3: the icon is still a yellow warning (correctly so — `security fixes only` genuinely is a `warning`-level status, not a false-clean green check), but the text now reads `security fixes only` instead of the meaningless `Unknown`.

## Acceptance Criteria

- [x] PHP 8.3 shows `security fixes only`, not `Unknown`.
- [x] PHP 8.4/8.5 show `active` (green).
- [x] PHP 8.0/8.1 show `end of life` (red alert), not `active`/`security fixes only`.
- [x] A regression test covers each of the four status buckets plus the unrecognized-version fallback.
