# Phase 38: Express Ports Wave 3 — Essentials - Research

**Researched:** 2026-03-20
**Domain:** Express route + service layer for essentials schema; Census Geocoder + PostGIS geofence; Go server parity analysis
**Confidence:** HIGH (codebase), MEDIUM (essentials.geofence_boundaries column structure — see open questions)

---

## Summary

Phase 38 ports all ~25 essentials routes from the Go server to the ev-accounts Express API. The implementation pattern is fully established from phases 36 and 37: route file → service file → `pool.query()`. No new libraries are required. The essentials schema (36 tables, 206k+ rows) is already live and RLS-protected in production.

The core technical challenge is the address-search flow: Census Geocoder → PostGIS geofence → politicians. The Census Geocoder (`geocoding.geo.census.gov`) is free, returns lat/lng as `x`/`y` coordinates (x=longitude, y=latitude), and indicates no-match by returning an empty `addressMatches` array. The existing `resolve_user_jurisdiction` RPC demonstrates the correct PostGIS query pattern using `ST_Covers` against `inform.district_boundaries`; Phase 38 needs the analogous pattern against `essentials.geofence_boundaries`.

**Key discovery:** The Go server's `/essentials/politicians/:id` route is currently broken (returns 400) and `/essentials/candidates/:zip` returns empty arrays for all tested Indiana ZIPs. The Go server only reliably serves `GET /essentials/politicians` (the flat list). Phase 38 routes for politician detail, legislative data, governments, chambers, and districts are effectively greenfield builds from the essentials schema — not ports of working Go routes. "Go parity" applies to response shape (which can be inferred from the schema + the politicians list response), not from observing working Go endpoints.

**Primary recommendation:** Build Phase 38 as three service domains — geocodingService (Census rewrite), essentialsPoliticiansService (extended profile + address-search), and essentialsLegislativeService (bills/votes/committees) — using the established `pool.query()` pattern throughout.

---

## Standard Stack

No new libraries needed. All tools already present.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `pg` (pool) | existing | All essentials schema queries | essentials not in PostgREST exposed schema list — pool.query() only |
| Express Router | existing | Route file structure | All 22 existing route files use this pattern |
| `@upstash/redis` (cache) | existing | 24hr geocoder result caching | cache.ts already wraps this; use `cache.get/set/del` |
| `optionalAuth` middleware | existing | All essentials routes | Defined in middleware/auth.ts; exports `optionalAuth` |
| `zod` | existing | No new route validation needed (all GET, no body validation) | Used in staging.ts for body validation |

### No New Libraries
Census Geocoder is a free HTTP API requiring only `fetch()` (Node 18+ built-in). No npm package needed.

**Installation:** None required.

---

## Architecture Patterns

### Recommended File Structure

```
backend/src/
├── routes/
│   └── essentials.ts              # All /api/essentials/* routes (replace split files)
│       OR keep split:
│   ├── essentialsPoliticians.ts   # Extended to match Go response shape
│   └── essentialsAddress.ts       # New: address-search, governments, chambers, districts
└── lib/
    ├── geocodingService.ts        # REWRITE: Census Geocoder replaces Google Maps
    ├── essentialsService.ts       # EXTEND: politician list, politician detail, address-search
    └── essentialsLegislativeService.ts  # NEW: bills, votes, committees (or add to essentialsService)
```

Register in `backend/src/index.ts` — the existing `essentialsPoliticians` and `essentialsCandidates` routes are mounted separately. Phase 38 should introduce a unified `/api/essentials` router or mount new route files at their respective paths.

### Pattern 1: Public Read Route with optionalAuth

