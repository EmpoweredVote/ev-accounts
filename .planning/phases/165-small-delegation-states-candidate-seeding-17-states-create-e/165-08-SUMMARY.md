---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 08
state: MT+ND+SD
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1276, 1277, 1278, 1279, 1280, 1281]
election_name: "MT/ND/SD 2026 Statewide General"
---

# 165-08 SUMMARY — MT + ND + SD decided fields

## What was built
3 elections + 4 races (MT 2, ND/SD 1 at-large each) on existing NATIONAL_LOWER offices. DECIDED — no PROVISIONAL. Two open seats (MT-1 Zinke retired; SD Johnson → Governor).

## Key facts (for 165-17 gate)
- **MT (migs 1276/1277):** MT-1 OPEN all-new — -300101 Aaron Flint (R), -300102 Sam Forstag (D), -300103 Nick Sheedy (L); Zinke (eb9fac1d) **0 active rows**. MT-2: Downing (-30002) reused + -300285 Brian Miller (D), -300286 Patrick McCracken (L) (**safe_start_seq=85** honored; seq 84 = unrelated legacy record, untouched).
- **ND (migs 1278/1279):** Fedorchak (-38000) reused + -380001 Trygve Hammer (D-NPL).
- **SD (migs 1280/1281):** OPEN — Johnson (4ec42691) **0 active rows**; **Marty Jackley = pid-reuse of the v2.18 SD Attorney General record (2537050a, no new politician)** + -460001 Nikki Gronli (D). **SD field FINAL** (Apr-28 independent deadline passed — NO Phase-167 follow-up for SD).
- **EXCLUDED → Phase 167 queue:** MT-1 Kimberly Persico + MT-2 Michael Eisenhauer (cert deadline 2026-08-20), ND Helene Neville + Charles Tuttle (petition window to 2026-08-31). **EXCLUDED PERMANENTLY:** SD Jack Pittman (absent from the authoritative SD SoS certified list).
- 4 races, all office_id NOT NULL; open-seat races have 0 incumbent flags; idempotent (re-run all 6 = 0 rows).

## Headshots — 1 upload, 6 honest-skips
Uploaded: -300102 Sam Forstag (cc0, distinctive-name direct match). Skips documented in `_mt/_nd/_sd-house-headshot-results.json`: -300101 Flint, -300103 Sheedy, -300285 Miller, -300286 McCracken, -380001 Hammer, -460001 Gronli. Jackley reuses the already-imaged v2.18 record.

## Files
- `backend/scripts/165-{mt,nd,sd}-generate.mts`
- `backend/migrations/1276..1281_seed_{mt,nd,sd}_2026_house_*.sql`
- `backend/scripts/seed-{mt,nd,sd}-house-headshots.py`
- `backend/data/seed-mt-2026-house/165-08-mt-nd-sd-reconciliation.csv`

## Self-Check: PASSED
MT 2 + ND 1 + SD 1 races, office_id NOT NULL; MT-1/SD open all-new with retired pids at 0 rows; safe_start_seq=85 honored; exclusions absent; Jackley pid-reused; 0 dup; idempotent; headshots verified or honest-skipped. Ready for stance research (165-16). **Wave 1 complete — all 34 districts seeded.**
