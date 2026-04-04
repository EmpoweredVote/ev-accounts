---
phase: 103-essentials-wiring-landing-page
plan: "04"
subsystem: database
tags: [typescript, postgresql, pg, dotenv, headshots, cdn, audit, csv]

# Dependency graph
requires:
  - phase: 103-essentials-wiring-landing-page
    provides: Phase context — D-16/D-17/D-18 decisions locking script location, four checks, and CSV format
provides:
  - TypeScript CLI script that audits all CDN politician headshots and outputs flagged issues as CSV
affects: [data-import, headshot-quality, cdn-health]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure Node PNG/JPEG header parsing via Buffer (no native deps like sharp)"
    - "AbortController 10s timeout on HEAD requests"
    - "Batched HTTP: 20 concurrent HEAD, 10 concurrent GET for memory safety"
    - "stderr for progress, stdout for CSV data"

key-files:
  created:
    - ev-accounts/backend/scripts/auditHeadshots.ts
  modified: []

key-decisions:
  - "Use pure Buffer header parsing for PNG/JPEG dimensions — avoids native sharp binary dep"
  - "--dry-run outputs counts to stdout (not stderr) for grep-ability"
  - "Only GET-fetch images that returned HTTP 200 in HEAD pass — avoids redundant fetches on broken URLs"

patterns-established:
  - "Pattern: Headshot audit script — dotenv + pg Pool + LEFT JOIN + batched fetch + CSV to stdout"

requirements-completed: [DATA-04]

# Metrics
duration: 2min
completed: 2026-04-04
---

# Phase 103 Plan 04: Headshot Audit Script Summary

**TypeScript CLI audit script scanning 645 CDN headshots across 78K politicians, flagging broken URLs, bad dimensions, file size outliers, and missing headshots as CSV**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-04T03:01:41Z
- **Completed:** 2026-04-04T03:03:13Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Created `ev-accounts/backend/scripts/auditHeadshots.ts` following established pg Pool + dotenv pattern
- Implemented four checks: missing headshots, broken CDN URLs (HEAD with 10s timeout), file size outliers (>500KB or <2KB), and image dimensions/aspect ratio (landscape/too_small/bad_aspect_ratio)
- Pure Node PNG/JPEG header parsing via Buffer reads — no native dependencies required
- Batched HTTP: 20 concurrent HEAD requests then 10 concurrent GET requests
- `--dry-run` flag for quick count verification (skips all HTTP)
- Verified against production DB: 78,936 politicians, 645 with images, 78,291 missing headshots

## Task Commits

Each task was committed atomically:

1. **Task 1: Create headshot audit script with four checks and CSV output** - `35f78e6` (feat)

## Files Created/Modified
- `ev-accounts/backend/scripts/auditHeadshots.ts` - CDN headshot audit script with four checks, CSV output to stdout, --dry-run support

## Decisions Made
- Used pure Buffer header parsing (PNG bytes 16-23, JPEG SOF0/SOF2 markers) instead of sharp — avoids native binary compilation
- Only GET-fetch images that passed the HEAD check — broken URLs skip dimension analysis to avoid redundant failures
- `--dry-run` sends summary to stdout (not stderr) for scripting/grep use

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The worktree at `agent-a9dad830` only has a partial ev-accounts checkout (no `node_modules`) — verified by copying to the main backend install and running there. Script functioned correctly with production DB returning 78,936 politicians.

## User Setup Required
None - no external service configuration required. Script uses existing `DATABASE_URL` env var.

## Next Phase Readiness
- Headshot audit script ready to run: `cd ev-accounts/backend && npx tsx scripts/auditHeadshots.ts --dry-run`
- Full audit (no --dry-run) will output CSV of flagged headshot issues for manual review
- DATA-04 requirement satisfied

---
*Phase: 103-essentials-wiring-landing-page*
*Completed: 2026-04-04*
