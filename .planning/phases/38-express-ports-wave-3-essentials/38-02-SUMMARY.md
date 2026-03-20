---
phase: 38-express-ports-wave-3-essentials
plan: 02
subsystem: api
tags: [postgis, census-geocoder, essentials, politicians, typescript, express]

# Dependency graph
requires:
  - phase: 38-express-ports-wave-3-essentials
    provides: Census Geocoder rewrite, geocodingService.ts with GeocodingError codes, verified PostGIS join path
  - phase: 38-express-ports-wave-3-essentials
    provides: geofence_boundaries column name (geometry not geom), join path verified with 291 Indiana politicians

provides:
  - GET /api/essentials/address-search (Census -> PostGIS -> politicians flat list)
  - getPoliticiansFlatList (Go-parity flat list with all office/district/chamber/government fields)
  - getRepresentativesByAddress (geocode address + PostGIS geofence lookup)
  - PoliticianFlatRecord and AddressSearchResult interfaces
  - data_level tier signaling on all essentials endpoints
affects:
  - 38-03: politician detail routes (can import PoliticianFlatRecord, use same join pattern)
  - 38-04: address-search tests (verify ADDRESS_NOT_FOUND, GEOCODER_UNAVAILABLE, PostGIS match)
  - any frontend consuming /api/essentials/politicians (response shape changed from grouped to flat)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GeocodingError propagates from service layer — never caught in essentialsService, always caught in route handler"
    - "data_level tier signaling: userId present = 'connected', absent = 'inform' — appended to all essentials responses"
    - "null string fields coerced to '' in Go-parity flat list (empty string not null, matching Go convention)"
    - "essentials router mount order: /politicians and /candidates before /essentials to prevent path conflicts"

key-files:
  created:
    - backend/src/routes/essentials.ts
  modified:
    - backend/src/lib/essentialsService.ts
    - backend/src/routes/essentialsPoliticians.ts
    - backend/src/index.ts

key-decisions:
  - "GeocodingError propagates from service layer to route handler — no wrapping in service"
  - "essentialsPoliticians.ts rewritten to use getPoliticiansFlatList (flat list) not getPoliticiansGrouped (grouped)"
  - "index.ts mounts /api/essentials router after /politicians and /candidates mounts to avoid path shadowing"
  - "null string coercion to '' follows Go convention for flat politician records"

patterns-established:
  - "Address-search pattern: optionalAuth -> validate param -> geocodeAddress -> pool.query ST_Covers -> return { politicians, jurisdiction, data_level }"
  - "GeocodingError instanceof check with err.code: ADDRESS_NOT_FOUND=422, PO_BOX_REJECTED=422, GEOCODER_UNAVAILABLE=503"

# Metrics
duration: 4min
completed: 2026-03-20
---

# Phase 38 Plan 02: Address-Search Route + Go-Parity Politicians List Summary

**GET /api/essentials/address-search (Census Geocoder -> PostGIS ST_Covers -> politicians flat list) and Go-parity /api/essentials/politicians rewrite with district_id, district_type, and data_level tier signaling**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-20T19:31:44Z
- **Completed:** 2026-03-20T19:35:14Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Built `getRepresentativesByAddress`: geocodes address via Census, runs PostGIS ST_Covers query against `essentials.geofence_boundaries`, returns politicians + jurisdiction
- Built `getPoliticiansFlatList`: Go-parity flat list joining politicians → offices → districts → chambers → governments; null strings coerced to '' per Go convention
- Created `essentials.ts` router with full error handling for all GeocodingError codes (ADDRESS_NOT_FOUND 422, PO_BOX_REJECTED 422, GEOCODER_UNAVAILABLE 503)
- Rewrote `essentialsPoliticians.ts` to use flat list with data_level tier signaling
- Registered new `/api/essentials` router in `index.ts`

## Task Commits

1. **Task 1: Build address-search service functions + Go-parity politicians list** — `849e326` (feat)
2. **Task 2: Create essentials router + update politicians route** — `3cef488` (feat)

## Files Created/Modified

