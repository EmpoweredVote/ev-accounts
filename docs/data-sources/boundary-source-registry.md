# Boundary Source Registry

The authoritative, official GIS sources we pull district/boundary geometry from.

**Why this file exists.** Our geometry lives in `essentials.geofence_boundaries`. Each row
carries a free-text `source` tag (e.g. `monroe_county_gis`, `tiger_unsd_in_2024`), but the tag
alone does not tell you the live service URL. Those URLs were buried in individual fetch/import
script headers. This registry is the one place to look up the official source for a jurisdiction
**before** re-deriving anything — check the official source first.

**How to use it.** When a boundary looks wrong, or you need to add/refresh a layer, find the
jurisdiction below, open the service URL, and confirm against it. When you load a new layer, add
a row here and set the matching `geofence_boundaries.source` tag.

**Verification note.** "Verified" = a person opened the URL and confirmed it returns the expected
features on that date. Rows marked "from script header" carry the URL a loader script recorded but
have not been re-checked recently — treat the date as the last time we know it worked.

---

## How to query an ArcGIS layer

Most rows below are ArcGIS FeatureServer/MapServer layers. Two useful read-only calls:

- **Download geometry as GeoJSON (WGS84):**
  `…/FeatureServer/{layer}/query?where=1=1&outFields=*&outSR=4326&f=geojson`
- **Which feature contains a point (partition check):**
  `…/FeatureServer/{layer}/query?geometry={lon},{lat}&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=*&returnGeometry=false&f=json`

A clean single-member layer returns **exactly one** feature for a point-in-polygon query.

---

## Registry

### Indiana — Monroe County (Bloomington)

| Layer | Service URL | Key field | Coverage | Loaded as | Verified |
|---|---|---|---|---|---|
| **School Board Districts** | `https://services1.arcgis.com/nYfGJ9xFTKW6VPqW/arcgis/rest/services/Monroe_County_Election_Map_Current_WFL1/FeatureServer/15` | `schlbrd` = `1`–`7` (MCCSC), `RBBSC` (Richland-Bean Blossom) | MCCSC 7 single-member board districts + RBBSC | **MCCSC loaded** 2026-09-03 as `mtfcc=X0002`, `SCHOOL`, `source=monroe_county_election_map_arcgis_2026` (branch `pilot/mccsc-board-subdistricts`). RBBSC not yet loaded. | **2026-09-03** (point −86.606,39.145 → district 3; 8 features total) |
| County Council 2022 | `https://services1.arcgis.com/nYfGJ9xFTKW6VPqW/arcgis/rest/services/Monroe_County_Election_Map_Current_WFL1/FeatureServer/13` | — | 4 county council districts | `mtfcc=X-MCC-DIST` (see below) | 2026-09-03 (same service) |
| County Commissioner 2022 | `…/Monroe_County_Election_Map_Current_WFL1/FeatureServer/12` | — | 3 commissioner districts | not loaded | 2026-09-03 |
| Precincts (Current) | `…/Monroe_County_Election_Map_Current_WFL1/FeatureServer/2` | — | Voter precincts (IN board districts follow precinct lines) | not loaded | 2026-09-03 |
| Town of Ellettsville Wards | `…/Monroe_County_Election_Map_Current_WFL1/FeatureServer/14` | — | Ellettsville wards | not loaded | 2026-09-03 |
| County Council (older county server) | `https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0` | `CountyCouncil` = `1`–`4` | 4 county council districts | `mtfcc=X-MCC-DIST`, `source=monroe_county_gis` | from script header (`fetch-mcc-district-polygons.ts`) |

