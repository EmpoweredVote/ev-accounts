# 150-02 SUMMARY — 150-verify.sql gate

**Status:** ✅ Complete (gate authored; data-dependent assertions correctly FAIL pre-seed)
**Wave:** 1
**Artifact:** `backend/scripts/150-verify.sql`

## What was built

A standalone, write-free, per-state TX/NY-scoped labeled-assertion gate adapting the 149-verify.sql precedent for two states. Run with:
```
cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/150-verify.sql
```

## Assertion labels

| Label | Asserts |
|-------|---------|
| scope | exactly 38 TX + 26 NY distinct House races (per-state) |
| USHC-03a | every race ≥1 active candidate (hard floor; NOTICE counts <2 as uncontested allowance) |
| USHC-03b | 0 active race_candidates with NULL politician_id |
| USHC-02a | 0 duplicate full_name among active candidates WITHIN each state (D-03) |
| USHC-02c | every pinned renominated/cross-district incumbent reuses its 148 pid as active |
| D-05 | Crenshaw (deae1b6d)/Goldman (c7f357ce)/Espaillat (26636234) absent; Toth/Lander/Avila Chevalier present |
| D-02 | NY-13 Bob Cohen + NY-21 Robert Smullen seeded active (minor lines) |
| USHC-04 | every new-band candidate has a politician_images row (honest-skips pinned by external_id) |
| USHC-05a | 0 unsourced stance rows for the in-scope set |
| USHC-05b | each in-scope candidate ≥1 sourced federal stance OR pinned whole-record skip |

## Key conventions (for 150-05..12)

- **Per-state scoping:** `r.election_id IN (tx_eid, ny_eid)` + `NATIONAL_LOWER` + `substr(geo_id,1,2) IN ('48','36')`; `_house.st` column distinguishes TX/NY. Never a cross-state count.
- **In-scope TEMP tables** (so 150-05..11 can run the gate mid-wave):
  - `_new_cands` = headshot scope = active candidates with external_id in **TX -4819999..-4810000** or **NY -3619999..-3610000**.
  - `_in_scope` = stance scope = **ALL active TX candidates** UNION **only NEW NY candidates** (new band).
- **D-01 NY exclusion:** the 25 NY partial incumbents + NY-14 AOC are EXCLUDED from `_in_scope` (their external_ids are −36001..−36026, outside the new band) — their pre-existing partial coverage cannot false-fail 05a/05b.
- **Honest-skip ORDER BY (143 lesson):** `_stance_skip` (by UUID) and the USHC-04 external_id `NOT IN` list both carry explicit ORDER BY; currently empty (placeholder `0`), POPULATED-BY the headshot (150-05/06) and stance (150-07..11) waves.
- **POPULATED-BY-150-03 marker:** the 4 redistricted-away TX incumbents (TX-9 Green / TX-30 Crockett / TX-32 Johnson / TX-33 Veasey) reuse pins are added from the 150-03 reconciliation once their new districts are known (the renominated 25 + Casar TX-37 are pinned now).

## Pre-seed run result (expected)

`FAIL USHC-03a: 64 TX/NY House race(s) have 0 active candidates` — the gate reached USHC-03a, meaning setup + scope sanity (38/26 race counts) PASSED; candidate/dedup/headshot/stance assertions legitimately fail pre-seed and go green after Waves 2–4.

## Verify check

`PASS-scoped-and-write-free` (NATIONAL_LOWER + '48'/'36' present; no DELETE/UPDATE/INSERT INTO essentials|inform).
