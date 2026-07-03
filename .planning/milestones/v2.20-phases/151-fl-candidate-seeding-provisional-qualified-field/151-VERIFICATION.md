---
phase: 151-fl-candidate-seeding-provisional-qualified-field
verified: 2026-06-29T00:00:00Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification
---

# Phase 151: FL Candidate Seeding (provisional qualified field) — Verification Report

**Phase Goal:** Every FL US House race surfaces its full qualified Nov-3 field on `/elections` now — seeded provisionally so residents get upcoming-vote data before the Aug-18 primary; partisan losers pruned in Phase 153.

**Verified:** 2026-06-29
**Status:** PASSED
**Re-verification:** No — initial verification

## Methodology

Goal-backward against the live prod DB (`kxsdzaojfaibhuzmclfq`). Did NOT trust SUMMARY claims — independently ran the gate, the smoke, and hand-written cross-check queries replicating the gate's scoping (election → NATIONAL_LOWER → geo prefix `12`). All checks read-only.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every FL US House race (28) exists and links to a non-null district House office | ✓ VERIFIED | Independent query: 28 distinct races, all on NATIONAL_LOWER geo-`12` offices; gate USHC-03a/c PASS |
| 2 | Every qualified candidate surfaces as a card (field completeness) | ✓ VERIFIED | 181 active `race_candidates`, 0 null politician_id; smoke surfaces 4/4 districts incl. FL-19 (14), FL-20 (10), FL-1 (5), FL-10 (1 uncontested) |
| 3 | FL-20 vacant seat's office was created (no prior office row) | ✓ VERIFIED | 1 office geo 1220, chamber=U.S. House of Representatives, politician_id NULL, race links (office_id non-null); gate USHC-03c PASS |
| 4 | All 28 FL races recorded as PROVISIONAL (no general-winner guess) | ✓ VERIFIED | 28/28 `description LIKE 'PROVISIONAL:%'`; gate D-04 PASS; `primary_party` NULL (no party on card) |
| 5 | Zero duplicate full_name; cross-district redistricting reuse correct (3) | ✓ VERIFIED | 0 dup full_name; Frankel -12022→FL-23, Moskowitz -12023→FL-25, Wasserman Schultz -12025→FL-20 all active by exact external_id; Cherfilus-McCormick NEW in FL-20; gate USHC-02a/b/c + D-05 PASS |
| 6 | 158 new records created (band -1210101..-1212802), retired/redistricted incumbents absent in old seat | ✓ VERIFIED | 158 new-band + 3 cross-district reuse + 20 home incumbents = 181; gate D-05 PASS |
| 7 | 17 Nov-final independents get full coverage: stances (6 stanced / 11 pinned skip) with 0 unsourced | ✓ VERIFIED | 17 records resolve; 6 stanced, 36 answers; 0 answers lack a sourced context row (independent query); gate USHC-05a/b + in-scope PASS |
| 8 | 17 independents get headshot-or-pinned-skip (0 imaged / 17 skip) | ✓ VERIFIED | 0 `politician_images` for the 17; all 17 pinned in `_headshot_skip`; gate USHC-04 PASS |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/migrations/1115_seed_fl_2026_house_elections_races.sql` | 1 election + FL-20 office + 28 races | ✓ VERIFIED | Applied; effects present in prod |
| `backend/migrations/1116_seed_fl_2026_house_candidates.sql` | 158 new politicians + 181 race_candidates | ✓ VERIFIED | Applied; effects present in prod |
| `backend/scripts/151-verify.sql` | Write-free FL single-state gate, 13 assertions | ✓ VERIFIED | Runs exit 0, all PASS; all INSERTs target `ON COMMIT DROP` temp tables only |
| `backend/scripts/151-coordinate-smoke.ts` | ST_Covers surfacing smoke | ✓ VERIFIED | Runs exit 0, 4/4 districts |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| races | district House office | `office_id` (non-null) | ✓ WIRED | 0 null office_id on FL House races; FL-20 links to new office |
| race_candidates | politicians | `politician_id` (non-null) | ✓ WIRED | 0 null pid among 181 active |
| coordinate | full field | electionService ST_Covers join | ✓ WIRED | smoke surfaces full provisional field per district |
| politician_answers | sourced context | `politician_context.sources[]` | ✓ WIRED | 0 of 36 independent answers missing a sourced context row |

### Live Probe / Gate Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| FL gate | `psql -v ON_ERROR_STOP=1 -f scripts/151-verify.sql` | 13 assertions PASS, exit 0, write-free | ✓ PASS |
| Coordinate smoke | `node --import tsx scripts/151-coordinate-smoke.ts` | 4/4 districts, exit 0 | ✓ PASS |

Independent cross-check queries (not via the gate) confirmed: 28 races / 28 provisional / 181 active / 0 null pid / 0 dup name / FL-20 vacant office=1 / 3 cross-district reuse / 17 indep records / 6 stanced / 36 answers / 0 unsourced / 0 headshots.

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| USHC-02 | Records reconciled, zero dup full_name, correct reuse | ✓ SATISFIED | USHC-02a/b/c PASS + independent dup check 0 |
| USHC-03 | Election + 28 races + race_candidates for every qualified candidate; full field surfaces | ✓ SATISFIED | USHC-03a/b/c PASS + smoke 4/4 |
| USHC-04 | Headshot or pinned skip for in-scope (17 indep) | ✓ SATISFIED | 0/17 imaged, 17/17 pinned skip |
| USHC-05 | 0-unsourced stances for in-scope (17 indep), honest-skip thin | ✓ SATISFIED | 6 stanced/11 skip, 0 unsourced |

### Anti-Patterns Found

None. No TBD/FIXME/XXX/HACK/PLACEHOLDER debt markers in the gate or smoke scripts (the only "placeholder" references are documentation describing empty temp-table pins, not code debt). Gate is write-free (all INSERTs target `_`-prefixed `ON COMMIT DROP` temp tables). No assertion relaxed.

### Design-Intended Deferral (NOT a gap)

The **138 partisan (R/D) primary candidates** carry records only (no headshots, no stances) and the **27 partial-stance incumbents** are left as-is. Per CONTEXT D-01 (operator-locked Option A) and ROADMAP success-criterion 2 (explicitly updated to record the records-now/stances-at-153 split), this is the INTENDED design — these candidates are winnowed Aug-18 and their coverage lands in Phase 153. The gate correctly excludes them from USHC-04/05 (the NY false-fail trap, mirrored). This was evaluated and is correctly NOT flagged as a failure. The phase goal is field COMPLETENESS plus full coverage for the 17 Nov-final independents — both achieved.

### Human Verification Required

None. All success criteria are programmatically verifiable and were verified against live prod (DB state + coordinate-surfacing join). Visual `/elections` card rendering is downstream of the verified data layer and not part of this data-only phase's goal.

### Gaps Summary

No gaps. Every observable truth is independently confirmed against the live prod DB. The gate's 13 assertions pass write-free, the smoke surfaces 4/4 districts (≥3 required), and hand-written cross-check queries reproduce every headline count (28/181/0/0/1/3/17/6/36/0/0). The records-now/stances-at-153 split is correctly implemented and is the intended design, not a deficiency.

---

_Verified: 2026-06-29_
_Verifier: Claude (gsd-verifier)_
