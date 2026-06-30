---
phase: 154-field-resolution-stance-gap-diagnostic
plan: 01
status: complete
completed: 2026-06-30
requirements: [USHC2-01]
---

# 154-01 SUMMARY — Incumbent Map + Stance-Gap Diagnostic

## What was built

- `backend/scripts/diag-154-incumbent-stance-gap.ts` — read-only (SELECT-only) clone of `diag-148-incumbent-stance-gap.ts`, adapted to the 8 Wave-2 states (PA 42 / IL 17 / OH 39 / GA 13 / NC 37 / MI 26 / NJ 34 / VA 51). Query A (incumbent→`politician_id` map by `(NATIONAL_LOWER, geo_id)`, `COUNT(*)` stance counts), Query B (per-state stance gap), Query C (vacancy detection), per-state tally, robust 0-holder→VACANT-row construction, GA-14 live resolution, 113-row hard guard.
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv` — 113 data rows (9-column header), one per Wave-2 district.

## Result (live prod DB `kxsdzaojfaibhuzmclfq`)

- Per-state tally all OK: PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / MI 13 / NJ 12 / VA 11 = **113**.
- 112 mapped incumbents + 1 vacant = 113. Tiers: **partial 111, zero 1, vacant 1, done 0**.
- Stance gap (report-only per D-02): **every incumbent is partial (1–23) — zero incumbents at the full 24**. Only stance-research target among incumbents is the 1 zero-stance row.

## Key findings — DB is MORE current than RESEARCH.md assumed (overrides for Plan 02)

| Special seat | RESEARCH.md assumption | LIVE DB reality | Plan-02 implication |
|---|---|---|---|
| GA-13 (1313) | open/vacant | **0-holder VACANT** ✓ | Clark + Chavez = genuine new-record needs |
| GA-14 (1314) | Fuller likely NOT in DB (Open Q1) | **1-holder = Clay Fuller** (pid `8c4ce29b…`, ext -13014, 1 stance) | Maps as incumbent; NOT a new record; no anomaly |
| NJ-11 (3411) | stale Sherrill row (Pitfall 5) | **1-holder = Analilia Mejia** (pid `93874414…`, ext -34011, 7 stances) | Maps as incumbent; NOT a new record; no Sherrill override needed |
| VA-11 (5111) | Walkinshaw NOT in DB | **1-holder = James Walkinshaw** (pid `32ea954f…`, ext -5102011, 7 stances) | Maps as incumbent; VA-11 field still `pending-primary (Aug-4)` |

**Net:** three of the four "special seats" are already correctly-seeded incumbents → no ghost-incumbent risk and far fewer new records than feared. Only GA-13 is a true vacancy. The 1 zero-stance incumbent is **NC-6 Addison P. McDowell** (pid `74579547…`, ext -37006) — the sole incumbent stance-research target (Phase 156).

## Deviations

- Made vacancy-row construction **robust**: VACANT rows are derived from Query C's actual 0-holder districts (not a hardcoded list), with the expected set `{1313,3411,5111}`(+1314 if 0-holder) used only for WARNING/anomaly surfacing. This correctly adapted to the DB reality above (only GA-13 vacant) and kept the 113-row hard guard valid. The `missing-expected-vacant` WARNING fired for NJ-11 + VA-11 (now-seated incumbents) — expected and informational, not an error.
- GA-14 1-holder = Fuller (not MTG) → no stale-incumbent anomaly; mapped normally.

## Verification

- `node --import tsx scripts/diag-154-incumbent-stance-gap.ts` exits 0; prints Query A/B/C + `TOTAL: 113`. No `column pa.id` error, no module-resolution error.
- `csv.DictReader` → 113 rows, 9-column header, tiers {partial:111, vacant:1, zero:1}.

## Self-Check: PASSED

## Key files
- created: `backend/scripts/diag-154-incumbent-stance-gap.ts`, `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv`
