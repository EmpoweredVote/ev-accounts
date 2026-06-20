---
phase: 138-ks-ms-nv-ne-nm-house-rep-stances
plan: 03
status: complete
requirements: [USHS-12]
---

# 138-03 SUMMARY — NV House (NV-1..NV-4)

**Completed:** 2026-06-20
**Scope:** external_id −32001..−32004 (4 reps), all previously 0 stances.

## Result

56 sourced answers + 56 paired sourced context rows pushed to production. **0 unsourced.** 6 quotes inserted, 5 selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −32001 | NV-1 | Dina Titus | 11 | (D); healthcare=1/medicare=1 (Medicare for All Caucus); deportation=3 (Laken Riley vote) |
| −32002 | NV-2 | Mark E. Amodei | 16 | SSM=4 (voted AGAINST Respect for Marriage Act, called it a "messaging bill"; sponsored Fairness for All) — correctly not 5 |
| −32003 | NV-3 | Susie Lee | 16 | (D); immigration=3 + climate=3 (Laken Riley vote + "gradual" clean-energy stance, not value-2 chair); trans-athletes honest-skipped |
| −32004 | NV-4 | Steven Horsford | 13 | (D) CBC chair; agent correctly skipped trans-athletes as caucus-only |

Per-scope verification (−32001..−32004): answers = 56, unsourced = 0.

## Calibration notes

- **Dropped Titus trans-athletes=1** before push — rested only on Equality Caucus membership + Equality Act support, no athletics-specific position. Consistent with the Horsford agent self-skipping the identical caucus-only basis. (Titus civil-rights=2 kept — backed by her 2010 U.S. Commission on Civil Rights appointment + scorecard, not caucus alone.)
- Amodei SSM=4 well-calibrated (anti-RFMA + Fairness for All civil-unions posture, not an anti-recognition/ban position → not 5).
- Both swing-district Dems (Titus, Lee) scored deportation/immigration toward center on the documented Laken Riley Act vote — evidence over party.

## Artifacts

- `backend/data/stance-research/2026-06-20-nv-house.csv` (committed)
- `backend/data/stance-research/nv-house/`

## Self-Check: PASSED
