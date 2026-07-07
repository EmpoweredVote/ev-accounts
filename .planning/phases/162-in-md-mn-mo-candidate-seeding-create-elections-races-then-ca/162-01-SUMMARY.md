---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 01
subsystem: research
tags: [mo-redistricting, correspondence-audit, election-data, house-2026]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic (plan 03)
    provides: 160-field-table-p162.csv (33-row field table incl. MO's 8 late-primary rows), MO redistricting provenance in 160-03-SUMMARY.md
  - phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca (plan 01)
    provides: 161-tn-correspondence-audit.md (rubric + structure cloned verbatim)
provides:
  - 162-mo-correspondence-audit.md — 8-district MO old-vs-new severity table, rubric, and the machine-readable "Severe geo_id list:" line (2902, 2903, 2904, 2905, 2906)
affects: [162-02 (MO seed — must withhold the 5 severe races per D-01b), 162-11 (verify.sql severe-race non-surfacing assertion + negative coordinate-smoke sample), 164.1 (polygon-refresh/dual-map design un-gates withheld MO districts), 167 (MO Aug-4 re-pull after referendum-certification decision)]

# Tech tracking
tech-stack:
  added: []
  patterns: [">25%-moved OR anchor-changed severity rubric (cloned verbatim from TN 161-01) applied via named-source county-reassignment evidence + Cook-rating/presidential-margin proxy, no GIS/shapefile dependency"]

key-files:
  created:
    - .planning/phases/162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca/162-mo-correspondence-audit.md
  modified: []

key-decisions:
  - "Severe set = 5 of 8 (2902/2903/2904/2905/2906), expanded beyond the pre-audit hypothesis ({2905}, check 2904/2906). The KC three-way split forces MO-4/5/6 severe (MO-4 +25% of KC, MO-6 +35% of KC = new metro anchors absent from the old rural districts; MO-5 anchor dismantled + full partisan flip). The St. Louis-region domino forces MO-2/MO-3 severe: St. Charles County (~400k) swaps whole from MO-2 into MO-3, and MO-3 consolidates Columbia — >25%-moved on both, confirming RESEARCH Pitfall 1 (budget for a larger severe set; MO lands 5/8, echoing TN's 5/9)"
  - "MO-3 scored SEVERE despite unchanged partisan lean (R+20 both maps) — partisan stability does NOT imply geographic stability; the rubric scores boundary/population movement, and MO-3 'looks fairly different' (Inside Elections) after gaining all of St. Charles + Columbia and shedding 4 southern counties"
  - "Flagged a MO-specific legal-freshness risk harder than TN's: map is locked for the Aug-4 primary, but SoS Hoskins ('the map will not be frozen until I certify the referendum') + county signature-certification due July 27 mean the GENERAL-election map is unsettled and could revert to OLD boundaries — which would invert the staleness logic. D-01b withholding is the hedge that stays correct under either outcome; MO is a mandatory Phase-167 re-pull"

requirements-completed: [USHC3-03]

# Metrics
duration: ~40min
completed: 2026-07-04
---

# Phase 162 Plan 01: MO Old-vs-New Congressional Map Correspondence Audit Summary

**8-district MO redistricting severity audit scoring 5 districts (MO-2/3/4/5/6) severe via named-source county-reassignment evidence + Cook-rating/presidential-margin proxy, producing the machine-readable severe-geo_id list `2902, 2903, 2904, 2905, 2906` that 162-02/162-11 will consume — plus a loud flag on MO's unsettled general-election map status (referendum certification ~July 27).**

## Performance

- **Duration:** ~40 min (majority spent fetching and cross-reading named sources; several 403/Playwright walls routed around via Sabato + Inside Elections + KCUR + STLPR + Votebeat)
- **Tasks:** 2 (gather old-vs-new composition; score severity + write artifact)
- **Files modified:** 1 (162-mo-correspondence-audit.md, new)
- **Subagents used:** 0 (done inline, per session decision to limit subagent load)

## What was built

- `162-mo-correspondence-audit.md`: rubric (cloned verbatim from TN), 8-row per-district severity table, `Severe geo_id list: 2902, 2903, 2904, 2905, 2906`, a Notes-for-downstream-consumers section, and 9 source URLs (all freshly fetched, zero TN URLs reused).

## Severe geo_id list (the downstream contract)

`2902, 2903, 2904, 2905, 2906` (MO-2, MO-3, MO-4, MO-5, MO-6). NOT-SEVERE: 2901 (MO-1), 2907 (MO-7), 2908 (MO-8). MO has no CD-9.

## Verification

- `test -f` + `grep "Severe geo_id list:"` → FOUND
- District table row count = 8 (all districts scored, none skipped)
- File length 85 lines (> 40-line minimum)
- No DB writes; `essentials.offices` untouched

## Notes / carry-forward for 162-02

- Withhold the 5 severe races via the D-01b election_id-substitution mechanism (clone 161-06 exactly): severe → withheld election `'MO 2026 Congressional Redistricting - Polygon Pending'` (WITHHELD_ELECTION date = 2026-03-24, MO Supreme Court upholding date), non-severe → `'MO 2026 Statewide General'`.
- **Re-verify MO legal status before authoring 162-02** if executed >3 days after 2026-07-04 — the referendum-certification decision (~July 27) could freeze/revert the map for the general.
