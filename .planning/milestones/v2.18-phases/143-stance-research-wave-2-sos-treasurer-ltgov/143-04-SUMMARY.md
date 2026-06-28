# 143-04 SUMMARY — Batch D (WI/CO/MN/SC SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 10/11 execs covered + 1 documented SoS whole-record honest-skip, 0 unsourced.

## Result
- **87 answers + 87 contexts** pushed to prod, 22 quotes, 21 selected, 0 surname leaks.
- `verify-stance-coverage.mjs 10 …` (all 11 ids, expected 10) → **PASS covered=10/10 unsourced=0**.
- Per-exec rows: Rodriguez(WI LtGov) 17, Godlewski(WI SoS) 8, Leiber(WI Treas) 1, Primavera(CO LtGov) 11, Griswold(CO SoS) 6, Young(CO Treas) 5, Flanagan(MN LtGov) 15, Simon(MN SoS) 10, Evette(SC LtGov) 13, Hammond(SC SoS) **0 — whole-skip**, Loftis(SC Treas) 1.

## Documented honest-skip-of-whole-record (pin in 143-11 gate)
- **Mark Hammond, SC Secretary of State (-4500004)** — SC SoS is a **purely ministerial office** (business/charity registration, notaries; SC elections run by the separate SC Election Commission). In office since 2003 with **no documentable policy stance on any compass topic** (Ballotpedia blank, OnTheIssues 404, no questionnaires/statements). Honest whole-skip, not a miss.

## Notes / deviations
- ≤3 researcher concurrency held throughout.
- **Auto-re-research (<5):** Godlewski 4→8 ✓ (2022 Senate + Treasurer fund actions), Primavera 4→11 ✓ (CO House record via Vote Smart/Ballotpedia after the CO GA bill-search wall). **Leiber (1)** accepted as genuine — WI Treasurer is the weakest such office nationally (no investment authority); **Loftis (1)** accepted — SC Treasurer press/news walled (404/429); honest-partial beats inference.
- No SSM=5 rows; no Governor-mirroring (Rodriguez/Primavera/Flanagan scored from own legislative records; Simon from MN House + SoS actions); no party inference; no isidewith. Evette SSM honest-skipped despite "traditional values" rhetoric (no documented anti-recognition vote).
- Griswold scored from her documented election-admin actions (AVR, 14th-Amendment ballot ruling) + AG-campaign platform; Evette taxes=5/vouchers=5/civil-rights=5 from her explicit 2026 gubernatorial platform.

Data record: `backend/data/stance-research/exec-w2-batch-d/` (11 CSVs incl. header-only hammond.csv + scripts).
