---
phase: 78-city-stance-research
plan: "02"
subsystem: stance-research
tags: [stance-research, san-jose, migration, csta-01]
dependency_graph:
  requires: [78-01]
  provides: [sj-mayor-stances]
  affects: [inform.politician_answers, inform.politician_context]
tech_stack:
  added: []
  patterns: [city-stance-migration, ON-CONFLICT-DO-UPDATE, dollar-quoted-reasoning]
key_files:
  created:
    - backend/migrations/221_sj_stances.sql
  modified:
    - backend/data/stance-research/2026-05-28-san-jose-officials.csv
decisions:
  - "Excluded 10 SJ council members (adjacent-evidence only) — user decision 2026-05-28"
  - "CSTA-01 partially closed: Mayor covered, council members deferred"
  - "Migration number 221 (one above 220_sacramento_officials.sql)"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-28"
  tasks_completed: 2
  files_created: 1
  files_modified: 0
---

# Phase 78 Plan 02: San Jose Officials Stances Summary

**One-liner:** Matt Mahan (SJ Mayor) ingested with 12 direct-evidence stance rows across homelessness, housing, public safety, economic development, and more; 10 council members excluded by user decision (adjacent-evidence only).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | CSV reviewed and filtered | (prior session) | backend/data/stance-research/2026-05-28-san-jose-officials.csv |
| 2 | Migration 221 generated, applied, spot-checked | (this session) | backend/migrations/221_sj_stances.sql |

## Migration Details

- **Migration file:** `backend/migrations/221_sj_stances.sql`
- **Migration number:** 221 (one above 220_sacramento_officials.sql, the previous highest-numbered file)
- **Applied via psql:** Yes — transaction committed, 24 INSERT statements (12 answers + 12 context rows)

## Stance Rows Per Politician

| Politician | Role | Stances Ingested | Evidence Type |
|-----------|------|-----------------|---------------|
| Matt Mahan | Mayor | 12 | Direct evidence |
| Rosemary Kamei | Council D1 | 0 | Excluded — adjacent only |
| Pamela Campos | Council D2 | 0 | Excluded — adjacent only |
| Anthony Tordillos | Council D3 | 0 | Excluded — adjacent only |
| David Cohen | Council D4 | 0 | Excluded — adjacent only |
| Peter Ortiz | Council D5 | 0 | Excluded — adjacent only |
| Michael Mulcahy | Council D6 | 0 | Excluded — adjacent only |
| Bien Doan | Council D7 | 0 | Excluded — adjacent only |
| Domingo Candelas | Council D8 | 0 | Excluded — adjacent only |
| Pam Foley | Council D9 | 0 | Excluded — adjacent only |
| George Casey | Council D10 | 0 | Excluded — adjacent only |
| **Total** | | **12** | |

## Matt Mahan Topics Ingested

| Topic Key | Value |
|-----------|-------|
| homelessness | 4.0 |
| homelessness-response | 3.0 |
| housing | 3.0 |
| public-safety-approach | 4.0 |
| economic-development | 4.0 |
| growth-and-development | 4.0 |
| residential-zoning | 3.0 |
| taxes | 3.0 |
| redistricting | 3.0 |
| local-immigration | 3.0 |
| transportation-priorities | 3.0 |
| city-sanitation | 4.0 |

## Spot-Check Results

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| politician_answers rows for Matt Mahan | 12 | 12 | Yes |
| data-centers rows (must be 0) | 0 | 0 | Yes |
| Unpaired answers (no context row) | 0 | 0 | Yes |
| Distinct SJ politicians with stances | 1 | 1 | Yes |

## Deviations from Plan

### User-Directed Scope Reduction

**D-07 Floor Override — User Decision 2026-05-28**

- **Found during:** Task 1 review / checkpoint
- **Issue:** The approved CSV contained 12 rows of direct evidence for Matt Mahan and 61 rows of adjacent-evidence-only inferences for the 10 council members (D1–D10). The plan's D-07 floor required 5 stances per politician, but the council member rows were constructed from district demographics, historical voting patterns, and endorsement profiles — not direct public statements or votes.
- **User decision:** Explicitly chose to remove all 10 council member rows. Only direct-evidence stances to be ingested. The D-07 5-stance floor was overridden by this decision.
- **Fix:** CSV filtered to Matt Mahan's 12 rows only. Migration written and applied for 1 politician.
- **Files modified:** backend/data/stance-research/2026-05-28-san-jose-officials.csv (council member rows retained in file but not in migration)
- **CSTA-01 impact:** Partially closed — Mayor covered; council members deferred until direct evidence becomes available (future phase).

## CSTA-01 Status

**Partially closed.** Matt Mahan (Mayor of San Jose) appears in the compass compare view with 12 sourced stances across housing, homelessness, public safety, economic development, and more. The 10 SJ council members (D1–D10) remain without stance data in the DB. Their politician records exist (migration 218) but `politician_answers` rows are absent pending a future research pass that produces direct-evidence sourcing.

## Self-Check: PASSED

- [x] `backend/migrations/221_sj_stances.sql` exists
- [x] Migration applied successfully (COMMIT received, 24 INSERT 0 1 lines)
- [x] 12 answer rows in DB for Matt Mahan
- [x] 0 data-centers rows
- [x] 0 unpaired answer rows (every answer has a context row)
- [x] 1 distinct SJ politician with stances (as expected — only Mayor ingested)
