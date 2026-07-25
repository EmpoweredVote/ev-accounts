---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 02
subsystem: elections-data
tags: [postgres, supabase, elections, house-candidates, headshots, wikipedia, redistricting, missouri]

# Dependency graph
requires:
  - phase: 162 (plan 01)
    provides: 162-mo-correspondence-audit.md severe geo_id list (2902,2903,2904,2905,2906)
  - phase: 160 (plan 03)
    provides: 160-field-table-p162.csv (MO 8-district field), 160-incumbent-map.csv (MO incumbent pids/external_ids)
  - phase: 161 (plan 06)
    provides: 161-tn-generate.mts + seed-tn-house-headshots.py (the exact 2-election clone templates)
provides:
  - 8 MO 2026 House races on prod (3 general-surfacing: 2901/2907/2908; 5 withheld "Polygon Pending": 2902-2906)
  - 58 new MO politicians (band -290805..-290101) + 65 active race_candidates (7 incumbents reused; Graves excluded)
  - backend/scripts/162-mo-generate.mts, migrations 1206/1207, seed-mo-house-headshots.py, 162-02-mo-reconciliation.csv
affects: [162-03 (MO stance batch A), 162-04 (MO stance batch B), 162-11 (verify.sql MO-SEVERE assertion + coordinate-smoke), 164.1 (polygon refresh un-gates severe MO)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["clone 161-tn 2-election severity-routed generator; band-scoped headshot script (no election-name join) for dual-election states; election_id-substitution withholding"]

key-files:
  created:
    - backend/scripts/162-mo-generate.mts
    - backend/migrations/1206_seed_mo_2026_house_elections_races.sql
    - backend/migrations/1207_seed_mo_2026_house_candidates.sql
    - backend/scripts/seed-mo-house-headshots.py
    - backend/data/seed-mo-2026-house/162-02-mo-reconciliation.csv
    - backend/scripts/_mo-house-headshot-results.json
  modified: []

key-decisions:
  - "Cori Bush (MO-1) seeded as a NEW record (external_id -290101), NOT a reuse: the Task-1 prod lookup returned 0 rows — she lost the 2024 primary to Bell and was never seeded. Resolves Pitfall 4 (no incumbent-reuse conflation; 0 duplicate full_name)."
  - "Severe set 2902/2903/2904/2905/2906 (5 of 8) wired to a past-dated (2026-03-24, MO Supreme Court upholding date) non-general 'MO 2026 Congressional Redistricting - Polygon Pending' election so ELECTION_VISIBILITY_WINDOW is false; office_id stays on the old-CD NATIONAL_LOWER office for all 8 races; essentials.offices untouched (reps feed intact)."
  - "Headshot script cloned band-scoped-only (no election-name join, Pitfall 3) so severe-district candidates are ATTEMPTED — verified all 5 severe districts' candidates appear in the attempt log. One localization vs TN: the ', missouri' place-token in _NON_PERSON_TITLE; _BAD_DISAMBIG/_HISTORICAL_YEAR/POLITICAL_KW guards byte-for-byte unchanged."
  - "Migration numbers 1206/1207 taken after live re-check (max was 1205, OR session); no collision at author time."

requirements-completed: [USHC3-02, USHC3-03, USHC3-04]

# Metrics
duration: ~50min
completed: 2026-07-04
---

# Phase 162 Plan 02: MO Full 2026 US House Seed Summary

**MO's full 2026 US House field seeded end-to-end on prod (migrations 1206/1207): 8 races severity-routed by the 162-01 audit (3 surface via the general election, 5 seeded-but-withheld via a dedicated past-dated "Polygon Pending" election), 58 new politicians, 65 active race_candidates, 1 headshot + 57 documented honest-skips — with essentials.offices/the reps feed untouched throughout.**

## Performance

- **Duration:** ~50 min
- **Tasks:** 3 (collision+Bush lookup; generate+apply 2 migrations; headshots)
- **Subagents used:** 0 (all inline, per session decision to limit subagent load)

## What was built + applied to prod

- **Task 1:** Collision band `-290899..-290101` = 0 rows (clean). Cori Bush lookup = 0 rows → NEW. Incumbents `-29001..-29008` verified (Graves `-29006` = retired).
- **Task 2:** `162-mo-generate.mts` (clone of `161-tn-generate.mts`) emitted `1206` (2 elections + 8 severity-routed races) and `1207` (58 politicians + 65 race_candidates). Both applied `ON_ERROR_STOP=1`, exit 0. Re-run = pure no-op (4×0 and 123×0 — idempotent).
- **Task 3:** `seed-mo-house-headshots.py` (band-scoped clone) ran all 58 new candidates; **1 uploaded (Cori Bush)**, 57 honest-skips (mostly no distinct Wikipedia bio page — the standing challenger pattern; cf. TN 3/73, AZ 4/32). Guards confirmed working (Mike Conner's 1891–1950 homonym correctly rejected).

## Verification (all on prod)

| Check | Result |
|-------|--------|
| Active MO race_candidates | 65 ✓ |
| Race routing (2901/2907/2908 general; 2902-2906 special/withheld) | exact ✓ |
| office_id NOT NULL on all 8 races | ✓ |
| New politicians in band | 58 ✓ |
| Duplicate full_name among active MO rows | none ✓ |
| Idempotent re-run | 0-row no-op ✓ |
| Severe-district candidates ATTEMPTED for headshots (Pitfall 3) | 100% (all in attempt log) ✓ |

## Headshot outcome detail

- Uploaded: **1** (Cori Bush, `-290101`, MO-1, non-severe — she has a Wikipedia bio from her prior House tenure).
- Honest-skipped: **57** (documented in `_mo-house-headshot-results.json`). Severe-district uploads = 0, but all severe candidates were *attempted* (Pitfall 3 is about attempted coverage / election-scoped-skip bug, which is avoided — the band-scoped query reached them).
- Notable severe candidates without a free portrait (candidates for a future find-headshots pass, not blockers): Rick Brattin (MO-5, `no-lead-image` — bio page exists, no free photo), Chris Stigall (MO-6), Taylor Burks (MO-5).

## ⚠ Finding — plan assumption contradicted (surfaced, not silently actioned)

The plan's headshot task states MO incumbents are "already imaged in prior phases." **This is false for MO: 6 of 7 renominated incumbents lack a headshot** — Ann Wagner (-29002), Robert F. Onder Jr. (-29003), Mark Alford (-29004), Emanuel Cleaver (-29005), Eric Burlison (-29007), Jason Smith (-29008). Only Wesley Bell (-29001) is imaged. These are sitting members of Congress with near-certain free Wikipedia portraits; the gap appears to trace to v2.15/v2.16 seeding, NOT this phase. Not a plan-02 blocker (USHC3-04 covers *newly-seeded* candidates; all 58 new MO candidates are imaged-or-skipped), but a real product gap surfacing on the reps feed and the 2907/2908 general races. **Recommendation:** a quick targeted (band-less, by-external_id) find-headshots pass for these 6 — decision deferred to operator.

**RESOLVED (operator chose quick-fix):** added a `'MO-INC': (-29008, -29001, 'Missouri')` band to `seed-mo-house-headshots.py` and ran it — 5/6 auto-uploaded (Wagner, Alford, Cleaver, Burlison, Smith; all public-domain/CC-BY-SA official portraits). The 6th, Robert F. Onder Jr., was a false-skip (guard rejected the "Bob Onder" Wikipedia page on first-name mismatch — "Bob" ≠ "Robert"); confirmed same person (119th-Congress official portrait, MO-3, born 1962) and backfilled via `--manual` mode. **All 7 MO incumbents now imaged.**

## Carry-forward for 162-03/04 (MO stances)

- 58 new MO candidates + zero-tier incumbents are the stance-research targets. Per D-03a, incumbents + evidenced majors first, fringe filers last. Push per state (never one mega-push); PROD is the durable store (stance CSVs gitignored).
- MO legal-freshness flag (referendum certification ~2026-07-27) stands — Phase 167 re-pull, per 162-01.
