---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 02
subsystem: elections-data-seeding
tags: [wisconsin, us-house-2026, candidate-seeding, headshots, pure-data]
dependency-graph:
  requires: [160-field-resolution-stance-gap-diagnostic]
  provides: [wi-2026-house-election, wi-2026-house-races, wi-2026-house-candidates, wi-headshot-pipeline]
  affects: [163-07-wi-stances, 166-consolidated-verify]
tech-stack:
  added: []
  patterns: ["vanilla single-election new-election seed (clone of 162-mn-generate.mts)", "band-scoped headshot ingestion (clone of seed-mo-house-headshots.py)"]
key-files:
  created:
    - backend/scripts/163-wi-generate.mts
    - backend/migrations/1220_seed_wi_2026_house_elections_races.sql
    - backend/migrations/1221_seed_wi_2026_house_candidates.sql
    - backend/scripts/seed-wi-house-headshots.py
    - backend/data/seed-wi-2026-house/163-02-wi-reconciliation.csv
  modified: []
decisions:
  - "WI-7 Thomas P. Tiffany (retired, running for Governor) excluded from race_candidates entirely (REUSE-NO-ROW); no active House row authored for him — open seat"
  - "WI-2 legitimately has only 2 all-Democratic candidates (Pocan + Alexander) — no Republican filed, verified via local news source, not treated as an error"
  - "Added a foreign-nationality-homonym guard to seed-wi-house-headshots.py after the bare 'politician' POLITICAL_KW match resolved 'Douglas Alexander' to a British Labour MP instead of the WI-2 challenger"
metrics:
  duration: ~35min
  completed: 2026-07-05
---

# Phase 163 Plan 02: Wisconsin 2026 US House Seed Summary

Seeded Wisconsin's full 2026 US House field (8 districts, 28 new candidate records) onto prod via the vanilla single-election pattern (WI is not redistricted, no withholding), then ran band-scoped headshot ingestion.

## What Was Built

1 `essentials.elections` row ("WI 2026 Statewide General", 2026-11-03) + 8 `essentials.races` rows wired to WI's existing NATIONAL_LOWER US House offices (geo_ids 5501-5508), all with non-null `office_id`. 28 new `essentials.politicians` records (external_id band -550101..-550803) plus 35 active `essentials.race_candidates` rows (28 new + 7 renominated incumbents reused by external_id). WI-7's incumbent, Thomas P. Tiffany, retired to run for Governor and is excluded entirely from the new race's candidate set (no active row authored) — WI-7 is a fully open 7-candidate field. Every race description carries the `PROVISIONAL:` prefix (Aug-11 late primary; cull scheduled ≥ 2026-08-12). Headshot ingestion then ran against the new-candidate external_id band, uploading 1 verified free-license portrait (Rebecca Cooke, WI-3) and honest-skipping the remaining 27 (26 for lacking a dedicated Wikipedia biographical page, 1 — Douglas Alexander — corrected from a wrong-person upload to an honest-skip after a guard fix).

## Task Execution

### Task 1: Fresh FIPS-55 collision check
Verified 0 collisions in the WI new-challenger band (-550899..-550101) against prod `essentials.politicians`. Confirmed the 8 legacy incumbent external_ids (-55001..-55008) sit outside that band and match `160-field-table-p163.csv` exactly (Bryan Steil, Mark Pocan, Derrick Van Orden, Gwen Moore, Scott Fitzgerald, Glenn Grothman, Thomas P. Tiffany, Tony Wied). Confirmed Tiffany (WI-7) is departing (running for Governor) — no active House row planned for him. Pure verification task, no commit.

### Task 2: Generate + apply WI elections/races + candidates migrations
Cloned `backend/scripts/162-mn-generate.mts` → `backend/scripts/163-wi-generate.mts` (FIPS 55, 8 districts, INC_EXT map -55001..-55008 with Tiffany `vacate:true`, 28-record `FIELD` array from `160-field-table-p163.csv`, election name "WI 2026 Statewide General", description "PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12"). Re-verified 1220/1221 were still the next-free migration pair (`ls backend/migrations | sort -n | tail` showed highest as 1219) — no shift needed. Ran the generator (`node --import tsx scripts/163-wi-generate.mts`), which emitted both migrations and the reconciliation CSV; console output confirmed 28 new records, 0 duplicate external_id, 0 duplicate full_name, correct per-district active counts (WI-2=2, WI-7=7, others 4-6). Applied both migrations to prod via `psql -v ON_ERROR_STOP=1`: 1220 inserted 1 election + 8 races; 1221 inserted 28 politicians + 35 race_candidates. Verified: 8 races all `office_id` non-null; 28 new politicians in-band; WI-2 has exactly Pocan + Alexander; WI-7 has exactly the 7 new candidates with `is_incumbent=false` (Tiffany absent); 0 duplicate `full_name` across the whole WI candidate set. Re-ran both migrations to confirm idempotency — 0-row no-op on every INSERT.

