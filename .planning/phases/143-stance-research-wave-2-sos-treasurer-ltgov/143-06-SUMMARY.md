# 143-06 SUMMARY — Batch F (OK/CT/IA/NV SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 9/11 execs covered + 2 documented LtGov whole-record honest-skips, 0 unsourced.

## Result
- **42 answers + 42 contexts** pushed to prod, 10 quotes, 10 selected, 0 surname leaks.
- `verify-stance-coverage.mjs 9 …` (all 11 ids, expected 9) → **PASS covered=9/9 unsourced=0**.
- Per-exec rows: Pinnell(OK LtGov) **0 — whole-skip**, Russ(OK Treas) 2, Bysiewicz(CT LtGov) 13, Thomas(CT SoS) 2, Russell(CT Treas) 6, Cournoyer(IA LtGov) **0 — whole-skip**, Pate(IA SoS) 1, Smith(IA Treas) 5, Anthony(NV LtGov) 1, Aguilar(NV SoS) 2, Conine(NV Treas) 10.

## Documented honest-skips-of-whole-record (pin in 143-11 gate)
- **Matt Pinnell, OK Lt Governor (-4000002)** — ministerial LtGov (tourism/commerce), withdrew from the 2026 Gov race and from politics; no bill/vote/platform record on any topic.
- **Chris Cournoyer, IA Lt Governor (-1900002)** — real IA Senate record (2019–2024) but behind a total source wall (legis.iowa.gov dynamic-rendered 500s, IA news 403/ECONNREFUSED, Ballotpedia empty); chamber-vote totals found but un-attributable to her individually → no-inference rule → 0 rows. Confirmed on re-research.

## Notes / deviations
- ≤3 researcher concurrency held throughout. Batch F was the thinnest-yielding batch (IA/NV/OK state sources heavily walled: IA legislature is a JS-SPA, state .gov 403s, local news paywalled).
- **Auto-re-research (<5):** Bysiewicz 3→13 ✓ (OnTheIssues 2010 Gov / 2012 Senate campaigns), Smith 4→5 ✓ (radioiowa). Russ (2), Cournoyer (0) confirmed **genuine source walls** on re-research. Pate (1, SoS + pre-1995 Senate), Anthony (1, ceremonial LtGov — only a documented trans-athletes task force), Thomas (2, short CT House + SoS election-only), Aguilar (2, SoS election-only) accepted as **genuine narrow scope** (SoS/ceremonial offices produce election-only or near-zero topical records; not source walls). Honest-partial beats inference.
- No SSM=5 rows; no Governor-mirroring; no party inference; no isidewith. Conine scored from documented Treasurer fund actions (gun divestment, COVID housing, baby bonds) + 2026 Gov campaign; Russell from CT Baby Bonds + pension ESG actions.

Data record: `backend/data/stance-research/exec-w2-batch-f/` (11 CSVs incl. header-only pinnell.csv + cournoyer.csv + scripts).
