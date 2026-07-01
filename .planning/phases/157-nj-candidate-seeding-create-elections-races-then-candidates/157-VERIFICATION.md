---
phase: 157-nj-candidate-seeding-create-elections-races-then-candidates
verified: 2026-07-01T00:00:00Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification
gaps: []
human_verification: []
---

# Phase 157: NJ Candidate Seeding Verification Report

**Phase Goal:** Seed the full Nov-3, 2026 general candidate field for all 12 NJ US House districts (geo_id 3401..3412) onto `/elections`, applying the create-races-first pipeline, with headshots + federal-24 stances for new candidates (USHC2-02/03/04/05).

**Verified:** 2026-07-01
**Status:** PASSED
**Re-verification:** No — initial verification
**Method:** Goal-backward. Every claim re-derived with independent SQL queries run directly against live prod (`DATABASE_URL`), NOT trusting the self-authored `157-verify.sql` PASS labels. The gate + smoke were also executed independently.

## Independent Claim Checklist

| # | Claim | Result | Evidence (independent query) |
|---|-------|--------|------------------------------|
| 1 | Gate green: `157-verify.sql` exits 0, 11 assertions PASS | PASS | Ran it; exit 0; all 11 NOTICE PASS lines incl. `ALL ASSERTIONS PASSED` |
| 2 | Coordinate smoke green: 4 NJ districts surface, exit 0 | PASS | Ran it; exit 0; NJ-6/8/11/12 surface (contested / uncontested / special-seat / open-seat) |
| 3a | 1 election "NJ 2026 Statewide General" (2026-11-03, general, state, NJ) | PASS | `count=1` on full-attribute match |
| 3b | 12 NJ races, office_id never NULL | PASS | `n_races=12, null_office=0`; geo_ids = 3401..3412 (all 12) |
| 3c | 26 active race_candidates, 0 NULL politician_id | PASS | `active=26, null_pid=0` |
| 3d | 0 duplicate full_name (D-03) | PASS | dup query returned NONE |
| 3e | NJ-8 (geo 3408) exactly 1 active = Menendez, incumbent | PASS | geo 3408: `active=1, incumbents=1, cands="Robert Menendez"` |
| 3f | NJ-12 Watson Coleman (a75a3e6e-…) absent from active field | PASS | 0 active rows for that pid; geo 3412 `incumbents=0`, cands = Hamawy + Mele |
| 3g | 0 unsourced stance rows for 15 new candidates (band -341299..-340101, scoped to active NJ rc) | PASS | 80 context rows, `empty_src=0, nonhttp_src=0`; per-candidate answers==contexts==sourced |
| 4 | NO new essentials.offices row for NJ (retirement, not vacancy) | PASS | exactly 12 NJ NATIONAL_LOWER House offices, 1 per geo_id, 0 duplicates |

## Goal Achievement — Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Election + 12 races authored on existing offices (create-races-first) | ✓ VERIFIED | 1 election, 12 races, office_id 0-null, geo 3401..3412 |
| 2 | Every district carries its full active field; 26 active race_candidates | ✓ VERIFIED | per-district counts (NJ-3=4, NJ-5=3, NJ-8=1, others 2), 0 null pid |
| 3 | 11 renominated/reused incumbents reuse their 154 pid (incl. NJ-11 Mejia special-seat) | ✓ VERIFIED | 11/11 expected incumbent UUIDs matched as active is_incumbent=true; Mejia 93874414-… reused |
| 4 | NJ-8 uncontested = Menendez only (single-candidate general) | ✓ VERIFIED | geo 3408 exactly 1 active, incumbent |
| 5 | NJ-12 retirement: Watson Coleman absent, Hamawy+Mele new; NO office created | ✓ VERIFIED | 0 active WColeman rows; 12 offices intact (no dup); open-seat pair active |
| 6 | Minor lines seeded (D-02): NJ-3 Welzer+Kelly, NJ-5 Rueda | ✓ VERIFIED | all 3 present as active race_candidates |
| 7 | 15 new candidates seeded, dedup enforced (0 dup full_name, band split 15 new / 11 reused) | ✓ VERIFIED | band split query = 15/11/26; dup=NONE |
| 8 | Headshots: every new candidate imaged OR pinned honest-skip | ✓ VERIFIED | 1 imaged (Hamawy -341201) + 14 pinned in _img_skip |
| 9 | Stances: 0 unsourced; each new candidate ≥1 sourced stance OR pinned whole-record skip | ✓ VERIFIED | 11 candidates stanced (real URLs), 4 zero-stance pinned in _stance_skip |
| 10 | The 4 stance honest-skip UUIDs == the 4 actual zero-stance candidates (no silent miss) | ✓ VERIFIED | pinned UUIDs map exactly to Galdo/-340101, McGuire/-340301, Kelly/-340303, Rueda/-340502 |
| 11 | Band-pollution guard: unrelated band records excluded via active-rc scoping | ✓ VERIFIED | 3 Utah legislators (Kohler/Grover/Peterson) in band but not NJ candidates → correctly excluded |
| 12 | Gate is write-free (read-only proof) | ✓ VERIFIED | no INSERT/UPDATE/DELETE to persistent tables; only TEMP … ON COMMIT DROP |

