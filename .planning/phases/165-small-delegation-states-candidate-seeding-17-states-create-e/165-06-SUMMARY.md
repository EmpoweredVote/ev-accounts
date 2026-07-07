---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 06
state: HI+NH
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1264, 1265, 1266, 1267]
election_name: "HI 2026 Statewide General / NH 2026 Statewide General"
---

# 165-06 SUMMARY — HI + NH late-primary PROVISIONAL fields

## What was built
'HI 2026 Statewide General' + 2 races and 'NH 2026 Statewide General' + 2 races on existing NATIONAL_LOWER offices, full qualified pre-primary fields marked **PROVISIONAL** with verified cull dates: **HI cull ≥ 2026-08-08** (elections.hawaii.gov), **NH cull ≥ 2026-09-08** (verified 2026-07-07).

## Key facts (for 165-17 gate)
- **HI new (mig 1265, In-Primary status ONLY):** -150101 Booker, -150102 Fatula, -150103 Keohokalole, -150104 Kiswanto, -150105 Berning, -150106 Conley, -150107 Lam (HI-1); -150201 Basin, -150202 Guithues, -150203 King, -150204 Awa, -150205 Codelia, -150206 Terry (HI-2). Incumbents reused on their crowded primaries: -15001 Case, -15002 Tokuda. **EXCLUDED 'Issued' non-filers:** Belatti, Burd, Cuadra, Frazier, Gisa, Curtis, Lucas-Tadeo, Martin (0 records live).
- **NH-1 OPEN (mig 1267): 14 candidates (9D+5R) at -330133..-330146 (safe_start_seq=33; -330128..-330132 = 5 NH local officials, untouched), 0 incumbent rows.** Pappas (-33001, pid 36c07696) → Senate run, NO row. NH-2: Goodlander (-33002) reused + -330201 Beauchemin, -330202 Callis, -330203 Nicholson, -330204 Orlando, -330205 Lily Tang Williams.
- **EXCLUDED NH-2 pending-independents (Phase 167 queue, window closes 2026-09-02):** Scott Matthew Black, Robbie Mahrou, Sterling Thomas Sykes (0 records live).
- 4 races, all office_id NOT NULL, all 'PROVISIONAL:'; 0 dup full_name; idempotent (re-run = 0 rows).

## Headshots — 4 verified uploads, 28 honest-skips
- **Uploaded (correct-person verified):** -150103 Keohokalole + -150204 Awa (HI state senators), -330140 Maura Sullivan + -330205 Lily Tang Williams (repeat NH candidates for these exact seats).
- **Wrong-person purged:** -150206 "Randall Terry" — Wikipedia page is the Operation Rescue founder (NY activist); no evidence the HI-2 Nonpartisan filer is him. Image row + storage deleted; results JSON marked. (3rd homonym catch this phase: Schultz, Terry; guard-rejected Carney.)
- All other skips documented in `_hi-house-headshot-results.json` / `_nh-house-headshot-results.json`.

## Files
- `backend/scripts/165-hi-generate.mts` + `165-nh-generate.mts`
- `backend/migrations/1264..1267_seed_{hi,nh}_2026_house_*.sql`
- `backend/scripts/seed-hi-house-headshots.py` + `seed-nh-house-headshots.py` (NH band upper bound -330133 protects the parallel-session local officials)
- `backend/data/seed-hi-2026-house/165-06-hi-nh-reconciliation.csv`

## Self-Check: PASSED
HI 2 + NH 2 races PROVISIONAL with verified dates; NH-1 14-candidate open field, 0 incumbent; Issued/pending exclusions absent live; seq floors honored; 0 dup; idempotent; headshots verified or honest-skipped. Ready for stance research (165-14).
