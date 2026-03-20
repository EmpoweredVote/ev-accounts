---
phase: 38-express-ports-wave-3-essentials
plan: 01
subsystem: api
tags: [geocoding, census, redis, postgis, essentials, typescript]

requires:
  - phase: 37-express-ports-wave-2-staging
    provides: established pool.query() pattern for all non-public schemas

provides:
  - geocodingService.ts rewritten with Census Geocoder (free, no API key required)
  - Redis cache layer on geocoder results (24hr TTL, geocode:v1:{normalized_address})
  - GEOCODER_UNAVAILABLE error code replacing LOW_CONFIDENCE + GEOCODING_API_ERROR
  - env.ts: GOOGLE_MAPS_API_KEY now optional (server starts without it)
  - connect.ts: updated error handling for GEOCODER_UNAVAILABLE (503)
  - Complete column inventory for geofence_boundaries, districts, offices, politicians
  - Verified join path: geofence_boundaries.geo_id -> districts.geo_id -> districts.id = offices.district_id -> offices.id = politicians.office_id
affects:
  - 38-02: address-search route (depends on schema join path documented here)
  - 38-03: politician detail routes
  - all phases that use geocodingService.ts

tech-stack:
  added: []
  patterns:
    - "Census Geocoder: AbortController 5s timeout, AbortError catches to GEOCODER_UNAVAILABLE"
    - "Geocoder cache key: geocode:v1:{address.toLowerCase().trim().replace(/\\s+/g, ' ')}"
    - "Census coordinate order: x=longitude, y=latitude (opposite of common convention)"

key-files:
  created: []
  modified:
    - backend/src/lib/geocodingService.ts
    - backend/src/lib/env.ts
    - backend/src/routes/connect.ts

key-decisions:
  - "Census Geocoder replaces Google Maps — free, no API key, public benchmark Public_AR_Current"
  - "geofence_boundaries joins districts via geo_id (text), NOT a UUID FK — no FK constraints defined"
  - "Full join path confirmed: geofence_boundaries -> districts -> offices -> politicians (291 Indiana politicians reachable)"
  - "GOOGLE_MAPS_API_KEY kept in env.ts as optional (not removed) to avoid breaking existing deployments with key set"

patterns-established:
  - "AbortController timeout pattern: const controller = new AbortController(); const timeout = setTimeout(() => controller.abort(), 5000)"
  - "Census coordinate extraction: const lng = matches[0].coordinates.x; const lat = matches[0].coordinates.y"
  - "Geocoder cache: cache.get<{lat,lng}>(key) before fetch; cache.set(key, {lat,lng}, 86400) after"

duration: 7min
completed: 2026-03-20
---

# Phase 38 Plan 01: Schema Investigation + Census Geocoder Rewrite Summary

**Census Geocoder replaces Google Maps in geocodingService.ts; Redis cache added; essentials join path (geofence_boundaries -> districts -> offices -> politicians) verified with 291 reachable Indiana politicians**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-20T19:21:16Z
- **Completed:** 2026-03-20T19:28:08Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Queried live database to establish complete column inventory for 4 essentials tables
- Verified join path from geofence_boundaries to politicians (291 Indiana politicians reachable)
- Rewrote geocodingService.ts: Census Geocoder + Redis cache + AbortController timeout
- Made GOOGLE_MAPS_API_KEY optional in env.ts (server no longer crashes without it)
- Updated connect.ts error handling: GEOCODER_UNAVAILABLE returns 503, LOW_CONFIDENCE removed

## Task Commits

1. **Task 1: Investigate essentials schema join paths** — no file commit (investigation only; results in this SUMMARY)
2. **Task 2: Rewrite geocodingService.ts + update env.ts + update connect.ts** — `8668d3d` (feat)

## Files Created/Modified
- `backend/src/lib/geocodingService.ts` — complete rewrite: Census Geocoder, Redis cache, 5s timeout
- `backend/src/lib/env.ts` — GOOGLE_MAPS_API_KEY changed from required to optional
- `backend/src/routes/connect.ts` — set-location error handling: GEOCODER_UNAVAILABLE added, LOW_CONFIDENCE removed

---

## Schema Investigation Results (CRITICAL — Plan 02 depends on this)

### essentials.geofence_boundaries columns

