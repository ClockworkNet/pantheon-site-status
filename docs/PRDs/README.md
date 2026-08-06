# PRDs

Work is organized into iterations, each its own PRD. Move a PRD's file from `Todo/` to `Completed/` when it ships (no renumbering needed — the number reflects intended order, not folder).

| # | PRD | Priority | Depends on |
|---|---|---|---|
| 01 | [Correctness & Public-Exposure Fixes](Todo/01-correctness-and-exposure-fixes.md) | P0 | — |
| 02 | [Data Pipeline Reliability](Todo/02-data-pipeline-reliability.md) | P1 | 01 |
| 03 | [Pipeline Performance & CI Hardening](Todo/03-pipeline-performance-and-ci-hardening.md) | P2 | 02 |
| 04 | [Test Coverage for the Bug-Prone Paths](Todo/04-test-coverage.md) | P2 | 01 |
| 05 | [Debug Cleanup & Buildchain Decision](Todo/05-cleanup-and-buildchain-decision.md) | P3 | — |

Background: [../REQUIREMENTS.md](../REQUIREMENTS.md) and [../RECOMMENDATIONS.md](../RECOMMENDATIONS.md).
