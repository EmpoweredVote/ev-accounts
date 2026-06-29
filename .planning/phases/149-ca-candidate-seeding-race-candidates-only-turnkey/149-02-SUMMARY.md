---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 02
subsystem: validation
tags: [verify-gate, read-only-sql, ca-house, race-candidates, honest-skip-pinning, nyquist-wave-0]

# Dependency graph
requires:
  - phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
    plan: 01
    provides: 104 active CA race_candidates on the 52 House races (728d0074), Ruiz CA-25 dedup, 38 new -601xxxx politicians
  - phase: 148-field-resolution-stance-gap-diagnostic
    provides: locked CA field (148-field-table.csv), 9 same-party generals (148-FIELD-TABLE.md), incumbent pid map
provides:
  - backend/scripts/149-verify.sql — read-only, write-free, House-scoped (NATIONAL_LOWER + 728d0074) labeled-assertion gate covering USHC-02/03/04/05 + D-04
  - in-scope stance/headshot TEMP-table convention (38 new + 36 zero-incumbents) reusable by 149-04..10 mid-wave
  - honest-skip pinning slot (_stance_skip TEMP table, ORDER BY politician_id) for Wave-3 whole-record skips
affects: [149-04-headshots, 149-05-to-10-stances, 149-11-final-gate, 150-tx-ny-seeding, 151-fl-seeding, 152-coordinate-verification-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read-only labeled-assertion gate (148-verify.sql / verify-phase-141-144.sql precedent): DO-block IF NOT (...) THEN RAISE EXCEPTION 'FAIL <label>' + RAISE NOTICE 'PASS <label>'"
    - "House-scope every query via races->offices->districts filtered NATIONAL_LOWER + substr(geo_id,1,2)='06' within election 728d0074 — the 52-vs-53 (Governor) trap"
    - "Honest-skip set pinned by exact UUID in a TEMP table with explicit ORDER BY politician_id (the Phase 143 ordering lesson)"
    - "CREATE TEMP TABLE ... ON COMMIT DROP is the only allowed write (write-free gate)"

key-files:
  created:
    - backend/scripts/149-verify.sql
  modified: []

key-decisions:
  - "USHC-02c reuse pin = 46 renominated + redistricted-home incumbents (Bera/Kiley/Calvert/Young Kim). Linda Sánchez (CA-38 incumbent bb73793e, redistricted to CA-41) was EXCLUDED from the reuse set: 149-01 seeded her CA-41 candidacy as a NEW record (-6014101), not a pid reuse — confirmed live (bb73793e carries no 2026 candidacy; Hilda Solis is the new CA-38 nominee)."
  - "In-scope stance/headshot set defined as TEMP tables (38 new in -6015999..-6010000 band + 36 zero-stance incumbents pinned by 148 pid) so 149-04..10 can run the gate mid-wave."
  - "USHC-05a unsourced = inform.politician_answers with no matching inform.politician_context having a non-empty sources ARRAY (array_length(c.sources,1) >= 1)."

patterns-established:
  - "Per-requirement labeled PASS/FAIL with RAISE NOTICE on pass — the gate self-documents which slice each wave satisfied."

requirements-completed: []

# Metrics
duration: 12min
completed: 2026-06-29
---

# Phase 149 Plan 02: CA Verify Gate (149-verify.sql) Summary

**Authored `backend/scripts/149-verify.sql` — a write-free, House-scoped (NATIONAL_LOWER + election 728d0074) labeled-assertion gate covering USHC-02/03/04/05 + D-04; the USHC-02/03/D-04 assertions PASS now against live prod, and the USHC-04/05 assertions are authored and legitimately FAIL pre-Wave-2/3.**

## Performance
- **Duration:** ~12 min
- **Completed:** 2026-06-29
- **Tasks:** 1
- **Files created:** 1

## Accomplishments
- Built a single read-only gate with 9 labeled assertions, every data query House-scoped via `races -> offices -> districts` filtered `district_type='NATIONAL_LOWER' AND substr(geo_id,1,2)='06'` within election `728d0074-...`. A scope sanity check (`COUNT(DISTINCT race_id)=52`) fails fast if the 53rd Governor race ever leaks in (Pitfall 1).
- Encoded the in-scope stance/headshot set as TEMP tables: the 38 genuinely-new CA candidates (politician_id in the `-6015999..-6010000` band) UNION the 36 zero-stance CA incumbents (pinned by 148 pid). Reusable mid-wave by 149-04..10.
- Pinned the whole-record stance honest-skip slot (`_stance_skip` TEMP table, `ORDER BY politician_id`) per the Phase 143 lesson; currently empty, populated by the Wave-3 stance plan if any candidate is a documented whole-record skip.
- Verified write-free + scoped via the automated check (`PASS-scoped-and-write-free`) and ran read-only against prod (`psql ... -f`, exit clean syntactically).

## Assertion Coverage
| Label | Requirement | Scope | Status NOW (pre-Wave-2/3) |
|-------|-------------|-------|---------------------------|
| USHC-03a | race wiring | 52 House races each >= 2 active | **PASS** |
| USHC-03b | race wiring | 0 active rc with NULL politician_id | **PASS** |
| USHC-02a | records | 0 duplicate full_name among active CA House cands | **PASS** |
| USHC-02b | records | Ruiz CA-25 canonical 5238b298 active; dup 05349fa0 retired | **PASS** |
| USHC-02c | records | 46 renominated/redistricted-home incumbents reuse 148 pid (no dup-incumbent) | **PASS** |
| D-04 | same-party generals | both advancers active in CA-4/7/11/12/14/29/34/37/40 | **PASS** |
| USHC-04 | headshots | every new candidate has a politician_images row | **FAIL (expected — Wave 2)** |
| USHC-05a | stances | 0 unsourced rows for the in-scope set | not reached pre-Wave-3 (after USHC-04) |
| USHC-05b | stances | federal-24 coverage OR pinned honest-skip per in-scope candidate | not reached pre-Wave-3 |

**The gate currently halts at USHC-04** because Wave 2 (headshots) has not run — all 38 new candidates correctly lack a `politician_images` row. Once headshots (149-04) and stances (149-05..10) land, the gate runs fully green; 149-11 runs it as the final consolidated proof.

## How 149-04..10 should invoke it mid-wave
```
cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/149-verify.sql
```
Each wave runs the full gate to verify its slice; the labeled `PASS/FAIL <label>` NOTICEs show exactly which requirement that wave satisfied. `\set ON_ERROR_STOP on` means the gate halts at the first unmet assertion, so a wave knows precisely what remains.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed an invalid placeholder guard line in the USHC-02b Ruiz check**
- **Found during:** Task 1 (first parse/run)
- **Issue:** An initial `SELECT ... WHERE id = '05349fa0-...'::text::uuid IS NOT NULL AND FALSE` placeholder line was malformed and redundant.
- **Fix:** Deleted it; kept the single correct `id::text LIKE '05349fa0%' AND is_active=true` dup-retirement check.
- **Files modified:** backend/scripts/149-verify.sql
- **Verification:** Gate parses + runs read-only; USHC-02b PASSes.

**2. [Rule 1 - Bug] Corrected the USHC-02c reuse pin — Linda Sánchez (CA-41) is a NEW record, not a pid reuse**
- **Found during:** Task 1 self-test (USHC-02c FAILed with "1 reused-incumbent pid absent")
- **Issue:** I initially pinned CA-38 incumbent Linda Sánchez (pid `bb73793e`) as a redistricted-home reuse at CA-41 (mirroring Bera/Kiley/Calvert). Live data showed 149-01 actually seeded her CA-41 candidacy as a NEW record (`2ebe5440`, external_id `-6014101`) — `bb73793e` carries no 2026 candidacy, and Hilda Solis is the new CA-38 nominee.
- **Fix:** Removed `bb73793e` from the `_reuse_pid` set and documented (inline comment) that she is a new record, not a reuse. USHC-02c now correctly asserts the 46 genuine reuses.
- **Files modified:** backend/scripts/149-verify.sql
- **Verification:** USHC-02c PASSes (46 reuses); this is a gate-accuracy fix, not a data change.

---
**Total deviations:** 2 auto-fixed (both Rule 1, gate-accuracy). No scope change.

## Issues Encountered
- None blocking. A diagnostic query hit a PL/pgSQL `record`-vs-table-alias name collision (`r`) during investigation only — no impact on the gate file.

## Known Stubs
None. The USHC-04/05 assertions are authored and legitimately FAIL until Waves 2/3 populate headshots and stances — this is the planned wave structure (documented in the gate header and the Assertion Coverage table above), not a stub.

## Threat Flags
None — the gate is SELECT-only/write-free against production (only `CREATE TEMP TABLE ... ON COMMIT DROP`). No new security surface.

## Self-Check: PASSED
- FOUND: backend/scripts/149-verify.sql
- VERIFIED: automated check `PASS-scoped-and-write-free` (NATIONAL_LOWER + 728d0074 present; no INSERT/UPDATE/DELETE INTO essentials|inform)
- VERIFIED: runs read-only against prod (exit clean syntactically; USHC-02/03/D-04 PASS, USHC-04 FAIL expected pre-Wave-2)

---
*Phase: 149-ca-candidate-seeding-race-candidates-only-turnkey*
*Completed: 2026-06-29*
