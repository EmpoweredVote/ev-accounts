---
phase: 118-read-rank-verdict-badge-fix
plan: 03
status: complete
started: 2026-04-15
completed: 2026-04-15
---

# Plan 118-03 Summary: Production Verification

## What Was Built

Verified all three fixes on production and captured user sign-off per D-16.

During verification, discovered **Bug C** — StanceAccordion fetch paths in ev-ui were missing the `/api` prefix, causing 404s on both quotes and reasoning endpoints in production. Fixed in ev-ui v0.4.2, auto-bumped to all consumers.

## Verification Results

- ev-accounts deployed with topic_key in topics API and quotes endpoint (confirmed via curl)
- essentials deployed with fetchUserVerdicts fix (confirmed via git push)
- ev-ui v0.4.2 published and auto-bumped to essentials, CompassV2, read-rank (all 3 PRs auto-merged)
- User opened Pierce profile, confirmed quotes and verdict badges render, signed off

## Cross-consumer smoke: N/A

Bug C fix (ev-ui v0.4.2) was auto-bumped to all 3 consumers. All auto-merge PRs passed build checks.

## Key Files

### Modified
- `ev-ui/src/StanceAccordion.jsx` — added `/api` prefix to fetch paths
- `.planning/phases/118-read-rank-verdict-badge-fix/118-VERIFICATION.md` — updated with sign-off
- `.planning/phases/118-read-rank-verdict-badge-fix/118-DIAGNOSIS.md` — added Bug C

## Self-Check: PASSED

- [x] Production verification complete
- [x] User sign-off captured (D-16)
- [x] All 3 bugs fixed and deployed
- [x] ev-ui auto-bump pipeline completed successfully