```typescript
// Source: backend/src/routes/essentialsPoliticians.ts (existing pattern)
import { Router } from 'express';
import { optionalAuth } from '../middleware/auth.js';
import type { Request, Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth.js';

const router = Router();

router.get('/address-search', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const userId = (req as AuthenticatedRequest).userId; // undefined if unauthenticated
  const address = typeof req.query.address === 'string' ? req.query.address : null;
  if (!address) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'address query parameter is required' });
    return;
  }
  try {
    const result = await getRepresentativesByAddress(address, userId ?? null);
    const dataLevel = userId ? 'connected' : 'inform';
    res.status(200).json({ ...result, data_level: dataLevel });
  } catch (err) {
    if (err instanceof GeocodingError) {
      if (err.code === 'ADDRESS_NOT_FOUND') {
        res.status(422).json({ code: 'ADDRESS_NOT_FOUND', message: err.message });
        return;
      }
      if (err.code === 'GEOCODER_UNAVAILABLE') {
        res.status(503).json({ code: 'GEOCODER_UNAVAILABLE', message: 'Address lookup temporarily unavailable.' });
        return;
      }
    }
    console.error('[GET /essentials/address-search] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

### Pattern 2: Census Geocoder Rewrite

The existing `geocodingService.ts` uses Google Maps (GOOGLE_MAPS_API_KEY). Phase 38 replaces the entire file with Census Geocoder implementation. The `env.ts` must remove `GOOGLE_MAPS_API_KEY` (currently required) and make it optional or remove it.

```typescript
// Census Geocoder — locations endpoint (no FIPS, just lat/lng — faster)
// Use this for address-search since we query our own geofence_boundaries
const url = new URL('https://geocoding.geo.census.gov/geocoder/locations/onelineaddress');
url.searchParams.set('address', normalizedAddress);
url.searchParams.set('benchmark', 'Public_AR_Current');
url.searchParams.set('format', 'json');

// 5-second timeout — CONTEXT.md decision
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 5000);

const response = await fetch(url.toString(), { signal: controller.signal });
clearTimeout(timeout);

// Empty addressMatches = no match (ADDRESS_NOT_FOUND)
// The batch API has matchStatus 'Match'/'No_Match' but single-address API uses array emptiness
const matches = data.result.addressMatches;
if (!matches || matches.length === 0) {
  throw new GeocodingError('ADDRESS_NOT_FOUND', "We couldn't find that address.");
}

// coordinates.x = longitude, coordinates.y = latitude (Census convention)
const { x: lng, y: lat } = matches[0].coordinates;
```

**CRITICAL:** Census coordinates use `x` (longitude) and `y` (latitude) — opposite of what most APIs expect. PostGIS `ST_MakePoint` takes (longitude, latitude) = (x, y) — same order as Census.

### Pattern 3: PostGIS Geofence Query

Based on the existing `connect.resolve_user_jurisdiction` RPC pattern (confirmed working in production), adapted for `essentials.geofence_boundaries`:

```sql
-- Source: supabase/migrations/20260310000032_location_rpcs.sql (resolve_user_jurisdiction pattern)
-- LONGITUDE FIRST in ST_MakePoint (PostGIS convention: X=lng, Y=lat)
-- ST_Covers preferred over ST_Contains (handles boundary-coincident points)
-- SRID 4326 (WGS84) must match geofence_boundaries.geom SRID

SELECT p.*
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id  -- or however the join works
JOIN essentials.geofence_boundaries g ON g.district_id = o.district_id  -- verify join columns
WHERE public.ST_Covers(
  g.geom,
  public.ST_SetSRID(public.ST_MakePoint($1, $2), 4326)  -- $1=lng, $2=lat
)
AND p.is_active = true;
```

**OPEN QUESTION:** The exact join path from `essentials.geofence_boundaries` to `essentials.politicians` must be verified before writing the query. See Open Questions section. The planner MUST include a task to query the column structure of `essentials.geofence_boundaries`, `essentials.districts`, and `essentials.offices` before writing the PostGIS query.

### Pattern 4: Redis Cache for Geocoder Results

```typescript
// Source: backend/src/lib/cache.ts (existing cache pattern)
// Key: normalize address to lowercase, collapse whitespace
const cacheKey = `geocode:${address.toLowerCase().replace(/\s+/g, ' ').trim()}`;
const cached = await cache.get<{ lat: number; lng: number }>(cacheKey);
if (cached) return cached;

