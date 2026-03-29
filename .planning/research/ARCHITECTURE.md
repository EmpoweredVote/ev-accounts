# Architecture Research

**Domain:** Civic data platform — election/candidate feature integration into existing Essentials app
**Researched:** 2026-03-29
**Confidence:** HIGH — based on direct code inspection of ev-accounts, essentials, and CivicEngine API docs

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    essentials (Cloudflare Pages)                          │
│                                                                           │
│  /                    /results?q=<addr>    /elections?q=<addr>            │
│  Landing              Results              ElectionCentral (NEW)          │
│  (address entry)      (representatives)    (upcoming races)               │
│                                                                           │
│  /politician/:id      /candidate/:id                                      │
│  Profile              CandidateProfile     <- reused as-is                │
│                                                                           │
│  State: ?q= URL param (shared across /results and /elections)            │
│         sessionStorage ev:results (back-nav cache, Results only)         │
│         sessionStorage ev:election-results (NEW, Election Central cache) │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │ apiFetch (Bearer JWT, optional)
                             │ all routes under /api/
┌────────────────────────────▼─────────────────────────────────────────────┐
│               ev-accounts (Express/TypeScript, Render)                    │
│                                                                           │
│  EXISTING routes:                      NEW routes:                        │
│  POST /api/essentials/candidates/search  POST /api/elections/search       │
│  GET  /api/essentials/politicians/:id    GET  /api/elections/:id/races    │
│  GET  /api/essentials/politicians/:id/*                                   │
│                                                                           │
│  EXISTING services:                    NEW service:                       │
│  essentialsService.ts                  electionService.ts                 │
│  essentialsProfileService.ts                                              │
│  geocodingService.ts (shared)                                             │
│  cache.ts (shared)                                                        │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │ pool.query() -- essentials schema not in PostgREST
                             │ supabaseAnon -- public reads where RLS allows
┌────────────────────────────▼─────────────────────────────────────────────┐
│               Supabase PostgreSQL (PostGIS enabled)                       │
│                                                                           │
│  essentials schema (existing)          essentials schema (new tables)     │
│  +-- politicians                       +-- elections                      │
│  +-- offices                           +-- races                          │
│  +-- districts                         +-- race_candidates                │
│  +-- chambers                                                             │
│  +-- geofences (PostGIS)                                                  │
│  +-- election_records (per-politician                                     │
│  |   historical record, from BallotReady)                                 │
│  +-- politician_images, contacts, etc.                                    │
└──────────────────────────────────────────────────────────────────────────┘
                             │ nightly import script (Python or tsx)
┌────────────────────────────▼─────────────────────────────────────────────┐
│          CivicEngine GraphQL API (https://bpi.civicengine.com/graphql)   │
│          Address -> elections -> races -> candidacies -> candidates       │
│          Existing vendor relationship (BallotReady rebranded)            │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Responsibility | Status |
|-----------|----------------|--------|
| `essentials/src/pages/ElectionCentral.jsx` | Address input, fetch races, render grouped by org/position | NEW |
| `essentials/src/pages/Results.jsx` | Add elected/appointed filter toggle | MODIFIED |
| `essentials/src/lib/classify.js` | Elected/appointed filter logic using existing `is_elected` field | MODIFIED |
| `essentials/src/pages/CandidateProfile.jsx` | Full profile for election candidates | REUSED as-is |
| `ev-accounts/src/routes/elections.ts` | `POST /api/elections/search`, `GET /api/elections/:id/races` | NEW |
| `ev-accounts/src/lib/electionService.ts` | DB queries against new election tables | NEW |
| `essentials.elections` (DB table) | Stores imported election events (date, name, type) | NEW |
| `essentials.races` (DB table) | One row per position in an election, with geo_id+mtfcc for geofence lookup | NEW |
| `essentials.race_candidates` (DB table) | One row per person running, links to politicians where matched | NEW |
| Import script | Pulls CivicEngine `races` query by lat/lng, upserts to DB, runs nightly | NEW |

---

## Recommended Project Structure

```
ev-accounts/backend/src/
+-- routes/
|   +-- elections.ts             # NEW - POST /search, GET /:id/races
|   +-- essentialsCandidates.ts  # EXISTING - no change needed
+-- lib/
|   +-- electionService.ts       # NEW - DB queries for elections/races/candidates
|   +-- essentialsService.ts     # EXISTING - no change (filter is frontend-only)
|   +-- geocodingService.ts      # EXISTING - shared, no change
+-- migrations/
    +-- 042_elections_schema.sql # NEW - elections, races, race_candidates tables

essentials/src/
+-- pages/
|   +-- ElectionCentral.jsx      # NEW - Election Central page
|   +-- Results.jsx              # MODIFIED - elected/appointed filter toggle
+-- components/
|   +-- ElectionGroup.jsx        # NEW - renders one election with its races
|   +-- RaceCard.jsx             # NEW - renders one race/position with candidates
+-- hooks/
|   +-- useElectionData.js       # NEW - mirrors usePoliticianData pattern
+-- lib/
|   +-- api.jsx                  # MODIFIED - add fetchElections()
|   +-- classify.js              # MODIFIED - add filterByAppointmentStatus()
+-- App.jsx                      # MODIFIED - add /elections route
```

---

## Question 1: New Tables vs Extending Existing Tables

### Recommendation: Three new tables in the essentials schema

The existing `essentials.election_records` table is a per-politician historical win/loss record (from the now-decommissioned BallotReady import). It is structurally incompatible with Election Central because:
- It is politician-keyed, not election-keyed
- It has no concept of races grouping multiple candidates for the same seat
- It carries historical results, not upcoming contested races

**New tables needed:**

```sql
-- One row per election event
CREATE TABLE essentials.elections (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id  TEXT UNIQUE,          -- CivicEngine election ID
  name         TEXT NOT NULL,
  election_day DATE NOT NULL,
  state        TEXT,
  is_primary   BOOLEAN NOT NULL DEFAULT FALSE,
  is_runoff    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- One row per position being contested in an election
CREATE TABLE essentials.races (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id    TEXT UNIQUE,        -- CivicEngine race ID
  election_id    UUID NOT NULL REFERENCES essentials.elections(id) ON DELETE CASCADE,
  position_name  TEXT NOT NULL,
  organization   TEXT NOT NULL,      -- for UI grouping ("City of Bloomington")
  seats          INT NOT NULL DEFAULT 1,
  is_partisan    BOOLEAN,
  is_recall      BOOLEAN NOT NULL DEFAULT FALSE,
  is_runoff      BOOLEAN NOT NULL DEFAULT FALSE,
  is_unexpired   BOOLEAN NOT NULL DEFAULT FALSE,
  geo_id         TEXT,               -- from CivicEngine position.geoId
  mtfcc          TEXT,               -- from CivicEngine position.mtfcc
  created_at     TIMESTAMPTZ DEFAULT now(),
  updated_at     TIMESTAMPTZ DEFAULT now()
);

-- One row per candidate per race
CREATE TABLE essentials.race_candidates (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  race_id        UUID NOT NULL REFERENCES essentials.races(id) ON DELETE CASCADE,
  politician_id  UUID REFERENCES essentials.politicians(id),  -- NULL if not in our DB
  external_id    TEXT,               -- CivicEngine candidacy ID
  first_name     TEXT NOT NULL,
  last_name      TEXT NOT NULL,
  is_incumbent   BOOLEAN NOT NULL DEFAULT FALSE,
  is_certified   BOOLEAN NOT NULL DEFAULT TRUE,
  withdrawn      BOOLEAN NOT NULL DEFAULT FALSE,
  result         TEXT,               -- NULL until election is over
  created_at     TIMESTAMPTZ DEFAULT now(),
  updated_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_races_election_id ON essentials.races(election_id);
CREATE INDEX idx_races_geo_id_mtfcc ON essentials.races(geo_id, mtfcc);
CREATE INDEX idx_race_candidates_race_id ON essentials.race_candidates(race_id);
CREATE INDEX idx_race_candidates_politician_id ON essentials.race_candidates(politician_id);
CREATE INDEX idx_elections_election_day ON essentials.elections(election_day);
```

**The is_appointed field situation:** `is_appointed_position` on `essentials.offices` is already populated and drives `is_elected` in the existing API response (`is_elected = NOT COALESCE(o.is_appointed_position, false)` — from essentialsService.ts line 449). The elected/appointed filter needs no new DB columns. Data quality of `is_appointed_position` should be validated before making it a prominent UI filter — some BallotReady-sourced values may be stale.

---

## Question 2: Address Context Sharing Between Results and Election Central

### Recommendation: Shared ?q= URL param, separate page routes

The existing Results page pattern:
- Address comes in via `?q=<address>` URL param
- User can also re-enter an address on the page
- `sessionStorage ev:results` caches rendered data for back-navigation

Election Central mirrors this exactly:

```
/results?q=123+Main+St+Bloomington+IN    <- existing representatives
/elections?q=123+Main+St+Bloomington+IN  <- new election races
```

**Cross-page navigation:** When the user has a formattedAddress from a completed Results search, link to `/elections?q=${encodeURIComponent(formattedAddress)}`. The Election Central page initializes its address bar from the URL param, skips the geocoding step if the address is already validated, and fetches election data immediately.

**SessionStorage:** Use `ev:election-results` (separate key from `ev:results`) for Election Central's back-nav cache.

**Why a separate page, not a tab in Results:** The data model is fundamentally different — "who represents me today" vs "who is running for office." Civic platforms (Vote.org, Ballotpedia, Vote411) all present these as distinct entry points. Mixing them in one page creates UX confusion and significantly complicates the Results page which is already the most complex component in the codebase (~900 lines).

---

## Question 3: API Endpoint Design for Election Data

### Recommendation: New route prefix /api/elections/

Keep elections separate from `/api/essentials/` to maintain clear domain boundaries. The essentials routes handle current officeholders; elections handle upcoming contests.

**Endpoints:**

```
POST /api/elections/search
  Body:    { address: string }
  Returns: ElectionSearchResult[]
  Headers: X-Formatted-Address (backend-validated address)
  Auth:    optionalAuth

GET /api/elections/:electionId/races
  Returns: Race[] with candidates for a specific election
  Auth:    optionalAuth
```

**Response shape for POST /api/elections/search:**

```typescript
interface ElectionSearchResult {
  election: {
    id: string;
    name: string;
    election_day: string;       // "2027-05-06"
    is_primary: boolean;
  };
  races: Array<{
    id: string;
    position_name: string;
    organization: string;       // for UI grouping
    seats: number;
    is_partisan: boolean | null;
    candidates: Array<{
      id: string;
      politician_id: string | null;  // link to full profile if in our DB
      first_name: string;
      last_name: string;
      is_incumbent: boolean;
      withdrawn: boolean;
    }>;
  }>;
}
```

**Implementation pattern:** Uses the same `geocodeAddress()` + PostGIS ST_Covers geofence lookup as `getRepresentativesByAddress()`. After getting matched geofence `geo_id+mtfcc` pairs, JOIN against `essentials.races` to find upcoming races in those geofences, then JOIN `elections` and `race_candidates`.

**Caching:** Use existing `cache.ts` with a 24-hour TTL keyed on a hash of the matched geofence IDs. Much longer than the 90-day officeholder cache is fine — election data only changes when the nightly import runs.

**Why not extend existing endpoints:** `POST /essentials/candidates/search` returns `PoliticianFlatRecord[]` — a flat array with a specific contract that the Results page depends on. Adding elections would require either a breaking change or an awkward response envelope. A new endpoint with its own response type is the correct separation.

---

## Question 4: Frontend Routing

### Recommendation: /elections as a peer route to /results in App.jsx

```jsx
// App.jsx - add this route
<Route path="/elections" element={<ElectionCentral />} />
// All existing routes unchanged
```

**Navigation integration:** Add an "Elections" tab/link in the Results page header. When the user has an active address, the link carries `?q=` forward — same pattern as Read & Rank's `?address=` passthrough from v2026.3.6.

**ElectionCentral page structure:**

```
ElectionCentral
+-- Address search bar (reuse useGooglePlacesAutocomplete hook from Results)
+-- useElectionData hook (mirrors usePoliticianData)
+-- Results grouped display:
    +-- ElectionGroup (one per election, sorted by election_day ascending)
    |   +-- Header: "May 6, 2027 - Bloomington City Primary"
    |   +-- RaceCard[] grouped by organization then position
    |       +-- Position title ("City Council - District 1")
    |       +-- Organization badge ("City of Bloomington")
    |       +-- Incumbent indicator
    |       +-- Candidate list (linked to /politician/:id or /candidate/:id where matched)
    +-- Empty state if no upcoming elections found for address
```

**Elected/Appointed filter on Results:**

The `is_elected` field is already in every `PoliticianFlatRecord` response. The filter is purely frontend — no API or service changes needed.

```javascript
// classify.js addition
export function filterByAppointmentStatus(politicians, filter) {
  if (filter === 'all') return politicians;
  if (filter === 'elected') return politicians.filter(p => p.is_elected === true);
  if (filter === 'appointed') return politicians.filter(p => p.is_elected === false);
  return politicians;
}
```

**Retention judges:** Retention judges have `is_appointed_position = false` in the current schema (they face voters on a retention ballot). `is_elected` = `NOT is_appointed_position` = `true`. They correctly appear under the Elected filter. If data quality issues exist, a fallback check against `essentials.judge_details.election_type = 'retention'` can override classification.

---

## Question 5: Data Import Pipeline for Election Data

### Recommendation: CivicEngine GraphQL API, nightly import script

**Why CivicEngine:** The workspace already has CivicEngine API documentation and the BallotReady data dictionary — this is an existing vendor relationship (BallotReady rebranded as CivicEngine). The `races` query accepts `location: { point: { latitude, longitude } }` and returns nested election, position (with geo_id/mtfcc), and candidacy data in a single request.

**Import script approach** (Python or tsx, consistent with existing pipeline scripts):

1. Query CivicEngine `races` for Bloomington IN coordinates with `electionDay: { gte: today }`
2. Query CivicEngine `races` for LA County coordinates with the same filter
3. Upsert `essentials.elections`, `essentials.races`, `essentials.race_candidates` (ON CONFLICT external_id DO UPDATE)
4. Best-effort name-match `race_candidates` to `essentials.politicians` by full name within same geo_id scope
5. Invalidate election cache keys
6. Run nightly via Render cron job or manual trigger

**CivicEngine query for import:**

```graphql
query getUpcomingRaces($lat: Float!, $lng: Float!, $afterDate: ISO8601Date!) {
  races(
    filterBy: { electionDay: { gte: $afterDate } }
    location: { point: { latitude: $lat, longitude: $lng } }
    orderBy: { field: ELECTION_DAY, direction: ASC }
  ) {
    nodes {
      id
      databaseId
      isPrimary
      isRecall
      isRunoff
      isUnexpired
      seats
      election {
        id
        name
        electionDay
        state
      }
      position {
        name
        geoId
        mtfcc
        level
        places { nodes { name } }
      }
      candidacies(includeUncertified: false) {
        id
        isCertified
        withdrawn
        result
        candidate { id firstName lastName }
      }
    }
  }
}
```

**Geofence matching for user queries:** The `geo_id` + `mtfcc` columns on `essentials.races` (populated from `position.geoId` + `position.mtfcc` during import) enable the same PostGIS join used by `getRepresentativesByAddress()`. The election search endpoint geocodes the user's address, gets matched geofence IDs via ST_Covers, then JOINs `races` on `geo_id + mtfcc IN (matched values)`. No live CivicEngine calls per user request.

---

## Data Flow

### Election Central request flow

```
User enters address
    |
    v
ElectionCentral -> useElectionData hook
    |
    v
POST /api/elections/search  { address }
    |
    v
electionService.searchElectionsByAddress(address)
    |
    +-- geocodingService.geocodeAddress(address)  [Census Geocoder - existing]
    |
    +-- getGeofencesByPoint(lat, lng)  [PostGIS ST_Covers - existing]
    |
    +-- SQL:
    |   SELECT e.*, r.*, rc.*
    |   FROM essentials.races r
    |   JOIN essentials.elections e ON e.id = r.election_id
    |   JOIN essentials.race_candidates rc ON rc.race_id = r.id
    |   WHERE (r.geo_id, r.mtfcc) IN (matched geofence pairs)
    |     AND e.election_day >= today
    |   ORDER BY e.election_day ASC, r.organization, r.position_name
    |
    v
Return ElectionSearchResult[] with X-Formatted-Address header
    |
    v
ElectionCentral renders: grouped by election date, then organization
```

### Elected/Appointed filter flow

```
User toggles filter on Results page
    |
    v
appointmentFilter state ('all' | 'elected' | 'appointed') in Results.jsx
    |
    v
filteredPoliticians = filterByAppointmentStatus(politicians, appointmentFilter)
    |
    v
classify() runs on filtered list -> sections re-render
No network request - entirely client-side
```

### Import pipeline flow

```
Nightly trigger (cron or manual)
    |
    v
CivicEngine GraphQL: races(location: Bloomington IN lat/lng, electionDay: >= today)
CivicEngine GraphQL: races(location: LA County lat/lng, electionDay: >= today)
    |
    v
Upsert essentials.elections ON CONFLICT (external_id) DO UPDATE
Upsert essentials.races ON CONFLICT (external_id) DO UPDATE
Upsert essentials.race_candidates ON CONFLICT (external_id) DO UPDATE
    |
    v
Best-effort name match: race_candidates -> essentials.politicians
    |
    v
Invalidate cache keys: elections:geofences:*
```

---

## Integration Points

### New: ev-accounts/backend/src/routes/elections.ts

Wire into `index.ts`:

```typescript
import electionsRouter from './routes/elections.js';
app.use('/api/elections', electionsRouter);
```

Architecture rule: `routes/elections.ts` calls `electionService.ts` functions only. Direct `pool.query()` or `supabaseAdmin` calls in route files are banned by `architecture.test.ts`.

### New: ev-accounts/backend/src/lib/electionService.ts

Uses `pool.query()` directly (not supabaseAnon) because the essentials schema is not in the PostgREST exposed schema list — consistent with how `essentialsService.ts` and `essentialsProfileService.ts` work.

Shares `geocodingService.geocodeAddress()` with `essentialsService.ts` — no duplication.

### Modified: essentials/src/App.jsx

Add `/elections` route. All existing routes (`/results`, `/politician/:id`, `/candidate/:id`) unchanged.

### Modified: essentials/src/pages/Results.jsx

Add filter toggle component. The `is_elected` field is already in the response. Filter state is local to Results — no changes to `usePoliticianData` hook or API calls.

### Modified: essentials/src/lib/classify.js

Add `filterByAppointmentStatus(politicians, filter)` function. No changes to existing `classifyCategory()` or `orderedEntries()` logic.

### Modified: essentials/src/lib/api.jsx

Add `fetchElections(address)` function that calls `POST /api/elections/search`.

### Existing: essentials/src/pages/CandidateProfile.jsx

No changes needed. Candidates with a `politician_id` match link to `/politician/:id`. For unmatched candidates (no politician_id), the simplest path is to link to the `/candidate/:id` page if a lightweight profile is needed, or display inline in the RaceCard without a link.

---

## Build Order (Dependencies Considered)

**Phase 1 — Database schema and import (unblocks everything)**
1. Write and apply `042_elections_schema.sql`
2. Write CivicEngine import script for Bloomington IN + LA County CA
3. Verify data quality: elections, races, race_candidates rows present with correct geo_id/mtfcc
4. Validate geo_id/mtfcc values match existing `essentials.geofences` table entries

**Phase 2 — Backend election search endpoint**
5. Write `electionService.ts` with `searchElectionsByAddress()`
6. Write `routes/elections.ts` with `POST /search`
7. Wire into `index.ts`, add to 62-route manifest for architecture test
8. Integration test with Bloomington address, verify response shape

**Phase 3 — Election Central frontend**
9. Write `useElectionData.js` hook (mirror usePoliticianData)
10. Add `fetchElections()` to `api.jsx`
11. Write `ElectionGroup.jsx` and `RaceCard.jsx` components
12. Write `ElectionCentral.jsx` page with address search
13. Add `/elections` route to `App.jsx`
14. Add Elections nav link in Results header with ?q= passthrough

**Phase 4 — Elected/Appointed filter on Results**
15. Add `filterByAppointmentStatus()` to `classify.js`
16. Add filter toggle UI to `Results.jsx` (local state, no hook changes)
17. Validate retention judge behavior with known test politicians
18. Test with Bloomington + LA County addresses

**Phase 5 — Candidate profile links**
19. Link candidates with `politician_id` to `/politician/:id`
20. Decide on experience for unmatched candidates (inline display vs stub page)

---

## Anti-Patterns

### Anti-Pattern 1: Live CivicEngine proxying per user request

**What people do:** Forward each `/api/elections/search` call directly to CivicEngine GraphQL.

**Why it's wrong:** CivicEngine rate limits apply, adds 200-800ms latency per request, election data changes at most daily, and the auth token cannot be safely used in a per-request path under load.

**Do this instead:** Nightly import into local DB. Serve from DB with 24h cache. Consistent with how Congress.gov, LegiScan, and OnBoard data are handled in this project.

### Anti-Pattern 2: Extending POST /essentials/candidates/search

**What people do:** Add an `includeElections` query param and append election data to the existing endpoint response.

**Why it's wrong:** That endpoint returns `PoliticianFlatRecord[]` — a flat array. Elections require a structurally different response (grouped by election, then race, then candidates). Changing the response shape would break Results page.

**Do this instead:** New `POST /api/elections/search` endpoint with its own response type.

### Anti-Pattern 3: Frontend-only filter via new API query param

**What people do:** Add `?elected=true` to `POST /essentials/candidates/search` and filter at the DB level.

**Why it's wrong:** `is_elected` is already returned in every response. DB-level filtering saves negligible payload at this scale (50-200 records), requires changes to service interface, route, and hook, and adds a tested query branch. Frontend filtering in classify.js is simpler, zero-risk, and sufficient.

**Do this instead:** `filterByAppointmentStatus()` in classify.js operating on the already-fetched array.

### Anti-Pattern 4: Repurposing election_records for upcoming races

**What people do:** Add upcoming race rows to `essentials.election_records` since it has "election" in the name.

**Why it's wrong:** `election_records` is per-politician historical data (past wins/losses). It has no race grouping, no org grouping, no geofence linkage, and no concept of contested seats with multiple candidates.

**Do this instead:** New `elections` + `races` + `race_candidates` tables as described above.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Current (2 geographies, ~50-200 races) | Nightly import, 24h cache, single SQL JOIN — adequate |
| 10 states, ~2000 races | Add compound index on (election_day, geo_id, mtfcc); still single query |
| National, 50K+ races | Separate elections schema; paginate Election Central; consider pre-computed race lookup table by geofence |

---

## Sources

- Direct code inspection: `ev-accounts/backend/src/lib/essentialsService.ts` — is_elected derivation (line 449), address search flow, geofence matching
- Direct code inspection: `ev-accounts/backend/src/lib/essentialsProfileService.ts` — election_records table structure, stances query pattern
- Direct code inspection: `ev-accounts/backend/src/routes/essentialsCandidates.ts` — POST /search endpoint pattern, optionalAuth usage
- Direct code inspection: `ev-accounts/backend/src/lib/candidateService.ts` — service layer pattern, cache.ts usage
- Direct code inspection: `essentials/src/pages/Results.jsx` — address flow (sessionStorage, ?q= param), showCandidates toggle pattern
- Direct code inspection: `essentials/src/hooks/usePoliticianData.js` — hook pattern to mirror for useElectionData
- Direct code inspection: `essentials/src/App.jsx` — routing structure
- Direct code inspection: `essentials/src/lib/api.jsx` — API call patterns, apiFetch usage
- Direct file inspection: `CivicEngine GraphQL API Documentation.md` — races/elections/candidacies schema, location filter, Relay pagination
- Direct file inspection: `BallotReadyDataDictionary.csv` — is_appointed field semantics, candidacy_id concept
- `.planning/PROJECT.md` — v2026.3.8 milestone requirements

---

*Architecture research for: Election Central integration into Essentials*
*Researched: 2026-03-29*
