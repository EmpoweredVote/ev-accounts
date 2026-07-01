# 157-03 SUMMARY — NJ records + race_candidates

**Status:** COMPLETE ✅
**Requirements:** USHC2-02, USHC2-03

## What was built
- `backend/data/seed-nj-2026-house/157-03-nj-reconciliation.csv` — 27 rows (12 incumbents + 15 new), race_ids resolved, live-DB dedup confirmed.
- Migration `backend/migrations/1141_seed_nj_2026_house_candidates.sql` — 15 new politicians + 26 race_candidates (11 reused incumbents NJ-1..11 active + 15 new). Watson Coleman (NJ-12) has NO active row. Idempotent.

## Dedup / collision (D-03)
- All 15 new names returned 0 prior records (clean inserts).
- external_id band `-341299..-340101`: only 3 UNRELATED **Utah** legislator records exist numerically in-band (Kohler -340539 / Grover -340436 / Peterson -340305); **none collide** with the 15 assigned NJ ids and none are NJ House candidates (gate `_new_cands` is scoped to active NJ race_candidates → excluded).
- All 12 incumbent pids confirmed live with correct names.

## New-candidate external_id list (for 157-04 headshots + 157-05 stances)
| ext_id | name | district | party (context only) |
|--------|------|----------|------|
| -340101 | Damon Galdo | NJ-1 | R |
| -340201 | Zack Mullock | NJ-2 | D |
| -340301 | Michael McGuire | NJ-3 | R |
| -340302 | Steven Welzer | NJ-3 | Green |
| -340303 | Ryan Michael Kelly | NJ-3 | Affordability Accountability People |
| -340401 | Rachel Peace | NJ-4 | D |
| -340501 | Sean Kirrane | NJ-5 | R |
| -340502 | Adam Rueda | NJ-5 | Humane Sustainable Future |
| -340601 | Hillary Herzig | NJ-6 | R |
| -340701 | Rebecca Bennett | NJ-7 | D |
| -340901 | Rosie Pino | NJ-9 | R |
| -341001 | Carmen Bucco | NJ-10 | R |
| -341101 | Joe Hathaway | NJ-11 | R |
| -341201 | Adam Hamawy | NJ-12 | D |
| -341202 | Gregg Mele | NJ-12 | R |

## Wrinkle confirmations
- **NJ-8** uncontested: only Menendez active (is_incumbent=true), 0 new.
- **NJ-11** Mejia (93874414-…) REUSED as special-seated incumbent; Joe Hathaway new.
- **NJ-12** Watson Coleman (a75a3e6e-…) retired → NO active row; Hamawy + Mele new. No office created (retirement, not vacancy).
- No 154-name flips; certified field matches diagnostic.

## Verification
- 12 races, 26 active rc, 0 null pid, 0 dup, Watson Coleman absent — PASS. Re-run inserted 0 (idempotent).
- Gate: USHC2-03a/03b/02a/02c + D-04-NJ12 + D-04-NJ8 + D-02 all PASS; USHC2-04 correctly fails pre-headshot (Wave 3).