**Score:** 12/12 truths verified

## Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `backend/migrations/1140_seed_nj_2026_house_elections_races.sql` | ✓ VERIFIED | 1 election + 12 races, idempotent NOT EXISTS guards; applied (prod shows rows) |
| `backend/migrations/1141_seed_nj_2026_house_candidates.sql` | ✓ VERIFIED | 15 new politicians + 26 race_candidates; applied (prod shows rows); WColeman intentionally omitted |
| `backend/scripts/157-verify.sql` | ✓ VERIFIED | 11-assertion read-only gate, exit 0; 4 stance-skip + 14 img-skip pins correct |
| `backend/scripts/157-coordinate-smoke.ts` | ✓ VERIFIED | exit 0; 4 districts surface |
| `backend/scripts/seed-nj-house-headshots.py` | ✓ VERIFIED | present; 1 image landed (Hamawy), 14 documented skips |
| `backend/data/stance-research/nj-2026-house/` | ✓ VERIFIED | 15 CSVs; 11 with stance data, 4 thin (honest-skip candidates: galdo/kelly/mcguire/rueda are 119-byte stubs) |
| SUMMARY 157-01..06 | ✓ VERIFIED | all 6 present |

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| USHC2-03 (elections/races scaffold + surfacing) | ✓ SATISFIED | 1 election, 12 races, smoke surfaces field |
| USHC2-02 (records + race_candidates, dedup, no party on card) | ✓ SATISFIED | 26 active, 0 null pid, 0 dup, races.primary_party NULL |
| USHC2-04 (headshots) | ✓ SATISFIED | 1 imaged + 14 pinned honest-skips |
| USHC2-05 (chairs-not-polarity stances, 0 unsourced) | ✓ SATISFIED | 80 sourced context rows, 0 unsourced, 4 pinned whole-record skips |

## Data-Flow Trace (Level 4)

race_candidates → resolves photo via `COALESCE(rc.photo_url, pi.url)` on politician_id; smoke confirms
districts surface with correct active/incumbent/null-pid counts, i.e. real data flows to `/elections`.
Stance answers each paired to a `inform.politician_context` row carrying a real `http(s)` source URL
(sampled Mullock → mullockforcongress.com/issues; aggregate 80/80 rows http, 0 empty). FLOWING.

## Anti-Patterns Found

None. The 4 thin stance CSVs (galdo/kelly/mcguire/rueda, 119 bytes each) are legitimate documented
whole-record honest-skips (party-inference refused, chairs-not-polarity), pinned by exact UUID in the
gate — not silent stubs. The 3 band records excluded by active-rc scoping are documented unrelated
Utah legislators, not seeding errors.

## Human Verification Required

None. This is a pure-data phase; all success criteria are DB-observable and were independently
queried. `/elections` surfacing is proven by the coordinate smoke (4 in-district coordinates return
their full field). No backend code changed.

## Gaps Summary

No gaps. All 12 observable truths, all 4 requirements, and all 4 primary claim groups verified by
independent prod queries that reproduce (rather than trust) the gate's assertions. Gate + smoke both
exit 0 when run by the verifier. NJ's three wrinkles (NJ-8 uncontested, NJ-11 Mejia reused special-seat
incumbent, NJ-12 Watson Coleman retirement with no office creation) are all correctly implemented and
independently confirmed.

Carry-forward (not a Phase 157 gap): PA independents post-Aug-10 re-check (Phase 155), and the
Phase 158 89-district consolidation gate / Phase 159 MI+VA date-gated seeding remain, per roadmap.

---

_Verified: 2026-07-01_
_Verifier: Claude (gsd-verifier)_
