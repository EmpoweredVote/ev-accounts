---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 04
title: AL 2026 US House seed (split-state, severity-routed)
status: complete
executed: 2026-07-05
execution_mode: inline (orchestrator, no sub-agent — per user request)
---

# 163-04 SUMMARY — Alabama 2026 US House seed (split-state + D-01b withholding)

**Result:** AL's full 2026 US House field seeded on prod. Split state handled on two independent axes — primary-timing (PROVISIONAL) and severity (withheld) — per the 163-01 audit. 3/3 tasks complete.

## Severity routing (from 163-01 AL audit: `Severe geo_id list: 0102`)
- **AL-2 (0102) → withheld** election `AL 2026 Congressional Redistricting - Polygon Pending` (special, 2026-06-02 = SCOTUS-stay date). Verified **non-surfacing**: `ELECTION_VISIBILITY_WINDOW` evaluates FALSE (`visible = f`). office_id still populated; essentials.offices untouched.
- **AL-1/3/4/5/6/7 → `AL 2026 Statewide General`** (surfacing).
- 164.1 must un-withhold AL-2 on polygon refresh (standing invariant).

## Primary-timing (independent of severity)
- **PROVISIONAL** (late-primary, Aug-11 SCOTUS-ordered special primary, cull >= 2026-08-12): AL-1, AL-2, AL-6, AL-7.
- **Decided** (plain general description): AL-3, AL-4, AL-5.
- AL-2 is BOTH late-primary AND severe → PROVISIONAL description + withheld routing (handled independently, both correct).

## Row counts (all verified on prod)
- **2 elections + 7 races**, every `office_id NOT NULL` (0 null).
- **21 new politicians** (band -10702..-10101; -(1*10000+cd*100+seq)), 0 dup external_id, 0 dup full_name. (Sarah McBride -10000 out-of-band, untouched.)
- **27 active race_candidates** = 21 new + 6 reused renominated incumbents (Figures -1002, Rogers -1003, Aderholt -1004, Strong -1005, Palmer -1006, Sewell -1007).
- Per-district active: AL-1=5(open), AL-2=7, AL-3=2, AL-4=2, AL-5=2, AL-6=6, AL-7=3.
- **Moore AL-1 (-1001)** retired → Senate → REUSE-NO-ROW: **0 active rows** (confirmed).
- Both migrations idempotent (re-run = all `INSERT 0 0`: 9 + 48).

## Migrations applied
- **1226** (2 elections + 7 severity-routed races) + **1227** (candidates); re-verified free at execution (1225 last), no shift; `psql -v ON_ERROR_STOP=1`.

## Headshots
- `seed-al-house-headshots.py` cloned from `seed-wi-house-headshots.py` (inherits `_FOREIGN_NATIONALITY` guard); BANDS 3-tuple `'AL': (-10799,-10101,'Alabama')`, band-scoped only (NO election join → AL-2 severe candidates still attempted), `_al-house-headshot-results.json`. Wrong-person guards unchanged.
- **1 uploaded** (Jerry Carl, AL-1, public_domain — former AL-1 Rep), **20 honest-skip** (no candidate-person page). Includes AL-2 severe-district candidates (all skipped, documented).

## Litigation freshness
- The 163-01 audit (same day, 2026-07-05) re-verified the SCOTUS stay is operative with no injunction; withheld election_date 2026-06-02 confirmed >30 days past → invisible.

## Files
- backend/scripts/163-al-generate.mts
- backend/migrations/1226_seed_al_2026_house_elections_races.sql
- backend/migrations/1227_seed_al_2026_house_candidates.sql
- backend/scripts/seed-al-house-headshots.py
- backend/data/seed-al-2026-house/163-04-al-reconciliation.csv

## For 163-11 gate / downstream
- **AL-SEVERE block:** assert AL-2 (0102) race wired to Polygon Pending election, non-surfacing; negative coordinate-smoke for an in-AL-2 coordinate → 0 surfaced races.
- AL-1 open-seat (Moore REUSE-NO-ROW) → assert 0 active rows for -1001.
- Phase-167: AL-1/2/6/7 Aug-11 special-primary result reconciliation (cull non-winners).
- Stances (163-08) must cover all 21 new incl. the 6 AL-2 severe-district candidates.
