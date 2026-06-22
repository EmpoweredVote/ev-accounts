# 143-07 SUMMARY — Batch G (AR/MS/KS SoS+Treasurer+LtGov)

**Status:** ✅ Complete — 8/9 execs covered + 1 documented Treasurer whole-record honest-skip, 0 unsourced.

## Result
- **45 answers + 45 contexts** pushed to prod, 11 quotes, 11 selected, 0 surname leaks.
- `verify-stance-coverage.mjs 8 …` (all 9 ids, expected 8) → **PASS covered=8/8 unsourced=0**.
- Per-exec rows: Rutledge(AR LtGov) 14, Jester(AR SoS) 1, Thurston(AR Treas) 2, Hosemann(MS LtGov) 5, Watson(MS SoS) 8, McRae(MS Treas) **0 — whole-skip**, Toland(KS LtGov) 4, Schwab(KS SoS) 9, Johnson(KS Treas) 2.

## Documented honest-skip-of-whole-record (pin in 143-11 gate)
- **David McRae, MS Treasurer (-2800005)** — businessman treasurer; MS Treasury site dead (`treasurer.ms.gov` redirects to a dead endpoint), no live campaign site, VoteSmart/MS Today 403, Wikipedia bio-only. No documentable stance on any topic.

## Notes / deviations
- ≤3 researcher concurrency held throughout.
- **SSM=5 KEPT — Leslie Rutledge** (AR LtGov, former AG): backed by **documented anti-recognition litigation** (as AG in 2015 she moved to defend Arkansas's SSM ban in court). This is the legitimate KEEP category (same basis as Paxton in Phase 142), distinct from the campaign-statement SSM=5 cases dropped in 143-01/02/05.
- **Auto-re-research (<5):** Schwab 2→9 ✓ (2026 KS-Gov campaign platform at scottschwab.com). Johnson (2), Thurston (2) confirmed **genuine walls** (KS legislature historical subdomain 404-trap, AR treasury ECONNREFUSED, news 403/429). Jester (1, brand-new 27yo appointee Jan-2025), Toland (4, LtGov w/ no legislative record — Commerce Secretary only), McRae (0) accepted as genuine — honest-partial beats inference.
- No party inference; no Governor-mirroring (Rutledge from her own AG record; Hosemann from his own SoS/Lt-Gov record; Schwab from his own campaign); no isidewith.

Data record: `backend/data/stance-research/exec-w2-batch-g/` (9 CSVs incl. header-only mcrae.csv + scripts).
