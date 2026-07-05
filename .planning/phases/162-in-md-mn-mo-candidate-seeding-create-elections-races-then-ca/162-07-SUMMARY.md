---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 07
subsystem: elections-data
tags: [postgres, supabase, elections, house-candidates, indiana, dedup, incumbent-flag-fix]

# Dependency graph
requires:
  - phase: 162 (plan 06)
    provides: MN fully end-to-end (wave dependency; IN runs last per D-03)
  - phase: 160 (plan 03)
    provides: 160-field-table-p162.csv (IN 9-district field), 160-incumbent-map.csv (IN mixed external_id schemes)
  - phase: 161 (plan 02)
    provides: 161-az-generate.mts (vanilla new-election generator base)
provides:
  - IN-9 primary incumbent flags corrected on prod (Houchin sole incumbent) — migration 1212
  - 1 IN election ('IN 2026 Statewide General') + 9 races (decided-field), 21 active race_candidates on prod — migs 1213/1214
  - 12 IN challengers band-addressable (-180902..-180101): 5 new + 7 reused (external_ids assigned); 9 incumbents reused (mixed schemes)
  - backend/scripts/162-in-generate.mts, seed-in-house-headshots.py, 162-07-in-reconciliation.csv
affects: [162-09 (IN stance research), 162-11 (verify.sql IN assertion)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["3-disposition generator (NEW / REUSE-by-pid+assign-external_id / INCUMBENT-by-extid); live-dedup reconciliation of pre-seeded discovery/bulk-seed records; idempotent guarded UPDATE for flag-fix + reuse-assign + junk-deactivate"]

key-files:
  created:
    - backend/migrations/1212_fix_in9_incumbent_flags.sql
    - backend/migrations/1213_seed_in_2026_house_elections_races.sql
    - backend/migrations/1214_seed_in_2026_house_candidates.sql
    - backend/scripts/162-in-generate.mts
    - backend/scripts/seed-in-house-headshots.py
    - backend/data/seed-in-2026-house/162-07-in-reconciliation.csv
    - backend/scripts/_in-house-headshot-results.json  (gitignored)
  modified: []

key-decisions:
  - "IN-9 FLAG FIX — plan/audit-CSV ids were ALL WRONG (conflated politician_ids, race_candidates.ids, race_ids). Live re-verify (A2 mitigation) revealed: 7d3f0042 = IN-9 DEMOCRATIC primary (4 Dem candidates all wrongly is_incumbent=true); 9d2de2ae = IN-9 REPUBLICAN primary RACE id (not an rc.id) holding only Houchin (wrongly false). Fix (mig 1212) uses live-verified ids: Houchin a61ab808 false->true; 4 Dem rows (e013947d/22151151/ec6f181a/9fe223d8) true->false. Intent preserved (1 IN-9 incumbent = Houchin)."
  - "DEDUP DEVIATION (operator-approved 2026-07-04) — plan assumed all 12 general challengers new; live prod showed 7 already existed from indiana_discovery (IN-specific) + federal_2026_bulk_seed (NATIONAL pool). Chosen: REUSE 7 + CREATE 5 + deactivate 2 junk 'Brad Meyer' dups. Reused pids assigned -180xxx external_ids via guarded UPDATE so the whole field is band-addressable for headshots/stances."
  - "Formal-name/nickname reuse mappings (rc.full_name uses ballot name; politician record keeps DB name): J.D. Ford=Jonathan Ford (ad47de71; sitting IN state senator, high confidence), Cinde Wirth=Cynthia Wirth (90342c06), Brad Meyer=Bradley Meyer (926943ad; rc-linked to IN-9 D primary = confirmed IN), Patrick McAuley=Patrick Mcauley (cda9e16f; bulk_seed exact name), William Henry (cfca3142), Kelly Thompson (e976e2c2), Tonya Hudson (8f08a551)."
  - "Genuinely-new (5): Barb Regnitz, Jamee Decio, Drew Cox, James Sceniak, Mary Allen. Incumbents (9) reused by existing external_id: -18001/-18002/-18003/499386/-18005/-18006/499408/499413/499417."
  - "DECIDED field (May-5 primary done) → races.description = 'Confirmed nominee + declared-so-far minor-party field (primary decided May-5)', NOT the PROVISIONAL wording (that is MN/MO-only)."
  - "Migration numbers 1212/1213/1214 taken after live HWM re-check (max was 1211). All idempotent: 1212 re-run UPDATE 0/0; 1213 INSERT 0 0; 1214 all 9 UPDATE 0 + all INSERT 0 0."

# Verification (all pass)
flag-fix-migration: 1212
seed-migrations: 1213 (1 election + 9 races), 1214 (7 reuse-assign + 2 junk-deactivate + 5 new + 21 race_candidates)
in9-incumbents-after-fix: 1 (Houchin, is_incumbent=true across both IN-9 primary races)
races: 9, null office_id: 0
active-race_candidates: 21 (9 incumbents flagged, 12 challengers not)
challenger-external-id-range: -180902 .. -180101 (12 records: 5 new + 7 reused)
junk-dups-deactivated: 2 (Brad Meyer orphans 32d8cc05, 9d124770)
dup-full-name: 0
headshots: 1 pre-existing (Bradley Meyer -180901); 11 documented honest-skips (guards rejected Pence page for Jonathan Ford, William-Henry-Harrison-1841 for William Henry). All 12 have image or honest-skip.

# Data-quality flags surfaced (for a future cleanup pass)
- The federal_2026_bulk_seed source is a NATIONAL pool (CA/other-state stubs present) — name-only matches there carry homonym risk; only Bradley Meyer was rc-confirmed as IN. Patrick McAuley reused per operator's exact-name criterion despite no IN-specific corroboration.
- Reused politician records keep their DB full_name (Jonathan Ford / Cynthia Wirth / Bradley Meyer / Patrick Mcauley); the candidate card uses race_candidates.full_name (ballot names). If any surface displays politicians.full_name, consider a preferred_name/alternate_names backfill later.
---

# 162-07 Summary — IN 2026 US House Seed (flag-fix + dedup reconciliation)

Fixed the IN-9 primary incumbent-flag bug first (migration 1212 — Houchin is now the
sole IN-9 incumbent), then seeded IN's decided 2026 US House field: 1 election + 9 races
+ 21 active race_candidates on prod. This plan hit two significant live-data deviations
from the plan, both handled and documented:

1. **The plan's IN-9 ids were entirely wrong** (conflated politician_ids / race_candidates.ids
   / race_ids). The mandatory A2 live re-verify caught it; the fix uses the real ids.
2. **7 of 12 general challengers already existed** (indiana_discovery / federal_2026_bulk_seed,
   several under formal names). Per operator decision, reused them (assigning band external_ids)
   + created 5 new + deactivated 2 junk "Brad Meyer" duplicate orphans. 0 duplicate full_name.

## Acceptance (all pass)
- IN-9: exactly 1 incumbent (Houchin) across both primary races ✓
- 9 races, 0 null office_id, decided-field wording ✓
- 21 active race_candidates (9 incumbents flagged, 12 challengers) ✓
- 12 challengers band-addressable (-180902..-180101); incumbents reused (mixed schemes) ✓
- 2 junk orphans deactivated; 0 dup full_name ✓
- All migrations idempotent (re-run = 0-row no-ops) ✓
- Every challenger has an image (Bradley Meyer) or a documented honest-skip (11) ✓

## Next
Chain to plan 09 (MD seed — races-only reuse onto 8 pre-existing MD races) then plan 08
(IN stances) + plan 10 (MD stances) + 162-11 verify. Per D-03, IN+MD are the decided,
low-urgency tail.
