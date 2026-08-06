# PRD 06 — Restrict Public Access to the Dashboard

**Status:** Todo — not started, blocked on an access-control decision + AWS access this session doesn't have
**Priority:** P0 — split out of PRD 01 because it's an infrastructure/access decision, not a code fix, but it's just as urgent
**Depends on:** nothing (independent of PRD 01/02's code fixes, though see note below on sequencing)
**Source:** [docs/RECOMMENDATIONS.md](../../RECOMMENDATIONS.md) §3; originally R3 in [PRD 01](../Completed/01-correctness-and-exposure-fixes.md)

## Problem

The generated dashboard JSON — including which sites have which vulnerable plugins — is synced to an S3 bucket with `--acl public-read` ([.github/workflows/update-sinfo.yml](../../../.github/workflows/update-sinfo.yml)) and served publicly via CloudFront, with no authentication in front of it. Anyone with the URL can see exactly which client sites have known-vulnerable plugins installed.

This was split out of PRD 01 (which fixed the vulnerability-detection logic itself) because it's a genuinely different kind of work: an access-control/architecture decision plus AWS infrastructure changes, not a code bug. It shouldn't block or be blocked by ordinary code review the way the PRD 01 fixes were.

## Why this is still urgent

PRD 01 fixed the plugin-vulnerability logic so it no longer falsely flags every plugin as vulnerable. Once real vulnerability detection is actually working (see the follow-up investigation spawned from PRD 01, about `launchcheck` not returning real data), this same public bucket will start correctly and accurately publishing which client sites are exploitable. Public + wrong was bad; public + correct is worse. Don't let this slip just because the false-positive symptom is gone.

## Goals

- The published dashboard is no longer readable by anyone on the internet.
- The daily pipeline continues to deploy successfully under whatever new access control is chosen.

## Non-goals

- Redesigning the dashboard's UI or data model.
- Building a general-purpose auth system — reuse whatever access control Clockwork already has (SSO, VPN, IP allowlist) rather than inventing new infrastructure.

## Requirements

### R1 — Decide the access-control mechanism
Options, roughly in order of implementation effort:
- CloudFront signed URLs/cookies
- IP allowlist (e.g., restrict to Clockwork office/VPN egress IPs) via CloudFront or bucket policy
- Put it behind existing Clockwork SSO (if there's already a pattern for this, e.g. an internal reverse proxy)
- Move off public S3/CloudFront entirely onto an internal-only host

This decision needs a human with AWS console/IAM access and knowledge of Clockwork's existing internal-tool access patterns — it's not something to decide from the repo alone.

### R2 — Implement the chosen mechanism
- Update the S3 bucket policy / CloudFront distribution configuration accordingly.
- Remove `--acl public-read` from the S3 sync step in `.github/workflows/update-sinfo.yml` once the replacement control is confirmed working — don't leave a window where both public-read and the new control are simultaneously in effect.
- Update the CloudFront invalidation step if the distribution config changes materially.

### R3 — Verify the pipeline still deploys
- Run the daily workflow (or trigger it manually) end-to-end after the change and confirm the site is still reachable through the new access-controlled path, and unreachable without it.

## Acceptance Criteria

- [ ] Loading the dashboard's public URL unauthenticated (fresh incognito session, no VPN/SSO) fails or is blocked.
- [ ] Loading the dashboard through the intended access path (VPN, SSO, signed link, etc.) succeeds.
- [ ] A full run of `.github/workflows/update-sinfo.yml` (manual trigger or next scheduled run) completes successfully and the redeployed site still enforces the same access control — i.e., the S3 sync step doesn't silently re-apply `public-read` or otherwise regress.

## Notes for whoever picks this up

- No Terraform/CloudFormation exists in this repo — bucket and distribution config are managed directly in AWS (console or CLI), outside of what's visible here.
- This requires AWS credentials/console access this session did not have — it should be picked up by someone (or a session) with that access.
