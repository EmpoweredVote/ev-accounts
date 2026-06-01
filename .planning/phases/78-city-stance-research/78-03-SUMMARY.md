---
phase: 78-city-stance-research
plan: "03"
subsystem: stance-research
tags: [stance-research, san-diego, migration, csta-02]
dependency_graph:
  requires: [78-02]
  provides: [sd-stances]
  affects: [inform.politician_answers, inform.politician_context]
tech_stack:
  added: []
  patterns: [city-stance-migration, ON-CONFLICT-DO-UPDATE, value-correction-migration]
key_files:
  created:
    - backend/migrations/244_sd_stances.sql
    - backend/migrations/250_sd_stances_corrections.sql
decisions:
  - "Heather Ferbert (City Attorney, took office Jan 2025) replaced Mara Elliott — external_id -650002"
  - "Migration 244 applied with pre-correction researcher values; migration 250 applied corrections + missing stances"
  - "data-centers topic excluded per D-06 convention"
  - "44 value corrections applied via migration 250 (inversion-trap topics)"
  - "20 new stance pairs added via migration 250 (topics missed in initial batch)"
metrics:
  duration: "~45 minutes (2 sessions)"
  completed: "2026-06-01"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 78 Plan 03: San Diego Officials Stances Summary

**One-liner:** All 11 San Diego officials ingested with corrected values across 164+ stance rows; migration 244 applied initial batch, migration 250 applied 44 value corrections + 20 new stance pairs.

## Tasks Completed

| Task | Name | Files |
|------|------|-------|
| 1 | Research (3 batches: Gloria+Ferbert, D1-D5, D6-D9) + CSV review with corrections tabulated | .continue-here.md |
| 2 | Migration 244 written + applied; migration 250 corrections written + applied | backend/migrations/244_sd_stances.sql, backend/migrations/250_sd_stances_corrections.sql |

## Migration Details

| Migration | Purpose | Applied |
|-----------|---------|---------|
| `244_sd_stances.sql` | Initial stance batch for 11 SD officials | Yes |
| `250_sd_stances_corrections.sql` | 44 value corrections + 20 missing stance pairs | Yes |

## Stance Rows Per Politician (final state)

| Politician | Role | Stances in DB |
|-----------|------|--------------|
| Todd Gloria | Mayor | 23 |
| Heather Ferbert | City Attorney | 17 |
| Joe LaCava | D1 | 13 |
| Jennifer Campbell | D2 | 15 |
| Stephen Whitburn | D3 | 11 |
| Henry L. Foster III | D4 | 16 |
| Marni von Wilpert | D5 | 32 |
| Kent Lee | D6 | 7 |
| Raul Campillo | D7 | 13 |
| Vivian Moreno | D8 | 18 |
| Sean Elo-Rivera | D9 | 19 |
| **Total** | | **184** |

## Spot-Check Results

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| Every official ≥ 5 stances (D-07 floor) | 11/11 | 11/11 | Yes |
| data-centers rows in SD range | 0 | 0 | Yes |
| Orphan answers (no paired context row) | 0 | 0 | Yes |
| Gloria civil-rights value | 5 | 5 | Yes |
| Gloria climate-change value | 5 | 5 | Yes |
| Gloria same-sex-marriage value | 5 | 5 | Yes |

## Key Corrections Applied (migration 250)

### Value inversions fixed
- Todd Gloria: civil-rights 2→5, climate-change 2→5, same-sex-marriage 1→5, trans-athletes 1→5, housing 2→4, local-environment 2→5, immigration 2→4, transportation-priorities 2→4
- Vivian Moreno: climate-change 2→5, housing 2→4, rent-regulation 4→2
- Sean Elo-Rivera: climate-change 2→5, housing 2→4, homelessness 2→1, local-immigration 2→1, taxes 2→4
- Marni von Wilpert: civil-rights 2→5, climate-change 2→5, homelessness 3→2, homelessness-response 3→2, housing 2→3, local-immigration 2→1
- Plus corrections for Ferbert, LaCava, Campbell, Whitburn, Foster, Lee, Campillo

### Missing stances added (20 pairs)
- Gloria: +healthcare, +medicare/aid, +campaign-finance, +economic-development, +rent-regulation, +city-sanitation, +childcare
- Ferbert: +judicial-transparency, +judicial-government-deference, +local-immigration, +judicial-police-accountability
- LaCava: +homelessness-response, +local-immigration, +residential-zoning
- Whitburn: +climate-change, +local-immigration
- Foster: +taxes
- Lee: +local-immigration, +residential-zoning
- Campillo: +local-immigration

## Deviations from Plan

**Two-migration approach** (unplanned): Migration 244 was written from pre-correction researcher output and applied. The corrected values table from the research session (in .continue-here.md) was then applied via migration 250 rather than rewriting 244. This preserves audit history — 244 shows original researcher output, 250 shows the authoritative corrections.

## CSTA-02 Status

**Closed.** All 11 San Diego officials appear in the compass compare view with sourced stances. Every official exceeds the D-07 minimum floor (7 stances minimum, Marni von Wilpert highest at 32). Every stance row has a paired context row with at least one source URL. data-centers topic excluded per convention.

## Self-Check: PASSED

- [x] `backend/migrations/244_sd_stances.sql` exists and applied
- [x] `backend/migrations/250_sd_stances_corrections.sql` exists and applied
- [x] All 11 officials have ≥ 5 stances
- [x] 0 data-centers rows for SD external_id range
- [x] 0 orphan answer rows (every answer has a context row)
- [x] Corrected inversion-trap values verified for Gloria (spot-checked civil-rights, climate-change, same-sex-marriage)
