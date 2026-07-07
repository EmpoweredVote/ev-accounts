# 156-06 SUMMARY — OH/GA/NC candidate headshots

**Status:** COMPLETE ✅
**Script:** `backend/scripts/seed-oh-ga-nc-house-headshots.py` (clone of the 155/150 pipeline)

## Result: 5 imaged / 57 honest-skip of 62 new candidates
| State | imaged | honest-skip |
|-------|--------|-------------|
| OH | 0 | 19 |
| GA | 2 | 16 |
| NC | 3 | 21 |

**Imaged (all free-license, 600×750, wrong-person guard passed):**
- GA-13 **Jasmine Clark** (-131301) — GA House member portrait
- GA-10 **Houston Gaines** (-131001) — official headshot
- NC-9 **Richard Ojeda** (-370901) — MAJ Richard Ojeda (2020 pres candidate)
- NC-3 **Raymond Smith Jr.** (-370301) — Rep. Raymond E. Smith Jr. (NC House member)
- NC-1 **Laurie Buckhout** (-370101) — 2024 nominee, retired Army colonel

## Two wrong-person attaches caught + reverted (T-156-25)
1. **John Hancock** (-390102, OH-1 Libertarian) — auto-pass attached the 1770 founding-father portrait. Root cause: `'american'` in `POLITICAL_KW`. **Deleted image + storage object; dropped 'american' from keyword list; added a pre-1940 historical-year guard.**
2. **Paul Barringer** (-371301, NC-13 D) — attached the 1778–1844 War-of-1812 NC legislator ("American politician", year only in extract). **Deleted image + storage object; honest-skipped.**

## Pipeline changes vs the 155 clone
- Added OH/GA/NC bands + per-state election name; **target query re-scoped to `race_candidates` in the state's 2026 election** (the raw negative bands are POLLUTED with unrelated records — e.g. CA-gubernatorial homonyms — so a bare band query touched non-2026-House rows).
- Guard hardened: removed `'american'` keyword; reject pages whose short description names a pre-1940 year (historical homonym).

## Gate integration
57 `_img_skip` pins injected into `156-verify.sql` (ORDER BY external_id, 143 lesson). `USHC2-04` now PASSES; gate advances to `USHC2-05b` (stances — 156-07/08/09).

## Verification
Missing-headshot query returns only the 57 documented honest-skips. Idempotent (WHERE NOT EXISTS). No placeholder/wrong-person images remain.
