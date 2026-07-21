---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 01
state: NV+ME
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1250, 1251]
election_name: "NV 2026 Statewide General / 2026 Maine General Election"
---

# 165-01 SUMMARY — NV + ME candidates-only reconciliation (Track 1)

## What was built
NV's and ME's full 2026 US House fields completed on prod via **candidates-only reconciliation** onto the 6 pre-existing races — **zero new elections/races authored**. NV: 5 new candidates + the Lynn Chapman NULL-pid FIX. ME: 2 new candidates (Russell, Dunlap) + Pingree/LePage status normalization. Both migrations idempotent (2nd run = all `INSERT 0 0` / `UPDATE 0`, verified live).

## Key facts (for 165-17 gate)
- **Reused race UUIDs (no INSERT):** NV-1 a5295941, NV-2 0c470cc0, NV-3 79e7fb35, NV-4 81eb1a27, ME-1 d92aa73a, ME-2 aa63d55d. 0 NULL politician_id across all 6 races post-migration.
- **NV new external_ids (mig 1250):** -320174 Bobby Khan (NV-1), -320175 Steven St John (NV-1), -320251 Lynn Chapman (NV-2, fix — see below), -320301 Jon Kamerath (NV-3), -320479 Russell Best (NV-4), -320480 William Johnson (NV-4). D-04 floors live-confirmed (NV-1 top was -320173, NV-2 -320250, NV-3 empty, NV-4 -320478). 0 dup full_name.
- **Chapman fix-not-recreate:** race_candidates row `08dfb911-9ddc-4c0d-85a2-fb14884a9160` had politician_id NULL; **no live Chapman politician existed** (ILIKE scan 2026-07-07) → created ONE at -320251 (NV-2 seq 51) and UPDATEd the existing row. No second Chapman rc row.
- **ME new external_ids (mig 1251):** -230103 Ronald Russell (R, ME-1), -230203 Matthew Dunlap (D, ME-2). **Neither reused a dormant pid** — live scans found only FEC-committee junk and different-first-name Russells → both create-new. ME-1 and ME-2 each end with exactly 2 active candidates.
- **NV-2 and ME-2 are open seats** (Amodei retired; Golden retired) — no incumbent flag on those races is correct per the 160 field table.

## Deviation (documented)
Pingree (rc a93b5364) and LePage (rc c58647c9) pre-existing rows carried `candidate_status='filed'` (legacy early-wave value; 'active' is the surfacing convention, 2006 vs 29 rows live). The must-have "each ME race ends with exactly 2 **active** candidates" required normalizing both rows `'filed'→'active'` via guarded idempotent UPDATE in mig 1251. `is_incumbent` untouched (Pingree true, LePage false).

## Headshots
- **ME: 1 uploaded** — Matthew Dunlap (cc_by-sa_3.0). Honest-skip: -230103 Ronald Russell (no candidate-person page).
- **NV: 0 uploaded, 6 honest-skips** (all minor-party/no-party candidates without free-license Wikipedia bios; guard rejected election-list pages): -320174 Khan, -320175 St John, -320251 Chapman, -320301 Kamerath, -320479 Best, -320480 Johnson. Documented in `_nv-house-headshot-results.json` / `_me-house-headshot-results.json`.

## Files
- `backend/scripts/165-nv-me-generate.mts`
- `backend/migrations/1250_seed_nv_2026_house_candidates.sql` + `1251_seed_me_2026_house_candidates.sql`
- `backend/scripts/seed-nv-house-headshots.py` + `seed-me-house-headshots.py` (+ gitignored results JSONs)
- `backend/data/seed-nv-2026-house/165-01-nv-me-reconciliation.csv`

## Self-Check: PASSED
6 races reused (count query = 6); 0 NULL pid; ME-1/ME-2 = 2 active each; 6 new-band NV records + 2 ME records at D-04 ids; 0 dup full_name per state; idempotent re-run verified; every new candidate imaged or honest-skipped. Ready for stance research (165-09).
