# 141-08 SUMMARY — Headshots batch A (AK, AL, FL, IL, MS, NC, NY, SD + IN)

**Status:** ✅ Complete  **Requirement:** SEXR-04
**Migration:** 985 (audit-only; planned 953, renumbered). Uploads were live via `seed-state-exec-headshots.py`.

35 of 35 batch-A execs have a headshot in the `politician_photos` bucket + `essentials.politician_images.url`. IN's Morales/Elliott (642977/688298) already had images (pre-existing) — confirmed present, not re-inserted.
- **1 honest-skip:** Josh Haeder (SD Treasurer, -4600005) — no Wikipedia portrait; sdtreasurer.gov 403s and Ballotpedia is anti-bot-blocked. Documented (McDowell precedent), pinned in gate SEXR-04.

Mechanism: Wikipedia pageimages → PIL crop 4:5 → 600×750 LANCZOS q90 → upload (`url` column). Wrong-person guard (wikidata description must be political) + free-license-only filter. Genuine Wikipedia gaps recovered via official `.gov` direct URLs (2nd-source agent pass).

## Self-Check: PASSED
