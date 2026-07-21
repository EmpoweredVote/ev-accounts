---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 05
subsystem: elections-data
tags: [postgres, supabase, elections, house-candidates, headshots, wikipedia, minnesota]

# Dependency graph
requires:
  - phase: 162 (plan 04)
    provides: MO end-to-end complete (wave dependency; plan 05 runs second per D-03)
  - phase: 160 (plan 03)
    provides: 160-field-table-p162.csv (MN 8-district field), 160-incumbent-map.csv (MN incumbent pids/external_ids)
  - phase: 161 (plan 02)
    provides: 161-az-generate.mts (vanilla 1-election generator to clone)
  - phase: 161 (plan 08)
    provides: seed-ma-house-headshots.py (1-election 4-tuple headshot clone template)
provides:
  - 1 MN election ('MN 2026 Statewide General', general, 2026-11-03) + 8 races on prod, all office_id NOT NULL
  - 35 new MN politicians (band -270804..-270101) + 42 active race_candidates (7 incumbents reused; Craig excluded)
  - backend/scripts/162-mn-generate.mts, migrations 1210/1211, seed-mn-house-headshots.py, 162-05-mn-reconciliation.csv
affects: [162-06 (MN stance research), 162-11 (verify.sql MN assertion + coordinate-smoke)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["clone 161-az vanilla 1-election generator; 4-tuple election-scoped headshot script (WHERE el.name join); open-seat REUSE-NO-ROW for Senate-departing incumbent"]

key-files:
  created:
    - backend/scripts/162-mn-generate.mts
    - backend/migrations/1210_seed_mn_2026_house_elections_races.sql
    - backend/migrations/1211_seed_mn_2026_house_candidates.sql
    - backend/scripts/seed-mn-house-headshots.py
    - backend/data/seed-mn-2026-house/162-05-mn-reconciliation.csv
    - backend/scripts/_mn-house-headshot-results.json  (gitignored)
  modified: []

key-decisions:
  - "MN is NOT redistricted — vanilla new-election, no withholding. Single 'MN 2026 Statewide General' election; all 8 races wired to the existing NATIONAL_LOWER offices (geo 2701..2708) via districts→offices join; essentials.offices untouched (reps feed intact)."
  - "Angie Craig (MN-2, -27002) filed for US Senate → REUSE-NO-ROW (open-seat convention, mirrors AZ-1/AZ-5). 7 renominated incumbents reused by external_id -27001/-27003..-27008. 0 duplicate full_name."
  - "Full field marked PROVISIONAL ('cull >= 2026-08-12', day after MN's Aug-11 primary) — late-primary bucket per D-03, same as MO; distinct from IN/MD decided bucket."
  - "Migration numbers 1210/1211 taken after live re-check (max was 1209, parallel OR session); no collision at author or apply time. Idempotency re-run = 2× + 77× INSERT 0 0 (clean no-op)."
  - "Headshot script cloned from seed-ma (1-election 4-tuple BANDS with el.name join); only docstring/BANDS/RESULTS_JSON/--state changed — wrong-person guard regexes byte-identical to MA (git diff confirmed)."

# Verification
new-candidate-external-id-range: -270804 .. -270101 (35 records)
migrations-applied: 1210 (1 election + 8 races), 1211 (35 politicians + 42 race_candidates)
headshots: 3 uploaded (Matt Little -270205, Kaela Berg -270203, Eric Pratt -270201 — all MN-2 state legislators w/ Wikipedia pages), 32 documented honest-skips
---

# 162-05 Summary — MN 2026 US House Seed (vanilla new-election)

Seeded Minnesota's full 2026 US House field on prod: 1 general election + 8 races
(all `office_id` NOT NULL), 35 new politicians + 42 active `race_candidates`. MN is
not redistricted, so this is the vanilla 161-AZ new-election pattern with no
withholding. Craig (MN-2) departed for the US Senate → open seat, no active row;
7 renominated incumbents reused by external_id. Field is PROVISIONAL (Aug-11 primary,
cull ≥ 2026-08-12). 3 free-license headshots found; 32 candidates honest-skipped
(no free portrait / wrong-person guard rejection), all documented in the results JSON.

## Acceptance (all pass)
- 8 races, 0 null office_id ✓
- 35 new politicians in-band (-270804..-270101) ✓
- 42 active race_candidates (7 incumbents + 35 new); Craig -27002 has 0 active rows ✓
- 0 duplicate full_name within the MN election ✓
- Idempotency: both migrations re-run as clean no-ops ✓
- Every new candidate has a politician_images row OR a documented honest-skip ✓

## Per-district active counts
MN-1: 5 (4 new) · MN-2: 7 (7 new, open) · MN-3: 3 (2 new) · MN-4: 5 (4 new) ·
MN-5: 10 (9 new, largest) · MN-6: 4 (3 new) · MN-7: 3 (2 new) · MN-8: 5 (4 new)

## Next
Plan 06 — MN stance research (federal-24 topic set; run on Sonnet, ≤3 concurrent,
push each batch to prod for resilience).