// ... geocode ...
await cache.set(cacheKey, { lat, lng }, 86400); // 24hr = 86400 seconds
```

### Pattern 5: Tier-Differentiated Response

```typescript
// userId is undefined if optionalAuth found no valid token
const userId = (req as AuthenticatedRequest).userId;
const dataLevel: 'inform' | 'connected' = userId ? 'connected' : 'inform';

// Base data always included
const response = { politicians: [...], jurisdiction: {...} };

// Connected-tier additive fields (empowered_profiles columns)
if (userId) {
  // Augment relevant politicians with their empowered_profiles data
  // Only for politicians who ARE in empowered_profiles
}

res.status(200).json({ ...response, data_level: dataLevel });
```

### Pattern 6: Router File Organization

The existing routes mount `essentialsCandidates` and `essentialsPoliticians` separately in index.ts:
```typescript
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);
```

New Phase 38 routes add:
```typescript
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);  // UPDATED (extends existing)
app.use('/api/essentials', essentialsRouter);  // NEW: address-search, governments, chambers, districts
```

**Note:** The existing `essentialsPoliticiansRouter` handles `GET /` — the new politicians detail routes (`/:id`, `/:id/legislative`, etc.) should be added to the same file or a unified essentials router. Subpath routes MUST be defined BEFORE `/:id` to prevent Express path matching "legislative" as an ID (pattern from staging.ts).

### Anti-Patterns to Avoid

- **Never use `supabaseAdmin.schema('essentials')` or PostgREST** — essentials is NOT in the PostgREST exposed schema list. Runtime failure guaranteed. Use `pool.query()` only.
- **Never spread DB rows into responses** — map to explicit field whitelists.
- **Never use ioredis** — project uses `@upstash/redis` HTTP client.
- **Never log or return raw lat/lng in API responses** — privacy contract from geocodingService. Return only politician lists and jurisdiction metadata.
- **Never place `/:id` before specific subpaths** — `/:id/legislative` must be defined before `/:id` in the router (same pattern as staging.ts lines 85-178).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Geocoder caching | Custom cache layer | `cache.get/set` from lib/cache.ts | Already wraps Upstash Redis with in-memory fallback |
| Optional auth | Custom token extraction | `optionalAuth` from middleware/auth.ts | Already handles Bearer-only, invalid-token passthrough |
| DB connection | New pg.Pool instance | `pool` from lib/db.ts | Single pool with correct SSL config for Supabase |
| Address normalization | Custom normalization logic | Simple `.toLowerCase().trim().replace(/\s+/g, ' ')` for cache key only | Cache key doesn't need complex normalization |
| PostGIS geofence match | Custom boundary matching | Standard `ST_Covers(geom, ST_SetSRID(ST_MakePoint(lng, lat), 4326))` SQL | Battle-tested in existing `resolve_user_jurisdiction` RPC |

**Key insight:** The Census Geocoder is stateless HTTP — no SDK needed. The existing `cache.ts` handles all persistence. The existing `optionalAuth` handles all auth variance.

---

## Common Pitfalls

### Pitfall 1: Census Coordinate Order (x=lng, y=lat)
**What goes wrong:** Passing `lat` as the x coordinate to `ST_MakePoint` — query returns zero results or wrong politicians.
**Why it happens:** Census uses `coordinates.x` for longitude and `coordinates.y` for latitude, which is backwards from how most people think (lat first). PostGIS also uses longitude-first in `ST_MakePoint`.
**How to avoid:** Always use `matches[0].coordinates.x` for longitude and `matches[0].coordinates.y` for latitude. Comment every `ST_MakePoint` call with `-- (longitude, latitude) = (x, y)`.
**Warning signs:** address-search returns empty `politicians: []` for addresses that should have results.

### Pitfall 2: Google Maps env var still required
**What goes wrong:** After rewriting `geocodingService.ts`, `env.ts` still has `GOOGLE_MAPS_API_KEY: z.string().min(1)` (required, not optional). Server crashes at startup on environments without the key.
**Why it happens:** env.ts validates all vars at startup. The key is currently required.
**How to avoid:** Change `GOOGLE_MAPS_API_KEY` to `z.string().optional()` in `env.ts` as part of the geocodingService rewrite. Confirm no other code references it.
**Warning signs:** Server fails to start with "Missing or invalid environment variables: GOOGLE_MAPS_API_KEY".

### Pitfall 3: Subpath routes defined after /:id
**What goes wrong:** `GET /essentials/politicians/legislative` matches `/:id` with id="legislative" instead of `/:id/legislative`.
**Why it happens:** Express matches routes in definition order. If `/:id` is defined first, "legislative" is captured as an ID.
**How to avoid:** Define all subpath routes (`/:id/legislative`, `/:id/committees`, etc.) BEFORE the `/:id` route. This is the established pattern from staging.ts (lines 85-178: subpath routes before `/:id`).
**Warning signs:** 400 or wrong response when hitting `GET /essentials/politicians/:id/legislative`.

### Pitfall 4: Using PostgREST / supabaseAdmin.schema('essentials')
**What goes wrong:** Runtime error "schema not in exposed schemas list" for any essentials query via PostgREST.
**Why it happens:** essentials is not in the PostgREST exposed schema list (`public, connect, empower, inform, graphql_public, validation_quests`). See MEMORY.md Critical Production Pattern.
**How to avoid:** All essentials reads use `pool.query()`. Never `supabaseAdmin.schema('essentials')`.
**Warning signs:** PostgREST 406 or 400 errors at runtime.

### Pitfall 5: fetch() timeout not enforced
**What goes wrong:** Census Geocoder call hangs indefinitely during an outage, blocking the route handler.
**Why it happens:** Node.js `fetch()` has no default timeout. The Census API can be slow under load.
**How to avoid:** Always use `AbortController` with `setTimeout` for the 5-second timeout. Catch `AbortError` and throw `GeocodingError('GEOCODER_UNAVAILABLE', ...)`.
**Warning signs:** Routes hang for 30+ seconds during Census API slowness.

### Pitfall 6: Missing PostgREST geofence join path
**What goes wrong:** PostGIS query written without knowing actual column names in geofence_boundaries — query fails at runtime.
**Why it happens:** The `essentials.geofence_boundaries` table was migrated from the Go backend database. No CREATE TABLE SQL exists in this repo's migrations. Column structure must be queried from the live database.
**How to avoid:** First task in Phase 38 must query column structure of `essentials.geofence_boundaries`, `essentials.districts`, `essentials.offices` to establish the exact join path. Do not write the PostGIS query until this is confirmed.
**Warning signs:** SQL error "column X does not exist" at runtime.

---

## Code Examples

### Census Geocoder — Complete Request/Response Pattern

```typescript
// Source: https://geocoding.geo.census.gov/ (live API verification 2026-03-20)
// Endpoint: /geocoder/locations/onelineaddress
// Returns: result.addressMatches[] — empty array = ADDRESS_NOT_FOUND
// Coordinates: x=longitude, y=latitude

