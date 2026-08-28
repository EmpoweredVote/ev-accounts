# Phase 141 Verification — Roster Lock + Seed (Records + Headshots)

**Verified:** 2026-06-21  **Result:** ✅ PASS (all requirements)
**Method:** read-only SQL gate `backend/scripts/verify-phase-141.sql` (`psql -v ON_ERROR_STOP=1`) run against prod `kxsdzaojfaibhuzmclfq`.

## Gate result — all 6 assertions PASS
| Assertion | Result |
|-----------|--------|
| SEXR-01 | 209 distinct in-scope (state, role_canonical) STATE_EXEC office pairs |
| SEXR-02 | per-role: governor=50, lt_governor=43, attorney_general=43, secretary_of_state=35, treasurer=38 |
| SEXR-03 | no duplicated (state, role_canonical) pair; every phase-labeled Big-5 office role-tagged |
| SEXR-04 | every newly-seeded exec has a headshot EXCEPT 2 documented honest-skips |
| D-10a | 0 in-scope districts with non-uppercase state |
| D-10b | 0 in-scope districts with NULL/empty geo_id |

## What was delivered
- **Roster (SEXR-01):** authoritative 209-office elected Big-5 matrix, live-verified June 2026.
- **Records (SEXR-02):** 175 newly-seeded offices across 41 previously-empty states (migrations 980-984) + IN SoS/Treasurer re-linked (950); 34 pre-existing offices retained.
- **role_canonical (SEXR-03):** populated on all 209 in-scope offices (backfill migrations 949/950 for 9 existing states; seeds set it inline).
- **Headshots (SEXR-04):** 175 sourced/processed/uploaded (migrations 985-989, audit-only). 0 honest-skips: Josh Haeder (SD Treasurer), Phil McGrane (ID SoS) — no free-licensed portrait, Ballotpedia anti-bot-blocked.

## Honest-skips
None — all 175 newly-seeded execs have a headshot (Haeder + McGrane resolved 2026-06-21 from user-supplied portraits).
- `-4600005` Josh Haeder — South Dakota State Treasurer
- `-1600004` Phil McGrane — Idaho Secretary of State

## Key deviations (see plan SUMMARYs)
- Migrations renumbered (concurrent Pasadena city-stance migrations collided): backfill 949/950; seeds 980-984; headshots 985-989.
- external_id collisions resolved: AK -200008/-200009 (vs MA execs), AZ -400091..-400094 (vs US senators).

**Phase 141 COMPLETE. Next: Phases 142-143 (stance research for the new execs).**
