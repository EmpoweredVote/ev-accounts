# 143-02 SUMMARY — Batch B (OH/GA/NC/MI SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 9/10 execs covered + 1 documented LtGov whole-record honest-skip, 0 unsourced.

## Result
- **100 answers + 100 contexts** pushed to prod, 45 quotes, 45 selected topics, 0 surname leaks.
- `verify-stance-coverage.mjs 9 …` (all 10 ids, expected 9) → **PASS covered=9/9 unsourced=0**.
- Per-exec rows: Tressel(OH LtGov) **0 — whole-skip**, LaRose(OH SoS) 15, Sprague(OH Treas) 4, Jones(GA LtGov) 13, Raffensperger(GA SoS) 19, Hunt(NC LtGov) 7, Marshall(NC SoS) 11, Briner(NC Treas) 4, Gilchrist(MI LtGov) 12, Benson(MI SoS) 15.

## Documented honest-skip-of-whole-record (pin in 143-11 gate)
- **Jim Tressel, OH Lt Governor (-3900002)** — former OSU football coach/university president, appointed Feb 2025, **no prior elected/legislative record and no documentable policy stance on any topic** (Ballotpedia empty, Wikipedia bio-only, gov site down). Honest whole-skip, not a miss. Analogous to OH AG Wilson (-3900003) in Phase 142.

## Notes / deviations
- ≤3 researcher concurrency held throughout.
- **Auto-re-research (<5):** LaRose 4→16 ✓, Marshall 0→11 ✓ (both recovered via OnTheIssues — LaRose's 2024 Senate run, Marshall's 2010 Senate run). Sprague (4) and Briner (4) confirmed **genuine thin records** on re-research (Sprague: OH House roll-calls unfetchable, treasury/gov 403; Briner: first-term, Jan-2025, no legislative history). Honest-partial accepted.
- **Proxy-row drops (2 SSM=5):** LaRose same-sex-marriage=5 dropped (campaign definitional quote "marriage is one man and one woman" — platform-statement-only, no documented vote/amendment/bill, per the reaffirmed strict bar). [Patrick was dropped on the same basis in 143-01.]
- Raffensperger scored from his documented 2020 certification/election-admin record; Benson from her election-admin + 2026 gov platform; Sprague voting-rights=5 from his OWN 2026 OH-SoS campaign platform (he's running for SoS). No Governor-mirroring, no party inference, no isidewith.

Data record: `backend/data/stance-research/exec-w2-batch-b/` (10 CSVs incl. header-only tressel.csv + scripts).
