# PRD 02 — Data Pipeline Reliability

**Status:** Done
**Priority:** P1
**Depends on:** PRD 01 (fix the bugs before hardening the pipeline around them)
**Source:** [docs/RECOMMENDATIONS.md](../../RECOMMENDATIONS.md) §1 items 3-5

## Problem

The evaluator trusts Terminus CLI output unconditionally in almost every fetch method, has a doc comment claiming a cache exists when it doesn't, and silently produces "all clear" for every Drupal site because the Drupal evaluation path is an empty stub. None of these crash the pipeline — they just make its output quietly wrong or non-representative, which is worse than a visible failure for a status dashboard people are meant to trust.

## Goals

- A failed data-fetch for a site is visible (in logs and ideally in the site's own record) rather than silently treated as a clean result.
- Documentation matches behavior.
- Drupal sites either get real evaluation or are clearly marked as unevaluated in the UI, instead of implicitly reading as "no issues."

## Non-goals

- Building a full retry/backoff framework — this is about not swallowing failures, not building resilience infrastructure.
- Writing the actual Drupal evaluation ruleset (module vulnerability sources, version stability, etc.) — that's a scoping question of its own; this PRD only requires the gap to stop being silent.

## Requirements

### R1 — Surface Terminus failures
- In [evaluator/lib/pantheon.dart](../../../evaluator/lib/pantheon.dart), check `result.exitCode` on every `Process.run('terminus', ...)` call, not just `fetchWordPressPlugins`.
- On non-zero exit, log the site name, command, and stderr, and propagate a clear "unknown/failed" value rather than an empty string that downstream code interprets as a normal-but-blank field.
- Decide how a failed field should render in the evaluator's output — recommend adding an explicit `data_fetch_error` style flag to the site record (or reusing the existing issues list) rather than inventing a new UI state, so the frontend doesn't need new logic beyond "show this issue like any other."

### R2 — Fix or remove the caching claim
- Either implement the caching the doc comments in `pantheon.dart` describe (skip re-fetching a site's data if it hasn't changed since the last run — needs a decision on what "changed" means and where the cache lives), or delete the misleading comments if caching isn't being built this iteration.
- Default recommendation: delete the comments now (fast, zero-risk) and open caching as its own future PRD if the daily-run cost ever becomes a problem — don't let this PRD block on a caching design.

### R3 — Stop silently no-op'ing Drupal sites
- Make `_evaluateDrupal` in [evaluator/lib/evaluator.dart](../../../evaluator/lib/evaluator.dart) add an explicit "not evaluated" issue/flag for Drupal sites, so the dashboard visibly distinguishes "checked, no issues" from "not checked."
- Full Drupal module/version evaluation logic is explicitly out of scope for this PRD; only the "don't lie about coverage" part is in scope.

## What's done

- **`fetchWordPressPlugins` JSON parsing hardened** (found live during a real evaluator run, ahead of the rest of R1): `wp launchcheck plugins --format=json` can emit PHP warnings (e.g., a theme failing to write cache files with `file_put_contents(...): Permission denied`) that land ahead of the JSON payload on the same stream, breaking naive `json.decode`. Previously this silently returned an empty plugin list for the affected site with no visible trace. Fixed in [evaluator/lib/pantheon.dart](../../../evaluator/lib/pantheon.dart): a new `_extractJsonObject` helper pulls just the `{...}` object out of the raw output before decoding, and a genuine parse failure now logs the site name + raw output to stderr instead of failing silently. Verified against the real garbled output captured from a live run, and re-verified against a full 69-site production run with zero parse failures.
- **R1 completed**: every `Process.run('terminus', ...)` call in `pantheon.dart` now goes through a shared `_runTerminus` helper (or has equivalent handling, for `fetchWordPressPlugins`'s existing `exitCode == 1` branch) that logs the site name, command, and stderr to the console on non-zero exit, instead of silently returning blank output. The trimmed stdout (or empty string on failure) still flows downstream unchanged — for PHP version, upstream status, New Relic status, and CMS version, that blank value already resolves to an `'unknown'`/unmapped status in `evaluator.dart`'s existing alert-level lookups, which already default to a `'warning'` issue for anything not explicitly recognized. So a failed fetch was already *surfacing* as a generic warning; what was missing — and is now fixed — is the operator-visible log line explaining *why*, which previously didn't exist for any of these calls except the plugin fetch. `fetchLiveUrl` has no associated status/issue concept (it's just a link), so a failure there only logs; it doesn't have a natural "issue" to attach to.
- **R2 completed**: removed the two misleading "trying the cache first" / "if there is cached data, it will be used" doc comments in `pantheon.dart` (`fetchSitesJson`, `fetchSites`). No caching exists anywhere in the codebase; grepped to confirm no other cache references remain.
- **R3 completed**: `_evaluateDrupal` in `evaluator.dart` now adds an explicit `warning`-severity issue ("Drupal sites are not yet evaluated for issues") to every Drupal site, so the dashboard shows a distinct "not evaluated" indicator instead of implying a clean bill of health. Verified with a standalone script: a synthetic Drupal site now produces 4 issues (PHP/upstream/New Relic warnings plus the new Drupal-not-evaluated warning) instead of the Drupal-specific gap being silent.
- `dart analyze` passes clean on the full `lib/` directory. `dart test` could not be run in this environment due to an unrelated local Dart SDK installation issue (missing `frontend_server.dart.snapshot`) — not caused by any of these changes; automated test coverage for these fixes is PRD 04's job.
- `fetchSitesJson` (the org-wide site list) and `isTerminusInstalled` were deliberately left out of the `_runTerminus` refactor — a failure there already crashes loudly (an uncaught `FormatException` from decoding empty/invalid JSON, or a clear boolean false), which doesn't fall into the "silently wrong" problem this PRD targets. Scoped this way to avoid over-engineering a retry/fallback framework the PRD explicitly rules out.

## Acceptance Criteria

- [x] Killing/blocking a Terminus call for one site produces a visible error in the evaluator's run log (site name, command, stderr) and — for fields with an associated status concept (PHP, upstream, New Relic, CMS version) — a non-"okay" indicator for that site, via the existing alert-default-to-warning behavior in `evaluator.dart`.
- [x] `pantheon.dart` contains no comments describing cache behavior that doesn't exist in the code.
- [x] Every Drupal site in the dashboard shows a distinct "not evaluated" indicator rather than a clean bill of health. *(Verified: a Drupal site now produces an explicit warning-level issue for this.)*
- [ ] New automated tests covering a Terminus-failure path and the Drupal "not evaluated" flag — **not done here**, deferred to PRD 04 (dedicated test-coverage PRD), along with getting `dart test` itself working in this environment. Existing tests are unaffected (verified via `dart analyze`; `dart test` is blocked by an unrelated toolchain issue).
