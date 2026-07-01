# 155-05 SUMMARY — PA headshots

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirement:** USHC2-04 (PA slice)

## What was done
Cloned the Phase-150 pipeline to **`backend/scripts/seed-pa-il-house-headshots.py`** (parameterized `--state PA|IL`, bands PA −429999..−420000 / IL −179999..−170000; ALL guards intact — free-license only, hardened wrong-person guard, 4:5 → 600×750, x-upsert, idempotent). Ran the PA auto Wikipedia pass. Shared script is ready for 155-06 (IL).

## Result — 2 imaged / 15 honest-skip (of 17 new PA candidates)
- **Imaged:** Paige Cognetti (−420801, cc_by_2.0), Chris Rabb (−420301, cc0) — the two with own Wikipedia bio pages.
- **15 honest-skips** (pinned in `155-verify.sql` `_img_skip`, ORDER BY external_id): Harvie, Arriaga, Stuski, Manganaro, Young, Brooks, Wallace, Stelson, Mannion, Hayes, Farnham, Bradstock, Bilger, Wagner, Guy. Reason: obscure first-time challengers with no own Wikipedia bio page / no free lead image; campaign & Ballotpedia images all-rights-reserved.

## Guard behavior (wrong-person refused, not filled)
The hardened guard correctly rejected: Nancy Mannion → "Nancy Pelosi"; James Hayes → Rutherford B. Hayes ("president… 1877 to 1881"); Justin Wagner → "The Colourist" (band). No wrong-person or copyrighted image was attached (T-155-19/20).

## Artifacts
- `backend/scripts/seed-pa-il-house-headshots.py` (shared PA/IL pipeline)
- `backend/data/seed-pa-2026-house/155-05-pa-headshots.manual.txt` (no free 2nd-source found; all 15 honest-skips)
- Results: `backend/scripts/_pa-il-house-headshot-results.json`

Consistent with the Phase-150 precedent (43/48 TX + 27/33 NY honest-skipped). Gate USHC2-04 PASSES with the pins.
