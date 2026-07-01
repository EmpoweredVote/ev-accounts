# 157-04 SUMMARY — NJ headshots

**Status:** COMPLETE ✅
**Requirement:** USHC2-04

## What was built
- `backend/scripts/seed-nj-house-headshots.py` — clone of the Phase-156 pipeline (all guards intact incl. dropped-`american`-kw + pre-1940 historical-year reject); only change = NJ band `(-341299,-340101,'New Jersey','NJ 2026 Statewide General')`. Targets new candidates via the election+band query (challengers have no offices row).
- `backend/data/seed-nj-2026-house/157-04-nj-headshots.manual.txt` — manual-source stub (no free-license sources located).

## Result: 1 imaged / 14 honest-skip
- **Imaged:** Adam Hamawy (-341201) — Wikipedia, `public_domain`.
- **14 honest-skips** (pinned in `157-verify.sql` `_img_skip`, ORDER BY external_id):
  -341202 Gregg Mele, -341101 Joe Hathaway, -341001 Carmen Bucco, -340901 Rosie Pino, -340701 Rebecca Bennett, -340601 Hillary Herzig, -340502 Adam Rueda, -340501 Sean Kirrane, -340401 Rachel Peace, -340303 Ryan Michael Kelly, -340302 Steven Welzer, -340301 Michael McGuire, -340201 Zack Mullock, -340101 Damon Galdo.
- **Reason:** Wikipedia search returned only 2026 election-article / district-special pages (not bio pages); Ballotpedia/campaign portraits are copyrighted (not free-license); non-incumbent challengers hold no federal office (no PD .gov portrait). No wrong-person/placeholder fill (guards enforced). Consistent with 155 (8/37) and 156 (5/62) precedent.

## Verification
- Missing-headshot query returns exactly the 14 documented honest-skips.
- Gate USHC2-04 PASSES with `_img_skip` pins; re-run of script inserts 0 (idempotent WHERE NOT EXISTS).
