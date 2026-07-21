---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 03
state: AK
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1254, 1255]
election_name: "AK 2026 Statewide General"
---

# 165-03 SUMMARY — AK top-four-RCV at-large field (jungle model)

## What was built
'AK 2026 Statewide General' + 1 at-large race on the existing NATIONAL_LOWER office (geo_id 0200), **primary_party=NULL** (LA/CA jungle convention — the documented Claude's-Discretion modeling choice; RCV is research-thoroughness only, no schema change). FULL 15-candidate declared top-four field seeded PROVISIONAL: 14 new + Begich III reuse.

## Key facts (for 165-17 gate)
- **Verified AK primary/cull date: 2026-08-18** (elections.alaska.gov, fetched 2026-07-07). Race description: `PROVISIONAL: pre-primary qualified field (top-four-RCV), cull >= 2026-08-18`.
- **Position name convention set: `U.S. Representative At-Large`** (no prior AK race existed; office title is 'U.S. Representative'). Plans 07/08 at-large states (DE/VT/WY/ND/SD) should follow.
- **Exactly 15 active race_candidates**, 1 incumbent (Begich pid 07c7a121, ext -2000, is_incumbent=true, reused — 9 stances, partial-tier → skipped in 165-11).
- **14 new external_ids -20005..-20018** (D-04 safe_start_seq=5; seqs 1–4 = unrelated KS records in the polluted band): -20005 Ambrose II, -20006 Dutchess, -20007 Foddrill Sr., -20008 Goldfarb, -20009 Hafner, -20010 Hill, -20011 McDermott, -20012 Reynoso, -20013 Richey, -20014 Salazar, -20015 Schultz, -20016 Strickland, -20017 J.B. Williams, -20018 M."Bronco" Williams. 0 dup full_name.
- 1 race, office_id NOT NULL, primary_party NULL live-verified. Idempotent: re-run = 0 rows.

## Headshots — 0 uploaded for new AK candidates, ALL 14 honest-skip (documented in `_ak-house-headshot-results.json`)
- **Wrong-person incident caught + purged:** the guard passed "Matt Schultz" (-20015) but Wikipedia's page is the **Iowa Republican** (SoS 2011-15), not the AK Democrat — image row `49c5dd4d` + storage object deleted, results JSON marked `wrong-person-purged`. Same class as the 164 Andrew Rice homonym.
- Side-effect (beneficial): the band sweep found the 4 KS records at -20001..-20004 (Mann/Schmidt/Davids/Estes) had NO images; all 4 resolved to their own correct bio pages and were uploaded (public_domain) — closes part of the incumbent-headshot gap.

## Files
- `backend/scripts/165-ak-generate.mts`
- `backend/migrations/1254_seed_ak_2026_house_election_race.sql` + `1255_seed_ak_2026_house_candidates.sql`
- `backend/scripts/seed-ak-house-headshots.py` (+ gitignored results JSON)
- `backend/data/seed-ak-2026-house/165-03-ak-reconciliation.csv`

## Self-Check: PASSED
1 jungle race (primary_party NULL, office_id NOT NULL, PROVISIONAL with verified date); exactly 15 active (14 new + Begich); safe_start_seq=5 honored; 0 dup; idempotent; every new candidate honest-skipped with documentation (incl. the purged Schultz homonym). Ready for stance research (165-11).
