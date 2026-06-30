---
phase: 151-fl-candidate-seeding-provisional-qualified-field
plan: 02
wave: 1
status: complete
requirements: [USHC-02, USHC-03, USHC-04, USHC-05]
---

# 151-02 SUMMARY — 151-verify.sql FL single-state gate

## Outcome
`backend/scripts/151-verify.sql` authored (303 lines): write-free, single-state FL `'12'`-scoped, provisional-aware, honest-skip-pinnable. Scoping + provisional + write-free check PASSES; parses + runs read-only against prod pre-seed (USHC-03a active-floor FAILs pre-seed as documented — no race_candidates yet).

## Assertion labels
- **USHC-03a** — exactly 28 FL House races; each ≥1 active candidate (>=1 floor; `<2` NOTICE for uncontested FL-10; NO per-party cap — D-02).
- **USHC-03b** — 0 active candidates with NULL politician_id.
- **USHC-03c** — FL-20 (geo 1220) vacant office present (NULL pid) + its race links (office_id non-null).
- **D-04** — all 28 races `description LIKE 'PROVISIONAL:%'`.
- **USHC-02a** — 0 duplicate full_name among active FL candidates.
- **USHC-02b** — 3 reuse incumbents active in NEW seat (Frankel `-12022`→FL-23, Moskowitz `-12023`→FL-25, Wasserman Schultz `-12025`→FL-20), matched by exact external_id.
- **USHC-02c** — Cherfilus-McCormick active FL-20 as a NEW-band record (Pitfall 3).
- **D-05** — retired/redistricted incumbents absent in old seat (Dunn/Buchanan/Donalds/Wilson + Frankel/Moskowitz/Wasserman Schultz), pinned by external_id w/ ORDER BY.
- **USHC-04** — every in-scope independent has a politician_images row OR a `_headshot_skip` pin.
- **USHC-05a** — 0 unsourced stance rows for the in-scope independents.
- **USHC-05b** — each in-scope independent ≥1 sourced federal stance OR `_stance_skip` pin.

## TEMP-table conventions (for W2/W3 mid-wave invocation)
- `_house` — all FL House races + LEFT JOIN candidates + external_id.
- `_reuse_pid` (3) / `_lost` (7) — pinned by exact external_id w/ ORDER BY.
- `_indep_scope` — the **17 independent/NPA new candidates** (the USHC-04/05 in-scope set), pinned by (geo_id, full_name) and resolved to pid via active NEW-band FL candidates. **A name/seed mismatch raises a FAIL** ("17 did not resolve") — so 151-03 must insert these 17 names verbatim from the 148 field.
- `_fed24` — 24 federal topic_ids by key.
- `_stance_skip` (UUID) / `_headshot_skip` (external_id) — **empty placeholders; 151-04/151-05 INSERT their documented whole-record skips here with explicit ORDER BY** (143 lesson).

## Key encodings
- **D-01 asymmetry:** stance/headshot in-scope = 17 independents ONLY; the 27 partial incumbents AND the ~138 partisan new candidates are EXCLUDED from USHC-04/05 (records-now/stances-at-153). This is the NY false-fail trap, mirrored.
- **No per-party cap** (FL-19 has 11 R by design).
- Cherfilus NEW; reuse by exact external_id (FEC-noise guard).

## Deviation
- Resolved `_indep_scope` pids via `CREATE TEMP TABLE AS SELECT` (correlated subquery) instead of INSERT+UPDATE — the planned UPDATE tripped the write-free grep guard (`UPDATE ` token); the inline-resolve is equivalent and passes the guard verbatim.

## How 151-03..05 invoke it
Run mid-wave: `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/151-verify.sql`. Expect USHC-03/02/D-04/D-05 green after 151-03; USHC-04 after 151-04; USHC-05 after 151-05. 151-04/05 must add their honest-skip pins to `_headshot_skip` / `_stance_skip`.
