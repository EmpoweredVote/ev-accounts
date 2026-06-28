---
phase: 139-single-low-rep-states-house-rep-stances
plan: 02
status: complete
requirements: [USHS-13]
---

# 139-02 SUMMARY — NH + RI + WV House (6 reps)

**Completed:** 2026-06-20
**Scope:** external_id −33001,−33002,−44001,−44002,−54001,−54002 (6 reps), all previously 0 stances.

## Result

58 sourced answers + 58 paired sourced context rows pushed to production. **0 unsourced.** 21 quotes inserted + selected, 0 leaks.

| ext_id | District | Rep | Answers | Note |
|--------|----------|-----|---------|------|
| −33001 | NH-1 | Chris Pappas (D) | 17 | swing-district moderate; deportation=3 (Laken Riley vote); SSM=1; voting-rights=2 |
| −33002 | NH-2 | Maggie Goodlander (D) | 6 | 2024 freshman; all 6 from documented campaign positions/quotes |
| −44001 | RI-1 | Gabe Amo (D) | 4 | seated Nov-2023; ukraine=2 (Apr-2024 supplemental vote), abortion/SS/medicare campaign priorities |
| −44002 | RI-2 | Seth Magaziner (D) | 11 | SSM=1 (served on Marriage Equality RI board — concrete); campaign-finance=2 (stock-trading-ban cosponsor) |
| −54001 | WV-1 | Carol D. Miller | 14 | abortion=5 (no exceptions); SSM=4 (capped — religious-exemption vote ≠ anti-recognition); LCV 0% → climate/fossil=5 |
| −54002 | WV-2 | Riley M. Moore | 6 | 2024 freshman / fmr WV Treasurer; fossil-fuels=5 + climate=5 (anti-ESG bank bans as Treasurer); source-blocked partial |

Per-scope verification (−33001..−54002): answers = 58, unsourced = 0.

## Calibration notes

- **Dropped 4 caucus/role-proxy rows before push:** Pappas ukraine-support=2 (New Dem Coalition membership + no-contrary-evidence inference), Amo climate-change=3 (chair selection rested on subcommittee Ranking-Member role, not a documented position), Magaziner civil-rights=2 (Equality Caucus + vague "enforcement stance") and ukraine-support=2 (Ukraine Caucus membership — same basis dropped for Flood/Tokuda/Pappas).
- **Kept** Magaziner SSM=1 (served on the Marriage Equality RI board — concrete documented action, not caucus inference) and Pappas SSM=1.
- Miller SSM=4 well-calibrated (religious-exemption vote + 2016 quote don't meet the anti-recognition/amendment bar). Moore RSC membership correctly NOT used as a stance.
- Freshmen (Goodlander, Amo, Moore) scored only from documented campaign positions / votes / Treasurer actions — honest partials, no party inference.

## Artifacts

- `backend/data/stance-research/2026-06-20-nh-ri-wv-house.csv` (committed)
- `backend/data/stance-research/nh-ri-wv-house/`

## Self-Check: PASSED
