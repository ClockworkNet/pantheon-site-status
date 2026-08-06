# PRD 05 — Debug Cleanup & Buildchain Decision

**Status:** Todo
**Priority:** P3 — low risk, low urgency, good filler iteration
**Depends on:** nothing (can be done any time, independently of the others)
**Source:** [docs/RECOMMENDATIONS.md](../../RECOMMENDATIONS.md) §1 item 6, §2 item 4

## Problem

Small pieces of leftover development-time cruft remain in the repo:

- Leftover `console.info` debug calls in production Vue code: `site/pages/sites.vue` ("filtered updated" on every computed re-run), `site/components/pages/sites/Header.vue` (logs every search/tag change), and `site/components/pages/sites/Table.vue` (logs the deprecated global `event` on every row click, which doesn't even log the clicked row).
- A half-built Docker-based buildchain (`Dockerfile`, `bin/build.sh`, `bin/shell.sh`) described in the README under "In Progress Work," not wired into CI, with a known-unsolved problem (authorizing Terminus inside the container).

Neither is a functional bug, but both make the codebase noisier to work in and the README misleading about what's actually supported.

## Goals

- Production code has no stray debug logging.
- The README accurately reflects what's supported: either the buildchain works and is documented as real, or it's removed so it stops looking like a maintained path.

## Non-goals

- Building out a full local-dev Docker workflow if the decision is to drop it — this PRD only requires making and executing the decision, not doing net-new buildchain engineering unless "finish it" is chosen.

## Requirements

### R1 — Remove stray debug logging
- Remove the three `console.info` calls identified above from `sites.vue`, `Header.vue`, and `Table.vue`.
- Skim the rest of `site/` for any other leftover `console.log`/`console.info` calls not intentionally left for user-facing debugging, and remove those too.

### R2 — Decide the fate of the Docker buildchain
- Make an explicit call: finish it (solve the Terminus-in-container auth problem, wire `bin/build.sh` into actual local dev or CI usage) or delete it (`Dockerfile`, `bin/build.sh`, `bin/shell.sh`, and the corresponding README section).
- Whichever is chosen, update `README.md`'s "In Progress Work" section so it no longer describes an unfinished, unverified path as available.

## Acceptance Criteria

- [ ] No `console.info`/`console.log` calls remain in `site/` outside of anything explicitly intended as user-facing (none currently qualify).
- [ ] `README.md` contains no "In Progress" section describing a buildchain that either doesn't exist anymore or is now fully working and documented as such.
- [ ] If the buildchain is kept: running `./bin/build.sh` followed by `./bin/shell.sh` and the evaluator command from inside the container succeeds end-to-end, including Terminus auth.
- [ ] If the buildchain is dropped: `Dockerfile`, `bin/build.sh`, `bin/shell.sh` are removed from the repo.
