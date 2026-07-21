---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 08
subsystem: elections-data
tags: [postgres, supabase, elections, house-candidates, maryland, races-only-reuse, dedup]

# Dependency graph
requires:
  - phase: 162 (plan 06)
    provides: MN done (wave dependency; MD runs last with IN per D-03)
  - phase: 160 (plan 03)
    provides: 160-field-table-p162.csv (MD field), 160-race-preexistence-audit.csv (8 MD existing_race_id UUIDs), 160-incumbent-map.csv
  - phase: 161 (plan 08)
    provides: 161-ma-generate.mts (races-only reuse analog), seed-ma-house-headshots.py
provides:
  - MD 2026 field wired onto the 8 PRE-EXISTING MD races (2026 Maryland General Election) — migration 1217; NO new elections/races
  - 20 race_candidates (13 challengers + 7 incumbents), exactly 1 per (race_id, politician_id); 12 new politicians (-240802..-240101) + Boafo reused
  - backend/scripts/162-md-generate.mts, seed-md-house-headshots.py, 162-08-md-reconciliation.csv
affects: [162-10 (MD stance research), 162-11 (verify.sql MD assertion)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["candidates-only race_candidates insert onto existing_race_id UUIDs (no elections/races INSERT); REUSE_PID challenger keeping its own out-of-band external_id (Boafo); NOT EXISTS (race_id, politician_id) idempotency"]

key-files:
  created:
    - backend/scripts/162-md-generate.mts
    - backend/migrations/1217_seed_md_2026_house_candidates.sql
    - backend/scripts/seed-md-house-headshots.py
    - backend/data/seed-md-2026-house/162-08-md-reconciliation.csv
    - backend/scripts/_md-house-headshot-results.json  (gitignored)
  modified: []

key-decisions:
  - "CANDIDATES-ONLY: wired onto the 8 existing MD races by hardcoded race_id UUID; NO elections/races INSERT (confirmed 8 races before + after). Confirmed 0 pre-existing race_candidates on those 8 races (no Clark/Pressley-style skip needed). Election name looked up live = '2026 Maryland General Election'."
  - "DEDUP (live, IN-style precaution): only 1 of 13 challengers pre-existed — Adrian Boafo (MD-5 D nominee, Hoyer's open-seat replacement) = prior MD state-delegate record pid 1da26040 / external_id -2420067 (already has a headshot). REUSED by pid (kept his -2420067 external_id, is_incumbent=false); NOT duplicated into the -240xxx band. Chris Chaffee's name-matches were all different people (Camden/Doug Chaffee) → genuinely new."
  - "Hoyer MD-5 (-2440005) RETIRED → no active row (open seat; mirrors AZ/MN Senate-departures). 7 active incumbents (Harris/Olszewski/Elfreth/Ivey/McClain Delaney/Mfume/Raskin) reused by pid, is_incumbent=true. All 8 MD incumbents are zero-tier (0 stances) → all 7 active ones are 162-10 stance targets."
  - "DECIDED field (Jun-23 primary done) → races.description set to 'Confirmed nominees + declared-so-far minor-party field; unaffiliated window open to 2026-08-03' (idempotent); NOT PROVISIONAL. Phase 167 reconciles late unaffiliated filers (window to Aug-3)."
  - "Migration 1217 (HWM re-checked live — 1215/1216 taken by a parallel washco session). Idempotent: re-run = 0 non-zero-row statements."

# Verification (all pass)
migration: 1217
md-election-name: 2026 Maryland General Election  (for 162-10 headshot/stance join)
races-before-and-after: 8 (no new races created)
race_candidates: 20 (7 incumbent=true + 13 challenger=false); exactly 1 per (race_id, politician_id)
new-politicians: 12 (band -240802..-240101); Boafo reused (-2420067)
hoyer-active-row: 0 (retired)
dup-full-name: 0
idempotent: yes (0-row re-apply)
headshots: Ficker + Schwartz uploaded; Boafo pre-existing (-2420067); 10 honest-skip (Chaffee correctly rejected via 2022-Senate-election-page guard). All 13 challengers have image or honest-skip.

# Note for 162-10 (MD stances)
Targets = 12 new challengers (band -240899..-240101) + Boafo -2420067 + 7 zero-tier active incumbents
(Harris/Olszewski/Elfreth/Ivey/McClain Delaney/Mfume/Raskin) = 20 targets. Hoyer excluded (no row).
Reused Boafo record display name is correct ("Adrian Boafo"). Robin Ficker is a very well-documented
perennial MD figure (rich stance sourcing expected); Raskin/Mfume are high-profile sitting reps.
---

# 162-08 Summary — MD 2026 US House Seed (candidates-only reuse)

Wired MD's full decided 2026 US House field onto its 8 pre-existing races (candidates-only,
no new elections/races) — 20 race_candidates (13 challengers + 7 incumbents), exactly 1 per
(race_id, politician_id). Clean plan with one IN-style dedup hit: Adrian Boafo already existed
as a MD state-delegate record and was reused (not duplicated). Hoyer (retired) got no row.

## Acceptance (all pass)
- 8 MD races unchanged (no new races); 0 pre-existing rc confirmed before seeding ✓
- 20 race_candidates, exactly 1 per (race_id, politician_id) ✓
- 12 new politicians (-240802..-240101) + Boafo reused; 7 incumbents reused; Hoyer no row ✓
- 0 duplicate full_name; migration idempotent ✓
- Ficker + Schwartz headshots uploaded, Boafo pre-existing, 10 honest-skip — all 13 covered ✓

## Next
Chain to plan 10 (MD stances — 20 targets incl. 7 zero-tier incumbents + Boafo) then plan 11
(verify.sql: add MN/IN/MD assertions + the whole-record skip / iSideWith-review pins).
