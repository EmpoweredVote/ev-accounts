---
phase: 160-field-resolution-stance-gap-diagnostic
plan: 05
subsystem: database
tags: [elections, us-house, field-resolution, csv, research-agents, ky, or, ct, ok, ar, ia, ks, ms]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 01)
    provides: 160-incumbent-map.csv, 160-race-preexistence-audit.csv (OR race IDs), 160-negative-id-audit.csv (KY-CD1/OK-CD1)
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 02)
    provides: validated 19-column template
provides:
  - 160-field-table-p164.csv — 38-row Phase-164 partial (KY 6 / OR 6 / CT 5 / OK 5 / AR 4 / IA 4 / KS 4 / MS 4); 29 decided + 9 late-primary
  - OR's 6 existing_race_id carried; KY-CD1/OK-CD1 collision notes embedded (alternate 200+ sub-band)
  - staging/p164-{KY,OR,CT,OK,AR,IA,KS,MS}.csv — per-state provenance
affects: [160-06, 160-07, phase-164]

# Tech tracking
tech-stack:
  added: []
  patterns: [3-batch dispatch across 8 states (max 3 concurrent throughout), inline collision-note embedding for saturated external-id bands]

key-files:
  created:
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p164.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-KY.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-OR.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-CT.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-OK.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-AR.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-IA.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-KS.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-MS.csv
  modified: []

key-decisions:
  - "KY-6 Barr (Senate run) normalized open-seat-vacancy → retired for milestone-wide taxonomy consistency (matches Moulton/Craig/Moore/Letlow/Hinson/Feenstra handling)"
  - "CT-1 Larson normalized contested-primary → renominated (provisional) with NOTE-CT1-CONTESTED preserved — he IS running; Bronin holds the convention line; re-pull after Aug-11"
  - "KY-CD1 + OK-CD1 rows carry NOTE-EXTERNAL-ID-COLLISION (alternate 200+ sub-band, safe_start_seq=200)"
  - "OK-1 counted decided: the triggered Aug-25 runoff dissolved when Lahmeyer withdrew Jun-17 (Tedford automatic nominee per OK procedure)"

patterns-established:
  - "Runoff-aware decided classification: OK/AR/MS runoff provisions checked explicitly before tagging decided"

requirements-completed: [USHC3-01]

# Metrics
duration: ~80min
completed: 2026-07-03
---

# Phase 160 Plan 05: Field Table P164 (8 states) Summary

**38-row Phase-164 partial (29 decided + 9 late-primary) across 8 states with OR's scaffolded races linked and the KY-CD1/OK-CD1 saturated ID bands flagged — headlined by KY-4 Thomas Massie LOSING his primary to Trump-endorsed Ed Gallrein and CT-1 Larson losing his convention endorsement**

## Performance

- **Duration:** ~80 min
- **Tasks:** 2
- **Files modified:** 9
- **Research agents:** 8, dispatched in rolling batches (KY/OR/OK → AR → IA → MS → CT → KS), never more than 3 concurrent

## Accomplishments
- All 38 districts resolved from real fetched sources; zero UNRESOLVED — no Playwright sweep needed
- **KY-4 UPSET: Massie lost his primary 45.1–54.9 to Ed Gallrein** (lost-primary; Massie not on the Nov ballot)
- Departures verified: KY-6 Barr (Senate), OK-1 Hern (Senate), IA-2 Hinson (Senate), IA-4 Feenstra (Governor) — all retired; all OR/AR/MS/KS incumbents refiled and renominated
- OK runoff check: the only triggered runoff (OK-1 R) dissolved via Lahmeyer's Jun-17 withdrawal → all 5 OK districts decided
- OR's 6 existing_race_id carried; OR minor-party window open to Aug-25 (Faler CD-6 petitioning, excluded until certified); no writes to the parallel session's 177/178 dirs
- KS redistricting verified: NO new map (veto not overridden; 2022 map + geo_ids 2001-2004 stand)
- IA ballot-access adjudications from official State Objection Panel rulings (Battaglia excluded pending litigation; Stewart kept)

## Task Commits

1. **Task 1: Dispatch 8-state research agents (3-concurrent batches)** - `081a2933` (feat)
2. **Task 2: Assemble 160-field-table-p164.csv (38-row guards + notes)** - `f2d51f29` (feat)

## Files Created/Modified
- `160-field-table-p164.csv` - 38-row Phase-164 partial, seeding_phase=164
- `staging/p164-{KY,OR,CT,OK,AR,IA,KS,MS}.csv` - per-state agent outputs

## Decisions Made
- Filing windows captured per D-03: CT independents 2026-08-05, KS independents 2026-08-03, OR minor-party 2026-08-25; KY/OK/AR/IA/MS closed (blank).
- Two agent-returned non-standard nominee_status values normalized to the 8-value taxonomy at assembly with the underlying facts preserved as row notes (KY-6, CT-1) — the assembly guard now enforces taxonomy membership.

## Deviations from Plan

**1. [Rule 1 - Data consistency] Agent-returned nominee_status values outside the taxonomy**
- **Found during:** Task 2 assembly validation
- **Issue:** KY agent used `open-seat-vacancy` for Barr's Senate run (milestone precedent = `retired`); CT agent used non-taxonomy `contested-primary` for Larson
- **Fix:** Normalized both at assembly; facts preserved in-row (NOTE-CT1-CONTESTED) and here
- **Verification:** Assembly guard asserts all 38 nominee_status values ∈ 8-value taxonomy
- **Impact:** Taxonomy-consistent master table; no information lost

**Total deviations:** 1 auto-fixed (value normalization). No scope creep.

## Issues Encountered
- FEC API DEMO_KEY rate-limited during this wave; KS SoS dynamic candidate tool throws a genuine server-side error on POST — both routed around via official static pages, certified-results PDFs, and fetched Wikipedia wikitext.
- CT-5 R primary field has one unconfirmed name (Botelho — included as declared but flagged unconfirmed for primary-ballot status); resolves at the Aug-11 re-pull.

## Next Phase Readiness
- Phase-164 seeding must: use the 200+ external-id sub-band for KY-CD1/OK-CD1; reuse OR's 6 races; re-pull CT after Aug-11 (+Aug-5 independents), KS after Aug-4 (+Aug-3 independents), OR minor-party after Aug-25.
- Wave 6 (Plan 06, 17 small states incl. AK/ME RCV over-indulgence) is the final research wave.

---
*Phase: 160-field-resolution-stance-gap-diagnostic*
*Completed: 2026-07-03*
