# 141-07 SUMMARY — Seed batch E (AZ, DE, ID, LA, MT, NM, SC, WY)

**Status:** ✅ Complete  **Requirements:** SEXR-01, SEXR-02, SEXR-03
**Migration applied to prod:** 984 (planned 952; renumbered) — final seed batch

35 in-scope Big-5 offices. Per-state: AZ=4 (LtGov DEFERRED to Jan 2027 per D/research), DE=4 (SoS appointed), ID=5, LA=5, MT=4 (Treasurer abolished), NM=5, SC=5, WY=3 (no LtGov, AG appointed).

Live-verified June 2026. Confirmed turnover: DE Gov Matt Meyer + LtGov Kyle Evans Gay (Jan 2025); LA Treasurer John Fleming (won 2025 special). SC Treasurer Curtis Loftis remains incumbent (impeachment proceedings filed Jan 2025 but not removed).

**Verification:** applied clean; POST = 35 offices, 0 lowercase/empty geo_id, 0 NULL role_canonical. Final gate: SEXR-01=209, SEXR-02 (50/43/43/35/38), SEXR-03, D-10a/b ALL PASS; SEXR-04 pending headshots (Wave 2/3).

## Deviations
- **external_id collision (AZ):** `-(4*100000+seq)` = -400001..-400004 collided with US Senators. AZ reassigned to free slots **-400091..-400094** (D-04 preflight-verified).
- Migration renumber 952→984 (concurrent city-stance collisions). Generated via `gen-state-exec-seed.mjs`.

## Self-Check: PASSED
