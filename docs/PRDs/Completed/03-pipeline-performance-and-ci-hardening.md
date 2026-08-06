# PRD 03 — Pipeline Performance & CI Hardening

**Status:** Todo
**Priority:** P2
**Depends on:** PRD 02 (parallelizing fetches that don't yet handle errors consistently would multiply confusing failure modes)
**Source:** [docs/RECOMMENDATIONS.md](../../RECOMMENDATIONS.md) §2 items 1-2

## Problem

`_enrichSites` in [evaluator/lib/sinfo_manager.dart](../../../evaluator/lib/sinfo_manager.dart) processes sites one at a time, each requiring ~5 sequential Terminus subprocess calls — the dominant cost of the daily run as the org's site count grows. Separately, the GitHub Actions workflow installs Dart by piping `apt-key add` from an unpinned `wget` URL on every run ([.github/workflows/update-sinfo.yml:29-36](../../../.github/workflows/update-sinfo.yml)), which is slow and one upstream change away from a silent pipeline break.

## Goals

- The daily run scales sub-linearly (in wall-clock time) as sites are added, instead of linearly with serial per-site latency.
- The CI environment setup is pinned and reproducible.

## Non-goals

- Moving off Terminus CLI to Pantheon's HTTP API — that's a bigger architectural change, not in scope here.
- Changing the run cadence (still daily).

## Requirements

### R1 — Parallelize per-site enrichment
- Replace the serial `for` loop in `_enrichSites` with concurrent processing (e.g., `Future.wait` over batches), with a concurrency cap chosen to stay well within Terminus/Pantheon API rate limits — start conservative (e.g., 5 concurrent sites) and confirm no rate-limit errors show up under PRD 02's new error surfacing before considering raising it.
- Progress reporting (the existing `ProgressBar`) should still reflect real completion count under concurrency, not just loop position.

### R2 — Pin the Dart toolchain in CI
- Replace the manual `wget`/`apt-key`/`apt-get install dart` block in `.github/workflows/update-sinfo.yml` with the official `dart-lang/setup-dart` GitHub Action, pinned to a specific Dart SDK version consistent with `evaluator/pubspec.yaml`'s SDK constraint.
- Mirror the pattern already used for Terminus (`pantheon-systems/terminus-github-actions`) for consistency.

## Acceptance Criteria

- [ ] A run against the current full site list completes in measurably less wall-clock time than the prior serial baseline (capture before/after timing in the PR description).
- [ ] No Terminus rate-limit or connection errors appear in a full run at the chosen concurrency level.
- [ ] `.github/workflows/update-sinfo.yml` no longer contains raw `wget`/`apt-key` Dart install steps.
- [ ] The workflow succeeds end-to-end (build → evaluator run → site build → S3 sync) using the pinned Dart action.