const url = new URL('https://geocoding.geo.census.gov/geocoder/locations/onelineaddress');
url.searchParams.set('address', address);        // Full address as single string
url.searchParams.set('benchmark', 'Public_AR_Current');  // Standard benchmark
url.searchParams.set('format', 'json');

// Verified response structure (2026-03-20):
// {
//   "result": {
//     "input": { "address": {...}, "benchmark": {...} },
//     "addressMatches": [
//       {
//         "tigerLine": { "side": "R", "tigerLineId": "31127863" },
//         "coordinates": { "x": -85.652994580982, "y": 40.092257190472 },
//         "addressComponents": { "zip": "46016", "streetName": "MOUNDS", "city": "ANDERSON", "state": "IN", ... },
//         "matchedAddress": "2201 MOUNDS RD, ANDERSON, IN, 46016"
//       }
//     ]
//   }
// }
//
// No match: addressMatches = [] (empty array, no matchStatus field at this API level)

const lng = matches[0].coordinates.x;  // longitude — x
const lat = matches[0].coordinates.y;  // latitude — y
```

### Verified PostGIS Pattern (from existing resolve_user_jurisdiction)

```sql
-- Source: supabase/migrations/20260310000032_location_rpcs.sql
-- Verified working in production

-- ST_MakePoint takes (longitude, latitude) — x first, y second
-- ST_Covers preferred over ST_Contains — handles boundary-coincident points correctly
-- SRID 4326 (WGS84) — must match geom column SRID
-- public. prefix required — PostGIS installs into public schema on this Supabase instance

