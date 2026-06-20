---
phase: 138-ks-ms-nv-ne-nm-house-rep-stances
plan: 05
status: complete
requirements: [USHS-12]
---

# 138-05 SUMMARY — NM House (NM-1..NM-3)

**Completed:** 2026-06-20
**Scope:** external_id −35001..−35003 (3 reps), all previously 0 stances.

## Result

30 sourced answers + 30 paired sourced context rows pushed to production. **0 unsourced.** 11 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −35001 | NM-1 | Melanie A. Stansbury | 12 | (D); abortion=1/healthcare=1/medicare=1 (Medicare for All); SSM=1 (RFMA vote); fossil-fuels corrected 2→3 (Chaco letter is site-specific) |
| −35002 | Gabe Vasquez | NM-2 | 6 | (D) swing-district centrist; fossil-fuels=3 (voted FOR Arctic drilling + WY coal 2025); SSM=2 (Equality Caucus platform) |
| −35003 | NM-3 | Teresa Leger Fernandez | 12 | (D); LCV 99% lifetime; RFMA cosponsor, DREAM Act, abortion vote, housing act — all individually sourced |

Per-scope verification (−35001..−35003): answers = 30, unsourced = 0.

## Calibration notes

- **Dropped Vasquez civil-rights=2** before push — rested only on "Vice Chair for Diversity & Inclusion of CHC + Equality Caucus member, indicating active support" (vague role→topic inference, no documented position). Kept Vasquez SSM=2 — Equality Caucus has a published marriage-equality platform (consistent with the kept-Morrison precedent).
- Vasquez is a genuine swing-district centrist — his 2025 Arctic Refuge drilling + Wyoming coal votes (fossil-fuels=3) are notably at odds with most House Democrats; scored on the documented votes, not party.
- Stansbury medicare/aid corrected to 1 (Medicare for All = expand to everyone) and ukraine-support removed by the agent (Biden-alignment % alone is not documentary evidence).

## Artifacts

- `backend/data/stance-research/2026-06-20-nm-house.csv` (committed)
- `backend/data/stance-research/nm-house/`

## Self-Check: PASSED
