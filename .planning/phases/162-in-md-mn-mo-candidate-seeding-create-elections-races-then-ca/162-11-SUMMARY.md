---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 11
subsystem: elections-data
tags: [postgres, verify-gate, coordinate-smoke, postgis, redistricting, phase-gate, standing-invariant]

# Dependency graph
requires:
  - phase: 162 (plans 01-10)
    provides: all IN/MD/MN/MO seed + stance + headshot work on prod
provides:
  - backend/scripts/162-verify.sql — consolidated 33-district read-only gate (11 criteria PASS), incl. NEW MO-SEVERE + IN9-FLAG blocks
  - backend/scripts/162-coordinate-smoke.ts — 4 positive (IN/MD/MN/MO) + 1 severe-MO negative sample, all green
affects: [164.1 (must inherit MO-SEVERE + un-withhold on polygon refresh), 166 (consolidated gate inherits MO-SEVERE + IN9-FLAG standing invariants), 167 (MO/MD/IN late-filer re-pull)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["consolidated multi-state read-only DO-block gate (clone 161-verify.sql); MO-SEVERE non-surfacing assertion (clone TN-SEVERE); novel IN9-FLAG two-primary-race incumbent assertion; live-reconstructed img-skip pin list; broadened UNSOURCED scope to include incumbents"]

key-files:
  created:
    - backend/scripts/162-verify.sql
    - backend/scripts/162-coordinate-smoke.ts
  modified: []

key-decisions:
  - "IN9-FLAG assertion CORRECTED from the plan's stale ids. Plan said 'race 7d3f0042 has exactly 1 is_incumbent=true = Houchin rc.id 9d2de2ae'. Live reality (per 162-07): 7d3f0042 = IN-9 DEMOCRATIC primary (4 Dem candidates, correctly 0 incumbents post-fix); 9d2de2ae = the REPUBLICAN primary RACE id; Houchin's rc.id is a61ab808. Gate asserts the true post-1212 invariant: exactly 1 is_incumbent=true across BOTH IN-9 primary races (Houchin a61ab808), and 7d3f0042 has 0 incumbents."
  - "MO-SEVERE block clones 161's TN-SEVERE: 5 severe geos (2902/2903/2904/2905/2906) -> mo_withheld_eid; 3 non-severe (2901/2907/2908) -> mo_gen_eid. Standing invariant Phase 166 inherits; 164.1 un-withholds on polygon refresh."
  - "MD dedup criterion added (exactly 1 rc per (race_id, politician_id)) — MD reused pre-existing races so duplicate wiring was the specific risk."
  - "UNSOURCED check BROADENED beyond 161's new-candidate-only scope to ALL active in-scope politicians (challengers + incumbents), since this phase stanced zero-tier incumbents (IN Baird/Carson/Messmer, MD's 7) too. COVERAGE (>=1 stance or pinned skip) stays new-candidate-band-scoped, matching 161."
  - "Headshot pin list (110: IN 11/MD 10/MN 32/MO 57) reconstructed live at authoring time via the 'active new-band candidate lacking an image' query (161 precedent). Stance whole-record skips (24: MN 4/IN 0/MD 1/MO 19) hardcoded from the 162-04/06/09/10 SUMMARYs."
  - "Both scripts WRITE-FREE (only CREATE TEMP TABLE ON COMMIT DROP); all PostGIS calls use the public. schema prefix."

# Verification (both green against prod 2026-07-05)
verify-sql: 11 criteria PASS (SCOPE 33 / NULLOFFICE 0 / NULLPID 0 / DUPNAME 0 / PARTY / MO-SEVERE / MD-DEDUP / IN9-FLAG / HEADSHOT 110-pinned / UNSOURCED 0 / COVERAGE 24-pinned)
coordinate-smoke: 4 positive (IN-1801 2a/1c, MD-2408 3a/2c, MN-2701 5a/4c, MO-2901 8a/7c) + 1 severe-MO negative (2905 -> 0 races)
severe-mo-geo-ids-asserted-withheld: 2902, 2903, 2904, 2905, 2906

# Standing invariants for downstream phases
- **Phase 164.1** (cross-state polygon refresh): when MO severe districts get fresh polygons, the MO-SEVERE assertion must be UPDATED (un-withheld districts move from mo_withheld_eid to mo_gen_eid) — do not let it silently pass on stale withholding.
- **Phase 166** (consolidated gate): must INHERIT both the MO-SEVERE non-surfacing invariant and the IN9-FLAG single-incumbent invariant (T-162-11-01/02) — they must not silently regress.
---

# 162-11 Summary — Phase Gate (33 districts, both green)

Authored and ran the phase-closing consolidated gate. **162-verify.sql** passes all 11
criteria across the 33 IN/MD/MN/MO districts, including two novel assertion blocks:
MO-SEVERE (the 5 severity-routed MO districts correctly wired to the withheld Polygon
Pending election) and IN9-FLAG (the IN-9 incumbent-flag fix from migration 1212 holds —
Houchin is the sole IN-9 incumbent). **162-coordinate-smoke.ts** proves 4 states surface
their contested House field end-to-end and the severe MO district (2905) surfaces zero races.

The IN9-FLAG assertion was corrected from the plan's stale ids (the live re-verify in 162-07
had revealed 7d3f0042 is the Democratic primary and 9d2de2ae the Republican primary race id,
not Houchin's rc.id) — the gate encodes the true post-fix invariant.

## Phase 162 is now complete end-to-end
All four states (IN + MD + MN + MO) seeded, headshot-covered, stance-complete (0 unsourced),
and gate-verified. Ready for /gsd:verify-work.

## Carry-forwards
- 164.1 must un-withhold MO severe districts on polygon refresh (update MO-SEVERE assertion).
- 166 consolidated gate inherits MO-SEVERE + IN9-FLAG (standing invariants).
- 167 late-filer re-pull: MO Aug-4 cull (Harbison MO-8 possible removal), MD unaffiliated
  window to Aug-3, IN Sceniak iSideWith ChatGPT-flag prune review.