| column_name  | data_type                   | Notes |
|--------------|-----------------------------|-------|
| id           | uuid                        | PK |
| geo_id       | character varying           | GEOID — JOIN key to districts.geo_id |
| ocd_id       | character varying           | OCD ID (nullable, null in current data) |
| name         | text                        | Boundary name (e.g., "Monroe", "Los Angeles") |
| state        | character                   | FIPS state code (e.g., "18" = Indiana, "06" = California) |
| mtfcc        | character varying           | Census MTFCC code (boundary type — see MTFCC table below) |
| geometry     | USER-DEFINED (PostGIS geom) | PostGIS geometry column — use in ST_Covers() |
| source       | text                        | e.g., "census_tiger_2024" |
| valid_from   | text                        | nullable |
| valid_to     | text                        | nullable |
| imported_at  | timestamp without time zone | |
| quality_flag | text                        | nullable |

**PostGIS column name is `geometry`, NOT `geom`.**
Use `ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326))` — NOT `gb.geom`.

**Sample rows:**
```
geo_id=18105, mtfcc=G4020, name=Monroe, state=18 (Indiana county)
geo_id=06037, mtfcc=G4020, name=Los Angeles, state=06 (CA county)
geo_id=1805510702, mtfcc=G4040, name=Cass, state=18 (Indiana school district)
```

**MTFCC distribution (all 6,552 rows):**
| MTFCC  | Count | Description |
|--------|-------|-------------|
| G6350  | 2,609 | School districts |
| G4040  | 1,416 | Unified school districts |
| G4110  | 1,048 | Congressional districts |
| G5420  | 675   | State senate districts |
| G4210  | 410   | County subdivisions |
| G5220  | 180   | State house districts |
| G5210  | 90    | (State house upper) |
| G5200  | 61    | State legislative districts |
| X0001  | 61    | Custom/other |
| G4020  | 2     | Counties |

---

### essentials.districts columns

| column_name         | data_type | Notes |
|--------------------|-----------|-------|
| id                  | uuid      | PK — referenced by offices.district_id |
| external_id         | bigint    | External system ID |
| ocd_id              | text      | OCD ID |
| label               | text      | Human-readable district name |
| district_type       | text      | e.g., "LOCAL_EXEC", "JUDICIAL", "COUNTY" |
| district_id         | text      | District number/label (e.g., "0", "4", "2") |
| subtype             | text      | |
| state               | text      | State abbreviation (e.g., "CA", "IN") |
| city                | text      | |
| num_officials       | bigint    | |
| valid_from          | text      | |
| valid_to            | text      | |
| last_update_date    | text      | |
| mtfcc               | text      | Census MTFCC code |
| geo_id              | text      | **JOIN key to geofence_boundaries.geo_id** |
| is_judicial         | boolean   | |
| has_unknown_boundaries | boolean | |
| retention           | boolean   | |

**Sample district rows:**
```
geo_id=0600394, district_type=LOCAL_EXEC, label=Agoura Hills Mayor, state=CA
geo_id=18, district_type=JUDICIAL, label=Indiana Appeals Court Judge - District 4
geo_id=18093, district_type=JUDICIAL, label=Lawrence County Superior Court Judge - Court 2
```

---

### essentials.offices columns

| column_name             | data_type                  | Notes |
|------------------------|----------------------------|-------|
| id                      | uuid                       | PK — referenced by politicians.office_id |
| politician_id           | uuid                       | FK → politicians.id |
| chamber_id              | uuid                       | FK → chambers.id |
| district_id             | uuid                       | **FK → districts.id** |
| title                   | text                       | Office title |
| representing_state      | text                       | |
| representing_city       | text                       | |
| description             | text                       | |
| seats                   | bigint                     | |
| normalized_position_name | text                      | |
| partisan_type           | text                       | |
| salary                  | text                       | |
| is_appointed_position   | boolean                    | |
| is_vacant               | boolean                    | |
| vacant_since            | timestamp with time zone   | |

---

### essentials.politicians columns (37 columns)

