---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 05
title: SC 2026 US House seed
status: complete
executed: 2026-07-05
execution_mode: inline (orchestrator, no sub-agent — per user request)
---

# 163-05 SUMMARY — South Carolina 2026 US House seed

**Result:** SC's full 2026 US House field seeded on prod — vanilla single-election (SC not redistricted, no withholding), decided general field (no PROVISIONAL prefix). 3/3 tasks complete.

## Row counts (all verified on prod)
- **1 election** ("SC 2026 Statewide General", general, 2026-11-03) + **7 races**, every `office_id NOT NULL` (0 null).
- **16 new politicians** (external_id band -450701..-450101; formula -(45*10000+cd*100+seq)), 0 duplicate external_id, 0 duplicate full_name.
- **21 active `race_candidates`** = 16 new + 5 reused renominated incumbents (Wilson -45002, Biggs -45003, Timmons -45004, Clyburn -45006, Fry -45007).
- Per-district active counts: SC-1=4 (open), SC-2=3, SC-3=3, SC-4=3, SC-5=3 (open), SC-6=3, SC-7=2.
- **Mace (-45001) + Norman (-45005)** both retired to run for Governor → REUSE-NO-ROW: politicians/offices rows untouched, **0 active race_candidates rows** for either (confirmed).
- Both migrations **idempotent**: re-run = all `INSERT 0 0`.

## Migrations applied
- Reserved pair **1224** (election+races) + **1225** (candidates); re-verified free at execution (1220-1223 taken by WI/CO), no shift needed; applied via `psql -v ON_ERROR_STOP=1`.

## Headshots
- `seed-sc-house-headshots.py` cloned from **this phase's `seed-wi-house-headshots.py`** (not the older MO script) to inherit the `_FOREIGN_NATIONALITY` homonym guard added in 163-02. Only SC-specific tokens changed (BANDS 3-tuple `'SC': (-450799,-450101,'South Carolina')`, `, south carolina` place-token, `_sc-house-headshot-results.json`); wrong-person guard regexes unchanged.
- **1 uploaded** (Nancy Lacore, SC-1, public_domain), **15 honest-skip** (14 no candidate-person page, 1 no-lead-image) — trail in `scripts/_sc-house-headshot-results.json` (gitignored).

## Jul-15 independent window (Pitfall 4)
- Execution date **2026-07-05 is BEFORE the 2026-07-15 filing deadline** → window still OPEN; no new independents can exist yet. Seeded the known decided field; **SC flagged for Phase-167 re-pull** to catch any independents/petition candidates filing before Jul-15. Recorded in the reconciliation CSV header.

## Files
- backend/scripts/163-sc-generate.mts
- backend/migrations/1224_seed_sc_2026_house_elections_races.sql
- backend/migrations/1225_seed_sc_2026_house_candidates.sql
- backend/scripts/seed-sc-house-headshots.py
- backend/data/seed-sc-2026-house/163-05-sc-reconciliation.csv

## For 163-11 gate / downstream
- SC decided field, no severe/withheld districts (not redistricted).
- SC-1 + SC-5 open-seat (incumbent REUSE-NO-ROW) — assert 0 active rows for -45001/-45005 in SC 2026 races.
- Phase-167: SC independent/petition window re-pull (deadline 2026-07-15).
