---
phase: 160-field-resolution-stance-gap-diagnostic
plan: 06
subsystem: database
tags: [elections, us-house, field-resolution, csv, research-agents, rcv, ak, me, nv, ut, small-states]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 01)
    provides: 160-incumbent-map.csv, 160-race-preexistence-audit.csv (NV/ME race IDs, NV-2 anomaly, UT primary rows)
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 02)
    provides: validated 19-column template
provides:
  - 160-field-table-p165.csv — 34-row Phase-165 partial (17 states); 24 decided + 10 late-primary; AK+ME rcv=true
  - AK full top-four-rcv field (15 certified candidates); ME complete rcv-general fields
  - NV reconciliation (9 wired rows all valid; 5 new certified candidates; NV-2 NULL-pid fix-not-recreate)
  - UT court-ordered-redistricting re-key note (NOTE-UT-REDISTRICTED-2026)
  - staging/p165-*.csv (17 files) — per-state provenance
affects: [160-07, phase-165]

# Tech tracking
tech-stack:
  added: []
  patterns: [D-04a RCV over-indulgence execution (exhaustive official-list cross-check), verify-not-duplicate reconciliation for pre-wired states]

key-files:
  created:
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p165.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p165-AK.csv (+ 16 more state staging CSVs)
  modified: []

key-decisions:
  - "UT-1/2/3 nominee_status=redistricted (incumbents moved districts under the court map), UT-4 retired — normalized from agent's non-taxonomy open-seat-redistricted"
  - "NE-2/MT-1/SD-0 normalized open-seat-vacancy → retired (chose-not-to-run precedent)"
  - "13 routine states dispatched as 5 paired/tripled agents (2-5 districts each) instead of 13 singles — concurrency cap (3) unchanged; per-agent load stayed below earlier single-state loads"
  - "NV: 5 stale Wikipedia-declared independents explicitly excluded (absent from the certified SoS ballot list) — do-not-add list recorded"

patterns-established:
  - "RCV exhaustiveness proof: official list + independent source must match exactly on candidate count before the field is accepted"

requirements-completed: [USHC3-01]

# Metrics
duration: ~2h
completed: 2026-07-03
---

# Phase 160 Plan 06: Field Table P165 (17 small states) Summary

**34-row Phase-165 partial with AK's full 15-candidate top-four-RCV field and ME's complete RCV general fields captured exhaustively (D-04a), NV's pre-wired races verified-not-duplicated, and the discovery that UTAH WAS COMPLETELY REDISTRICTED for 2026 by court order — every UT incumbent shifted one district and the DB must re-key before seeding**

## Performance

- **Duration:** ~2h (longest wave — 17 states)
- **Tasks:** 3
- **Files modified:** 18
- **Research agents:** 12 (4 special singles: AK/ME/NV/UT; 8 routine dispatches incl. paired NM, NE, WV+ID, MT+ND+SD, HI+NH, RI+DE+VT+WY), max 3 concurrent throughout

## Accomplishments
- **Zero UNRESOLVED districts across all 34** — no orchestrator Playwright sweep needed (the HI/NH agent ran its own Playwright for two bot-walled official sources: olvr.hawaii.gov grid + NH SoS cumulative-filing PDF)
- **RCV over-indulgence delivered:** AK = 15 certified candidates (official DoE list, exact cross-source match; Begich renominated); ME = complete general fields from official RCV tabulations (Pingree renominated 100%; ME-2 Dunlap-D beat Baldacci 52.5% in round 4; LePage-R; A2+A3 both CONFIRMED)
- **UT COURT-ORDERED REDISTRICTING (5th and most consequential mid-cycle map flag):** LWV v. Utah Legislature map effective Nov-2025 — Moore old-D1→new-D2, Maloy D2→D3, Kennedy D3→D4, Owens retired, new D1 open (Ben McAdams D field). DB primary races match the NEW map; incumbent map is OLD-keyed. NOTE-UT-REDISTRICTED-2026 embedded in the UT-1 row: Phase 165 must re-key incumbents to geo_ids and re-link existing pids (Moore/Maloy/Kennedy are NOT new records).
- NV reconciliation: all 9 pre-wired candidate rows confirmed valid (incl. Chapman/IAP — NULL-pid stays fix-not-recreate); Amodei retired (Flippo R nominee); 5 newly certified candidates missing from DB; 5 stale Wikipedia independents flagged do-not-add
- Departures verified: NV-2 Amodei, UT-4 Owens, NE-2 Bacon, ME-2 Golden, NH-1 Pappas (Senate), MT-1 Zinke, SD Johnson (Governor: Jackley-R vs Gronli-D), WY Hageman (Senate; 14-candidate open field)
- NE statute correction: independent deadline is Aug-1 (not September) — NE rows carry 2026-08-01