SELECT ...
FROM inform.district_boundaries
WHERE public.ST_Covers(
  geom,
  public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
  -- $1 = longitude (Census x), $2 = latitude (Census y)
);
```

### Go Server /essentials/politicians Response Shape (Verified 2026-03-20)

```json
// Source: GET https://api.empowered.vote/essentials/politicians (live query)
// This is the parity target for the politicians list endpoint
{
  "id": "f0f4beec-c959-4145-8420-8c5b09563278",
  "external_id": 449401,
  "first_name": "Vop",
  "middle_initial": "",
  "last_name": "Osili",
  "preferred_name": "",
  "name_suffix": "",
  "full_name": "Vop Osili",
  "party": "Democratic",
  "photo_origin_url": "",
  "web_form_url": "",
  "urls": ["https://www.linkedin.com/in/vop-osili-85151b106", ...],
  "email_addresses": ["vop.osili@indy.gov"],
  "office_title": "/Marion City/County Council - District 12",
  "representing_state": "IN",
  "representing_city": "",
  "district_type": "COUNTY",
  "district_label": "District 12",
  "mtfcc": "",
  "chamber_name": "/Marion City/County Council - District 12",
  "chamber_name_formal": "",
  "government_name": "City of Indianapolis, Indiana, US",
  "is_elected": true,
  "election_frequency": "4",
  "committees": null
}
// Total: 1,290 politicians in the list
// Additive fields (Phase 38 adds): district_id (GEOID), data_level
// Empowered profiles additions: bio_text, slug, and 9 empowered_profiles columns
```

### Existing Route Registration Pattern (from index.ts)

```typescript
// Source: backend/src/index.ts
// Current registration for essentials:
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);

// Phase 38 adds:
// Option A: Mount unified essentials router at /api/essentials
// Option B: Mount individual files per domain
// Claude's Discretion: researcher recommends Option A (single essentials router)
// to avoid explosion of route files; use subpath defines before param routes
```

### optionalAuth Usage (from existing essentialsPoliticians.ts)

```typescript
// Source: backend/src/routes/essentialsPoliticians.ts
import { optionalAuth } from '../middleware/auth.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';

