---
phase: 160-field-resolution-stance-gap-diagnostic
plan: 03
subsystem: database
tags: [elections, us-house, field-resolution, csv, research-agents, in, md, mn, mo]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 01)
    provides: 160-incumbent-map.csv (incl. 11 zero-tier flags), 160-race-preexistence-audit.csv (MD race IDs + IN-9 bug rows)
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 02)
    provides: validated 19-column template + agent-prompt discipline
provides:
  - 160-field-table-p162.csv — 33-row Phase-162 partial (IN 9 / MD 8 / MN 8 / MO 8); 17 decided + 16 late-primary
  - 11 zero-tier incumbents flagged in-scope for downstream stance research (MD all 8 + IN Baird/Carson/Messmer)
  - IN-9 incumbent-flag bug carried as NOTE-IN9-INCUMBENT-FLAG-BUG in the IN-9 row (documented, not propagated)
  - staging/p162-{IN,MD,MN,MO}.csv — per-state provenance
affects: [160-04, 160-05, 160-06, 160-07, phase-162]

# Tech tracking
tech-stack:
  added: []
  patterns: [decided-state pattern first use (confirmed Nov-3 general field from primary results)]

key-files:
  created:
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p162.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p162-IN.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p162-MD.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p162-MN.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p162-MO.csv
  modified: []

key-decisions:
  - "MD rows are field_status=decided (party nominees resolved from official Jun-23 results at 100% precincts) but carry filing_open_deadline=2026-08-03 — MD's unaffiliated/minor-party window is still open statewide; Phase 162 re-checks after Aug-3"
  - "MO rows carry filing_open_deadline=2026-07-27 (independent petition deadline still open)"
  - "MD unofficial-but-unambiguous results used per plan instruction (canvass finalizing, every district a clear plurality)"
  - "IN-9 bug note appended to new_records_needed at assembly (NOTE-IN9-INCUMBENT-FLAG-BUG) so Phase 162 fixes flags before seeding"

patterns-established:
  - "Decided-state rows: general_candidates = primary winners + ballot-qualified minor-party/independent candidates; write-ins excluded via official/Green-Papers classification"

requirements-completed: [USHC3-01]

# Metrics
duration: ~45min
completed: 2026-07-02
---

# Phase 160 Plan 03: Field Table P162 (IN/MD/MN/MO) Summary

**33-row Phase-162 partial: 17 decided rows (IN May-5 + MD Jun-23 primaries, nominees from official results) + 16 late-primary rows (MN/MO full filed fields), with all 11 zero-tier incumbents flagged and the IN-9 incumbent-flag bug documented-not-propagated**

## Performance

- **Duration:** ~45 min (incl. one full agent-wave retry after session-limit deaths)
- **Tasks:** 2
- **Files modified:** 5
- **Research agents:** 4 dispatched twice (first wave of 3 died instantly on session usage limit; clean re-dispatch after verifying zero partial files)

## Accomplishments
- All 33 districts resolved with real fetched sources; zero UNRESOLVED — no Playwright sweep needed
- Incumbent departures verified, not assumed: MD-5 Hoyer retired (Boafo won 23-candidate primary 32.84%), MN-2 Craig filed for US Senate (open seat, 7 candidates), MO-6 Graves retired (WSJ Mar-27; listed Withdrawn on official roster)
- IN: all 9 incumbents renominated May-5; Libertarian convention nominees included as ballot-qualified; write-ins excluded per Green Papers classification
- MO redistricting determination: the 2025 GOP-drawn map IS in effect for 2026 (MO Supreme Court upheld 4-3 on 2026-03-24; pending referendum does not affect the 2026 cycle)
- MD's 8 existing_race_id carried; 11 zero-tier incumbents (MD 8 + IN Baird/Carson/Messmer) confirmed in the partial

## Task Commits

1. **Task 1: Dispatch IN/MD/MN/MO research agents** - `e9ed5634` (feat)
2. **Task 2: Assemble 160-field-table-p162.csv (33-row guard)** - `7aa6da8a` (feat)

## Files Created/Modified
- `160-field-table-p162.csv` - 33-row Phase-162 partial, seeding_phase=162
- `staging/p162-{IN,MD,MN,MO}.csv` - per-state agent outputs

## Decisions Made
- MD decided + open independent window handled as decided-with-deadline (field_status=decided, filing_open_deadline=2026-08-03) — nominees are final, independents may still join; same pattern for MO late-primary (2026-07-27).
- MO source_url points to fetched raw Wikipedia wikitext (which cites the official SoS filing list) because the MO SoS ASPX candidate pages render only nav boilerplate through curl/jina.

## Deviations from Plan

**1. [Rule 3 - Blocking] First agent wave (IN/MD/MN) died instantly on provider session limit**
- **Found during:** Task 1 dispatch
- **Issue:** All three agents returned "You've hit your session limit" with no work done
- **Fix:** Verified no partial staging files existed, re-dispatched identical prompts after user said continue; second wave succeeded
- **Verification:** All 4 staging CSVs validate against the 19-column template
- **Impact:** ~15 min delay, no data impact

**Total deviations:** 1 auto-recovered (quota retry). No scope creep.

## Issues Encountered
- MO SoS dynamic ASPX candidate pages are unfetchable via curl/r.jina.ai (nav boilerplate only) — Wikipedia raw wikitext (citing the SoS list) used as the fetched source instead; MN's equivalent ASP.NET page DID render via r.jina.ai with the right GET params.

## Next Phase Readiness
- Phase-162 seeding must: (a) fix the IN-9 incumbent flags before wiring candidates (see NOTE-IN9-INCUMBENT-FLAG-BUG in the IN-9 row), (b) re-pull MD after Aug-3 and MO after Jul-27 for late independents, (c) treat the 11 zero-tier incumbents as IN-SCOPE for stance research.
- Wave 4 (Plan 04, WI/CO/AL/SC/LA) proceeds with the same validated template.

---
*Phase: 160-field-resolution-stance-gap-diagnostic*
*Completed: 2026-07-02*
