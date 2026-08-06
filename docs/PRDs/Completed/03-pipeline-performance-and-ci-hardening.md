# PRD 03 — Pipeline Performance & CI Hardening

**Status:** Done
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

## What's done

- **R1**: `_enrichSites` in `sinfo_manager.dart` now processes sites in batches of `_enrichmentConcurrency = 5` via `Future.wait`, instead of one at a time in a serial `for` loop. Progress reporting still reflects true completion count (each site's completion increments a shared counter synchronously right after its `await`, which is safe under Dart's single-threaded event loop — no explicit locking needed). Verified in isolation with a standalone timing script (23 fake 20ms-delay items processed in ~111ms vs. an ~460ms serial equivalent), then verified for real: a full production run against all 69 org sites (60 enriched) completed in **579.78s (~9m40s)**. The prior serial baseline wasn't captured with a precise timer, but was observed earlier in this same working session progressing at roughly 2%/minute (~50 minutes projected for a full run) — consistent with the ~5x speedup a concurrency-of-5 change should produce.
- **R2**: replaced the raw `wget`/`apt-key`/`apt-get install dart` block in `.github/workflows/update-sinfo.yml` with `dart-lang/setup-dart@v1`, pinned to `3.12.2`.
- **Found and fixed along the way**: `evaluator/pubspec.yaml`'s SDK constraint (`>=2.12.0 <3.0.0`) was already stale — this whole session's work has been running on Dart 3.12.2, which technically violates that constraint. Widened it to `>=3.0.0 <4.0.0` so the pinned CI version and the package's own declared constraint agree, rather than pinning CI to a version that contradicts `pubspec.yaml`. `dart pub get` re-resolved cleanly with no `pubspec.lock` changes.

## Acceptance Criteria

- [x] A run against the current full site list completes in measurably less wall-clock time than the prior serial baseline. *(579.78s real / 68.58s user / 22.77s sys for all 69 sites, concurrency=5 — see "What's done" for the serial-baseline caveat: it's an observed estimate, not a precisely timed comparison, since the original serial run in this session wasn't captured with `time`.)*
- [x] No Terminus rate-limit or connection errors appear in a full run at the chosen concurrency level. *(Only 2 warnings logged in the full run, both genuine WP-CLI errors for one non-WordPress site — "This does not seem to be a WordPress installation" — not rate-limiting. This is exactly the kind of failure PRD 02's logging was built to surface, and it worked as intended.)*
- [x] `.github/workflows/update-sinfo.yml` no longer contains raw `wget`/`apt-key` Dart install steps. *(Confirmed by inspection.)*
- [ ] The workflow succeeds end-to-end (build → evaluator run → site build → S3 sync) using the pinned Dart action. — **not verified in real CI**: this environment can't run GitHub Actions. The equivalent local steps (`dart pub get` + `dart run`) were verified with the same pinned Dart version (3.12.2) and succeeded. Recommend triggering the workflow manually (`workflow_dispatch`) after merge to confirm the CI-specific parts (the `dart-lang/setup-dart` action itself, runner environment) behave the same way.
