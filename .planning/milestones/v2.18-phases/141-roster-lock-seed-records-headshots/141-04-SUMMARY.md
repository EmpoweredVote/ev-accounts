# 141-04 SUMMARY — Seed batch B (AR, GA, HI, IA, MO, ND, OK, VT)

**Status:** ✅ Complete  **Requirements:** SEXR-01, SEXR-02, SEXR-03
**Migration applied to prod:** 981 (planned 949; renumbered)

35 in-scope Big-5 offices seeded idempotently with role_canonical, uppercase state, FIPS geo_id, collision-free external_ids. Per-state: AR=5, GA=4 (Treasurer appointed→excluded), HI=2 (AG/SoS/Treasurer none/appointed), IA=5, MO=5, ND=5, OK=4 (SoS appointed→excluded), VT=5.

Live-verified June 2026. Confirmed turnover: MO Gov Mike Kehoe + LtGov Wasinger + SoS Hoskins (Jan 2025), MO AG Catherine Hanaway (Sept 2025, succeeded Bailey→FBI); ND Gov Kelly Armstrong + LtGov Strinden (Jan 2025); AR John Thurston→Treasurer, Cole Jester→SoS.

**Verification:** applied clean; POST = 35 offices, 0 lowercase/empty geo_id, 0 NULL role_canonical.

## Deviations
- Migration renumber 949→981 (concurrent city-stance collisions). Generated via `gen-state-exec-seed.mjs`.

## Self-Check: PASSED
