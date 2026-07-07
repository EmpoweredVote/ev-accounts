---
phase: 160-field-resolution-stance-gap-diagnostic
plan: 04
subsystem: database
tags: [elections, us-house, field-resolution, csv, research-agents, wi, co, al, sc, la, jungle-primary, district-split]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 01)
    provides: 160-incumbent-map.csv
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 02)
    provides: validated 19-column template
provides:
  - 160-field-table-p163.csv — 36-row Phase-163 partial (WI 8 / CO 8 / AL 7 / SC 7 / LA 6); 18 decided + 18 late-primary
  - AL district-split handled (AL-3/4/5 decided; AL-1/2/6/7 Aug-11 special primary, no runoff)
  - LA jungle-primary rows (open-primary-nov3, qualifying closes 2026-08-07)
  - staging/p163-{WI,CO,AL,SC,LA}.csv — per-state provenance
affects: [160-05, 160-06, 160-07, phase-163]

# Tech tracking
tech-stack:
  added: []
  patterns: [district-level field_status split within one state (AL); open-primary-nov3 ballot_system first use (LA)]

key-files:
  created:
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p163.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p163-WI.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p163-CO.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p163-AL.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p163-SC.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p163-LA.csv
  modified: []

key-decisions:
  - "A6 re-verified: AL split (3 decided May-19+Jun-16 / 4 special Aug-11 no-runoff) unchanged as of capture; special-primary qualifying closed May-22 so AL filing_open_deadline blank"
  - "LA rows are declared-so-far captures (qualifying is Aug 5-7) — acceptable per D-03; Phase 163 re-pulls after Aug-7"
  - "SC rows carry filing_open_deadline=2026-07-15 (independent petition window open)"
  - "CO unofficial-but-decisive Jun-30 results used (every district clear margin; CO-1 upset confirmed by national press)"

patterns-established:
  - "AL-style district split: field_status is a PER-DISTRICT tag, never a state-level constant"

requirements-completed: [USHC3-01]

# Metrics
duration: ~50min
completed: 2026-07-03
---

# Phase 160 Plan 04: Field Table P163 (WI/CO/AL/SC/LA) Summary

**36-row Phase-163 partial handling the two hardest Wave-3 classification cases — Alabama district-split (3 decided / 4 Aug-11 special, re-verified against A6) and Louisiana's jungle-primary reversion (Act 7; open-primary-nov3, qualifying Aug 5-7) — plus a genuine primary upset: CO-1 DeGette lost her primary**

## Performance

- **Duration:** ~50 min
- **Tasks:** 2
- **Files modified:** 6
- **Research agents:** 5 (AL/LA/CO first, WI/SC as slots freed — max 3 concurrent held)

## Accomplishments
- All 36 districts resolved from real fetched sources; zero UNRESOLVED — no Playwright sweep needed
- AL split re-verified current (SCOTUS May-11 order reverted AL to the 2023 6-1 map; Gov. Ivey's Aug-11 special primary for AL-1/2/6/7 stands; qualifying closed May-22)
- LA jungle-primary reversion confirmed from the official LA SoS notice (Act 7 voided the May-16 closed-primary House votes; Nov-3 ballot is round one; Dec-12 runoff)
- **CO-1 UPSET: Diana DeGette LOST her Jun-30 primary to Melat Kiros 53.2–39.8** — nominee_status=lost-primary (first in this milestone); DeGette's record stays incumbent-only, Kiros is a new record
- Incumbent departures verified: AL-1 Moore (Senate run), LA-5 Letlow (Senate run), SC-1 Mace + SC-5 Norman (governor runs), WI-7 Tiffany (governor run)
- WI-2 has NO Republican filed (2-candidate all-Dem ballot); WI agent excluded two uncorroborated Wikipedia names after fetching the primary sources (one FEC citation mismatch)

## Task Commits

1. **Task 1: Dispatch WI/CO/AL/SC/LA research agents** - `06ff2409` (feat)
2. **Task 2: Assemble 160-field-table-p163.csv (36-row guards)** - `cc2dc8cb` (feat)

## Files Created/Modified
- `160-field-table-p163.csv` - 36-row Phase-163 partial, seeding_phase=163
- `staging/p163-{WI,CO,AL,SC,LA}.csv` - per-state agent outputs

## Decisions Made
- LA's 6 rows are declared-so-far (13 declared in open LA-5 alone) with filing_open_deadline=2026-08-07 — the field is structurally unknowable until qualifying closes.
- CO minor-party hopefuls without confirmed ballot qualification excluded (FEC-paperwork-only bar, consistent with MA/SC handling).

## Deviations from Plan

None - plan executed exactly as written (the anticipated Playwright sweep was unnecessary: all districts resolved from unwalled routes).

## Issues Encountered
- **MID-CYCLE REDISTRICTING FLAGS (3rd + 4th instances):** (a) Alabama now runs on the reinstated 2023 6-1 map — AL district boundaries differ from what the DB's 2024-era shapes may assume; (b) Louisiana's SB 121 (signed 2026-05-29) redrew CD-6 away from Black-majority status — litigation (Callais; LA Legislative Black Caucus) remains open but the map governs Aug 5-7 qualifying and very likely Nov-3. Phase 163 seeding must re-verify AL + LA district-shape/geo_id alignment (same class of problem as TN in Plan 02, MO's new map in Plan 03).
- WEC (elections.wi.gov) is Cloudflare-walled even via r.jina.ai — WI rows source Wikipedia raw wikitext + WEC-quoting news fetches instead.

## Next Phase Readiness
- Phase-163 must: re-pull AL-1/2/6/7 after Aug-11, LA after Aug-7 qualifying (and watch the CD-6 litigation), SC independents after Jul-15; verify AL/LA district shapes vs DB geo_ids.
- Wave 5 (Plan 05, KY/OR/CT/OK/AR/IA/KS/MS — 8 states) proceeds with the validated template.

---
*Phase: 160-field-resolution-stance-gap-diagnostic*
*Completed: 2026-07-03*
