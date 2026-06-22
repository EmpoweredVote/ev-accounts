# 143-10 SUMMARY — Batch J (SD/ND/AK/VT/WY SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 11/12 execs covered + 1 documented Treasurer whole-record honest-skip, 0 unsourced. **Closes Wave-2 research.**

## Result
- **40 answers + 40 contexts** pushed to prod, 16 quotes, 16 selected, 0 surname leaks.
- `verify-stance-coverage.mjs 11 …` (all 12 ids, expected 11) → **PASS covered=11/11 unsourced=0**.
- Per-exec rows: Venhuizen(SD LtGov) 2, Johnson(SD SoS) 1, Haeder(SD Treas) **0 — whole-skip**, Strinden(ND LtGov) 4, Howe(ND SoS) 1, Beadle(ND Treas) 1, Dahlstrom(AK LtGov) 8, Rodgers(VT LtGov) 4, Copeland-Hanzas(VT SoS) 6, Pieciak(VT Treas) 3, Gray(WY SoS) 6, Meier(WY Treas) 4.

## Documented honest-skip-of-whole-record (pin in 143-11 gate)
- **Josh Haeder, SD Treasurer (-4600005)** — businessman treasurer; sdtreasurer.gov entire domain 403, SD Searchlight/SDPB/Argus/VoteSmart all 403, Ballotpedia/Wikipedia no policy content. Confirmed total wall on re-research (0→0). No documentable stance.

## Notes / deviations
- ≤3 researcher concurrency held throughout. Smallest-state batch (SD/ND/VT/WY legislature sites JS-rendered, treasury sites 403/down) → many narrow honest-partials.
- Dahlstrom 8 (own AK House + 2024 US House campaign via OnTheIssues), Gray 6 (own WY-SoS election rulemaking + press quotes), Copeland-Hanzas 6 (own 18-yr VT House record incl. SSM=1 marriage-equality co-sponsorship) — no Governor-mirroring.
- The rest accepted as **genuine narrow scope / walled** (Venhuizen 2, Johnson 1, Howe 1, Beadle 1, Strinden 4, Rodgers 4, Pieciak 3, Meier 4) — SoS election-only, ceremonial LtGovs, businessman treasurers, with state-legislature sources JS-walled. Honest-partial beats inference. Strinden civil-rights=5 from her own sponsored HB1256 (false-discrimination-penalty bill).
- No SSM=5 rows; no party inference; no isidewith. Gray's quad-quote climate-change field auto-repaired by `_merge.ts repair()`.

Data record: `backend/data/stance-research/exec-w2-batch-j/` (12 CSVs incl. header-only haeder.csv + scripts).
