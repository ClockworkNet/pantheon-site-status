# PRDs

Work is organized into iterations, each its own PRD. Move a PRD's file from `Todo/` to `Completed/` when it ships (no renumbering needed — the number reflects intended order, not folder).

## Completed

| # | PRD | Priority |
|---|---|---|
| 01 | [Correctness & Public-Exposure Fixes](Completed/01-correctness-and-exposure-fixes.md) | P0 |
| 02 | [Data Pipeline Reliability](Completed/02-data-pipeline-reliability.md) | P1 |
| 03 | [Pipeline Performance & CI Hardening](Completed/03-pipeline-performance-and-ci-hardening.md) | P2 |
| 04 | [Test Coverage for the Bug-Prone Paths](Completed/04-test-coverage.md) | P2 |
| 08 | [WordPress Multisite Sites Silently Unevaluated](Completed/08-wordpress-multisite-evaluation-gap.md) | P1 |
| 09 | [Remove Misleading "Vulnerable" Plugin Count](Completed/09-remove-misleading-vulnerability-count.md) | P1 |
| 10 | [WordPress Version Column, and a Stdout-Error-Leak Bug It Surfaced](Completed/10-wordpress-version-column-and-stdout-error-leak.md) | P2/P1 |
| 11 | [Stale PHP Version Support Map](Completed/11-stale-php-version-support-map.md) | P2 |

## Todo

| # | PRD | Priority | Depends on |
|---|---|---|---|
| 05 | [Debug Cleanup & Buildchain Decision](Todo/05-cleanup-and-buildchain-decision.md) | P3 | — |
| 06 | [Restrict Public Access to the Dashboard](Todo/06-restrict-public-dashboard-access.md) | P0 | — |
| 07 | [Investigate `biomatrix-international` CMS Misclassification](Todo/07-biomatrix-international-misclassification.md) | P3 | — |

PRD 06 was split out of PRD 01 — it's an AWS/access-control decision requiring infra access, not a code fix, so it doesn't belong in the same review as the code-level correctness fixes. Despite the numbering, treat it as urgent (P0), not as low-priority cleanup.

PRD 07 was discovered live during PRD 03 verification — one site's data is silently unfetchable every day, scoped to that single site until proven otherwise.

PRD 08 was discovered live while reviewing PRD 04's work in the browser — same class of bug as PRD 02's Drupal fix (a whole CMS variant silently skipped all evaluation and showed falsely clean), fixed immediately since it affects live, currently-active sites.

PRD 09 followed directly from investigating PRD 08 — the "Vulnerable" count turned out to be sourced from a WP-CLI command that only ever checked for plugin updates, never vulnerabilities. Removed rather than left misleading; a real vulnerability-checking integration is a separate future decision (needs an external API key).

PRD 10 was a small feature request (a WP Version column) that immediately surfaced a real bug: a failed Terminus command's stdout — sometimes literally an error message — was being trusted as real field data. Fixed at the shared `_runTerminus` helper, so it can't recur for any field that goes through it.

PRD 11 was noticed directly from the new WP Version column's sibling PHP status field — the manually-maintained PHP support map (a documented playbook in the root README) had simply gone stale and was missing PHP 8.3 entirely.

Background: [../REQUIREMENTS.md](../REQUIREMENTS.md) and [../RECOMMENDATIONS.md](../RECOMMENDATIONS.md).
