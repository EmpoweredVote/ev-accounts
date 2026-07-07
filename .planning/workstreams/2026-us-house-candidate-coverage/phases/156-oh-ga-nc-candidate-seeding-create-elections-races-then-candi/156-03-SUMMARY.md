# 156-03 SUMMARY — OH House candidate seeding

**Status:** COMPLETE ✅
**Migration:** `backend/migrations/1128_seed_oh_2026_house_candidates.sql`
**Reconciliation:** `backend/data/seed-oh-2026-house/156-03-oh-reconciliation.csv` (34 rows)

## Result
- 15 OH races each carry their active field: **34 active race_candidates** (15 renominated incumbents REUSED is_incumbent=true + **19 NEW** challengers/minor-line).
- 0 NULL politician_id; 0 duplicate full_name within OH.
- OH all-renominated (mirrors PA): every incumbent reused by 154 pid.

## Dedup (D-03, live-verified 2026-06-30)
All 19 new names returned 0 prior real records (batched 62-name sweep + targeted surname checks on Merrin/Enoch). Only FEC committee junk homonyms. All genuinely NEW.

## New-candidate external_id list (for 156-06 headshots + 156-07 stances)
| ext | name | party | cd |
|-----|------|-------|----|
| -390101 | Eric Conroy | R | 1 |
| -390102 | John Hancock | L | 1 |
| -390201 | Jennifer Mazzuckelli | D | 2 |
| -390301 | Cleophus Dulaney | R | 3 |
| -390401 | Joshua Kolasinski | D | 4 |
| -390402 | Tamie Wilson | I | 4 |
| -390501 | Brian Shaver | D | 5 |
| -390601 | Elizabeth Kirtley | D | 6 |
| -390701 | Brian Poindexter | D | 7 |
| -390801 | Vanessa Enoch | D | 8 |
| -390901 | Derek Merrin | R | 9 |
| -390902 | Matthew Althaus | L | 9 |
| -391001 | Kristina Knickerbocker | D | 10 |
| -391101 | Mike Kirchner | R | 11 |
| -391201 | Jerrad Christian | D | 12 |
| -391301 | Carey Coleman | R | 13 |
| -391401 | Maria Jukic | D | 14 |
| -391501 | Don Leonard | D | 15 |
| -391502 | Brennan Barrington | L | 15 |

## Minor lines seeded (D-02)
OH-1 John Hancock (L), OH-4 Tamie Wilson (I), OH-9 Matthew Althaus (L), OH-15 Brennan Barrington (L).

## Verification
`OH OK: 15 races, 34 active rc, 0 null pid, 0 dup full_name`. Idempotent (NOT EXISTS guards).
