---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 01
subsystem: database
tags: [race_candidates, essentials, elections, ca-house, seeding, dedup, idempotent-migration]

# Dependency graph
requires:
  - phase: 148-field-resolution-stance-gap-diagnostic
    provides: locked CA field (148-field-table.csv existing_race_id + general_candidates + new_records_needed), incumbent reuse map (148-incumbent-map.csv)
provides:
  - 104 active essentials.race_candidates wired onto the 52 CA US House races (728d0074), every politician_id non-null
  - 38 new essentials.politicians records for genuinely-new CA challengers/open-seat candidates (-601xxxx external_id band)
  - Raul Ruiz CA-25 dedup applied (canonical 5238b298 wired; dup 05349fa0 retired is_active=false)
  - 149-01-reconciliation.csv (live reuse-vs-new decision per candidate) — inherited mechanics for Phases 150/151
affects: [150-tx-ny-seeding, 151-fl-seeding, 152-coordinate-verification-gate, ca-headshots, ca-stances]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Idempotent pure-SQL seed migration (1072 pattern): retire-dup + INSERT politicians + INSERT race_candidates in one BEGIN/COMMIT, NOT EXISTS guards on (external_id) and (race_id, full_name)"
    - "Live name-check reconciliation CSV before any insert (148 naive name-match caveat) — REUSE existing UUID over creating a new row"
    - "Redistricted incumbent runs in NEW district: reuse existing pid, is_incumbent=false"

key-files:
  created:
    - backend/migrations/1091_seed_ca_2026_house_candidates.sql
    - backend/data/seed-ca-2026-house/149-01-reconciliation.csv
  modified: []

key-decisions:
  - "New external_id scheme -(6010000 + cd*100 + seq); original -(6000000+cd*100+seq) COLLIDED with -6000xxx incumbents, switched to verified-empty -601xxxx band"
  - "No essentials.offices rows for new challengers (feed resolves via race_candidates.politician_id; an office row would pollute reps feed / geofence search)"
  - "Removed updated_at from Ruiz UPDATE — essentials.politicians has no updated_at column (Rule 3 blocking fix)"

patterns-established:
  - "Pattern: 38 NEW + 66 REUSE reconciliation, all 66 reuse pids live-confirmed active before authoring"
  - "Pattern: incumbent name-aliases (Luz Rivas/Ted Lieu/Nanette Barragan) reuse home pid as incumbent"

requirements-completed: [USHC-02, USHC-03]

# Metrics
duration: 18min
completed: 2026-06-29
---

# Phase 149 Plan 01: CA Candidate Seeding (race_candidates only — turnkey) Summary

**Migration 1091 wires the full Nov-3 general field — 104 active race_candidates — onto all 52 CA US House races (728d0074), creating 38 new politician records and reusing 66 existing ones, with the Raul Ruiz CA-25 duplicate retired.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-29T04:25:21Z (phase execution start)
- **Completed:** 2026-06-29
- **Tasks:** 2
- **Files created:** 2

## Accomplishments
- Live-confirmed reuse-vs-new for all 104 CA House general candidates: **38 NEW + 66 REUSE**, every REUSE target_politician_id verified active in prod before authoring.
- Seeded all **52 CA US House races** with their full field (≥2 active candidates each; 0 NULL politician_id). Total **104 race_candidates**.
- Resolved the **Raul Ruiz CA-25** 3-record state: canonical `5238b298` wired as CA-25 incumbent; active duplicate `05349fa0` retired via `is_active=false` (0 orphan rc/stances/images — only a stray office); `eb9448bd` already inactive.
- All **9 same-party generals** (CA-4/7/11/12/14/29/34/37/40) carry both advancers.
- Proven **idempotent**: a second run did `UPDATE 0; INSERT 0 0; INSERT 0 0`.
- **Governor race untouched** (still 76 candidates).

## Task Commits

1. **Task 1: Live reconciliation + Ruiz dedup resolution** — `5301d505` (feat)
2. **Task 2: Author + run idempotent CA House seed migration 1091** — `3ac07cb1` (feat)

## Files Created/Modified
- `backend/data/seed-ca-2026-house/149-01-reconciliation.csv` — 104-row per-candidate reuse/new decision with target_politician_id / assigned external_id, live-confirmed; header documents Ruiz dedup + external_id scheme.
- `backend/migrations/1091_seed_ca_2026_house_candidates.sql` — idempotent BEGIN/COMMIT: retire Ruiz dup + INSERT 38 politicians + INSERT 104 race_candidates. Applied to prod `kxsdzaojfaibhuzmclfq`.

## Decisions Made
- **external_id scheme correction:** the research-recommended `-(6000000 + cd*100 + seq)` collided with existing `-6000xxx` incumbent ids (e.g. -6000201, -6000301). Switched to `-(6010000 + cd*100 + seq)` and verified the entire `-6010000..-6015999` band empty (0 rows) before authoring. Final new range: `-6010201 .. -6015201`.
- **No offices for challengers** (A2 confirmed) — feed resolves candidates via `race_candidates.politician_id`; an office row would leak into the reps feed / geofence search.
- **Redistricted runners reuse pid, is_incumbent=false:** Ami Bera (CA-6→CA-3), Kevin Kiley (CA-3→CA-6 as Independent), Ken Calvert (CA-41→CA-40).
- **Incumbent name-aliases reuse home pid as incumbent:** Luz Rivas (stored "Luz Maria Rivas"), Ted Lieu ("Ted W. Lieu"), Nanette Barragán ("Nanette Diaz Baragán").

