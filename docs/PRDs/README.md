# PRDs

Work is organized into iterations, each its own PRD. Move a PRD's file from `Todo/` to `Completed/` when it ships (no renumbering needed — the number reflects intended order, not folder).

## Completed

| # | PRD | Priority |
|---|---|---|
| 01 | [Correctness & Public-Exposure Fixes](Completed/01-correctness-and-exposure-fixes.md) | P0 |
| 02 | [Data Pipeline Reliability](Completed/02-data-pipeline-reliability.md) | P1 |
| 03 | [Pipeline Performance & CI Hardening](Completed/03-pipeline-performance-and-ci-hardening.md) | P2 |

## Todo

| # | PRD | Priority | Depends on |
|---|---|---|---|
| 04 | [Test Coverage for the Bug-Prone Paths](Todo/04-test-coverage.md) | P2 | 01 |
| 05 | [Debug Cleanup & Buildchain Decision](Todo/05-cleanup-and-buildchain-decision.md) | P3 | — |
| 06 | [Restrict Public Access to the Dashboard](Todo/06-restrict-public-dashboard-access.md) | P0 | — |
| 07 | [Investigate `biomatrix-international` CMS Misclassification](Todo/07-biomatrix-international-misclassification.md) | P3 | — |

PRD 06 was split out of PRD 01 — it's an AWS/access-control decision requiring infra access, not a code fix, so it doesn't belong in the same review as the code-level correctness fixes. Despite the numbering, treat it as urgent (P0), not as low-priority cleanup.

PRD 07 was discovered live during PRD 03 verification — one site's data is silently unfetchable every day, scoped to that single site until proven otherwise.

Background: [../REQUIREMENTS.md](../REQUIREMENTS.md) and [../RECOMMENDATIONS.md](../RECOMMENDATIONS.md).
