---
phase: 151-fl-candidate-seeding-provisional-qualified-field
plan: 04
wave: 3
status: complete
requirements: [USHC-04]
---

# 151-04 SUMMARY — headshots for the 17 FL independents

## Outcome
`backend/scripts/seed-fl-house-headshots.py` cloned from the validated TX/NY pipeline, targeting the **explicit 17-independent external_id list** (not the full FL new-band — the 138 partisan candidates are deferred to 153 per D-01). Wikipedia auto-pass run. **0 imaged, 17 honest-skipped** — all 17 pinned by external_id in `151-verify.sql` `_headshot_skip`. Gate now PASSES USHC-04 (+ USHC-05a). Idempotent.

## Result: 17/17 honest-skip
The auto-pass found NO free-license portrait for any of the 17 — every match resolved to an election page or a wrong person (the hardened guard correctly rejected e.g. President **John Tyler** for "Tyler Davis", a **special-election page** for "Andrew Parrott", the **2026 FL gubernatorial** page for "Patricia Gonzalez"). These are obscure minor-line/NPA candidates with no Wikipedia bio. A manual 2nd-source pass for 17 minor independents is very low-yield; per the find-headshots rule (never a wrong-person or all-rights-reserved image) all 17 are honest-skips. Matches 149 (27/36 skipped) / 150 (70 skipped). The cards still surface by name on `/elections`.

## Honest-skips pinned in `_headshot_skip` (all 17, by external_id)
-1210104 Tyler Davis · -1210305 Mike Klein · -1210405 Todd Schaefer · -1210609 Andrew Parrott · -1210610 Alec Pavlik · -1211203 Branden Scrivener · -1211304 Tony D'Arrigo · -1211609 Mark Davis · -1211703 Michael Quirk · -1211802 Deva Simmons · -1211914 Seth Haskins · -1212009 Kedner MaximeDe · -1212103 Alexander Cooke · -1212409 Andy Daro · -1212410 Patricia Gonzalez · -1212602 Deborah Ann Meidinger Hosey · -1212802 Eddy Rojas.

## Verification
- Gate: PASS USHC-04 ("every in-scope independent has a headshot or a pinned honest-skip"). USHC-05a PASS (0 unsourced). USHC-05b FAILs pre-151-05 (no stances yet — expected).
- 27 incumbents + 138 partisan new candidates NOT processed (out of D-01 scope).

## Artifacts
- `backend/scripts/seed-fl-house-headshots.py` (FL mode = explicit 17-id list; all guards intact).
- `backend/data/seed-fl-2026-house/151-04-fl-headshots.manual.txt` (documents 0 manual sources).
- `151-verify.sql` `_headshot_skip` pin set (17 entries, ORDER BY external_id).