router.get('/', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const userId = (req as AuthenticatedRequest).userId; // string | undefined
  // userId === undefined → unauthenticated/Inform
  // userId === string → Connected
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Google Maps Geocoding API (paid) | US Census Geocoder (free) | Phase 38 | Remove GOOGLE_MAPS_API_KEY dependency; env.ts change required |
| Split essentialsCandidates + essentialsPoliticians files | Unified essentials router (recommendation) | Phase 38 | Cleaner file structure; all essentials routes in one place |
| Politicians from inform.politicians | Politicians from essentials.politicians | Phase 35 deduplication | essentials.politicians is now sole source of truth for all politician data |
| `supabaseAnon` hint in old essentialsService comment | `pool.query()` only | Phase 34-35 | essentials not in PostgREST; pool.query() confirmed correct approach |

**Deprecated/outdated:**
- `GOOGLE_MAPS_API_KEY` env var: No longer needed after geocodingService.ts rewrite. Remove from required env vars.
- `GeocodingErrorCode = 'LOW_CONFIDENCE'`: Google Maps-specific. Remove from new Census geocoder. Census doesn't have a confidence level concept — all matches are accepted.
- `inform.politicians`: Dropped in Phase 35. All politician references now use `essentials.politicians`.

---

## Claude's Discretion Recommendations

### Service File Split
**Recommendation: Two service files.**
- `essentialsService.ts` (extend existing): politician list, politician detail, address-search, governments, chambers, districts.
- `essentialsLegislativeService.ts` (new): bills, votes, committees, legislative sessions (high row counts, separate concerns).

Legislative tables are large (19,622 bills, 121,178 votes, 44,021 bill cosponsors). Keeping them separate makes both files manageable and allows independent testing.

### Redis Cache Key Format
**Recommendation:** `geocode:v1:{normalized_address}` where normalized = `.toLowerCase().trim().replace(/\s+/g, ' ')`.

Using a version prefix (`v1:`) allows cache invalidation if the geocoder implementation changes. Example: `geocode:v1:2201 mounds rd, anderson, in 46016`.

### SQL Query Structure for PostGIS
**Recommendation:** Direct `pool.query()` in the service layer (not an RPC). The `resolve_user_jurisdiction` RPC exists because it needs Vault access for decryption. Address-search doesn't need Vault — plain SQL is appropriate and simpler. Use `SET LOCAL search_path = public, essentials` at the start of the query or fully qualify all table references.

### Error Handling for Missing Nested Records
**Recommendation:** Return `null` for missing nested join targets (not 404). If a politician has no committees, return `committees: []`. If a government has no photo, return `building_photo: null`. Only return 404 when the root resource (the politician/government/chamber/district) doesn't exist.

### Plan Split Recommendation
Given the volume (~25 routes + geocodingService rewrite):
- **Plan 1:** Schema investigation (query geofence_boundaries/districts/offices column structure) + env.ts update + geocodingService.ts rewrite
- **Plan 2:** GET /essentials/address-search + extend GET /essentials/politicians with Go-parity fields
- **Plan 3:** GET /essentials/politicians/:id (full profile with nested joins)
- **Plan 4:** GET /essentials/politicians/:id/legislative, /committees, /bills, /votes
- **Plan 5:** GET /essentials/governments/:id, /chambers/:id, /districts/:id + index.ts registration

---

## Open Questions

1. **essentials.geofence_boundaries column structure — MUST resolve in Plan 1**
   - What we know: Table exists with 6,552 rows; PostGIS extension enabled in production; Column `geom` almost certainly exists (standard PostGIS pattern)
   - What's unclear: Other column names, specifically what links to districts/politicians. Does it have `district_id`, `district_type`, `geoid`? How does it join to `essentials.districts` or `essentials.offices`?
   - Recommendation: Plan 1 task queries `information_schema.columns WHERE table_schema = 'essentials' AND table_name IN ('geofence_boundaries', 'districts', 'offices', 'politicians')` before any PostGIS SQL is written. This is a hard blocker for the address-search route.

2. **Go server politician detail route — not viable for parity research**
   - What we know: `GET /essentials/politicians/:id` on the live Go server returns 400 "Missing or invalid zip parameter" for all tested IDs. Route is not accessible for response shape capture.
   - What's unclear: Whether a "full profile" response shape differs from the politicians list shape, and what nested objects it includes
   - Recommendation: Use the politicians list response shape as the baseline. For nested objects (contacts, images, endorsements, degrees, experiences), derive the response shape by querying the essentials schema directly (already have column inventories for these tables from Phase 34).

3. **district_id field source for politicians list**
   - What we know: `ESSENTIALS-INTEGRATION.md` Section 6 specifies `district_id` and `district_type` fields are needed on politician records for jurisdiction matching. Current essentialsService.ts SELECT doesn't include these.
   - What's unclear: Whether `district_id` is a direct column on `essentials.politicians` or must be JOINed from `essentials.offices` / `essentials.districts`
   - Recommendation: Plan 1 column structure query will resolve this. If it's a JOIN, the politicians list query needs to be extended.

4. **GEOFENCE approach — essentials.geofence_boundaries vs inform.district_boundaries**
   - What we know: The existing `resolve_user_jurisdiction` RPC uses `inform.district_boundaries` (Indiana TIGER/Line data, 5 district types). `essentials.geofence_boundaries` is the Go backend's original geofence data (6,552 rows, multi-state).
   - What's unclear: Whether Phase 38's address-search should query `essentials.geofence_boundaries` (Go parity) or `inform.district_boundaries` (existing infrastructure). They may have different schemas, coverage, and district type values.
   - Recommendation: Use `essentials.geofence_boundaries` for address-search since that's what the Go backend uses and it has broader coverage. Reserve `inform.district_boundaries` for the existing `resolve_user_jurisdiction` RPC.

---

## Sources

### Primary (HIGH confidence)
- `backend/src/routes/essentialsPoliticians.ts` — existing route pattern
- `backend/src/routes/essentialsCandidates.ts` — existing route pattern
- `backend/src/lib/essentialsService.ts` — existing service, confirmed pool.query() approach + column names
- `backend/src/lib/geocodingService.ts` — current Google Maps implementation to replace
- `backend/src/lib/cache.ts` — existing cache wrapper (get/set/del, ttlSeconds param)
- `backend/src/middleware/auth.ts` — optionalAuth exports and behavior
- `backend/src/index.ts` — router registration pattern
- `backend/src/lib/db.ts` — pool configuration
- `backend/src/lib/env.ts` — env schema (GOOGLE_MAPS_API_KEY currently required)
- `supabase/migrations/20260310000032_location_rpcs.sql` — PostGIS ST_Covers pattern, coordinate conventions
- `supabase/migrations/20260319000044_phase34_essentials_rls.sql` — complete table list (36 tables)
- `.planning/phases/34-database-schema-migration/34-01-SUMMARY.md` — row counts, no user_id columns in essentials
- `https://geocoding.geo.census.gov/` — live Census Geocoder API verification (2026-03-20)

### Secondary (MEDIUM confidence)
- `https://api.empowered.vote/essentials/politicians` — Go server response shape (live, 2026-03-20): verified 1,290 politicians, complete field list
- `.planning/phases/37-express-ports-wave-2-staging/37-RESEARCH.md` — essentials.politicians confirmed columns
- `PLATFORM-CONSOLIDATION.md` — route scope documentation, PostGIS pattern reference

### Tertiary (LOW confidence — unverified specifics)
- essentials.geofence_boundaries column structure: inferred from PostGIS conventions + existing resolve_user_jurisdiction pattern; not yet queried from live DB
- essentials.politicians full join structure for detail route: inferred from schema table list; column-level details not yet queried

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — same tools as phases 36-37, no new dependencies
- Architecture: HIGH — established patterns from essentialsPoliticians.ts, staging.ts
- Census Geocoder: HIGH — live API verified, response structure confirmed
- Go server parity target: MEDIUM — politicians list confirmed; politician detail route broken on Go server; detail shape must be inferred from schema
- PostGIS geofence query: MEDIUM — ST_Covers pattern confirmed from existing RPC; geofence_boundaries join path unverified
- Pitfalls: HIGH — most derived from code inspection and established production patterns

**Research date:** 2026-03-20
**Valid until:** 2026-04-20 (Census Geocoder API is stable; essentials schema won't change)