## Final reuse-vs-new counts
- **38 NEW** (matches the 148 count exactly — no live name-check flips; all 38 new_records_needed names returned 0 collisions in the live DB).
- **66 REUSE** — 43 home incumbents/redistricted runners + 21 previously-seeded non-incumbents (Connie Chan, Scott Wiener, Mai Vang, Aisha Wahab, Jacqui Irwin, Jason Gibbs, April Verlato, Scott Meyers, Eric Ching, Larry Thompson, Stephanie Vargas, Angela Gonzales-Torres, Mike Cargile, Houston Brignano, Samantha Mota, Marni von Wilpert, Steve Cohen, Joe Males, James Gallagher, Mike McGuire) + Ruiz canonical.

## New-candidate external_id list (downstream headshot/stance plans)
| ext_id | name | cd | ext_id | name | cd |
|--------|------|----|--------|------|----|
| -6010201 | Robin Littau | 2 | -6012301 | Tessa Lynn Hodge | 23 |
| -6010301 | Robb Tucker | 3 | -6012401 | Bob Smith | 24 |
| -6010401 | Eric Jones | 4 | -6012601 | Sam Gallucci | 26 |
| -6010501 | Michael Masuda | 5 | -6012901 | Angélica María Dueñas | 29 |
| -6010601 | Richard Pan | 6 | -6013801 | Hilda Solis | 38 |
| -6010801 | Rudy Recile | 8 | -6013802 | Pedro Antonio Casas | 38 |
| -6010901 | John McBride | 9 | -6013901 | Steve Manos | 39 |
| -6011001 | Jeff Frese | 10 | -6014101 | Linda Sánchez | 41 |
| -6011201 | Jamie Joyce | 12 | -6014102 | Mitch Clemmons | 41 |
| -6011301 | Kevin Lincoln | 13 | -6014201 | Brian Burley | 42 |
| -6011401 | Melissa Hernandez | 14 | -6014301 | Cristian Morales | 43 |
| -6011501 | Charles Hoelter | 15 | -6014401 | Genevieve Angel | 44 |
| -6011601 | Peter Sundin Soulé | 16 | -6014501 | Chuong Vo | 45 |
| -6011701 | Ritesh Tandon | 17 | -6014601 | David Pan | 46 |
| -6011801 | Shane Lewis | 18 | -6014701 | Jenny Le Roux | 47 |
| -6011901 | Peter Verbica | 19 | -6014801 | Jim Desmond | 48 |
| -6012001 | Sandra Van Scotter | 20 | -6014901 | Armen Kurdian | 49 |
| -6012101 | Kyle Kirkland | 21 | -6015101 | Richardo Cabrera | 51 |
| -6012201 | Randy Villegas | 22 | -6015201 | Jeff Belle | 52 |

These 38 are the headshot (USHC-04) + full-federal-24-stance (USHC-05) scope for downstream plans, plus the 36 zero-stance incumbents (D-01).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed nonexistent updated_at column from Ruiz UPDATE**
- **Found during:** Task 2 (first migration apply)
- **Issue:** Migration `SET is_active=false, updated_at=now()` failed — `essentials.politicians` has no `updated_at` column (transaction rolled back, no partial writes).
- **Fix:** Dropped `updated_at = now()` from the UPDATE.
- **Files modified:** backend/migrations/1091_seed_ca_2026_house_candidates.sql
- **Verification:** Re-applied cleanly (UPDATE 1, INSERT 0 38, INSERT 0 104, COMMIT).
- **Committed in:** `3ac07cb1` (Task 2 commit)

**2. [Rule 1 - Bug] Corrected new external_id scheme to avoid collision**
- **Found during:** Task 1 (collision check)
- **Issue:** Research-recommended `-(6000000+cd*100+seq)` collided with 4 existing `-6000xxx` incumbent ids.
- **Fix:** Switched to `-(6010000+cd*100+seq)`; verified `-6010000..-6015999` band empty before use.
- **Files modified:** backend/data/seed-ca-2026-house/149-01-reconciliation.csv (and the migration generated from it)
- **Verification:** 0 internal dups, 0 live collisions across the 38 ids.
- **Committed in:** `5301d505` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug).
**Impact on plan:** Both necessary for correctness. No scope change — still 38 NEW + 66 REUSE, 104 race_candidates.

## Issues Encountered
- A `node -e` verification query mis-bound a param inside `lpad('$1',...)` (the `$1` was inside a string literal, not a placeholder). Rewritten to compute the geo_id in JS — no impact on data.

## Known Stubs
None. Every race_candidate has a non-null politician_id. Headshots (USHC-04) and stances (USHC-05) for the 38 new + 36 zero-stance incumbents are intentionally deferred to downstream plans 149-02+ per the phase's wave structure (D-01).

## Threat Flags
None — no new security surface. Pure data writes to existing tables via a reviewed idempotent migration; antipartisan invariant preserved (no party stored).

## Next Phase Readiness
- All 52 CA House races now surface their full field on `/elections` (race_candidates wired, politician_id non-null). USHC-02 + USHC-03 delivered for CA.
- Downstream: 38-new-candidate external_id list (above) feeds the CA headshot (USHC-04) and stance (USHC-05) plans; 36 zero-stance incumbents are the additional stance scope.
- Mechanics (idempotent SQL seed, live reconciliation, reuse-by-id, redistricted-runner handling) are locked and inherited by Phase 150 (TX+NY) and 151 (FL).

## Self-Check: PASSED

- FOUND: backend/migrations/1091_seed_ca_2026_house_candidates.sql
- FOUND: backend/data/seed-ca-2026-house/149-01-reconciliation.csv
- FOUND: 149-01-SUMMARY.md
- FOUND: commit 5301d505 (Task 1)
- FOUND: commit 3ac07cb1 (Task 2)

---
*Phase: 149-ca-candidate-seeding-race-candidates-only-turnkey*
*Completed: 2026-06-29*
