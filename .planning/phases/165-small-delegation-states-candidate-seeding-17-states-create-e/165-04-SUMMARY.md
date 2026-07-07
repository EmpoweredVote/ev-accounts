---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 04
state: NM+NE
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1256, 1257, 1258, 1259]
election_name: "NM 2026 Statewide General / NE 2026 Statewide General"
---

# 165-04 SUMMARY — NM + NE decided fields (vanilla create-election-first)

## What was built
'NM 2026 Statewide General' + 3 races and 'NE 2026 Statewide General' + 3 races on existing NATIONAL_LOWER offices. DECIDED — no PROVISIONAL wording. NM: 3 incumbents reused + 3 new R challengers. NE: Flood/Smith reused; **NE-2 open** (Bacon retired → 0 rows) with all-new 3-candidate field.

## Key facts (for 165-17 gate)
- **NM new external_ids (mig 1257, D-04 seqs 26/51/82 live-confirmed):** -350126 Didi Okpareke (NM-1), -350251 Greg Cunningham (NM-2), -350382 Martin Zamora (NM-3). Incumbents reused: -35001 Stansbury, -35002 Vasquez, -35003 Leger Fernandez (all is_incumbent=true).
- **NE new external_ids (mig 1259):** -310101 Backemeyer, -310102 Sandman (NE-1); -310201 Brinker Harding, -310202 Denise Powell, -310203 Eric Foreman (NE-2 open field); -310360 Becky Stille, -310361 David Else (NE-3, safe_start_seq=60). Incumbents reused: -31001 Flood, -31003 Smith.
- **Bacon (0cc444a0) asserted: 0 active rows on the NE election; NE-2 has 3 active, 0 incumbent-flagged.**
- **EXCLUDED pending-independents (Phase 167 queue, NE petition window closes 2026-08-01):** NE-1 Austin Ahlman, NE-3 Macey Budke, NE-3 Mark Cohen — confirmed 0 politician records live.
- 6 races total, all office_id NOT NULL; 0 dup full_name per state; idempotent (re-run all 4 = 0 rows).

## Headshots — 0 uploaded, ALL 10 honest-skip (documented in `_nm-house-headshot-results.json` / `_ne-house-headshot-results.json`)
Pin list: NM -350126 Okpareke, -350251 Cunningham, -350382 Zamora (no-lead-image); NE -310101 Backemeyer, -310102 Sandman, -310201 Harding, -310202 Powell, -310203 Foreman, -310360 Stille, -310361 Else.

## Files
- `backend/scripts/165-nm-generate.mts` + `165-ne-generate.mts`
- `backend/migrations/1256..1259_seed_{nm,ne}_2026_house_*.sql`
- `backend/scripts/seed-nm-house-headshots.py` + `seed-ne-house-headshots.py`
- `backend/data/seed-nm-2026-house/165-04-nm-ne-reconciliation.csv`

## Self-Check: PASSED
NM 3 + NE 3 races, office_id NOT NULL; incumbents reused; NE-2 open all-new; safe_start_seq honored (26/51/82/60); Ahlman/Budke/Cohen absent; 0 dup; idempotent; all new candidates honest-skipped with documentation. Ready for stance research (165-12).
