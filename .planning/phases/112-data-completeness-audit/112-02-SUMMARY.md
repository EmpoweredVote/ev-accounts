---
phase: 112-data-completeness-audit
plan: 02
subsystem: database
tags: [typescript, postgresql, audit, csv, pg, dotenv, tsx]

requires:
  - phase: 112-data-completeness-audit/112-01
    provides: race and candidate audit scripts (AUDIT-01, AUDIT-02); established boilerplate pattern

provides:
  - audit-112-stances.ts: AUDIT-03 compass stance coverage per candidate (ratio, not binary)
  - audit-112-quotes.ts: AUDIT-04 Read & Rank quote count per candidate (count, not binary)
  - audit-112-headshots.ts: AUDIT-05 headshot classification as cdn/local/none per candidate
  - audit-112-profile.ts: AUDIT-06 individual profile field completeness for linked candidates

affects: [112-03, 112-04, gap-report, data-imports]

tech-stack:
  added: []
  patterns:
    - "Stub-safe audit queries: LEFT JOIN on politician_id guards against NULL FK silently producing zero-stance rows for unlinked candidates"
    - "Election validation gate: all audit scripts check election existence before running main query"
    - "is_linked column pattern: CASE WHEN politician_id IS NOT NULL THEN 'linked' ELSE 'stub' distinguishes linked vs stub in CSV output"
    - "pct=N/A for stubs: stub candidates get pct=N/A in stances output, not 0% — prevents misleading comparisons"

key-files:
  created:
    - ev-accounts/backend/scripts/audit-112-stances.ts
    - ev-accounts/backend/scripts/audit-112-quotes.ts
    - ev-accounts/backend/scripts/audit-112-headshots.ts
    - ev-accounts/backend/scripts/audit-112-profile.ts
  modified: []

key-decisions:
  - "Profile script (AUDIT-06) only processes linked candidates (politician_id IS NOT NULL) — stubs have no politician record to measure; stub count logged to stderr for auditor awareness"
  - "Stance pct computed in application code (not SQL) to enable N/A for stubs vs numeric percent for linked candidates"
  - "Headshots script is DB-only (no HTTP checks) — photo_source classification from DB state is sufficient for gap audit; HTTP checks are in the existing auditHeadshots.ts if needed"

patterns-established:
  - "Stub-safe LEFT JOIN: guard all cross-schema joins (race_candidates → inform/essentials) against NULL politician_id"
  - "Per-candidate ratio reporting: stance coverage as answered/total, not has-any binary"
  - "Field-level profile reporting: bio Y/N + individual counts (not rolled-up score)"

requirements-completed: [AUDIT-03, AUDIT-04, AUDIT-05, AUDIT-06]

duration: 15min
completed: 2026-04-12
---

# Phase 112 Plan 02: Data Completeness Audit — Stance/Quote/Headshot/Profile Scripts Summary

**Four audit dimension scripts covering stance coverage (ratio), quote count, headshot classification (cdn/local/none), and individual profile field completeness for Monroe County May 5, 2026 primary candidates**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-12T16:30:00Z
- **Completed:** 2026-04-12T16:45:00Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments

- Created `audit-112-stances.ts` (AUDIT-03): reports compass stance coverage per candidate as a ratio (answered/live topics), with stubs labeled is_linked=stub and pct=N/A — 26 live topics; 5/51 linked candidates have any stances
- Created `audit-112-quotes.ts` (AUDIT-04): reports Read & Rank quote count per candidate — 4/51 linked candidates have any quotes; 30 stubs correctly labeled
- Created `audit-112-headshots.ts` (AUDIT-05): classifies photo source as cdn/local/none per candidate via DB-only check — 19 cdn, 0 local, 62 none across 81 candidates
- Created `audit-112-profile.ts` (AUDIT-06): reports individual fields (has_bio Y/N, contact/degree/experience counts) for linked candidates only — 51 linked; 0/51 with bio, 30/51 with contacts, 15/51 with education, 23/51 with experience

## Task Commits

Each task was committed atomically (in ev-accounts repo):

1. **Task 1: Stance and quote audit scripts (AUDIT-03, AUDIT-04)** - `4893f79` (feat)
2. **Task 2: Headshot and profile completeness audit scripts (AUDIT-05, AUDIT-06)** - `895ef38` (feat)

## Files Created/Modified

- `ev-accounts/backend/scripts/audit-112-stances.ts` - AUDIT-03: compass stance coverage with ratio per candidate, stub-safe LEFT JOIN
- `ev-accounts/backend/scripts/audit-112-quotes.ts` - AUDIT-04: Read & Rank quote count per candidate
- `ev-accounts/backend/scripts/audit-112-headshots.ts` - AUDIT-05: headshot source classification (cdn/local/none), no HTTP checks
- `ev-accounts/backend/scripts/audit-112-profile.ts` - AUDIT-06: individual profile fields for linked candidates (bio Y/N + counts)

## Decisions Made

- Profile script only processes linked candidates — stubs have no politician_id and therefore no bio/contacts/degrees/experiences rows to count. Stub count is logged to stderr so the auditor knows how many were excluded.
- Stance pct computed in TypeScript, not SQL — enables N/A string for stubs vs numeric percent for linked candidates (SQL ROUND would return NULL for stubs, which CSV would render as empty string rather than the explicit "N/A" label)
- Headshot script performs DB-only classification — photo_source from DB state is the right audit question (does the platform have a photo?); broken URL checks are a separate concern already handled by the existing `auditHeadshots.ts` script

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. Scripts read from local `.env` (DATABASE_URL) which is already configured for all backend script work.

## Preliminary Audit Findings (from dry-run)

These numbers are the starting baseline for the gap report:

| Dimension | Total | Linked | Stubs | Coverage |
|-----------|-------|--------|-------|----------|
| Candidates | 81 | 51 | 30 | — |
| Stances | — | 51 | 30 | 5/51 linked have any stances (26 live topics) |
| Quotes | — | 51 | 30 | 4/51 linked have any quotes |
| Headshots (CDN) | 81 | — | — | 19 cdn, 0 local, 62 none |
| Bio | 51 | 51 | — | 0/51 |
| Contacts | 51 | 51 | — | 30/51 |
| Education | 51 | 51 | — | 15/51 |
| Experience | 51 | 51 | — | 23/51 |

The data completeness gap is significant across all dimensions — this is expected context for the gap report phase.

## Next Phase Readiness

- All 6 audit dimension scripts (AUDIT-01 through AUDIT-06) are complete and verified with `--dry-run`
- Combined with Plan 01's race/candidate scripts, full data quality picture is available
- Ready for assembly script (audit-112-assemble.ts) or direct gap report synthesis

---
*Phase: 112-data-completeness-audit*
*Completed: 2026-04-12*
