---
phase: 123-ward-geofencing-all-7-cities
plan: "02"
subsystem: geofencing
tags:
  - migrations
  - ward-geofencing
  - districts
  - office-relinks
  - x0014
  - newton
  - somerville
  - lynn
  - fall-river
dependency_graph:
  requires:
    - "123-01: 54 X0014 dissolved ward polygons loaded for all 7 cities (pre-flight guards unblocked)"
    - "120-01: Newton, Somerville, Lynn, Fall River district + politician + office records (FK targets)"
  provides:
    - "31 per-ward LOCAL district rows (newton=8, somerville=7, lynn=7, fall-river=9) with tiger_geoid set"
    - "22 office re-links (newton=8, somerville=7, lynn=7, fall-river=0) from citywide LOCAL to per-ward LOCAL rows"
    - "Migrations 706, 707, 708, 709 applied to production and recorded in schema_migrations ledger"
    - "MAGE-16, MAGE-17, MAGE-18, MAGE-19 district+re-link steps complete"
  affects:
    - "essentials.districts (31 new X0014 LOCAL rows)"
    - "essentials.offices (22 district_id updates)"
tech_stack:
  added: []
  patterns:
    - "Pre-flight DO $$ assertion — RAISES EXCEPTION if geofence_boundaries rows missing (T-119-M4 pattern)"
    - "WHERE NOT EXISTS guard on INSERT — idempotent per-ward district row creation"
    - "tiger_geoid = geo_id for X0014 per-ward rows — Path 0 join pattern"
    - "WHERE tiger_geoid IS NULL guard on citywide UPDATE steps — safe no-ops for already-backfilled rows"
    - "Post-verification DO $$ with 4 gates (A/B/C/D) for cities with ward seats; 2 gates (A/B) for at-large cities"
    - "Office re-link via external_id + citywide district_id guard — natural no-op on second run"
key_files:
  created:
    - backend/migrations/706_newton_council_ward_geofencing.sql
    - backend/migrations/707_somerville_council_ward_geofencing.sql
    - backend/migrations/708_lynn_council_ward_geofencing.sql
    - backend/migrations/709_fall_river_council_ward_geofencing.sql
  modified: []
decisions:
  - "Migration 709 (Fall River) explicitly omits Step 5 — at-large-only council has no ward councillors to re-link; post-verification uses 2 gates only (no C/D)"
  - "Newton non-sequential external_id mapping (Pitfall 3) handled correctly — Ward 7=Baker(-2545560018), Ward 6=Bixby(-2545560019), Ward 4=Block(-2545560020), Ward 8=Farrell(-2545560021), Ward 1=Greenberg(-2545560022), Ward 5=Irish(-2545560023), Ward 3=Malakie(-2545560024), Ward 2=Micley(-2545560025)"
  - "Steps 3-4 (citywide tiger_geoid backfill) included in all 4 migrations as WHERE IS NULL no-op guards — safe regardless of prior backfill state"
metrics:
  duration: "~20 minutes"
  completed: "2026-06-16"
  tasks_completed: 2
  files_modified: 4
---

# Phase 123 Plan 02: Ward Geofencing Migrations 706-709 (Newton, Somerville, Lynn, Fall River) Summary

Applied migrations 706-709 inserting 31 per-ward LOCAL district rows with tiger_geoid and 22 office re-links for Newton (8 wards), Somerville (7 wards), Lynn (7 wards), and Fall River (9 ward boundary rows, 0 re-links — fully at-large council).

## Tasks Completed

| Task | Description | Status | Commit |
|------|-------------|--------|--------|
| 1 | Write and apply migrations 706 (Newton) and 707 (Somerville) | DONE | 7f58a4b9 |
| 2 | Write and apply migrations 708 (Lynn) and 709 (Fall River — at-large) | DONE | f2bce8b4 |

## What Was Built

### Task 1: Migrations 706 (Newton) and 707 (Somerville)

**Migration 706 — Newton:**
- Pre-flight: asserts 8 X0014 `newton-ma-council-ward-*` rows in geofence_boundaries
- Step 1: inserted 8 per-ward LOCAL district rows (`newton-ma-council-ward-1` through `...-8`)
- Step 2: backfilled tiger_geoid on all 8 per-ward rows
- Steps 3-4: no-op guards on citywide `2545560` LOCAL/LOCAL_EXEC (migration 699 already set these)
- Step 5: 8 office re-links using exact non-sequential external_id → ward mapping (Pitfall 3 mitigated)
- Post-verification: Gate A=8, Gate B=2, Gate C=0, Gate D=8 — PASSED

**Migration 707 — Somerville:**
- Pre-flight: asserts 7 X0014 `somerville-ma-council-ward-*` rows
- Step 1: inserted 7 per-ward LOCAL district rows (`somerville-ma-council-ward-1` through `...-7`)
- Step 2: backfilled tiger_geoid on all 7 per-ward rows
- Steps 3-4: no-op guards on citywide `2562535` LOCAL/LOCAL_EXEC (migration 622 already set these)
- Step 5: 7 office re-links (McLaughlin W1 through Hardt W7)
- Post-verification: Gate A=7, Gate B=2, Gate C=0, Gate D=7 — PASSED

