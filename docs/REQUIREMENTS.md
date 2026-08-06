# Pantheon Site Status — Requirements

This document describes what the system does today, reverse-engineered from the code, so it can serve as a baseline for either a bug-fix pass or a replatform. It is not aspirational — items marked *(gap)* are things the system implies it should do but doesn't.

## 1. Purpose

Give Clockwork staff a daily-refreshed, at-a-glance status dashboard of every active site the org hosts on Pantheon: CMS/PHP version health, Pantheon upstream status, New Relic setup, and (for WordPress) plugin update/vulnerability status.

## 2. System Components

| Component | Tech | Role |
|---|---|---|
| Evaluator | Dart CLI (`evaluator/`) | Pulls site data from Pantheon (via Terminus CLI) and wordpress.org, scores it, writes `site/data/sites.json` |
| Static site | Nuxt 2 / Vue 2 / Vuetify 2 (`site/`) | Reads the generated JSON at build time, renders dashboard, sites table, and plugins table |
| Pipeline | GitHub Actions (`.github/workflows/update-sinfo.yml`) | Daily cron (+ push/manual): installs Terminus & Dart, runs evaluator, builds the static site, syncs to S3, invalidates CloudFront |

## 3. Functional Requirements

### 3.1 Data collection (evaluator)
- FR-1: Enumerate all sites in a configured Pantheon organization (`terminus org:site:list`).
- FR-2: Exclude frozen sites and sites on the "sandbox" plan.
- FR-3: For each remaining site, fetch: live PHP version, live site URL, New Relic state, Pantheon upstream update status.
- FR-4: For WordPress sites specifically, fetch CMS version, plugin list (name, installed/available version, update-needed flag, vulnerability description) via `wp launchcheck plugins`.
- FR-5: Cross-reference the live WordPress version against wordpress.org's stable-check API to classify it as latest/outdated/insecure.
- FR-6: Serialize the enriched, evaluated site list to a single JSON file consumed by the static site.

### 3.2 Evaluation / scoring
- FR-7: Classify PHP version into active / security-fixes-only / end-of-life, and raise an issue if not "active".
- FR-8: Raise an issue when Pantheon upstream status isn't "current".
- FR-9: Raise an issue when New Relic status isn't "active".
- FR-10: Raise an issue when a WordPress plugin's `vulnerable` field is not `"None"`.
- FR-11: Raise an issue when WordPress core version status isn't "latest".
- FR-12: *(gap, unimplemented)* Drupal-specific evaluation — `_evaluateDrupal` is an empty stub, so Drupal sites get no CMS/plugin checks at all.

### 3.3 Presentation (site)
- FR-13: Overview page: counts of sites grouped by CMS, CMS stability, PHP version, upstream status, New Relic status.
- FR-14: Sites page: searchable/sortable table of all sites with an aggregate issue-severity indicator (green/yellow/red), per-site detail modal, filters by CMS / CMS status / PHP status, and a "team" tag filter.
- FR-15: Plugins page: cross-site table of every distinct plugin, how many sites have it installed, how many need an upgrade, and the latest available version, with a per-plugin expandable list of installed sites/versions.
- FR-16: Each site row links out to the live URL and to the Pantheon dashboard for that site.

### 3.4 Pipeline / operations
- FR-17: Regenerate and redeploy the dashboard once daily automatically, and on demand via manual workflow dispatch.
- FR-18: Deploy the built static site to S3 and invalidate the CloudFront distribution so the public-facing dashboard reflects the latest run.
- FR-19: Authenticate to Pantheon in CI via a machine token (Terminus) and an SSH key (for site environment access).

## 4. Non-functional expectations implied by the code

- NFR-1: Runtime should tolerate an org with "many" sites — current design does one Terminus CLI subprocess **per site per field** (5 calls minimum, more for WordPress), executed **serially**, with no concurrency or caching, despite an inline comment claiming "trying the cache first" *(gap — no cache exists)*.
- NFR-2: Data freshness of "once a day" is acceptable per the current cron; no real-time requirement is evidenced.
- NFR-3: The generated JSON currently includes plugin-level vulnerability descriptions and is synced to a **public-read** S3 bucket. There is no evidence this exposure was a deliberate decision.

## 5. Explicit non-goals (as currently built)

- No authentication/authorization on the published dashboard — it's a public static site.
- No historical trending — each run overwrites the single JSON file; no time-series of issue counts.
- No alerting — the dashboard is pull-based only (someone has to go look at it).
- No support for hosting providers other than Pantheon, or CMSs other than WordPress (Drupal is enumerated but not evaluated).
