# 143-09 SUMMARY — Batch I (WV/HI/MT/RI/DE SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 10/10 execs covered, 0 whole-skips, 0 unsourced.

## Result
- **35 answers + 35 contexts** pushed to prod, 7 quotes, 7 selected, 0 surname leaks.
- `verify-stance-coverage.mjs 10 …` → **PASS covered=10/10 unsourced=0**.
- Per-exec rows: Warner(WV SoS) 1, Pack(WV Treas) 4, Luke(HI LtGov) 8, Juras(MT LtGov) 2, Jacobsen(MT SoS) 4, Matos(RI LtGov) 7, Amore(RI SoS) 2, Diossa(RI Treas) 2, Gay(DE LtGov) 4, Davis(DE Treas) 1.

## Notes / deviations
- ≤3 researcher concurrency held throughout. **No whole-record honest-skips this batch** (every exec yielded ≥1 sourced row).
- **Auto-re-research (<5):** Diossa 0→2 ✓ (Uprise RI article on his office's fossil-fuel divestment engagement; treasurer.ri.gov entirely ECONNREFUSED). Gay confirmed 4 (DE legislature blocks all bill-ID fetches with "invalid data"). Warner (1, new WV SoS election-only), Pack (4, brief WV House + treasurer anti-ESG), Juras (2, law-professor LtGov RFRA testimony), Jacobsen (4, MT SoS election-admin + campaign), Amore (2, RI SoS), Davis (1, DE Treasurer EARNS program) accepted as **genuine narrow scope** — SoS/Treasurer/ceremonial-LtGov offices produce election-only or fund-only documentable records. Honest-partial beats inference.
- Luke (HI LtGov) scored from her own 24-yr HI House / Finance-chair record (incl. her documented 2013 Marriage Equality Act YES vote → SSM=1); Matos from her own Providence Council + 2023 RI-01 campaign — no Governor-mirroring.
- No SSM=5 rows; no party inference; no isidewith.

Data record: `backend/data/stance-research/exec-w2-batch-i/` (10 CSVs + scripts).
