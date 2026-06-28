# 141-06 SUMMARY — Seed batch D (CT, KY, MN, NH, NV, RI, TN, WI, WV)

**Status:** ✅ Complete  **Requirements:** SEXR-01, SEXR-02, SEXR-03
**Migration applied to prod:** 983 (planned 951; renumbered)

35 in-scope Big-5 offices across 9 states. Per-state: CT=5, KY=5, MN=4 (Treasurer abolished), NH=1 (Gov only — no LtGov, AG appt, SoS/Treasurer legislature), NV=5, RI=5, TN=1 (Gov only — LtGov=Senate Pres, AG=SC-appointed, SoS/Treasurer legislature), WI=5, WV=4 (no elected LtGov).

Live-verified June 2026. Confirmed turnover: NH Gov Kelly Ayotte (Jan 2025, succeeded Sununu); WV Gov Patrick Morrisey + AG JB McCuskey + SoS Kris Warner + Treasurer Larry Pack (Jan 2025). KY surname distinction confirmed: AG Russell Coleman (R) ≠ LtGov Jacqueline Coleman (D). CT title "Secretary of the State".

**Verification:** applied clean; POST = 35 offices, 0 lowercase/empty geo_id, 0 NULL role_canonical.

## Deviations
- Migration renumber 951→983 (concurrent city-stance collisions). Generated via `gen-state-exec-seed.mjs`.

## Self-Check: PASSED
