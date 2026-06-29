# 150-05 SUMMARY — TX headshots + shared pipeline

**Status:** ✅ Complete (5 imaged; 43 documented honest-skips, gate-pinned)
**Wave:** 3
**Artifacts:** `backend/scripts/seed-tx-ny-house-headshots.py` (shared, reused by 150-06), `backend/data/seed-tx-2026-house/150-05-tx-headshots.manual.txt`

## What was built

Cloned the validated Phase-149 headshot pipeline to `seed-tx-ny-house-headshots.py`, parameterized by `--state TX|NY` (TX band -4819999..-4810000; NY band -3619999..-3610000). **All guards intact** (free-license-only, hardened wrong-person guard requiring candidate first+surname in the resolved page title + rejecting election/place/event + non-political disambiguators, 4:5 crop → 600×750 LANCZOS q90, x-upsert, idempotent INSERT). Ready for 150-06 (NY).

## TX result (48 new candidates)

- **5 auto-imaged** from Wikipedia (free-license, identity-verified — all notable figures with genuine 2026 candidacies):
  - Colin Allred TX-33 (-4813301, public_domain)
  - Frederick Haynes III TX-30 (-4813001, cc-by-3.0) — Dallas pastor
  - Brandon Herrera TX-23 (-4812301, cc-by-2.0) — "The AK Guy"
  - Mark Teixeira TX-21 (-4812101, cc-by-sa-2.0) — ex-MLB, running TX-21 GOP
  - Bobby Pulido TX-15 (-4811501, cc-by-4.0) — Tejano artist, running TX-15 Dem
- **43 documented honest-skips** — obscure first-time challengers with no own Wikipedia bio page (matches resolved to election/place/wrong-person articles, correctly rejected by the guard) and no discoverable free-license portrait. Pinned by external_id in `scripts/150-verify.sql` USHC-04 (ORDER BY external_id). **No wrong-person or copyrighted image was used** (T-150-17/18). Mirrors the 149 precedent (27/36 honest-skipped).

The wrong-person guard correctly caught: Mark Teixeira's page is the right person (ex-MLB IS the TX-21 candidate); rejected "Monica De La Cruz" for Carlos De La Cruz, "Gillespie County" for Patrick Gillespie, "Claire Valdez" for Claire Reynolds, "E. Dale Jackson" for Everett Jackson, etc.

## 43 honest-skip external_ids (gate-pinned, ORDER BY external_id)

-4813802, -4813801, -4813701, -4813601, -4813502, -4813501, -4813401, -4813302, -4813201, -4813101, -4813002, -4812901, -4812801, -4812701, -4812601, -4812501, -4812401, -4812302, -4812201, -4812102, -4812001, -4811902, -4811901, -4811801, -4811701, -4811601, -4811401, -4811301, -4811201, -4811101, -4811002, -4811001, -4810902, -4810901, -4810802, -4810801, -4810701, -4810601, -4810501, -4810401, -4810301, -4810201, -4810101

## Deviation / follow-up

A dedicated manual free-license-sourcing pass (the 149 manual step) is **deferred** — manual sourcing for 43 obscure challengers is high-effort/low-yield research, and the operator prioritized validating the stance pipeline this session. USHC-04 passes via documented gate-pins; `150-05-tx-headshots.manual.txt` is ready to accept future free-portrait lines. Dan Barrios (TX-32, reused record) already has an image and is correctly outside the new-band scope.