- `backend/src/lib/essentialsService.ts` — added `getRepresentativesByAddress`, `getPoliticiansFlatList`, `PoliticianFlatRecord`, `AddressSearchResult` interfaces
- `backend/src/routes/essentials.ts` — new router: GET /address-search with full GeocodingError handling
- `backend/src/routes/essentialsPoliticians.ts` — rewritten to use `getPoliticiansFlatList` (Go-parity flat list with data_level)
- `backend/src/index.ts` — added `essentialsRouter` import and `/api/essentials` mount

---

## PostGIS SQL Query (for Plan 03 to build on)

```sql
-- Address-search query: $1=longitude (Census x), $2=latitude (Census y)
SELECT p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
       p.preferred_name, p.name_suffix, p.party, p.photo_origin_url, p.web_form_url,
       p.urls, p.email_addresses, p.bio_text, p.slug,
       o.title AS office_title, o.representing_state, o.representing_city,
       d.district_type, d.label AS district_label, d.geo_id AS district_id,
       d.mtfcc,
       ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
       g.name AS government_name, g.is_elected, g.election_frequency
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.office_id = o.id
LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
LEFT JOIN essentials.governments g ON g.id = ch.government_id
WHERE public.ST_Covers(
  gb.geometry,
  public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
)
AND p.is_active = true
```

**Critical notes:**
- `gb.geometry` — PostGIS column is `geometry` (NOT `geom`)
- `$1=lng` (Census `coordinates.x`), `$2=lat` (Census `coordinates.y`)
- `d.geo_id = gb.geo_id` — text-to-varchar join, no FK constraint
- Zero rows → `{ politicians: [], jurisdiction: null }`

---

## Politician Response Shape (for Plan 03 and frontends)

```typescript
interface PoliticianFlatRecord {
  id: string;
  external_id: number | null;
  first_name: string;       // '' if null
  middle_initial: string;   // '' if null
  last_name: string;        // '' if null
  preferred_name: string;   // '' if null
  name_suffix: string;      // '' if null
  full_name: string;        // '' if null
  party: string;            // '' if null
  photo_origin_url: string; // '' if null
  web_form_url: string;     // '' if null
  urls: string[] | null;
  email_addresses: string[] | null;
  office_title: string;     // '' if null
  representing_state: string; // '' if null
  representing_city: string;  // '' if null
  district_type: string;    // '' if null
  district_label: string;   // '' if null
  district_id: string;      // geo_id ('' if null)
  mtfcc: string;            // '' if null
  chamber_name: string;     // '' if null
  chamber_name_formal: string; // '' if null
  government_name: string;  // '' if null
  is_elected: boolean;      // false if null
  election_frequency: string; // '' if null
  committees: null;         // always null (future use)
  bio_text: string | null;
  slug: string | null;
}

// address-search adds:
interface AddressSearchResponse extends AddressSearchResult {
  data_level: 'inform' | 'connected';
}
// where AddressSearchResult = { politicians: PoliticianFlatRecord[], jurisdiction: { district_type, district_id, district_label, mtfcc } | null }
```

---

## Decisions Made

- **GeocodingError propagates from service to route** — service layer does not catch GeocodingError; route handler owns all HTTP error translation. Clean separation of concerns.
- **essentialsPoliticians.ts rewritten** — switched from `getPoliticiansGrouped` (party-grouped shape) to `getPoliticiansFlatList` (Go-parity flat list). Breaking change to response shape intentional for Go parity.
- **index.ts mount order** — `/api/essentials/politicians` and `/api/essentials/candidates` mounted before `/api/essentials`; Express resolves more-specific mounts first, so no path conflict.
- **null → '' coercion** — matches Go server behavior where missing strings are empty strings, not null, in JSON responses.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- Plan 03 (politician detail routes) unblocked:
  - `PoliticianFlatRecord` interface exported from `essentialsService.ts`
  - PostGIS join pattern established (politicians → offices → districts → chambers → governments)
  - `data_level` tier signaling pattern established (copy from essentials.ts)
  - `pool.query()` pattern confirmed for all essentials queries
- Address-search endpoint live: GET /api/essentials/address-search?address=...
- Politicians flat list live: GET /api/essentials/politicians

---
*Phase: 38-express-ports-wave-3-essentials*
*Completed: 2026-03-20*
