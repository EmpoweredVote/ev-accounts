---
phase: 139-single-low-rep-states-house-rep-stances
plan: 03
status: complete
requirements: [USHS-13]
---

# 139-03 SUMMARY — At-Large States House (AK/DE/ND/SD/VT/WY, 6 reps)

**Completed:** 2026-06-20
**Scope:** external_id −2000,−10000,−38000,−46000,−50000,−56000 (6 at-large reps, `-{fips}000` ids), all previously 0 stances.

## Result

70 sourced answers + 70 paired sourced context rows pushed to production. **0 unsourced.** 24 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −2000 | AK-AL | Nicholas J. Begich III | 9 | 2024 freshman; Big Beautiful Bill + SAVE Act votes + direct quotes |
| −10000 | DE-AL | Sarah McBride (D) | 13 | 2024 freshman / fmr DE state senator + HRC advocate; SSM=1 (HRC role + Equality Act + 2013 DE nondiscrimination law she authored); childcare=1 |
| −38000 | ND-AL | Julie Fedorchak | 8 | 2024 freshman / fmr ND PSC; energy rows from PSC record + IRA-repeal bill; abortion=4 |
| −46000 | SD-AL | Dusty Johnson | 15 | Main Street Caucus chair; SSM=3 (voted against RFMA, "business of the states"); ukraine=2 (Apr-2024 aid vote) |
| −50000 | VT-AL | Becca Balint (D) | 11 | progressive; abortion=1 (VT constitutional-amendment vote); ai-regulation=3 (introduced NO FAKES Act); SSM=1 |
| −56000 | WY-AL | Harriet M. Hageman | 14 | abortion=5 (OTI "no exceptions" quote); climate/fossil=5 (LCV 0%); voting-rights=5 (abolish drop boxes) |

Per-scope verification (−2000,−10000,−38000,−46000,−50000,−56000): answers = 70, unsourced = 0.

## Calibration notes

- **Dropped 2 inference rows before push:** Hageman misinformation=4 (agent explicitly flagged "inferred from anti-federal-overreach posture, lower-confidence") and Balint trans-athletes=1 (record-alignment / "consistent trans rights record" — no athletics-specific documented position; same basis as the Thompson drop in 138).
- **Kept** McBride SSM=1 (HRC national press secretary + Equality Act champion + authored 2013 DE gender-identity nondiscrimination law — concrete), Balint SSM=1 (Equality Caucus co-chair + documented LGBTQ leadership) and ai-regulation=3 (NO FAKES Act she introduced — concrete bill).
- Johnson SSM=3 well-calibrated (anti-RFMA vote framed as states' issue, not anti-recognition → not 5). Hageman SSM honest-skipped (took office after the 2022 RFMA vote; no documented anti-recognition vote).
- **external_id quirk handled:** at-large states use −{fips}000 (verified in prod), not −{fips}001.

## Artifacts

- `backend/data/stance-research/2026-06-20-atlarge-house.csv` (committed)
- `backend/data/stance-research/atlarge-house/`

## Self-Check: PASSED
