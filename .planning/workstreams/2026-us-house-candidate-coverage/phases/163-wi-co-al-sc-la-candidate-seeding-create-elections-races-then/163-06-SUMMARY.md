---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 06
title: LA 2026 US House seed (jungle-primary, severity-routed)
status: complete
executed: 2026-07-05
execution_mode: inline (orchestrator, no sub-agent — per user request)
---

# 163-06 SUMMARY — Louisiana 2026 US House seed (jungle model + D-01b withholding)

**Result:** LA's full 2026 US House field seeded on prod using the jungle/open-primary model. 3/3 tasks complete.

## Jungle model (Critical Question 2)
- **6 races, one per district, all `primary_party = NULL`** (verified: with_party=0). ALL qualified candidates (incumbent + every party) wired to that single race — no per-party primary races.
- **NO December-2026 runoff** election or race created (verified: 0 LA elections dated >= 2026-12-01). Deferred to Phase 167 (unknowable until Nov-3 results).
- All 6 districts PROVISIONAL: 'declared-so-far field, re-pull after 2026-08-07 qualifying close'.

## Severity routing (from 163-01 LA audit: `Severe geo_id list: 2202, 2206`)
- **LA-2 (2202) + LA-6 (2206) → withheld** election `LA 2026 Congressional Redistricting - Polygon Pending` (special, 2026-05-29 = SB121/Act 2 signing). Both verified **non-surfacing** (`visible = f, f`). office_id populated; offices untouched.
- **LA-1/3/4/5 → `LA 2026 Statewide General`** (surfacing).
- 164.1 must un-withhold LA-2 + LA-6 on polygon refresh (standing invariant).

## Row counts (all verified on prod)
- **2 elections + 6 races**, all office_id NOT NULL, all primary_party NULL.
- **27 new politicians** (band -220604..-220101; -(22*10000+cd*100+seq)), 0 dup external_id, 0 dup full_name.
- **32 active race_candidates** = 27 new + 5 reused incumbents on the jungle ballot (Scalise -22001, Carter -22002, Higgins -22003, Johnson -22004, Fields -22006).
- Per-district active: LA-1=3, LA-2=2, LA-3=4, LA-4=5, LA-5=13(open), LA-6=5.
- **Letlow LA-5 (-22005)** retired → Senate → REUSE-NO-ROW: **0 active rows** (confirmed).
- Both migrations idempotent (re-run = all `INSERT 0 0`: 8 + 59).

## Migrations applied
- **1228** (2 elections + 6 jungle races) + **1229** (candidates); re-verified free (1227 last), no shift; `psql -v ON_ERROR_STOP=1`.

## Headshots
- `seed-la-house-headshots.py` cloned from `seed-wi-house-headshots.py` (inherits `_FOREIGN_NATIONALITY` guard); BANDS 3-tuple `'LA': (-220699,-220101,'Louisiana')`, band-scoped only (severe LA-2/LA-6 candidates still attempted), `_la-house-headshot-results.json`.
- **1 uploaded** (Michael Echols, LA-5, cc_by_4.0 — state legislator), **26 honest-skip** (no candidate-person page). Includes LA-2/LA-6 severe candidates (skipped, documented).

## Litigation freshness
- 163-01 audit (same day, 2026-07-05) re-verified SB121 operative, no live injunction; withheld date 2026-05-29 confirmed >30 days past → invisible.

## Files
- backend/scripts/163-la-generate.mts
- backend/migrations/1228_seed_la_2026_house_elections_races.sql
- backend/migrations/1229_seed_la_2026_house_candidates.sql
- backend/scripts/seed-la-house-headshots.py
- backend/data/seed-la-2026-house/163-06-la-reconciliation.csv

## For 163-11 gate / downstream
- **LA-SEVERE block:** assert LA-2 (2202) + LA-6 (2206) races wired to Polygon Pending, non-surfacing; negative coordinate-smoke for in-LA-2 / in-LA-6 coordinates → 0 surfaced races.
- Assert all 6 LA races have primary_party NULL (jungle invariant); assert no Dec-2026 LA election exists.
- LA-5 open-seat (Letlow REUSE-NO-ROW) → assert 0 active rows for -22005.
- Phase-167: LA Aug-7 qualifying-close re-pull (declared-so-far → final field); Dec-12 runoff authoring after Nov-3 results.
- Stances (163-09) must cover all 27 new incl. LA-2/LA-6 severe candidates and LA-5's 13.
