---
phase: 75-race-catalog-candidate-records
plan: 01
status: complete
date: 2026-05-22
subsystem: essentials.politicians + essentials.offices
affects: [phase-76-candidate-stance-research]
requires: [phase-72, phase-73]
tech-stack:
  added: []
  patterns: ["candidate discriminator: essentials.offices.title LIKE 'Candidate for U.S. Senate%' + p.is_incumbent=false"]
key-files:
  created:
    - backend/migrations/196_us_senate_candidates_2026.sql
    - .planning/phases/75-race-catalog-candidate-records/75-01-photo-url-table.md
    - .planning/phases/75-race-catalog-candidate-records/75-01-SUMMARY.md
  modified:
    - .planning/STATE.md
decisions:
  - id: CAND-DISCRIMINATOR
    choice: offices.title LIKE 'Candidate for U.S. Senate%' (not a politician column)
    reason: essentials.politicians has no office_title column; all title data lives in essentials.offices
  - id: BROWN-PATH
    choice: INSERT new at -400137
    reason: No existing Sherrod Brown record found in DB (0 rows returned from ILIKE query)
  - id: EXPLICIT-NULL-PHOTOS
    choice: 8 candidates left with NULL photo_origin_url
    reason: No stable public photo found after exhaustive search 2026-05-22; documented in migration header
metrics:
  duration: 8m 16s
  completed: 2026-05-22
---

# Phase 75 Plan 01 SUMMARY

**Migration 196: 43 non-incumbent 2026 Senate candidates inserted as essentials.politicians + offices rows, linked to NATIONAL_UPPER districts by state, with photo_origin_url set where available — Phase 76 stance research unblocked**

## Performance

- Duration: 8m 16s
- Tasks: 3
- Files created: 3
- Files modified: 1 (STATE.md)

## What Shipped

- Migration 196 applied: 43 candidate politician rows (external_id -400101 to -400143) + 43 office rows
- Candidate discriminator: `essentials.offices.title = 'Candidate for U.S. Senate — [State]'` (NOT a politician column — `office_title` column does not exist on `essentials.politicians`)
- Sherrod Brown handling: **INSERT-new-at-400137** — no existing record found in DB (query returned 0 rows)
- Husted (OH, -400061) and Armstrong (OK, -400064) untouched — remain appointed incumbents from migration 176
- RACE-01: `.planning/phases/75-race-catalog-candidate-records/75-RESEARCH.md` IS the race catalog. Spec said "34 races" — actual count is **35** (33 Class 2 + FL/OH Class 3 specials). Both specials included because they have competitive non-incumbent candidates tracked in this phase.
- 35 photo URLs set: 16 from unitedstates.github.io CDN (current/former Congress members), 19 from Wikipedia direct upload.wikimedia.org URLs — all HEAD-verified HTTP 200 before committing to SQL
- 8 candidates left with NULL photo_origin_url (documented in migration header and explicit-null section below)

## Success-Criteria Verification

| Query | Expected | Actual | Pass |
|-------|----------|--------|------|
| CAND-01 candidate count (distinct p.id via offices join) | >=43 | 43 | PASS |
| CAND-02 office count (o.title LIKE 'Candidate for U.S. Senate%') | 43 | 43 | PASS |
| CAND-02 state mismatch (representing_state vs district.state) | 0 rows | 0 rows | PASS |
| CAND-03 missing photos | 0 or documented 8 | 8 (documented) | PASS |
| Idempotency: re-apply produces 0 net changes | all INSERT 0 0 / UPDATE 0 | confirmed | PASS |
| Husted/Armstrong duplicate check (-400061, -400064) | 2 rows w/ row_count=1 | 2 rows, each count=1 | PASS |
| Sherrod Brown duplicate check | 1 row | 1 row | PASS |

## Explicit-Null Candidates (8 total)

These candidates had no stable, hotlinkable public photo URL found after search 2026-05-22:

| external_id | Name | State | Party | Reason |
|-------------|------|-------|-------|--------|
| -400103 | Dakarai Larriett | AL | D | New candidate, no Wikipedia page or stable public photo |
| -400105 | Hallie Shoffner | AR | D | Rice farmer, no stable public photo |
| -400106 | Janak Joshi | CO | R | Wikipedia page exists but no image |
| -400111 | David Roth | ID | D | New candidate, no Wikipedia page or stable public photo |
| -400113 | Don Tracy | IL | R | Former IL GOP chair, no stable public photo |
| -400129 | Scott Colom | MS | D | Wikipedia page exists but no image |
| -400140 | Annie Andrews | SC | D | Pediatrician candidate, no stable public photo |
| -400141 | Rachel Fetty Anderson | WV | D | City councilwoman, no stable public photo |

## Task Commits

1. **Task 1: Pre-flight verification + photo URL table** — `b883ffc`
2. **Task 2: Migration 196** — `3364e27`
3. **Task 3: Verification + SUMMARY** — (this commit)

## Files Created/Modified

- `backend/migrations/196_us_senate_candidates_2026.sql` (created — 1,444 lines)
- `.planning/phases/75-race-catalog-candidate-records/75-01-photo-url-table.md` (created)
- `.planning/phases/75-race-catalog-candidate-records/75-01-SUMMARY.md` (this file)
- `.planning/STATE.md` (updated — Phase 75 Plan 01 completion noted)

## Deviations from Plan

None — plan executed exactly as written.

Key notes that are not deviations:
- The RESEARCH.md comment about `is_current = false` in the SQL pattern was a documentation error in that file. The actual `essentials.offices` table has no `is_current` column. The migration correctly omits it (grep confirmed 0 actual column references in the SQL).
- 8 explicit-null photos is within the plan's documented acceptable range ("0 or documented null count").

## Issues Encountered

None. Migration applied cleanly on first run; idempotency confirmed on second run.

## Next Phase Readiness

Phase 76 (Candidate Stance Research) is now unblocked. All 43 candidate politician rows exist with correct NATIONAL_UPPER office FK chain. The compass compare view can FK-resolve candidates using `essentials.offices.title LIKE 'Candidate for U.S. Senate%'` + `p.is_incumbent = false` as the discriminator, the same pattern it uses to distinguish sitting senators from candidates.

---
*Phase: 75-race-catalog-candidate-records*
*Plan: 01*
*Completed: 2026-05-22*
