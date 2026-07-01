# 156-04 SUMMARY — GA House candidate seeding

**Status:** COMPLETE ✅
**Migration:** `backend/migrations/1129_seed_ga_2026_house_candidates.sql`
**Reconciliation:** `backend/data/seed-ga-2026-house/156-04-ga-reconciliation.csv` (28 rows)

## Result
- 14 GA races each carry their active field: **28 active race_candidates** (10 renominated incumbents REUSED + **18 NEW**).
- **Exactly 10 incumbents** (GA-2..9, 12, 14) — GA-1/10/11/13 correctly carry NO incumbent row.
- 0 NULL politician_id; 0 duplicate full_name within GA.

## D-04 wrinkles handled
- **GA-1** Carter (ran Senate) → NO active row; Kingston (R) -130101 + Hollowell (D) -130102 new.
- **GA-10** Collins (ran Senate) → NO active row; Gaines (R) -131001 + DeLancy (D) -131002 new.
- **GA-11** Loudermilk (retired) → NO active row; Cowan (R) -131101 + Harden (D) -131102 new.
- **GA-13 TRUE VACANCY** → no incumbent; Jasmine Clark (D) -131301 + Jonathan Chavez (R) -131302 new, both active non-incumbent (office created in 156-01).

## Dedup (D-03, live-verified)
Jasmine Clark (GA state rep), Houston Gaines (GA state rep), Shawn Harris (2024 GA-14 nominee), Jim Kingston, Amanda Hollowell — all returned 0 prior real records. All 18 genuinely NEW.

## New-candidate external_id list (for 156-06 + 156-08)
-130101 Jim Kingston(R), -130102 Amanda Hollowell(D), -130201 Matt Day(R), -130301 Maura Keller(D), -130401 James Duffe(R), -130501 John Salvesen(R), -130601 Kevin Martin(R), -130701 Anthony Kozycki(D), -130801 Kelly Esti(D), -130901 Caitlyn Gegen(D), -131001 Houston Gaines(R), -131002 Pamela DeLancy(D), -131101 John Cowan(R), -131102 Chris Harden(D), -131201 Ceretta Smith(D), -131301 Jasmine Clark(D), -131302 Jonathan Chavez(R), -131401 Shawn Harris(D).

## Verification
`GA OK: 14 races, 28 active rc, 10 incumbents, 0 null pid, 0 dup`. Idempotent.