### Task 2: Migrations 708 (Lynn) and 709 (Fall River)

**Migration 708 — Lynn:**
- Pre-flight: asserts 7 X0014 `lynn-ma-council-ward-*` rows
- Step 1: inserted 7 per-ward LOCAL district rows (`lynn-ma-council-ward-1` through `...-7`)
- Step 2: backfilled tiger_geoid on all 7 per-ward rows
- Steps 3-4: no-op guards on citywide `2537490` LOCAL/LOCAL_EXEC (migration 622 already set these)
- Step 5: 7 office re-links (Meaney W1 through Avery W7; Council President Alinsug W3 re-linked correctly)
- Post-verification: Gate A=7, Gate B=2, Gate C=0, Gate D=7 — PASSED

**Migration 709 — Fall River (at-large only):**
- Pre-flight: asserts 9 X0014 `fall-river-ma-council-ward-*` rows
- Step 1: inserted 9 per-ward LOCAL district rows (`fall-river-ma-council-ward-1` through `...-9`)
- Step 2: backfilled tiger_geoid on all 9 per-ward rows
- Steps 3-4: no-op guards on citywide `2523000` LOCAL/LOCAL_EXEC (migration 622 already set these)
- Step 5: OMITTED — Fall River is fully at-large; all 9 councillors remain at citywide LOCAL
- Post-verification: Gate A=9, Gate B=2 (no Gate C/D for at-large city) — PASSED

## Final Verification Results

| Check | Result | Expected |
|-------|--------|----------|
| Total per-ward districts (all 4 cities) | 31 | 31 (8+7+7+9) |
| Newton ward councillors at citywide LOCAL | 0 | 0 |
| Somerville ward councillors at citywide LOCAL | 0 | 0 |
| Lynn ward councillors at citywide LOCAL | 0 | 0 |
| Fall River at-large councillors at citywide LOCAL | 9 | 9 |
| Migrations in schema_migrations ledger | 706, 707, 708, 709 | 706, 707, 708, 709 |

## Must-Have Verification

| Criterion | Result |
|-----------|--------|
| 8 newton-ma-council-ward-N LOCAL rows with tiger_geoid | PASS |
| 8 Newton ward councillors re-linked (non-sequential mapping) | PASS |
| 16 Newton at-large councillors still at citywide 2545560 LOCAL | PASS |
| 7 somerville-ma-council-ward-N LOCAL rows with tiger_geoid | PASS |
| 7 Somerville ward councillors re-linked | PASS |
| 4 Somerville at-large councillors still at citywide 2562535 LOCAL | PASS |
| 7 lynn-ma-council-ward-N LOCAL rows with tiger_geoid | PASS |
| 7 Lynn ward councillors re-linked | PASS |
| 4 Lynn at-large councillors still at citywide 2537490 LOCAL | PASS |
| 9 fall-river-ma-council-ward-N LOCAL rows with tiger_geoid | PASS |
| Migration 709 has NO UPDATE essentials.offices step | PASS |
| 9 Fall River at-large councillors still at citywide 2523000 LOCAL | PASS |
| Migrations 706, 707, 708, 709 in schema_migrations ledger | PASS |

## Deviations from Plan

None — plan executed exactly as written.

All four migrations followed the exact structure of migration 661 (Springfield) as specified. Newton's non-sequential external_id mapping (Pitfall 3) was handled correctly using the exact table from migration 578. Fall River's at-large-only structure (Pitfall 1) was handled by explicitly omitting Step 5 and using only 2 post-verification gates.

## Security Review

No security-relevant surface changes. All work is:
- Operator-run SQL migrations (no user input, no API endpoints)
- All external_ids are hardcoded constants from verified migration files (T-123-D1 mitigated)
- Fall River at-large constraint enforced by omitting Step 5 entirely (T-123-D2 mitigated)
- WHERE tiger_geoid IS NULL guard on citywide UPDATE steps — safe no-ops (T-123-D3 mitigated)
- Pre-flight assertion RAISES EXCEPTION if geofence rows missing (T-123-D4 mitigated)

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. All work is data migration of pre-loaded boundary data.

## Known Stubs

None — all 31 per-ward district rows have real tiger_geoid values pointing to verified MassGIS ward polygon geometry loaded in Plan 01.

## Next Steps

- Plan 03: Phase gate verification — verify-phase-123.sql assertions for MAGE-16..22 (all 7 cities). Requires Plans 123-01 and 123-02 complete, plus Wave 3 plans (123-03 sub-plans for Waltham/Medford/New Bedford — migrations 710-712).

## Self-Check: PASSED

- `backend/migrations/706_newton_council_ward_geofencing.sql` exists: VERIFIED
- `backend/migrations/707_somerville_council_ward_geofencing.sql` exists: VERIFIED
- `backend/migrations/708_lynn_council_ward_geofencing.sql` exists: VERIFIED
- `backend/migrations/709_fall_river_council_ward_geofencing.sql` exists: VERIFIED
- Commit 7f58a4b9 exists (Task 1): VERIFIED
- Commit f2bce8b4 exists (Task 2): VERIFIED
- 31 per-ward district rows with tiger_geoid: VERIFIED via SQL query
- 706, 707, 708, 709 in schema_migrations ledger: VERIFIED via SQL query
