---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 05
state: WV+ID
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04]
migrations_applied: [1260, 1261, 1262, 1263]
election_name: "WV 2026 Statewide General / ID 2026 Statewide General"
---

# 165-05 SUMMARY — WV + ID decided fields (vanilla create-election-first)

## What was built
'WV 2026 Statewide General' + 2 races and 'ID 2026 Statewide General' + 2 races on existing NATIONAL_LOWER offices. DECIDED — no PROVISIONAL. All 4 incumbents renominated and reused. ID field is multi-party (Constitution/Libertarian/Independent).

## Key facts (for 165-17 gate)
- **WV new (mig 1261, seq from 1, band was empty):** -540101 Vince George (D), -540102 Isaiah Rucker (I) on WV-1; -540201 Ace Parsi (D), -540202 Pat Carney (I), -540203 Chris Whitcomb (I) on WV-2. Incumbents reused: -54001 Carol D. Miller, -54002 Riley M. Moore. WV independent window open to **2026-08-03 → Phase 167** (noted in race description).
- **ID new (mig 1263, seq from 1, band was empty):** -160101 Kaylee Peterson (D), -160102 Brendan Gomez (Constitution), -160103 Sarah Zabel (I) on ID-1; -160201 Elinor Gilbreath (D), -160202 Will Johanson (L), -160203 Carta Sierra (Constitution), -160204 Emre Houser (I), -160205 Tripp Hutchinson (I) on ID-2. Incumbents reused: -16001 Fulcher, -16002 Simpson.
- 4 races, all office_id NOT NULL; 0 dup full_name per state; idempotent (re-run all 4 = 0 rows).

## Headshots — 0 uploaded, ALL 13 honest-skip (documented in `_wv-house-headshot-results.json` / `_id-house-headshot-results.json`)
Guard highlight: Pat Carney (-540202) correctly rejected as a **historical homonym** (Canadian politician 1935–2023). Pin list = all 13 new external_ids above.

## Files
- `backend/scripts/165-wv-generate.mts` + `165-id-generate.mts`
- `backend/migrations/1260..1263_seed_{wv,id}_2026_house_*.sql`
- `backend/scripts/seed-wv-house-headshots.py` + `seed-id-house-headshots.py`
- `backend/data/seed-wv-2026-house/165-05-wv-id-reconciliation.csv`

## Self-Check: PASSED
WV 2 + ID 2 races, office_id NOT NULL; 4 incumbents reused (is_incumbent=true); multi-party ID challengers present; 0 dup; idempotent; all new candidates honest-skipped with documentation. Ready for stance research (165-13).
