# 143-01 SUMMARY — Batch A (TX/FL/NY/PA/IL SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 11/11 execs covered, 0 unsourced.

## Result
- **103 answers + 103 contexts** pushed to prod (`kxsdzaojfaibhuzmclfq`), 38 quotes, 37 selected topics, 0 surname leaks.
- `verify-stance-coverage.mjs 11 …` → **PASS covered=11/11 unsourced=0**.
- Per-exec rows: Patrick(TX LtGov) 9, Hegar(TX Comptroller) 4, Collins(FL LtGov) 14, Ingoglia(FL CFO) 14, Delgado(NY LtGov) 15, DiNapoli(NY Comptroller) 5, Davis(PA LtGov) 7, Garrity(PA Treasurer) 13, Stratton(IL LtGov) 8, Giannoulias(IL SoS) 11, Frerichs(IL Treasurer) 3.

## Notes / deviations
- **≤3 researcher concurrency held throughout** (inline from main checkout; gsd-executor cannot dispatch researchers).
- **Auto-re-research (<5 rows) applied:** Collins 2→14 and DiNapoli 2→5 recovered via OnTheIssues + bill/shareholder-action targeting. Hegar (4) and Frerichs (3) confirmed **genuine source walls** on re-research (Ballotpedia JS-shell, OnTheIssues 404, VoteSmart 403, treasury press archives inaccessible) — honest-partial accepted, no inference.
- **Proxy-row drop (1):** Dan Patrick same-sex-marriage=5 dropped — evidence was opposition-to-legalization + HERO opposition + an inflammatory quote, with no documented marriage-amendment vote / marriage-definition bill / one-man-one-woman amendment endorsement. Stays within the reaffirmed strict SSM=5 bar.
- No LtGov stance mirrored a Governor (each scored from the official's own legislative/office record); no party inference; no isidewith sources.
- Treasurer/Comptroller/CFO scored from fund actions (DiNapoli fossil-fuel divestment, Garrity Russia divestment, Hegar SB-13 blacklist, Ingoglia anti-ESG).

Data record: `backend/data/stance-research/exec-w2-batch-a/` (11 CSVs + scripts). Dated merged CSV is gitignored (regenerable).
