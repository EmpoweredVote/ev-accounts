# 155-06 SUMMARY — IL headshots

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirement:** USHC2-04 (IL slice)

## What was done
Ran the shared `backend/scripts/seed-pa-il-house-headshots.py --state IL` (created in 155-05) over the 28 new IL candidates (band −179999..−170000). All guards intact.

## Result — 6 imaged / 22 honest-skip (of 28 new IL candidates)
- **Imaged:** Daniel Biss (−170901), Melissa Bean (−170801), La Shawn Ford (−170701), Tommy Hanson (−170501), Byron Sigcho-Lopez (−170407), Donna Miller (−170201) — the notable sitting/former officials with own Wikipedia bio pages.
- **22 honest-skips** (pinned in `155-verify.sql` `_img_skip`): Maxwell, Noack, Banks, Oakley, Garcia, Castillo, Hershey, Church, Getty, Macías, Conforti, Koppie, Davis, Elleson, Lambrecht, Walter, Fortier, Wilson, Marter, Todd, Nolley, Vancil. Reason: obscure first-time challengers, no own Wikipedia bio page / no free lead image; campaign & Ballotpedia all-rights-reserved.

## Guard behavior
Wrong-person correctly rejected: Ashley Banks → "The Fresh Prince of Bel-Air"; Jennifer Davis → 2026 Senate election page; James Marter → 2024 election page. No wrong-person/copyrighted fill.

## Combined Wave-3a headshot tally (PA+IL)
**8 imaged / 37 honest-skip of 45** new candidates. Gate USHC2-04 PASSES (all 45 imaged-or-pinned). USHC2-05a passes (0 unsourced pre-stance); USHC2-05b remains (stances = 155-07/08).

Artifact: `backend/data/seed-il-2026-house/155-06-il-headshots.manual.txt`.
