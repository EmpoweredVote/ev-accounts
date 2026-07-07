# 157-06 SUMMARY — NJ consolidated gate + coordinate smoke

**Status:** COMPLETE ✅
**Requirements:** USHC2-02/03/04/05 (consolidated)

## What was built
- `backend/scripts/157-coordinate-smoke.ts` — read-only ST_Covers surfacing smoke for NJ (clone of 156-coordinate-smoke.ts) handling the three NJ wrinkles + one standard contested.

## Gate result — `157-verify.sql` GREEN (exit 0, 11 PASS)
USHC2-03a, USHC2-03b, USHC2-02a, USHC2-02c, D-04-NJ12, D-04-NJ8, D-02, USHC2-04, USHC2-05a, USHC2-05b, ALL ASSERTIONS PASSED. Write-free, NJ-scoped, D-01 honored (no incumbent in stance scope).

## Coordinate smoke GREEN — 4 NJ districts surface their full field
- **NJ-6 (3406)** contested: 2 active, 1 challenger (Pallone + Herzig).
- **NJ-8 (3408)** UNCONTESTED: exactly 1 active = Robert Menendez, is_incumbent=true, 0 challengers.
- **NJ-11 (3411)** special-seated: Mejia reused is_incumbent=true + Hathaway challenger.
- **NJ-12 (3412)** OPEN SEAT (retirement): Hamawy + Mele active, 0 is_incumbent, Watson Coleman absent.

## Final NJ tallies (Phase 157 input to Phase 158 full gate)
- 1 election ("NJ 2026 Statewide General" `cdb3f77b-…`) + 12 races (mig 1140).
- 15 new politicians + 26 active race_candidates (11 reused incumbents + 15 new); NJ-8 Menendez-only; NJ-12 Watson Coleman no active row (mig 1141).
- Headshots: 1 imaged (Hamawy) + 14 honest-skip (pinned `_img_skip`).
- Stances: 80 answers/80 contexts across 11 candidates, 0 unsourced; 4 whole-record honest-skips (pinned `_stance_skip`).
- All 12 NJ partial incumbents untouched (D-01).

## Honest-skip pins (complete, ORDER BY per 143 lesson)
- `_img_skip` (14 external_ids): all new candidates except Hamawy.
- `_stance_skip` (4 UUIDs): Kelly, Galdo, McGuire, Rueda.

## Notes
- No assertion relaxed to force green (T-157-47). No office created (NJ-12 retirement ≠ vacancy).
