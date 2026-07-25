---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 02
state: CT
status: complete
completed: 2026-07-06
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1233, 1234]
---

# 164-02 SUMMARY — CT 2026 US House Seed

## What was built
Full 2026 CT US House convention/petition field seeded on **prod**: 1 election, 5 races, **17 new** candidate records + 22 active `race_candidates` (17 new + 5 renominated/running incumbents). PROVISIONAL pre-primary field (CT Aug-11 primary, cull ≥ 2026-08-12). CT is NOT redistricted — vanilla single-election, no withholding.

## Key facts (for 164-13 gate)
- **Election:** `CT 2026 Statewide General` (general, 2026-11-03, state, CT). 5 races, all `office_id` NOT NULL → NATIONAL_LOWER offices geo 0901-0905. Description = `PROVISIONAL: pre-primary convention/petition qualified field, cull >= 2026-08-12`.
- **New-candidate external_id range: -90504 .. -90101** (17 records, standard seq start 1). No dup external_id/full_name. Per-district new: CT-1=4, CT-2=1, CT-3=3, CT-4=5, CT-5=4.
- **Incumbents reused (is_incumbent=true):** -9001 John B. Larson (CT-1), -9002 Joe Courtney (CT-2), -9003 Rosa L. DeLauro (CT-3), -9004 James A. Himes (CT-4), -9005 Jahana Hayes (CT-5). **Larson (D-01):** lost the Dem convention endorsement to Bronin 214-204 but is a genuine 4-way primary candidate → is_incumbent reuse row present. **CT-1 has 5 active candidates** (Larson + Bronin/Gilchrest/Fortune/Chai) ✓.
- Idempotent: both migrations re-run = all `INSERT 0 0`.

## D-02 include/hold re-verification (directly-fetched: FEC candidate API + Ballotpedia)
All four flagged unconfirmed names **re-verified against directly-fetched primary sources**:
- **Bueno CT-4** → INCLUDE: FEC `H6CT04176` REP, Statement of Candidacy filed **2026-04-08** (concrete signal; provisional-with-note).
- **Cerreta CT-4** → INCLUDE: FEC `H0CT04237` IND, filed (concrete signal; provisional-with-note).
- **Miressi CT-4** → INCLUDE: FEC `H6CT04150` REP **status=C statutory** + convention-qualified.
- **Botelho CT-5 → HOLD→INCLUDE (DEVIATION from field-table starting point):** FEC `H2CT05230` REP **status=C statutory** for the 2026 cycle AND Ballotpedia lists her in the Aug-11 3-way GOP primary (Shea/De Barros/Botelho). The stale May-16 CT Mirror "two-way primary" report is superseded. Per D-02 concrete-signal-in + the plan's explicit "unless re-verification changes it," she is seeded. **This makes the count 17 new, not the 16 the plan's starting point projected.** No names are currently HELD.

## Headshots — 2 uploaded, 15 honest-skip (incl. 1 wrong-person purge)
- **Uploaded (correct):** Luke Bronin `-90101` (cc_by_2.0, former Hartford mayor, distinctive), Jillian Gilchrest `-90102` (cc_by_4.0, CT state rep, distinctive).
- **WRONG-PERSON PURGED:** Andrew Rice `-90303` — the guard accepted the plain "Andrew Rice" Wikipedia page, which is the **Oklahoma ex-state-senator (b. 1973)**, NOT the CT-3 independent petitioner. Homonym trap (Bouchard/Hancock/Douglas-Alexander precedent). Deleted from prod: `politician_images` row + storage object `9bb089f1-…-headshot.jpg`. Converted to honest-skip. **Guard-hardening candidate for a future phase** (per-district clone rule forbids editing the guard here).
- **Honest-skip (14 + Rice = 15 total, all documented in `_ct-house-headshot-results.json`):** -90103 Ruth Fortune, -90104 Amy Chai, -90201 George Austin, -90301 Christopher Lancia, -90302 Rafael Irizarry, **-90303 Andrew Rice (wrong-person)**, -90401 Michael Goldstein, -90402 Daniel Miressi, -90403 Luz Helena Bueno (no-wikipedia-page), -90404 Joseph Perez-Caputo, -90405 Damon Lawrence Cerreta, -90501 Chris Shea, -90502 Jonathan De Barros, -90503 Michele Botelho, -90504 Jackson Taddeo-Waite.

## Files
- `backend/scripts/164-ct-generate.mts`
- `backend/migrations/1233_seed_ct_2026_house_elections_races.sql`
- `backend/migrations/1234_seed_ct_2026_house_candidates.sql`
- `backend/scripts/seed-ct-house-headshots.py` + `backend/scripts/_ct-house-headshot-results.json` (gitignored)
- `backend/data/seed-ct-2026-house/164-02-ct-reconciliation.csv`

## Self-Check: PASSED
5 races / 0 null office_id; 22 active race_candidates (5 incumbent, Larson present); 17 new in-band; CT-1=5; 0 dup name; idempotent; D-02 include/hold trail documented; wrong-person headshot purged; every new candidate has an image or documented honest-skip. Ready for stance research (164-08).
