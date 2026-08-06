# PRD 02 — Data Pipeline Reliability

**Status:** Todo — R1 partially done (see note below)
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

- **`fetchWordPressPlugins` JSON parsing hardened** (part of R1, found live during a real evaluator run): `wp launchcheck plugins --format=json` can emit PHP warnings (e.g., a theme failing to write cache files with `file_put_contents(...): Permission denied`) that land ahead of the JSON payload on the same stream, breaking naive `json.decode`. Previously this silently returned an empty plugin list for the affected site with no visible trace. Fixed in [evaluator/lib/pantheon.dart](../../../evaluator/lib/pantheon.dart): a new `_extractJsonObject` helper pulls just the `{...}` object out of the raw output before decoding, and a genuine parse failure now logs the site name + raw output to stderr instead of failing silently. Verified against the real garbled output captured from a live run. `dart analyze` passes; `dart test` could not be run in this environment due to an unrelated local Dart SDK installation issue (missing `frontend_server.dart.snapshot`), not caused by this change.
- The rest of R1 (checking `exitCode` on every other `Process.run('terminus', ...)` call) is still open — this fix only covers the plugin-fetch path where the bug was actually observed.

## Acceptance Criteria

- [ ] Killing/blocking a Terminus call for one site (e.g., temporarily revoking its access) produces a visible error in the evaluator's run log and a non-"okay" indicator for that site in the output JSON, rather than a blank/default value with no issues.
- [ ] `pantheon.dart` contains no comments describing cache behavior that doesn't exist in the code.
- [ ] Every Drupal site in the dashboard shows a distinct "not evaluated" indicator rather than a clean bill of health.
- [ ] Existing evaluator unit tests still pass; new tests cover at least one Terminus-failure path and the Drupal "not evaluated" flag.
