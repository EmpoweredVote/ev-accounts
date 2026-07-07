---
phase: 160-field-resolution-stance-gap-diagnostic
plan: 02
subsystem: database
tags: [elections, us-house, field-resolution, csv, research-agents, wa, az, tn, ma]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 01)
    provides: 160-incumbent-map.csv (incumbent pid/external_id/stance_count/tier by geo_id), 160-race-preexistence-audit.csv (MA existing_race_id)
provides:
  - 160-field-table-p161.csv — 37-row Phase-161 field partial (WA 10 / AZ 9 / TN 9 / MA 9), all field_status=late-primary, 19-column schema
  - Validated 19-column row template (D-01a) reused verbatim by Waves 3-6
  - staging/p161-{WA,AZ,TN,MA}.csv — per-state research-agent outputs with provenance
affects: [160-03, 160-04, 160-05, 160-06, 160-07, phase-161]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-state research agent fan-out (max 3 concurrent), authoritative incumbent-map join at assembly, 37-row hard guard before write]

key-files:
  created:
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p161.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p161-WA.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p161-AZ.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p161-TN.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p161-MA.csv
  modified: []

key-decisions:
  - "MA rows carry filing_open_deadline=2026-08-25 (independent filing still open per sec.state.ma.us) with field_status=late-primary — the D-03 declared-so-far pattern's first live use"
  - "Incumbent columns are overwritten from 160-incumbent-map.csv at assembly time (authoritative join), not trusted from agent echoes"
  - "AZ minor-party candidates with conflicting party labels in sources recorded generically as (IND) rather than overclaiming a specific ballot line"
  - "MA bare-FEC-filing independents excluded pending the Aug-25 state deadline; only news-evidenced declared independent (Milleron MA-1) included"

patterns-established:
  - "Late-primary template: full filed-qualified field in general_candidates, field_status=late-primary, filing_open_deadline only when a filing window is genuinely open"
  - "Staging-file provenance: each research agent writes its own state CSV; orchestrator validates against the 19-col template before assembly"

requirements-completed: [USHC3-01]

# Metrics
duration: ~35min
completed: 2026-07-02
---

# Phase 160 Plan 02: Field Table P161 (WA/AZ/TN/MA) Summary

**37-row late-primary field partial for the Phase-161 seeding group, resolved from official SoS candidate lists (VoteWA, TN SoS qualified-candidate PDF, MA Elections Division certified lists) with zero UNRESOLVED districts and the 19-column template validated on the anchor wave**

## Performance

- **Duration:** ~35 min
- **Tasks:** 2
- **Files modified:** 5 (4 staging + 1 final CSV)
- **Research agents:** 4 (one per state, max 3 concurrent honored — MA dispatched only after AZ returned)

## Accomplishments
- All 37 districts resolved from real fetched unwalled sources — **no Playwright sweep needed** (zero UNRESOLVED residue)
- D-01a template validation passed on first-returned agent (AZ) with no correction; WA/TN/MA conformed
- Open seats / departures correctly resolved: AZ-1 Schweikert `retired` (governor run), AZ-5 Biggs `retired` (governor run), WA-4 Newhouse `retired`, TN-6 Rose `retired` (governor run), TN-9 Cohen `redistricted`, MA-6 Moulton `retired` (Senate run vs Markey)
- MA's 9 rows carry existing_race_id from the race-preexistence audit; WA/AZ/TN blank as required
- WA's 10 rows tagged ballot_system=top-two; withdrawn candidates excluded per official VoteWA status

## Task Commits

1. **Task 1: Dispatch WA/AZ/TN/MA research agents + validate template** - `f1b9ecd8` (feat)
2. **Task 2: Assemble 160-field-table-p161.csv (37-row guard)** - `d2009e3c` (feat)

## Files Created/Modified
- `160-field-table-p161.csv` - 37-row Phase-161 partial, 19 columns, seeding_phase=161
- `staging/p161-{WA,AZ,TN,MA}.csv` - per-state agent outputs (provenance retained)

## Decisions Made
- MA filing_open_deadline=2026-08-25 on all 9 rows: MA party filing closed Jun-2 but independent filing runs to Aug-25 — first live use of the D-03 declared-so-far pattern; Phase 161 re-pulls MA after Aug-25.
- Authoritative incumbent join at assembly (map wins over agent echoes) — guarantees the acceptance criterion "incumbent_pid matches 160-incumbent-map.csv" structurally.

## Deviations from Plan

**1. [Rule 1 - Bug-adjacent] Plan verify snippets use `python3`, which is a dead Microsoft-Store alias on this machine**
- **Found during:** Task 2 verification
- **Issue:** `python3` exits 49 (Store stub); real interpreter is `py` (Python 3.14.3)
- **Fix:** Ran the identical verification code via `py`
- **Verification:** PLAN VERIFY PASS + ACCEPTANCE PASS printed
- **Impact:** None on data; note for Plans 03-07 verify snippets

**Total deviations:** 1 auto-fixed (tooling substitution only). No scope creep.

## Issues Encountered
- **TENNESSEE MID-CYCLE REDISTRICTING (flagged for downstream phases):** TN enacted HB 7003/SB 7001 (signed May 7, 2026) redrawing its congressional map mid-cycle (Memphis majority-Black district dismantled; qualifying deadline extended to May 15, 2026). The field rows reflect the NEW districts per the official May-29 qualified-candidate list, but **TN district boundaries no longer match 2024 TIGER shapes** — Phase 161 seeding and House geofencing for TN must verify district-shape/geo_id alignment before wiring races to districts. TN-9 nominee_status=redistricted (Cohen withdrew citing the new map).
- AZ SoS candidate portal is Cloudflare-walled even via r.jina.ai; AZ rows source raw Wikipedia wikitext (fetched, which itself cites the portal) cross-checked against the FEC API.

## Next Phase Readiness
- The 19-column template is validated; Waves 3-6 (Plans 03-06) reuse it verbatim.
- TN redistricting flag must be carried into 160-FIELD-TABLE.md (Plan 07) and the Phase 161 seeding notes.

---
*Phase: 160-field-resolution-stance-gap-diagnostic*
*Completed: 2026-07-02*