## Task Commits

1. **Task 1: AK/ME/NV/UT special states** - `c54b7ccf` (feat)
2. **Task 2: 13 routine small states** - `d5edb929` (feat)
3. **Task 3: Assemble 160-field-table-p165.csv (34-row guards)** - `440b2bdd` (feat)

## Files Created/Modified
- `160-field-table-p165.csv` - 34-row Phase-165 partial, seeding_phase=165
- `staging/p165-{AK,ME,NV,UT,NM,NE,WV,ID,HI,NH,RI,MT,DE,ND,SD,VT,WY}.csv`

## Decisions Made
- Filing windows captured per D-03: RI 2026-07-10, DE 2026-07-14, NE 2026-08-01, WV 2026-08-03, MT 2026-08-20, ND 2026-08-31, NH 2026-09-02; closed for the rest.
- MT pending-certification independents (Persico/Eisenhauer) excluded until the Aug-20 certification; VT's Adam Ortiz (Independent) INCLUDED — present on the official VT qualified-candidates XLSX though absent from Wikipedia.

## Deviations from Plan

**1. [Rule 1 - Efficiency, documented] Routine states dispatched in pairs/triples instead of strictly one-per-state**
- **Found during:** Task 2
- **Issue:** 13 single-state agents at ≤3 concurrent would stretch the wave with 1-2-district workloads
- **Fix:** Paired tiny states (WV+ID, MT+ND+SD, HI+NH, RI+DE+VT+WY); per-agent district load (2-5) stayed below earlier single-state loads (9-10); the max-3-concurrent cap — the actual rate-limit protection — was held at all times
- **Verification:** All 17 staging CSVs validate; zero UNRESOLVED
- **Impact:** Faster wave, same quality bar

**2. [Rule 1 - Data consistency] Non-taxonomy nominee_status values normalized at assembly**
- **Issue:** Agents returned `open-seat-redistricted` (UT 1/2/3) and `open-seat-vacancy` (NE-2, MT-1, SD-0)
- **Fix:** UT→`redistricted`, others→`retired` per milestone precedent; facts preserved in row notes and here
- **Verification:** Assembly guard enforces 8-value taxonomy membership

**Total deviations:** 2 auto-fixed. No scope creep.

## Issues Encountered
- The incumbent map's UT rows are keyed to the OLD district numbering — the p165 UT rows echo those authoritative-pid columns per geo_id, so UT incumbent columns describe the OLD district's incumbent while general_candidates describes the NEW district's field. This is exactly what NOTE-UT-REDISTRICTED-2026 tells Phase 165 to resolve (re-key + re-link).

## Next Phase Readiness
- All five seeding-group partials (p161-p165) now exist: 37+33+36+38+34 = 178 rows — ready for the Plan 07 master merge, validator, and DB baseline gate.
- Phase-165 must handle: UT re-key, NV 5 new candidates + NULL-pid fix, ME zero-tier incumbents, AK/ME RCV depth priority.

---
*Phase: 160-field-resolution-stance-gap-diagnostic*
*Completed: 2026-07-03*
