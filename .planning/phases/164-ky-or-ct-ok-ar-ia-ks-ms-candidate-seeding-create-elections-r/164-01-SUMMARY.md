---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 01
state: KS
status: complete
completed: 2026-07-06
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1231, 1232]
---

# 164-01 SUMMARY — KS 2026 US House Seed

## What was built
Full 2026 KS US House field seeded on **prod** (`kxsdzaojfaibhuzmclfq`): 1 election, 4 races, 22 new candidate records + 26 active `race_candidates` (22 new + 4 renominated incumbents). PROVISIONAL pre-primary field (KS Aug-4 primary, cull ≥ 2026-08-05). KS is NOT redistricted — vanilla single-election pattern, no withholding.

## Key facts (for 164-13 gate)
- **Election:** `KS 2026 Statewide General` (general, 2026-11-03, state, KS). 4 races, all `office_id` NOT NULL → existing NATIONAL_LOWER offices geo 2001-2004. Description = `PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05`.
- **New-candidate external_id range: -200410 .. -200103** (22 records). D-04 sub-bands applied: KS-1 seq 3 (-200103..-200106), KS-2 seq 10 (-200210..-200212), KS-3 seq 1 (-200301..-200305), KS-4 seq 1 (-200401..-200410). No dup external_id, no dup full_name.
- **Incumbents reused (is_incumbent=true, no new row):** -20001 Tracey Mann (KS-1), -20002 Derek Schmidt (KS-2), -20003 Sharice Davids (KS-3), -20004 Ron Estes (KS-4). All 4 renominated; no open seats.
- Idempotency confirmed: both migrations re-run = all `INSERT 0 0`.

## Collision nuance (documented for 164.1/166)
The KS band `-(20*10000+cd*100+seq)` collides with **11 legacy Massachusetts incumbents**: senators Warren (-200101) / Markey (-200102) and MA House Neal…Keating (-200201..-200209). This is exactly the 160-audit collision (KS-1 seqs 1-2, KS-2 seqs 1-9 occupied) that D-04 sub-bands avoid. All 11 MA records are already imaged and untouched by this seed.

## Headshots — ALL 22 honest-skip (documented in `backend/scripts/_ks-house-headshot-results.json`)
No new KS candidate has a free-license Wikipedia portrait (all down-ballot challengers/minor candidates; wrong-person guard correctly rejected election-list pages). 0 uploaded, 22 documented skips. External_ids for 164-13 gate pin (all 22 new records skipped):
-200103 Colin McRoberts, -200104 Lauren Reinhold, -200105 Steven Jacob (no-lead-image), -200106 Craig Musser, -200210 Chad Young, -200211 Don Coover, -200212 Braeden Curwick, -200301 Sarah Preu, -200302 Eric Jenkins, -200303 Chase LaPorte, -200304 Gavin Solomon, -200305 Blake Stanley, -200401 Michael Gaynor, -200402 Frank McCollum, -200403 Chris Carmichael, -200404 Katy Tyndell, -200405 Cole Epley, -200406 Ryan Gilbert, -200407 Jordan Mitchell, -200408 Daniel Schneider, -200409 Drew Cranmer, -200410 Paul Catanese.

## Files
- `backend/scripts/164-ks-generate.mts`
- `backend/migrations/1231_seed_ks_2026_house_elections_races.sql`
- `backend/migrations/1232_seed_ks_2026_house_candidates.sql`
- `backend/scripts/seed-ks-house-headshots.py` + `backend/scripts/_ks-house-headshot-results.json`
- `backend/data/seed-ks-2026-house/164-01-ks-reconciliation.csv`

## Self-Check: PASSED
4 races / 0 null office_id; 26 active race_candidates (4 incumbent); 22 new in D-04 bands; 0 dup name; idempotent; every new candidate has a documented honest-skip. Ready for stance research (164-07).
