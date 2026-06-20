---
phase: 138-ks-ms-nv-ne-nm-house-rep-stances
plan: 04
status: complete
requirements: [USHS-12]
---

# 138-04 SUMMARY — NE House (NE-1..NE-3)

**Completed:** 2026-06-20
**Scope:** external_id −31001..−31003 (3 reps), all previously 0 stances.

## Result

39 sourced answers + 39 paired sourced context rows pushed to production. **0 unsourced.** 9 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −31001 | NE-1 | Mike Flood | 10 | abortion=4 (authored NE's first 20-week ban); trans-athletes=4 / healthcare=4 / medicare=4 on the OBBBA omnibus vote |
| −31002 | NE-2 | Don Bacon | 14 | swing-district moderate; SSM=2 (voted FOR Respect for Marriage Act); tariffs=2 (bill requiring Congressional tariff approval, opposed Trump tariffs); ukraine=2 (F-16 advocacy) |
| −31003 | NE-3 | Adrian Smith | 15 | SSM=4 (capped — no anti-recognition vote); social-security=5 (9% ARA privatization record); tariffs=3 (USMCA/bilateral) |

Per-scope verification (−31001..−31003): answers = 39, unsourced = 0.

## Calibration notes

- **Dropped Flood ukraine-support=2** before push — rested only on Ukraine Caucus membership ("signaling consistent support"), no documented vote/statement. (Bacon's ukraine=2 kept — backed by F-16 advocacy + an "appeasement" quote.)
- Bacon SSM=2 (RFMA vote) and Smith SSM=4 (no anti-recognition vote documented; Equality-Act opposition alone doesn't clear the bar) both well-calibrated.
- Smith social-security=5 from a documented 9% ARA rating (privatization record), not inference.

## Artifacts

- `backend/data/stance-research/2026-06-20-ne-house.csv` (committed)
- `backend/data/stance-research/ne-house/`

## Self-Check: PASSED
