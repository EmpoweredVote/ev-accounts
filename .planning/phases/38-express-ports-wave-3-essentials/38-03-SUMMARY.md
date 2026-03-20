---
phase: 38-express-ports-wave-3-essentials
plan: 03
subsystem: api
tags: [essentials, politicians, typescript, express, postgis, pool-query]

# Dependency graph
requires:
  - phase: 38-express-ports-wave-3-essentials
    provides: getPoliticiansFlatList, PoliticianFlatRecord interface, pool.query() pattern for essentials schema
  - phase: 38-express-ports-wave-3-essentials
    provides: Census Geocoder, verified join path (politicians -> offices -> districts -> chambers -> governments)

provides:
  - GET /api/essentials/politicians/:id — full politician profile with nested contacts, images, degrees, experiences
  - getPoliticianById() — exports PoliticianDetail interface with all nested arrays
  - PoliticianContact, PoliticianImage, PoliticianDegree, PoliticianExperience interfaces
  - Bug fix: is_elected derived from NOT o.is_appointed_position (governments table has no is_elected column)
  - Bug fix: election_frequency pulled from chambers table, not governments

affects:
  - 38-04: legislative data routes (can build on same join pattern)
  - 38-05: governments/chambers/districts routes (government_id and government fields confirmed)
  - any frontend consuming /api/essentials/politicians/:id (new endpoint, full profile shape documented here)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Promise.all for parallel nested queries (contacts, images, degrees, experiences) in single DB round-trips"
    - "UUID validation at route layer: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i → 422 VALIDATION_ERROR"
    - "is_elected derived: NOT COALESCE(o.is_appointed_position, false) — governments table has no is_elected column"
    - "election_frequency from chambers table, not governments — verified against live DB"
    - "Nested arrays always [] not null when no records found for politician_id FK queries"

key-files:
  created: []
  modified:
    - backend/src/lib/essentialsService.ts
    - backend/src/routes/essentialsPoliticians.ts

key-decisions:
  - "is_elected derived: NOT o.is_appointed_position — governments.is_elected column does not exist; derivation from office data is the correct approach"
  - "election_frequency from chambers, not governments — governments table only has id, name, type, state, city; chambers has election_frequency"
  - "Parallel nested queries via Promise.all — contacts, images, degrees, experiences are independent; no sequential dependency"
  - "Nested arrays return [] not null — consistent with Go convention for empty collections"
  - "UUID validation at route layer before service call — prevents unnecessary DB query for malformed input"

patterns-established:
  - "getPoliticianById pattern: base query + Promise.all([contacts, images, degrees, experiences]) — all with politician_id = $1"
  - "experience.end quoted: SELECT 'end' (reserved keyword in SQL requires quoting)"

# Metrics
duration: 6min
completed: 2026-03-20
---

# Phase 38 Plan 03: Politician Detail Endpoint Summary