### Task 3: WI headshots (band-scoped)
Cloned `backend/scripts/seed-mo-house-headshots.py` → `backend/scripts/seed-wi-house-headshots.py` (BANDS = `{'WI': (-550899, -550101, 'Wisconsin')}`, RESULTS_JSON = `_wi-house-headshot-results.json`, localized `, wisconsin` place-token in `_NON_PERSON_TITLE`). Ran against the 28-candidate band: uploaded 1 (Rebecca Cooke, WI-3, cc_by_3.0, verified "American political candidate" description) and initially uploaded a second — "Douglas Alexander" (WI-2) — that turned out to be a **wrong-person match**: Wikipedia's `Douglas Alexander` page is a British Labour MP ("British politician (born 1967)"), and the bare word "politician" satisfied the existing `POLITICAL_KW` filter with no nationality check. Deleted the bad `politician_images` row from prod immediately, added a `_FOREIGN_NATIONALITY` guard (rejects descriptions naming a non-US nationality unless the target state name is also present) to `seed-wi-house-headshots.py`, and re-ran — the candidate now correctly honest-skips as `foreign-nationality-homonym-desc`. Final state: 1 verified upload, 27 honest-skips (26 no-dedicated-bio-page + 1 corrected foreign-nationality-homonym), all recorded in `backend/scripts/_wi-house-headshot-results.json` (gitignored per `backend/scripts/_*` convention).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wrong-person headshot upload (foreign-nationality homonym)**
- **Found during:** Task 3
- **Issue:** `seed-wi-house-headshots.py`'s `POLITICAL_KW` guard passed any Wikipedia short description containing the substring "politic", with no check for nationality. This let "Douglas Alexander" (WI-2 Democratic challenger) resolve to the Wikipedia page for a British Labour MP of the same name ("British politician (born 1967)"), and a wrong-person headshot was uploaded to prod.
- **Fix:** Deleted the bad `essentials.politician_images` row from prod (id `a61fb1f2-0554-4337-800c-8ca3adde0667`). Added a `_FOREIGN_NATIONALITY` regex guard + `_desc_is_foreign_homonym()` check to `seed-wi-house-headshots.py`, mirroring the existing `_desc_is_historical` pattern: reject any resolved description naming a non-US nationality (British, Scottish, Canadian, etc.) unless the target US state name also appears in the description. Re-ran the script; the candidate now correctly honest-skips as `foreign-nationality-homonym-desc`.
- **Files modified:** backend/scripts/seed-wi-house-headshots.py
- **Commit:** 296ad0b3
- **Scope note:** This guard fix was applied only to the newly-created `seed-wi-house-headshots.py` (in scope for this task). It has NOT been backported to the prior states' headshot scripts (seed-mo/mn/in/md/tn/etc-house-headshots.py) — those are out of scope for this plan. Flagging for the 163-12 consolidated gate / future audit: a spot-check of prior-phase headshot uploads for similar cross-national homonyms may be warranted.

No other deviations — plan executed as written otherwise.

## Known Stubs

None — all 28 new candidate records are fully wired into `race_candidates` with real names/sources; headshots are either a verified upload or a documented honest-skip (no placeholder/empty values).

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced. The wrong-person headshot incident (see Deviations) is a data-integrity correctness issue already remediated, not an unaddressed threat surface; it maps onto the plan's own threat register (T-163-02-02, duplicate/wrong-record risk) rather than introducing a new category.

## Verification Results

- 8 WI races exist under "WI 2026 Statewide General", all `office_id NOT NULL` (verify query returned `8|0`)
- 28 new politicians in the -550899..-550101 band
- WI-2 has exactly 2 race_candidates (Mark Pocan, Douglas Alexander)
- WI-7 has exactly 7 race_candidates, all `is_incumbent=false` (Tiffany correctly excluded)
- 0 duplicate `full_name` across WI's race_candidates
- Re-running both migrations (1220, 1221) is a confirmed 0-row no-op
- 1 politician_images row in the WI new-candidate band (Rebecca Cooke); 27 documented honest-skips in `_wi-house-headshot-results.json`

## Self-Check: PASSED

- FOUND: backend/scripts/163-wi-generate.mts
- FOUND: backend/migrations/1220_seed_wi_2026_house_elections_races.sql
- FOUND: backend/migrations/1221_seed_wi_2026_house_candidates.sql
- FOUND: backend/scripts/seed-wi-house-headshots.py
- FOUND: backend/data/seed-wi-2026-house/163-02-wi-reconciliation.csv
- FOUND commit 8973d5d3 (WI seed)
- FOUND commit 296ad0b3 (WI headshots)
