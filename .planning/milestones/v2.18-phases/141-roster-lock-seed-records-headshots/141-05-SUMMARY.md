# 141-05 SUMMARY — Seed batch C (CO, KS, MI, NE, NJ, OH, PA, WA)

**Status:** ✅ Complete  **Requirements:** SEXR-01, SEXR-02, SEXR-03
**Migration applied to prod:** 982 (planned 950; renumbered)

35 in-scope Big-5 offices seeded. Per-state: CO=5, KS=5, MI=4 (Treasurer appointed), NE=5, NJ=2 (AG/SoS/Treasurer appointed), OH=5, PA=4 (SoS appointed), WA=5.

Live-verified June 2026. Confirmed turnover: WA Gov Bob Ferguson + AG Nick Brown (Jan 2025); **NJ Gov Mikie Sherrill + LtGov Dale Caldwell** (won Nov 2025, inaugurated Jan 2026 — post-election current holders); OH AG **Andy Wilson** (appointed June 7 2026 after Yost→ADF), OH LtGov Jim Tressel; PA AG Dave Sunday (Jan 2025); NE Treasurer Joey Spellerberg (Nov 2025).

**Verification:** applied clean; POST = 35 offices, 0 lowercase/empty geo_id, 0 NULL role_canonical.

## Deviations
- Migration renumber 950→982 (concurrent city-stance collisions). Generated via `gen-state-exec-seed.mjs`.

## Self-Check: PASSED
