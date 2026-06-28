---
phase: 112-va-delegate-stances
plan: "02"
subsystem: stance-data
tags: [stance-research, virginia, house-of-delegates, wave2, non-contiguous]
dependency_graph:
  requires: [Phase 112-01 (migration 331, Wave 1 baseline), Phase 110 delegate records]
  provides: [Migration 332 applied, Wave 2 stances live — 20 rows across 5 delegates]
  affects: [inform.politician_answers, inform.politician_context]
tech_stack:
  added: []
  patterns: [sequential-research-webfetch, pre-flight-json, csv-source-of-truth, psql-wave-migration, DO-IN-non-contiguous, honest-skip]
key_files:
  created:
    - backend/data/stance-research/2026-06-10-112-va-delegates-wave2.csv
    - supabase/migrations/20260610000002_332_va_delegates_wave2_stances.sql
  modified: []
decisions:
  - "Wave 2 non-contiguous IN() range confirmed — HD-53/54/55 + HD-37-42 cannot use BETWEEN"
  - "Ballotpedia is the only accessible source (vpap.org blocked, griffinforvirginia.com accessible for Griffin)"
  - "4 of 9 delegates are honest-skips: Davis, McNamara, Franklin, Ballard — no survey completions across any election cycle"
  - "Sam Rasoul's 2021 LG campaign website content (via Ballotpedia) is the richest source at 7 stances"
  - "Laufer's 2019 State Senate survey is the source — older but still valid as documented public position"
metrics:
  duration: "~120 minutes (including context restoration)"
  completed: "2026-06-10"
---

# Phase 112 Plan 02: VA Delegate Stances Wave 2 Summary

Wave 2 of 10 for Phase 112 (VA House Delegate Stances). Covers 9 non-contiguous delegates: HD-53 through HD-55 (Charlottesville-area) plus HD-37 through HD-42 (Roanoke-area). 5 of 9 delegates have documentable stances; 4 are honest-skips. Migration 332 applied with 20 stance rows (20 `politician_answers` + 20 `politician_context`). VAST-05 invariant holds: unsourced_count=0.

## Total Stances Ingested for Wave 2

**20 stances** across 5 delegates.

## Per-Delegate Breakdown

| HD | Delegate | Party | Stances | Status |
|----|----------|-------|---------|--------|
| 37 | Terry L. Austin | R | 3 | abortion=4, taxes=4, religious-freedom=4 |
| 38 | Sam Rasoul | D | 7 | climate-change=1, fossil-fuels=1, abortion=2, same-sex-marriage=1, civil-rights=2, voting-rights=2, healthcare=2 |
| 39 | Will P. Davis | R | 0 | Honest-skip: no survey completions; endorsement-only (Patriot Parents) |
| 40 | Joseph P. McNamara | R | 0 | Honest-skip: no survey completions across 2019/2021/2023/2025 |
| 41 | Lily V. Franklin | D | 0 | Honest-skip: newly elected 2025, no survey completions |
| 42 | Jason S. Ballard | R | 0 | Honest-skip: no survey completions across 2021/2023/2025 |
| 53 | Timothy P. Griffin | R | 5 | abortion=4, religious-freedom=4, taxes=4, school-vouchers=4, voting-rights=4 |
| 54 | Katrina E. Callsen | D | 2 | abortion=2, school-vouchers=1 |
| 55 | Amy J. Laufer | D | 3 | abortion=2, climate-change=3, healthcare=2 |

## Sources Used

| Delegate | Source | Survey Year |
|----------|--------|-------------|
| Timothy P. Griffin | griffinforvirginia.com/issues + ballotpedia.org/Tim_Griffin_(Virginia) | Campaign issues page |
| Katrina E. Callsen | ballotpedia.org/Katrina_Callsen | 2023 Candidate Connection |
| Amy J. Laufer | ballotpedia.org/Amy_Laufer | 2019 Candidate Connection (State Senate race) |
| Terry L. Austin | ballotpedia.org/Terry_Austin | Candidate Connection survey |
| Sam Rasoul | ballotpedia.org/Sam_Rasoul | 2021 LG campaign website + 2023 endorsements |

All sources fetched via WebFetch (Python urllib + Chrome UA). vpap.org returned empty (blocked from this environment). house.virginia.gov confirmed Jason Ballard is HD-42 but no policy detail available.

## Honest-Skipped Delegates (4 of 9)

- **Will P. Davis (HD-39, R)**: Ballotpedia shows no Candidate Connection survey completions in 2023 or 2025; only endorsement is Patriot Parents — insufficient for stance values.
- **Joseph P. McNamara (HD-40, R)**: No survey completions across 2019, 2021, 2023, 2025 election cycles.
- **Lily V. Franklin (HD-41, D)**: Newly elected November 2025 (defeated incumbent Chris Obenshain); no survey completions in 2023 or 2025 campaigns.
- **Jason S. Ballard (HD-42, R)**: No survey completions across 2021, 2023, 2025. Confirmed on `ballotpedia.org/Jason_Ballard` (without Virginia qualifier). house.vga.virginia.gov confirms office: Capitol 710, District 42.

## Migration Number Used

**Migration 332** — confirmed correct. Pre-flight verified:
- `SELECT MAX(version)` = 325
- Highest file on disk: `20260610000001_331_va_delegates_wave1_stances.sql`
- Next free: 332
- DO $$ uses `IN()` not `BETWEEN` — Pitfall 7 for non-contiguous range

## VAST-05 Invariant

**Holds — unsourced_count = 0** for all 9 Wave 2 delegates (IN clause).

Post-apply DO $$ block output:
- `NOTICE: VA delegates with stances (Wave 2): 5`
- `NOTICE: Unsourced VA delegate stances (Wave 2): 0`
- `ASSERT unsourced_count = 0` — passed

## Deviations from Plan

None — plan executed exactly as written. The 4 honest-skip delegates were predicted by RESEARCH.md (D-10): "SW Roanoke/NRV delegates likely thin web presence." Sam Rasoul (HD-38) was the predicted exception with richest web presence (ran for LG 2021), yielding 7 stances as expected.

## Known Stubs

None — this plan writes stance rows only. No UI stubs or placeholder data.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes. Migration writes to existing `inform.politician_answers` and `inform.politician_context` tables.

## Self-Check: PASSED
