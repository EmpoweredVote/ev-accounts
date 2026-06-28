---
phase: 135-tn-co-mn-mo-house-rep-stances
plan: 02
status: complete
requirements: [USHS-09]
---

# 135-02 SUMMARY — TN House Batch B (TN-6..TN-9)

**Completed:** 2026-06-19
**Scope:** external_id −47006..−47009 (4 reps), all previously 0 stances.

## Result

53 sourced answers + 53 paired sourced context rows pushed to production. **0 unsourced.** 16 quotes inserted + selected, 0 surname leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −47006 | TN-6 | John Rose | 15 | SSM row dropped (over-read: "opposes legalization" + RSC-alignment didn't cleanly document the value-5 "make illegal" chair) |
| −47007 | TN-7 | Matt Van Epps | 8 | honest-partial — 2025 special-election freshman; sourced via Wikipedia + LCV + OBBB votes |
| −47008 | TN-8 | David Kustoff | 13 | SSM=5 kept (documented anti-RFMA vote + direct quote) |
| −47009 | TN-9 | Steve Cohen | 17 | lone Democrat; consistent progressive record |

Per-scope verification (external_id −47006..−47009): answers=53, unsourced=0.

## Calibration note

Both Rose and Kustoff agents flagged doubt on `same-sex-marriage=5`. Kustoff retained (documented RFMA vote + verbatim quote support the value-5 chair). Rose's row dropped — its evidence ("opposes legalization" + "consistent with RSC positions") leaned on group alignment and over-read the value-5 "make illegal" position. Consistent with the no-party-inference rule.

## Artifacts

- `backend/data/stance-research/2026-06-19-tn-house-batch-b.csv` (committed)
- `backend/data/stance-research/tn-house-b/`

## Self-Check: PASSED