| column_name         | data_type                | Notes |
|--------------------|--------------------------|-------|
| id                  | uuid                     | PK |
| external_id         | bigint                   | |
| full_name           | text                     | |
| first_name          | text                     | |
| last_name           | text                     | |
| party               | text                     | |
| source              | text                     | |
| last_synced         | timestamp with time zone | |
| office_id           | uuid                     | **FK → offices.id** |
| valid_from          | text                     | |
| valid_to            | text                     | |
| last_update_date    | text                     | |
| middle_initial      | text                     | |
| preferred_name      | text                     | |
| name_suffix         | text                     | |
| email_addresses     | ARRAY                    | |
| urls                | ARRAY                    | |
| web_form_url        | text                     | |
| photo_origin_url    | text                     | |
| notes               | ARRAY                    | |
| photo_custom_url    | text                     | |
| bio_text            | text                     | |
| bioguide_id         | text                     | |
| slug                | text                     | |
| total_years_in_office | bigint                 | |
| party_short_name    | text                     | |
| is_appointed        | boolean                  | |
| is_vacant           | boolean                  | |
| is_off_cycle        | boolean                  | |
| specificity         | text                     | |
| external_global_id  | text                     | |
| is_active           | boolean                  | |
| data_source         | text                     | |
| term_date_precision | text                     | |
| leg_data_fetched_at | timestamp with time zone | |
| is_incumbent        | boolean                  | |
| appointment_date    | date                     | |

---

### FK Relationships

No FK constraints are formally defined (FK query returned 0 rows). All joins are by convention only:

| Join | Type | Verified |
|------|------|---------|
| `geofence_boundaries.geo_id = districts.geo_id` | text = text | YES — 609 matching rows |
| `offices.district_id = districts.id` | uuid = uuid | YES — 1,794 matching rows |
| `politicians.office_id = offices.id` | uuid = uuid | YES — full chain verified |

---

### Verified Join Path: geofence_boundaries → politicians

```sql
-- VERIFIED: 291 Indiana politicians reachable via this join path
-- geofence_boundaries.geometry is the PostGIS column (NOT geom)
-- ST_MakePoint($1, $2) = (longitude, latitude) = (Census x, Census y)

SELECT p.*,
       d.district_type,
       d.geo_id AS district_geo_id,
       d.label AS district_label,
       d.mtfcc AS district_mtfcc
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.office_id = o.id
WHERE public.ST_Covers(
  gb.geometry,
  public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
  -- $1 = longitude (Census coordinates.x), $2 = latitude (Census coordinates.y)
)
AND p.is_active = true;
```

**Critical notes for Plan 02:**
1. Column is `geometry` (not `geom`) in geofence_boundaries
2. Join is `d.geo_id = gb.geo_id` (text-to-varchar, no FK constraint)
3. 291 Indiana politicians reachable in production — join path is live and working
4. No FK constraints — joins are by convention only; no cascade guarantees
5. MTFCC values on geofence_boundaries map to district types (G4110=congressional, G5420=state_senate, G5220=state_house, G4020=county, G6350=school_district)

---

## Decisions Made

- **Census Geocoder over Google Maps** — free, no API key, reliable (US government), returns lat/lng in `coordinates.x` (longitude) / `coordinates.y` (latitude). `addressMatches: []` = no match (no matchStatus field at this API level).
- **GOOGLE_MAPS_API_KEY kept as optional** — removing it would break existing deployments where the key is set; optional achieves the goal (server starts without it) without forcing key removal.
- **`geometry` confirmed as PostGIS column name** — NOT `geom`. Any Plan 02 SQL must use `gb.geometry` in ST_Covers calls.
- **geofence_boundaries.geo_id join is text/varchar** — no FK constraint; join works correctly in production (609 geofence-to-district matches verified).

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- Plan 02 (address-search route) is fully unblocked:
  - Join path verified: `geofence_boundaries.geo_id = districts.geo_id` → `districts.id = offices.district_id` → `offices.id = politicians.office_id`
  - PostGIS column name confirmed: `geometry` (not `geom`)
  - Census Geocoder returns `coordinates.x` (lng) and `coordinates.y` (lat)
  - SQL template provided above; 291 Indiana politicians reachable in production
- Geocoding service is production-ready (Redis cache + timeout + PO Box guard)
- Server starts without GOOGLE_MAPS_API_KEY

---
*Phase: 38-express-ports-wave-3-essentials*
*Completed: 2026-03-20*
