# UT School District Roster Audit Notes

**Status (2026-05-14):** Scaffolded. All 41 unified school districts have a stub TSV with a PENDING_RESEARCH placeholder row so the POL-04 floor (>= 1 board member per district) is achievable once rosters are filled in.

## What's here

41 TSVs under `data/rosters/manual/<slug>_school_district.tsv`. Each has:

- Header row: `external_id full_name role geo_id email phone term_start term_end photo_url source`
- One placeholder row with `full_name="PENDING_RESEARCH"`, `role="Board President"`, blank geo_id (loader resolves to whole-district G5420 — LAUSD pattern per POL-04), and a `source` cell describing the gap.

The loader (`scripts/load-ut-school-rosters.ts`) **skips placeholder rows** where `full_name === 'PENDING_RESEARCH'` so a re-run after a real fill-in is idempotent (no orphan PENDING_RESEARCH politician records).

## Scrape candidates (5)

Per `data/sources/ut_school_rosters.json` `source: "scrape"`:

- alpine_school_district.tsv — Alpine
- canyons_school_district.tsv — Canyons
- davis_school_district.tsv — Davis
- granite_school_district.tsv — Granite
- jordan_school_district.tsv — Jordan

A future pass should WebFetch each district's "board" page, extract 5-7 members, replace the PENDING_RESEARCH placeholder with real rows, set `source` to the page URL + date.

## Manual TSV fill (36)

For the remaining 36 districts, hand-curation is required (planner-noted ~12h worst case). Approach per district:

1. Visit `https://www.<district>.k12.ut.us/board` (or search "<district> School District Utah board members").
2. Extract 5-7 board members (or whatever the official site lists — small rural districts may have 3-5).
3. Replace the PENDING_RESEARCH row in the TSV with real rows. Leave `geo_id` blank — the loader resolves to whole-district SCHOOL row per LAUSD pattern (POL-04 floor).
4. Populate `source` with the URL + retrieval date.

## Sub-district polygons

`has_subdistrict_polygons: false` for all 41 districts in `ut_school_rosters.json` — UT publishes no sub-district board precinct polygons in TIGER 2024 or via UGRC SGID. All board members attach to the whole-district G5420 geofence (POL-04 explicit floor; LAUSD pattern).

If a future audit discovers a district that does publish sub-district polygons (rare), document it here and the W2 polygon import pass picks it up.

## Loader behavior contract

- Reads each TSV under `data/rosters/manual/<slug>_school_district.tsv` (also tries `<slug>_sd.tsv` for back-compat).
- Skips rows where `full_name === 'PENDING_RESEARCH'` (placeholder rows are tracked but not inserted).
- For real rows: resolves `essentials.districts` by `district_geo_id` and `district_type='SCHOOL'`, creates if missing.
- Upserts politician via shared `lib/politician-upsert.ts` (antipartisan invariant enforced).
- Idempotent re-run yields `inserted=0 updated=N` for filled rows.

## Acceptance ceiling (POL-04 floor)

`SELECT COUNT(DISTINCT data_source) FROM essentials.politicians WHERE data_source LIKE 'ut-school-%'` should equal 41 once the TSVs are filled in (every district has >= 1 board member). The current scaffolding state yields 0 — the loader runs cleanly but inserts nothing until placeholders are replaced.