> **Note — two Monroe County sources.** The county publishes on its **own** server
> (`gis.co.monroe.in.us`, used by the original council import) **and** on its **ArcGIS Online**
> org (`services1.arcgis.com/nYfGJ9xFTKW6VPqW`, the "Election Map Current" service behind the
> public [election map experience](https://experience.arcgis.com/experience/47d72e9b0d60426f98ffb5ed54251a92/)).
> The ArcGIS Online "Election Map Current" service is the richer, election-office-maintained one
> and is the preferred source going forward.

### Indiana — Statewide (IGIO / gisdata.in.gov)

| Layer | Service URL | Coverage | Verified |
|---|---|---|---|
| State Senate districts | `https://gisdata.in.gov/server/rest/services/Hosted/Senate_Districts_of_Indiana_Current/FeatureServer/0` | Current IN Senate | from experience-app config, 2026-09-03 |
| State House districts | `https://gisdata.in.gov/server/rest/services/Hosted/House_Districts_of_Indiana_Current/FeatureServer/57` | Current IN House | from experience-app config, 2026-09-03 |
| Congressional districts | `https://gisdata.in.gov/server/rest/services/Hosted/Congressional_Districts_of_Indiana_Current/FeatureServer/0` | Current IN congressional | from experience-app config, 2026-09-03 |

### Wisconsin — Racine County

| Layer | Service URL | Key field | Loaded as | Verified |
|---|---|---|---|---|
| Board of Supervisors districts | `https://arcgis.racinecounty.com/arcgis/rest/services/Supervisor_Districts/Supervisor_Districts/MapServer/0` | `DISTRICTID` (21) | `mtfcc=X-RC-SUP`, `source=racine_county_gis` | from script header (`import-racine-supervisor-districts.ts`) |

> **⚠ Geometry only.** This layer's `REPNAME`/`Photos` attributes are materially stale (10 of 21
> disagreed with the county roster on 2026-07-25). Use it for polygons; take names from the roster
> migration, not the layer.

### California — Los Angeles County

| Layer | Service URL | Loaded as | Verified |
|---|---|---|---|
| Supervisorial districts | *(URL in loader — fill from the LA County GeoHub supervisor-districts script/migration)* | `source=la_county_geohub_supervisor_districts_2024` | from script header — URL to backfill |
| **Registrar-Recorder precincts** (every voting district, countywide) | `https://public.gis.lacounty.gov/public/rest/services/LACounty_Dynamic/Political_Boundaries/MapServer/34` | Compton + Pomona council districts loaded 2026-09-22 as `mtfcc=X0001`, `LOCAL`, `source=lacounty_rrcc_precincts_2026` (CA_0141) | **2026-09-22** (33,236 precincts) |

> **The precinct layer covers every by-area contest in the county.** Each precinct carries a
> district code and a division number per contest type: `DST_CITY`/`DIV_CITY` (2-letter city code +
> council district; e.g. `CO` Compton, `PY` Pomona, `MP` Monterey Park, `LS` Los Angeles, `ZZ`
> unincorporated), `DST_USD`/`DIV_USD` (unified school district + trustee area; numeric codes),
> `DST_HSD`, `DST_ESD`, `DST_JRC` (community college), `DST_HOSP`, `DST_MWD`, `DST_WR`, `DST_CW`,
> `DST_IRR`, `DST_LIB`, `DST_PARK`, and more. Dissolve precincts by (district, division) to get one
> polygon per seat. The service text says "Last Updated: March 2022", but the data is current: the
> Monterey Park dissolve matches the city's 2026 redistricting map (CC_0023) at IoU 0.994–0.995.
> Numeric school/college codes are not labelled — decode them by overlap with the TIGER polygons.
> Page with `resultOffset`/`resultRecordCount=1000` and `outSR=4326`.

### Nationwide — Census TIGER (whole school-district outlines only)

| Layer | Service URL | Coverage | Loaded as |
|---|---|---|---|
| Unified School Districts (UNSD) 2024 | `https://www2.census.gov/geo/tiger/TIGER2024/UNSD/` | Whole school-**corporation** outlines (NOT board sub-districts) | `mtfcc=G5420`, `source=tiger_unsd_{state}_2024` |

> **Limit.** TIGER school layers are the whole-corporation outline only. Board **sub-districts**
> (single-member seats) are **not** in TIGER — source them from the county/state, as with the
> Monroe County school board layer above.

---

## Adding a new source

1. Confirm the URL is the **official** publisher (county election office, state GIS, Census) and
   the **adopted/current** plan — not a draft or preliminary map.
2. Do a point-in-polygon check (above): a single-member layer returns exactly one feature.
3. Add a row here with the URL, key field, coverage, and today's date.
4. Set the loader's `geofence_boundaries.source` tag to a short slug and record it in the row.
