# 143-08 SUMMARY — Batch H (NM/NE/ID SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 8/9 execs covered + 1 documented LtGov whole-record honest-skip, 0 unsourced.

## Result
- **24 answers + 24 contexts** pushed to prod, 3 quotes, 3 selected, 0 surname leaks.
- `verify-stance-coverage.mjs 8 …` (all 9 ids, expected 8) → **PASS covered=8/8 unsourced=0**.
- Per-exec rows: Morales(NM LtGov) 6, Oliver(NM SoS) 6, Montoya(NM Treas) 2, Kelly(NE LtGov) **0 — whole-skip**, Evnen(NE SoS) 1, Spellerberg(NE Treas) 1, Bedke(ID LtGov) 5, McGrane(ID SoS) 2, Ellsworth(ID Treas) 1.

## Documented honest-skip-of-whole-record (pin in 143-11 gate)
- **Joe Kelly, NE Lt Governor (-3100002)** — career prosecutor / former US Attorney; never held legislative office; ltgov.nebraska.gov is content-free (bio only, no press/initiatives); no documentable stance on any topic.

## Notes / deviations
- ≤3 researcher concurrency held throughout.
- **Auto-re-research (<5):** Ellsworth 0→1 ✓ (ID House HB587 → healthcare; treasurer.idaho.gov ECONNREFUSED throughout). Montoya (2, NM Treas — anti-tariff SCOTUS action + anti-tax statement; Tesla proxy vote not topic-mappable), Evnen (1, NE SoS election-only), Spellerberg (1, NE Treas new Nov-2025), McGrane (2, ID SoS election-only) accepted as **genuine narrow scope** — SoS/Treasurer offices produce election-only or fund-only documentable records; honest-partial beats inference.
- Bedke (ID LtGov) scored entirely from his own 22-yr ID House / Speaker record (abortion, trans-athletes, taxes, voting-rights, redistricting=5 on his documented Prop 1 opposition); Oliver/Morales from their own SoS/Senate records — no Governor-mirroring.
- No SSM=5 rows; no party inference; no isidewith.

Data record: `backend/data/stance-research/exec-w2-batch-h/` (9 CSVs incl. header-only kelly.csv + scripts).
