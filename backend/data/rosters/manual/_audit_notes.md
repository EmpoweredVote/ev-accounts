# UT Politician Roster Audit Notes

## Counties (133-04)
# UT County Roster TSV Audit Notes

**Generated:** 2026-05-14 (Phase 133 Plan 4)
**Status:** STUB BASELINE — all rows are `PENDING_RESEARCH` placeholders. Operator must replace `full_name` cells with real elected official names via WebSearch / county website lookups before re-running `load-ut-county-rosters.ts`.

## Scaffold Provenance

All 29 TSVs were generated mechanically from `data/sources/ut_county_rosters.json` by the helper script `scripts/scaffold-ut-county-tsvs.ts` (also runnable inline via Node — see plan 133-04 SUMMARY for the one-shot snippet).

The scaffold produces deterministic role rows so the loader's role-based external_id hash (D-07) is stable across operator fills: a real name added on day 1 keeps the same `external_id` as the same role re-filled on day 30.

## Per-County Layout

### Council counties (5 — Grand reclassified to commission per 133-02)

| County | Rows | District seats with `geo_id` populated | Notes |
|--------|------|----------------------------------------|-------|
| Salt Lake | 17 | 6 (1..6, polygons exist) | + 3 at-large + Mayor + 7 officers. Roster URL: https://www.saltlakecounty.gov/council/contact/ |
| Summit | 12 | 5 (1..5, polygons loaded in 133-02) | + 7 officers |
| Morgan | 12 | 5 (1..5, polygons loaded in 133-02) | + 7 officers |
| Cache | 12 | 0 (no_source — falls back to G4020) | Council form but no public polygon FeatureServer; loader attaches members to whole-county G4020 |
| Wasatch | 12 | 0 (no_source — falls back to G4020) | Council form but no public polygon FeatureServer |

### Commission counties (24 — includes Grand)

Each TSV has 10 rows: 3 commissioners (Seats A/B/C) + 7 at-large officers (Sheriff, County Attorney, Clerk/Auditor, Recorder, Assessor, Treasurer, Surveyor).

Counties: Beaver, Box Elder, Carbon, Daggett, Davis, Duchesne, Emery, Garfield, Grand*, Iron, Juab, Kane, Millard, Piute, Rich, San Juan, Sanpete, Sevier, Tooele, Uintah, Utah, Washington, Wayne, Weber.

\* Grand reclassified from council → commission per 133-02 probe (CONTEXT D-01 premise corrected; manifest updated this plan).

## At-Large Officer Convention

> **⚠️ CORRECTED 2026-07-29 — do not use the uniform 7 as a seat count.** The convention below is a
> *scaffold* convention (stable role hashes), and it was mistakenly consumed as an authoritative
> roster size, which made 5 counties read over-roster on the coverage tracker. Utah Code 17-66-102
> enumerates **8** county-wide officers; 17-66-104 lets each county consolidate them by ordinance, so
> the true count is **5 to 8 per county**. The uniform 7 assumes Clerk+Auditor consolidated
> everywhere and nothing else consolidated anywhere. It also omits the elected county executive
> (Cache) / mayor (Salt Lake), and its `3 commissioners` default is wrong for Grand (7), Wasatch (7),
> Morgan (5) and Tooele (5). **All 29 counties were audited 2026-07-29 and 18 seat totals were
> wrong** — the real range is 8–18, not the 10/12/16 this scaffold could produce. The TSV row counts
> below are therefore scaffold artifacts, NOT roster sizes; take seat counts from
> `ut_county_rosters.json` (`expected_seat_total`, with `roster_confidence`).
> See `data/coverage/README.md` → "The 7-officer template".

All 29 counties have the same 7 at-large officer rows regardless of government shape. Some counties consolidate offices in practice (e.g., Clerk-Auditor combined, Clerk-Recorder combined, Surveyor sometimes absent). The TSV `role` column should be edited verbatim to match the county's actual title; the loader passes the role string through to `offices.title` and uses `slugify(role)` only for the external_id hash, so spelling changes after first load do NOT shift external_ids.

## Floor Coverage (manual_partial threshold)

The plan's acceptance threshold is "every county has >= 1 politician". Because all rows are stubs at scaffold time, the floor is **not yet met** until operator does the roster research pass.

When a county's roster is genuinely undiscoverable online (e.g., Daggett, Wayne, Rich are tiny), the operator should:
1. Fill in the Sheriff row at minimum (sheriffs are reliably listed on state-wide sheriff association rosters).
2. Mark the county's `status` in `ut_county_rosters.json` as `manual_partial` and add a note explaining the gap.
3. Leave remaining rows as `PENDING_RESEARCH` — the loader skips them, so no garbage politicians are inserted.

## Operator Re-Run Workflow

```bash
# After editing one or more TSVs in this directory:
cd ev-accounts/backend
npx tsx scripts/load-ut-county-rosters.ts --dry-run        # all 29
npx tsx scripts/load-ut-county-rosters.ts --county utah    # just Utah County
npx tsx scripts/load-ut-county-rosters.ts                  # apply
```

Re-runs are idempotent (D-08). PENDING_RESEARCH rows are skipped silently; the loader prints `skipped_stubs=N` in the totals line.

## Source-Audit Pointers (for operator)

Useful entry points when filling roster TSVs:

- **Salt Lake**: https://www.saltlakecounty.gov/council/contact/ (per manifest)
- **Summit**: https://www.summitcounty.org/177/County-Council
- **Cache**: https://www.cachecounty.org/council/ (or executive page)
- **Wasatch**: https://www.wasatch.utah.gov/county-council
- **Morgan**: https://www.morgancountyutah.gov/county-council/
- **All-county sheriff index**: Utah Sheriffs' Association — https://utahsheriffs.org/
- **Commission counties index**: each county has `{name}county{ut|utah}.gov` or `{name}.utah.gov` with an "Elected Officials" page

WebSearch queries that worked well in similar past phases:
- `"{County} County Utah commissioners 2026"`
- `"{County} County Utah elected officials"`
- `"{County} County Utah Sheriff"`

## Deferred Items

- **Operator must replace ALL `PENDING_RESEARCH` rows** with real names + (optionally) email/phone/term_start/term_end/photo_url before the POL-02 floor is met. Estimated effort: ~30 min per commission county × 24 = ~12 hours; council counties (~45–60 min × 5) = ~4 hours. **Total ~16h** of manual research.
- **Sub-divided Cache/Wasatch council districts**: even after operator fills rosters, members will attach to G4020 (whole-county) until council polygons are sourced. This is the documented degraded-UX path per 133-02 D-01.

## Cities (133-05)
# Phase 133 Plan 05 — UT City Rosters: Source Audit Notes

**Date scaffolded:** 2026-05-14
**Status:** STUBS — manual research deferred to user per Plan 05 source-audit checkpoint (Task 5.1).

---

## What's wired (Task 5.2 — autonomous, COMPLETE)

| City | Source | URL | Status |
|------|--------|-----|--------|
| Salt Lake City (council) | FeatureServer | `services.arcgis.com/mMBpeYj0vPFotzbe/.../Salt_Lake_City_Council_Districts/FeatureServer/1` | CITYCOUNCIL_MEMBER + DISTRICT verified in 132 D-04 |
| Provo (council)         | FeatureServer | `gispublicweb.provo.org/.../Council/Council_Districts/FeatureServer/3` | COUNCIL_MEMBER + EMAIL + PHONE + TERM_EXPIRES + picture verified in 132 D-04 / RESEARCH §External Sources POL-03 |

Loader (`scripts/load-ut-city-rosters.ts`) reads these FeatureServers on every run — names update automatically when the city republishes the layer.

---

## What's STUBBED (pending user research)

Each stub TSV contains `PENDING_RESEARCH_*` placeholder rows. The loader's `isStubName` regex skips these so the file is safe to commit + safe to run against the DB; no garbage politicians are inserted.

User action required before this plan is fully realized:

| City | TSV(s) to fill | WebSearch starter |
|------|---------------|-------------------|
| Salt Lake City (mayor only) | `salt_lake_city_mayor.tsv` | `https://www.slcgov.com/mayor` |
| Provo (mayor only) | `provo_mayor.tsv` | `https://www.provo.org/government/mayor` |
| Ogden | `ogden_city.tsv`, `ogden_mayor.tsv` | `"Ogden Utah city council members"` |
| Sandy | `sandy_city.tsv`, `sandy_mayor.tsv` | `"Sandy Utah city council members"` |
| West Valley City | `west_valley_city_city.tsv`, `west_valley_city_mayor.tsv` | `"West Valley City Utah council"` |
| West Jordan | `west_jordan_city.tsv`, `west_jordan_mayor.tsv` | `"West Jordan Utah city council"` |
| Orem | `orem_city.tsv`, `orem_mayor.tsv` | `"Orem Utah city council members"` |
| Layton | `layton_city.tsv`, `layton_mayor.tsv` | `"Layton Utah city council"` |
| Lehi | `lehi_city.tsv`, `lehi_mayor.tsv` | `"Lehi Utah city council"` |
| St. George | `st_george_city.tsv`, `st_george_mayor.tsv` | `"St. George Utah city council"` |

### How to fill a stub
1. Open the TSV in a tab-aware editor.
2. Replace each `PENDING_RESEARCH_seat_N` with the actual full name.
3. If the city uses **wards/districts**:
   - Set `role` to `Council Ward N` (or `Council District N`).
   - Set `geo_id` to `ocd-division/country:us/state:ut/place:{slug}/ward:N`.
4. If the city is **at-large only** (most smaller UT cities):
   - Leave `role` as `Council At-Large`.
   - Leave `geo_id` blank — loader resolves to whole-place jurisdiction.
5. Fill `email` / `phone` / `photo_url` if discovered (all optional).
6. **Mayor:** TSV has one row. Replace `PENDING_RESEARCH_mayor` with the actual name. Leave `geo_id` blank.

### Loader contract
- `external_id` column always blank — auto-computed via SHA1(geo_id + role).
- Header row required.
- Lines starting with `#` are comments (ignored).
- Rows where `full_name` begins with `PENDING_RESEARCH` are skipped (with stderr log).

### Seat-count guesses (seed values — adjust to reality)
The stubs assume the following council seat counts. **These are best-guess seeds** and must be reconciled against each city's actual charter:

- Ogden: 5 (W-3 hint — Ogden uses a ward system)
- Sandy: 5
- West Valley City: 6
- West Jordan: 4
- Orem: 6
- Layton: 4
- Lehi: 4
- St. George: 4

Add or remove rows as the actual count requires.

---

## W-3 cleanup (this plan)

Removed dead `mayor_geo_id` field from `ut_city_rosters.json` SLC + Provo records.
Rationale: the loader derives mayor `geo_id` from the row's `jurisdiction_id` directly
(see `loadMayorTsv` — passes `city.jurisdiction_id` as the LOCAL_EXEC geo_id). The
`mayor_geo_id` field was unused by any code path and duplicated the jurisdiction_id.