**GET /api/essentials/politicians/:id with full profile (contacts, images, degrees, experiences) via parallel Promise.all queries; fixed is_elected/election_frequency bug (columns don't exist on governments table)**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-20T19:37:53Z
- **Completed:** 2026-03-20T19:44:11Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Queried live DB to confirm exact column locations: election_frequency on chambers (not governments), is_elected absent from all essentials tables
- Fixed runtime bug in getPoliticiansFlatList and getRepresentativesByAddress: removed non-existent g.is_elected and g.election_frequency references
- Added getPoliticianById() with Promise.all parallel nested queries (contacts, images, degrees, experiences)
- Added GET /:id route with UUID validation (422), 404 for missing, data_level tier signaling

## Task Commits

1. **Task 1: Query nested essentials tables + add getPoliticianById** — `61e91e2` (feat)
2. **Task 2: Add GET /:id route to essentialsPoliticians.ts** — `efe6af5` (feat)

## Files Created/Modified
- `backend/src/lib/essentialsService.ts` — Added PoliticianDetail interface (with 4 nested array interfaces), getPoliticianById(); fixed is_elected/election_frequency bug in getPoliticiansFlatList and getRepresentativesByAddress
- `backend/src/routes/essentialsPoliticians.ts` — Added GET /:id route (UUID validation, 404, data_level)

---

## PoliticianDetail Response Shape

```typescript
interface PoliticianDetail {
  // Identity
  id: string;
  external_id: number | null;
  first_name: string;        // '' if null
  middle_initial: string;    // '' if null
  last_name: string;         // '' if null
  preferred_name: string;    // '' if null
  name_suffix: string;       // '' if null
  full_name: string;         // '' if null
  party: string;             // '' if null
  party_short_name: string;  // '' if null
  // Contact / web
  photo_origin_url: string;  // '' if null
  web_form_url: string;      // '' if null
  urls: string[] | null;
  email_addresses: string[] | null;
  // Biography
  bio_text: string | null;
  slug: string | null;
  total_years_in_office: number | null;
  // Status flags
  is_incumbent: boolean;
  is_appointed: boolean;
  is_vacant: boolean;
  is_active: boolean;
  is_elected: boolean;       // derived: NOT o.is_appointed_position
  // Office details
  office_id: string | null;
  office_title: string;      // '' if null
  representing_state: string;
  representing_city: string;
  office_seats: number | null;
  is_appointed_position: boolean;
  // District details
  district_type: string;     // '' if null
  district_label: string;    // '' if null
  district_id: string;       // geo_id, '' if null
  district_state: string;    // '' if null
  mtfcc: string;             // '' if null
  // Chamber details
  chamber_name: string;      // '' if null
  chamber_name_formal: string; // '' if null
  election_frequency: string; // from chambers table, '' if null
  // Government details
  government_id: string | null;
  government_name: string;   // '' if null
  // Nested arrays (always [], never null, when no records exist)
  contacts: PoliticianContact[];
  images: PoliticianImage[];
  degrees: PoliticianDegree[];
  experiences: PoliticianExperience[];
  // Added by route
  data_level: 'inform' | 'connected';
}
```

## Nested Tables Queried

| Table | FK | Fields returned |
|-------|-----|-----------------|
| `essentials.politician_contacts` | `politician_id` | id, source, email, phone, fax, contact_type, website_url |
| `essentials.politician_images` | `politician_id` | id, url, type, photo_license |
| `essentials.degrees` | `politician_id` | id, degree, major, school, grad_year |
| `essentials.experiences` | `politician_id` | id, title, organization, type, start, end |

## DB Schema Findings (Task 1 investigation)

### governments table (id, name, type, state, city only)
- NO `is_elected` column — this column does not exist anywhere in essentials schema
- NO `election_frequency` column

### chambers table has election_frequency
- `election_frequency` text — e.g., "2 years", "4 years", null

### is_elected derivation
- Derived as `NOT COALESCE(o.is_appointed_position, false)` (inverted from offices.is_appointed_position)
- Confirmed against Go server example: `"is_elected": true` for non-appointed council member positions

---

## Decisions Made

- **is_elected from NOT is_appointed_position** — governments.is_elected doesn't exist. Offices.is_appointed_position is the correct inverse source. Elected = not appointed.
- **election_frequency from chambers** — verified in DB: chambers has election_frequency, governments does not. Previous code referenced g.election_frequency (wrong table; runtime error).
- **Promise.all for nested queries** — contacts/images/degrees/experiences are fully independent; parallel execution is correct and faster than sequential.
- **"end" column quoted in SQL** — experiences.end is a reserved SQL keyword; must be quoted as `"end"` in SELECT.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed non-existent is_elected and election_frequency columns on governments table**
- **Found during:** Task 1 (DB schema investigation before writing code)
- **Issue:** Existing `getPoliticiansFlatList` and `getRepresentativesByAddress` queries used `g.is_elected` and `g.election_frequency` (governments table alias). The governments table only has columns: id, name, type, state, city. These columns do not exist. Both functions would fail at runtime with "column g.is_elected does not exist".
- **Fix:** Changed `g.is_elected, g.election_frequency` to `o.is_appointed_position, ch.election_frequency`. Mapped `is_elected` as `!row.is_appointed_position` and `election_frequency` as `row.election_frequency ?? ''`.
- **Files modified:** backend/src/lib/essentialsService.ts
- **Verification:** `node -e "pool.query(...)"` against live DB — query returns correct data. Election frequency shows "2 years" for chambers with frequency set, null for others.
- **Committed in:** 61e91e2 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Critical correctness fix. Without this fix, the entire /api/essentials/politicians endpoint would fail at runtime. No scope creep.

## Issues Encountered

None beyond the bug documented above.

## Next Phase Readiness

- Plan 04 (legislative routes) is fully unblocked:
  - essentials schema table list confirmed (legislative_bills, legislative_votes, legislative_committee_memberships, etc.)
  - getPoliticianById established — Plan 04 can add legislative sub-routes (/politicians/:id/legislative, etc.)
  - is_elected/election_frequency pattern established and documented
- Politician detail endpoint live: GET /api/essentials/politicians/:id
- Full nested profile available for frontend consumption

---
*Phase: 38-express-ports-wave-3-essentials*
*Completed: 2026-03-20*
