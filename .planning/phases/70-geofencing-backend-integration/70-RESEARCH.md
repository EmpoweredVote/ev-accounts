# Phase 70: Geofencing Backend Integration — Research

**Researched:** 2026-05-09
**Domain:** Express 4.x route wiring, Postgres RPC calls, PostGIS district caching
**Confidence:** HIGH — all findings sourced from live codebase inspection

---

## Summary

Phase 70 wires the `essentials.cache_user_districts` RPC (created in Phase 69) into two existing
location-write flows and adds one new read endpoint. All three GEO requirements are pure integration
work — no new schema, no new RPCs, no new migrations. The RPC signature, table schema, and layer
mappings were fully established by Phase 69.

The primary implementation risk is the `last_essentials_location` payload format: the field is raw
JSONB with no enforced schema. Phase 70 must define the expected `{ lat, lng }` shape on the
location-hint path, validate it defensively, and fall back gracefully when lat/lng are absent.

The `GET /api/essentials/representatives/me` rewrite (GEO-12) adds a new fast Path 0 that reads from
`connect.user_districts` and joins via `tiger_geoid + district_type`. This sits above the existing
Path 1 (stored geo_ids) and Path 1.5 (encrypted coords). The statewide politicians query (senators,
governor, president) is driven by congressional geo_id and must still run in parallel — Path 0 does
NOT eliminate it.

**Primary recommendation:** Implement `cache_user_districts` as an inline async call inside each route
handler with structured try/catch for fail-open behavior. Do not introduce a shared service wrapper —
the pattern is simple enough (one `pool.query` call) that a wrapper adds indirection without benefit.

---

## Standard Stack

No new dependencies. All Phase 70 work uses the established stack.

### Core (already present)

| Component | Version | Purpose |
|-----------|---------|---------|
| `pool.query()` | pg 8.x | All non-public schema reads/writes — mandatory for essentials/connect |
| `adminRpc()` | @supabase/supabase-js | Call SECURITY DEFINER RPCs via service role |
| `requireAuth` | local middleware | Auth guard for `GET /api/account/districts` |
| `requireConnected` | local middleware | Tier guard for `GET /essentials/representatives/me` |
| `requireInform` | local middleware | Tier guard for `PATCH /api/account/location-hint` |
| Express 4.x Router | 4.x | Route registration |

### Calling `cache_user_districts`

The RPC is in the `essentials` schema, which is NOT in the PostgREST exposed schema list.
Use `pool.query()` directly — NOT `adminRpc()`:

```typescript
// Source: migration 090 — function signature
// essentials.cache_user_districts(p_user_id UUID, p_lat float8, p_lng float8) RETURNS void
await pool.query(
  `SELECT essentials.cache_user_districts($1, $2, $3)`,
  [userId, lat, lng]
);
```

`adminRpc()` calls `.schema('essentials').rpc(...)` which hits PostgREST. The `essentials` schema
is not in the PostgREST exposed schema list — this will fail at runtime. Use `pool.query()`.

---

## Architecture Patterns

### Existing Route Anatomy (must match)

**`POST /api/connect/set-location`** (Connected tier, `backend/src/routes/connect.ts` line 500):
- Validates body: `{ address: string, force?: boolean }`
- Calls `geocodeAddress(address)` → `{ lat, lng, state, city }`
- Calls `adminRpc('upsert_user_location', ...)` to save encrypted coords
- Calls `adminRpc('resolve_user_jurisdiction', ...)` to get geo IDs
- Writes geo IDs to `connect.connected_profiles` via `pool.query()`
- Returns `{ location_consent: true, first_location: bool, jurisdiction: {...} }`
- **Phase 70 adds:** after the `pool.query()` jurisdiction write, call `cache_user_districts`

**`PATCH /api/account/location-hint`** (Inform tier, `backend/src/routes/account.ts` line 663):
- Accepts `{ location: z.unknown() }` — raw, no structural validation today
- Writes `location` as JSONB to `inform.inform_profiles.last_essentials_location`
- **Phase 70 adds:** extract lat/lng from `location`, call `cache_user_districts` if valid

**`GET /api/essentials/representatives/me`** (`backend/src/routes/essentials.ts` line 453):
- Requires `requireAuth` + `requireConnected`
- Reads from `connect.connected_profiles` (encrypted_lat, geo_ids)
- Path 1: stored geo_ids → `getRepresentativesByJurisdiction()` + `getLocalOfficialsByUserId()`
- Path 1.5: encrypted coords but no geo_ids → `adminRpc('resolve_user_jurisdiction')` + write-back
- Falls through to 204 No Content when no location data
- **Phase 70 adds:** Path 0 before Path 1 — read from `connect.user_districts`, join via `tiger_geoid`

### `connect.user_districts` Schema (Phase 69, migration 089)

```sql
-- PRIMARY KEY (user_id, layer)
CREATE TABLE connect.user_districts (
  user_id      UUID  NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  layer        TEXT  NOT NULL,   -- 'ca_assembly' | 'ca_senate' | 'us_house'
  geoid        TEXT  NOT NULL,   -- TIGER GEOID, e.g. '06054'
  district_num TEXT  NOT NULL,   -- numeric string, e.g. '54'
  resolved_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, layer)
);
```

### Layer → district_type Mapping (Phase 69 discovery, 69-02-SUMMARY.md)

| geo_districts.layer | essentials.districts.district_type | Notes |
|--------------------|------------------------------------|-------|
| `ca_assembly` | `STATE_LOWER` | CA State Assembly |
| `ca_senate` | `STATE_UPPER` | CA State Senate |
| `us_house` | `NATIONAL_LOWER` | US House of Representatives |

This mapping is critical for GEO-12. TIGER geoid is non-unique — assembly D20 and senate D20 both
store `geoid = '06020'`. Joins MUST filter by both `tiger_geoid` AND `district_type`.

### Path 0 Join Query (GEO-12)

The fast path reads all three layers from `user_districts`, then queries `essentials.districts`:

```sql
-- Read user's cached districts
SELECT layer, geoid FROM connect.user_districts WHERE user_id = $1

-- For each (layer, geoid) pair, resolve to essentials.districts row:
-- ca_assembly → district_type = 'STATE_LOWER'
-- ca_senate   → district_type = 'STATE_UPPER'
-- us_house    → district_type = 'NATIONAL_LOWER'
SELECT d.geo_id, d.district_type
FROM essentials.districts d
WHERE (d.tiger_geoid = $1 AND d.district_type = 'STATE_LOWER')   -- ca_assembly geoid
   OR (d.tiger_geoid = $2 AND d.district_type = 'STATE_UPPER')   -- ca_senate geoid
   OR (d.tiger_geoid = $3 AND d.district_type = 'NATIONAL_LOWER') -- us_house geoid
```

Once `d.geo_id` is resolved per district_type, the existing
`getRepresentativesByJurisdiction({ congressional, state_senate, state_house, ... })` function
handles the rest. `d.geo_id` is the existing jurisdiction geo_id format (e.g., `'1807'` for
congressional) — NOT the TIGER geoid.

**Important:** After resolving `geo_id` from the district join, the congressional `geo_id` is used to
drive the statewide politicians subquery (senators, governor) inside `getRepresentativesByJurisdiction`.
This subquery still runs in Path 0 — it is not eliminated.

### Opportunistic Backfill Pattern (GEO-12, pre-Phase-70 users)

For users with `encrypted_lat IS NOT NULL` but no `user_districts` rows (pre-Phase-70), trigger
`cache_user_districts` inline within the Path 0 check, then serve them from the newly populated cache:

```
check user_districts → 0 rows, but has_coords = true
→ call cache_user_districts(userId, lat, lng)  [decrypt coords via adminRpc first]
→ re-read user_districts
→ serve from cache (now Path 0)
```

However: decrypting coords requires `adminRpc('upsert_user_location')` or reading encrypted_lat
(which requires the `pgsodium` key). The existing Path 1.5 already handles this via
`resolve_user_jurisdiction` RPC. The simpler approach: when `user_districts` is empty but geo_ids
are present in `connected_profiles` (Path 1 data), call `cache_user_districts` opportunistically
by passing the stored lat/lng (if available) OR skip backfill and let the next location-write trigger it.

**Decision from CONTEXT.md:** "Users with stored lat/lng but no cached districts get
`cache_user_districts` triggered inline on their next call." This means Path 0 opportunistic backfill
needs the raw lat/lng. Since those are encrypted in `connected_profiles`, the backfill call needs
decrypted coords — the simplest approach is to proceed to Path 1 (geo_id lookup) for the current
request and call `cache_user_districts` as a fire-and-forget via `adminRpc` after the response is sent.
The next call then hits Path 0. This avoids blocking the response on decryption.

### `GET /api/account/districts` Endpoint Shape (GEO-11)

```typescript
// Response shape
{
  ca_assembly:  { district_number: string; name: string; tiger_geoid: string } | null;
  ca_senate:    { district_number: string; name: string; tiger_geoid: string } | null;
  us_house:     { district_number: string; name: string; tiger_geoid: string } | null;
}

// 204 No Content when no rows in user_districts
// Auth: requireAuth only (both Inform and Connected tiers)
```

Reading from `user_districts` — use `pool.query()` (connect schema, not PostgREST-accessible):

```typescript
const { rows } = await pool.query<{
  layer: string; geoid: string; district_num: string; resolved_at: string;
}>(
  `SELECT layer, geoid, district_num, resolved_at
   FROM connect.user_districts WHERE user_id = $1`,
  [userId]
);
```

Note: `user_districts` stores `geoid` and `district_num` but NOT `name`. The `name` for the
grouped response must come from `essentials.geo_districts` joined on `(layer, geoid)`. The response
shape in CONTEXT.md includes `name` — so a join is required.

Join to get district name:

```sql
SELECT ud.layer, ud.geoid, ud.district_num, gd.name
FROM connect.user_districts ud
LEFT JOIN essentials.geo_districts gd
  ON gd.layer = ud.layer AND gd.geoid = ud.geoid
WHERE ud.user_id = $1
```

### `PATCH /api/account/location-hint` — lat/lng extraction

The `location` payload is raw JSONB. Phase 70 needs lat/lng from it. Since the location-hint
endpoint is called by the Essentials frontend, which passes location objects with `lat` and `lng`
properties, the extraction pattern is:

```typescript
// location is z.unknown() — may be anything
// Defensive extraction: only proceed with cache call if both lat and lng are numeric
const loc = location as Record<string, unknown>;
const lat = typeof loc?.lat === 'number' ? loc.lat : null;
const lng = typeof loc?.lng === 'number' ? loc.lng : null;
```

If lat/lng cannot be extracted (payload has a different shape), skip `cache_user_districts` silently.
This is fail-open: the location hint still saves, district caching is skipped. Log at WARN level.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Point-in-polygon resolution | Custom PostGIS query in JS | `essentials.cache_user_districts(user_id, lat, lng)` via `pool.query()` |
| District caching | Manual INSERT to user_districts | Same RPC — it handles ON CONFLICT upsert |
| Layer→type mapping | Runtime string lookup table in JS | Hard-code the three pairs from Phase 69 discovery |
| Politician lookup from cache | New query path in essentialsService | Reuse `getRepresentativesByJurisdiction()` with geo_ids resolved from tiger_geoid join |

---

## Common Pitfalls

### Pitfall 1: Calling cache_user_districts via adminRpc instead of pool.query

**What goes wrong:** `adminRpc('cache_user_districts', ...)` calls `.schema('essentials').rpc(...)`,
which routes through PostgREST. The `essentials` schema is not in PostgREST's exposed schema list
(`public, connect, empower, inform, graphql_public, validation_quests`). The call will fail with a
runtime error like "schema not found" or 404.

**How to avoid:** Always call via `pool.query('SELECT essentials.cache_user_districts($1, $2, $3)', [userId, lat, lng])`.

**Warning signs:** `error.message` contains "Not Found" or schema error on what should be a simple RPC call.

### Pitfall 2: Joining user_districts to essentials.districts without district_type filter

**What goes wrong:** TIGER GEOIDs are non-unique across layers. Assembly D20 and Senate D20 both
store `geoid = '06020'`. A join on `tiger_geoid` alone returns two rows where one is expected.

**How to avoid:** Always filter: `WHERE d.tiger_geoid = $1 AND d.district_type = $2` using the
layer→type mapping (`ca_assembly`→`STATE_LOWER`, `ca_senate`→`STATE_UPPER`, `us_house`→`NATIONAL_LOWER`).

**Warning signs:** Path 0 returns duplicate politicians for same-numbered assembly/senate districts.

### Pitfall 3: Blocking the location-save response on cache_user_districts error

**What goes wrong:** If `cache_user_districts` throws (PostGIS hiccup, empty geo_districts for
out-of-CA users), the caught error propagates to the route handler and returns 500 to the user,
masking the fact that the location save succeeded.

**How to avoid:** Wrap the cache call in try/catch that logs the error and continues. The location
write must have already committed before the cache call. Structure:

```typescript
// 1. Location write (must succeed — fail hard on error)
await pool.query(`UPDATE connect.connected_profiles SET ... WHERE user_id = $1`, [...]);
// 2. District cache (fail-open — never block or rollback location write)
try {
  await pool.query(`SELECT essentials.cache_user_districts($1, $2, $3)`, [userId, lat, lng]);
} catch (cacheErr) {
  console.error('[set-location] district cache failed (non-fatal):', cacheErr);
}
```

**Warning signs:** Location saves start returning 500 when PostGIS is slow or geo_districts is empty.

### Pitfall 4: Missing statewide politicians query in Path 0

**What goes wrong:** Path 0 resolves ca_assembly, ca_senate, us_house from `user_districts`, passes
`congressional` geo_id to `getRepresentativesByJurisdiction()`, which then queries statewide
politicians (senators, governor, president) from that geo_id. If Path 0 short-circuits before
passing the congressional geo_id, statewide officials disappear from the response.

**How to avoid:** `getRepresentativesByJurisdiction()` already handles the statewide subquery
internally when `congressional` is non-null. Just pass the resolved congressional `geo_id` and
everything works. Do not build a separate statewide query in Path 0.

### Pitfall 5: user_districts has geoid but not name — needs join to geo_districts for the districts endpoint

**What goes wrong:** Building `GET /api/account/districts` by reading only from `user_districts`
yields `geoid` and `district_num` but no human-readable `name`. The CONTEXT response shape
requires `name`.

**How to avoid:** JOIN `connect.user_districts` to `essentials.geo_districts` ON `(layer, geoid)`.
Both tables are pool.query-accessible. The join is cheap (indexed on `(layer, geoid)` with UNIQUE constraint).

### Pitfall 6: Wrong schema for user_districts read in requireInform context

**What goes wrong:** `PATCH /api/account/location-hint` is gated by `requireInform` (Connected users
get 403). When calling `cache_user_districts` for Inform users, the `user_districts` table requires
a `user_id` that exists in `public.users`. Inform users do have a `public.users` row — the FK is
`REFERENCES public.users(id)`, not `connect.connected_profiles`. This is fine and works correctly.

**Warning signs:** None — this is a non-issue, but document it so the implementer doesn't second-guess.

---

## Code Examples

### GEO-10: Adding cache call to `POST /api/connect/set-location`

```typescript
// Source: backend/src/routes/connect.ts — after jurisdiction pool.query() write succeeds
// Insert after the pool.query() UPDATE block (line ~598) and before building the response.

// District cache — fail-open: never block location save on PostGIS error
try {
  await pool.query(
    `SELECT essentials.cache_user_districts($1, $2, $3)`,
    [userId, lat, lng]
  );
} catch (cacheErr) {
  console.error('[connect/set-location] district cache failed (non-fatal):', cacheErr);
}
```

### GEO-10: Adding cache call to `PATCH /api/account/location-hint`

```typescript
// Source: backend/src/routes/account.ts — after the pool.query INSERT ON CONFLICT
// The location JSON has already been written. Now attempt district caching.

// Extract lat/lng from location payload (opaque JSONB — defensive extraction)
const loc = location as Record<string, unknown>;
const hintLat = typeof loc?.lat === 'number' ? loc.lat : null;
const hintLng = typeof loc?.lng === 'number' ? loc.lng : null;

if (hintLat !== null && hintLng !== null) {
  try {
    await pool.query(
      `SELECT essentials.cache_user_districts($1, $2, $3)`,
      [authReq.userId, hintLat, hintLng]
    );
  } catch (cacheErr) {
    console.warn('[location-hint] district cache failed (non-fatal):', cacheErr);
  }
} else {
  console.warn('[location-hint] no lat/lng in payload — skipping district cache');
}
```

### GEO-11: `GET /api/account/districts` endpoint

```typescript
// In backend/src/routes/account.ts, add before export default router

router.get('/districts', requireAuth, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;

  try {
    const { rows } = await pool.query<{
      layer: string; geoid: string; district_num: string; name: string | null;
    }>(
      `SELECT ud.layer, ud.geoid, ud.district_num, gd.name
       FROM connect.user_districts ud
       LEFT JOIN essentials.geo_districts gd
         ON gd.layer = ud.layer AND gd.geoid = ud.geoid
       WHERE ud.user_id = $1`,
      [authReq.userId]
    );

    if (rows.length === 0) {
      res.status(204).end();
      return;
    }

    // Group by layer
    const byLayer = Object.fromEntries(
      rows.map((r) => [r.layer, {
        district_number: r.district_num,
        name: r.name ?? null,
        tiger_geoid: r.geoid,
      }])
    );

    res.status(200).json({
      ca_assembly: byLayer['ca_assembly'] ?? null,
      ca_senate:   byLayer['ca_senate']   ?? null,
      us_house:    byLayer['us_house']    ?? null,
    });
  } catch (err) {
    console.error('[GET /api/account/districts] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

### GEO-12: Path 0 addition to `GET /api/essentials/representatives/me`

```typescript
// Source: backend/src/routes/essentials.ts — insert before the existing Path 1 check

// --- Path 0: TIGER user_districts cache — fastest path ---
const { rows: districtRows } = await pool.query<{
  layer: string; geoid: string;
}>(
  `SELECT layer, geoid FROM connect.user_districts WHERE user_id = $1`,
  [userId]
).catch(() => ({ rows: [] as any[] }));

if (districtRows.length > 0) {
  // Resolve tiger_geoid → essentials.districts.geo_id for each layer
  const layerTypeMap: Record<string, string> = {
    ca_assembly: 'STATE_LOWER',
    ca_senate:   'STATE_UPPER',
    us_house:    'NATIONAL_LOWER',
  };

  try {
    // Build OR conditions for the three layers
    const params: string[] = [];
    const conditions: string[] = [];
    for (const row of districtRows) {
      const distType = layerTypeMap[row.layer];
      if (!distType) continue;
      params.push(row.geoid, distType);
      conditions.push(`(d.tiger_geoid = $${params.length - 1} AND d.district_type = $${params.length})`);
    }

    if (conditions.length > 0) {
      const { rows: geoRows } = await pool.query<{
        district_type: string; geo_id: string;
      }>(
        `SELECT d.district_type, d.geo_id
         FROM essentials.districts d
         WHERE ${conditions.join(' OR ')}`,
        params
      );

      // Map district_type back to jurisdiction field
      const typeToField: Record<string, string> = {
        NATIONAL_LOWER: 'congressional',
        STATE_UPPER:    'state_senate',
        STATE_LOWER:    'state_house',
      };
      const jurisdiction: Record<string, string | null> = {
        congressional: null, state_senate: null, state_house: null,
        county: null, school_district: null,
      };
      for (const row of geoRows) {
        const field = typeToField[row.district_type];
        if (field) jurisdiction[field] = row.geo_id;
      }

      if (jurisdiction.congressional || jurisdiction.state_senate) {
        const [politicians, localOfficials] = await Promise.all([
          getRepresentativesByJurisdiction(jurisdiction as JurisdictionGeoIds),
          getLocalOfficialsByUserId(userId),
        ]);
        const seenIds = new Set(politicians.map((p) => p.id));
        const merged = [...politicians, ...localOfficials.filter((p) => !seenIds.has(p.id))];
        res.setHeader('X-Data-Status', merged.length === 0 ? 'no-geofence-data' : 'fresh');
        res.status(200).json(merged);
        return;
      }
    }
  } catch {
    // fall through to Path 1
  }
}
// ... existing Path 1, Path 1.5, 204 ...
```

### Admin Bulk Re-cache Script

Pattern: Node.js/TypeScript script in `backend/scripts/` (matches existing `backfill-*.ts` pattern).
Runs against the DB directly via `pool` from `../src/lib/db.js`.

```typescript
// backend/scripts/recache-user-districts.ts
// Usage: npx tsx scripts/recache-user-districts.ts [--before=2026-05-09]
// Targets: users where resolved_at < cutoff date (redistricting or new TIGER import)

import { pool } from '../src/lib/db.js';

const cutoffDate = process.argv.find(a => a.startsWith('--before='))?.split('=')[1];

const { rows: users } = await pool.query<{ user_id: string; lat: number; lng: number }>(
  cutoffDate
    ? `SELECT ud.user_id, ... FROM connect.user_districts ud
       JOIN connect.connected_profiles cp ON cp.user_id = ud.user_id
       WHERE ud.resolved_at < $1
       GROUP BY ud.user_id, lat, lng`
    : `SELECT DISTINCT ud.user_id, ... FROM connect.user_districts ud
       JOIN connect.connected_profiles cp ON cp.user_id = ud.user_id`,
  cutoffDate ? [cutoffDate] : []
);

for (const user of users) {
  await pool.query(
    `SELECT essentials.cache_user_districts($1, $2, $3)`,
    [user.user_id, user.lat, user.lng]
  );
}
```

**Note:** The actual lat/lng for Connected users is stored encrypted in `encrypted_lat`/`encrypted_lng`
in `connect.connected_profiles`. The re-cache script needs to decrypt them, which requires calling the
`upsert_user_location` RPC (which decrypts internally) OR a direct `pgsodium.crypto_aead_det_decrypt`
call from SQL. The simpler approach: drive re-cache from SQL entirely using a stored procedure that
reads the encrypted coords and calls `cache_user_districts` without exposing plaintext to Node.js.
This is a design decision left to the planner.

---

## Route Registration

`GET /api/account/districts` — register in `backend/src/routes/account.ts` (same file as location-hint).
The account router is mounted at `/api/account` in `backend/src/index.ts`.

`GET /api/essentials/representatives/me` — modification in `backend/src/routes/essentials.ts`.

`PATCH /api/account/location-hint` — modification in `backend/src/routes/account.ts`.

`POST /api/connect/set-location` — modification in `backend/src/routes/connect.ts`.

---

## Open Questions

### 1. Decrypt coords for opportunistic backfill in Path 0

**What we know:** Phase 69's `cache_user_districts` needs plaintext lat/lng. Connected users store
encrypted coords. The existing Path 1.5 decrypts via `resolve_user_jurisdiction` RPC (which handles
decryption internally). Phase 70 could reuse the same decrypt-then-cache approach.

**What's unclear:** CONTEXT.md says "opportunistic backfill" for pre-Phase-70 users. But to call
`cache_user_districts(user_id, lat, lng)` we need the plaintext lat/lng. The only way to get them
from Node.js is via an RPC that decrypts internally (e.g., `resolve_user_jurisdiction`).

**Recommendation:** For Path 0 opportunistic backfill, call `resolve_user_jurisdiction` (which
decrypts and resolves geo_ids), use those geo_ids for the current request via Path 1 logic, AND
separately trigger `cache_user_districts` by calling a new RPC or SQL function that accepts
`p_user_id` and decrypts internally. Alternatively, skip the backfill in the response path and
let the user's next `set-location` call trigger it. The CONTEXT says "no separate migration script
needed" but doesn't specify how to obtain lat/lng within the request path. **This is left to
Claude's discretion per CONTEXT.md.**

### 2. Admin re-cache script — encrypted lat/lng access

**What we know:** `connected_profiles.encrypted_lat` is `pgsodium`-encrypted. The re-cache script
needs decrypted coords to call `cache_user_districts(user_id, lat, lng)`.

**Recommendation:** Write the re-cache script as a SQL function (stored procedure) rather than a
Node.js script, so the decryption happens inside Postgres where pgsodium keys are accessible.
Or add a new `essentials.recache_all_user_districts(cutoff_date)` SQL function that iterates users,
decrypts coords internally, and calls `cache_user_districts` for each. The Node.js script would
simply call this function and report results.

---

## Sources

### Primary (HIGH confidence)
- `backend/src/routes/account.ts` — location-hint handler, `GET /api/account/me`, existing route shapes
- `backend/src/routes/connect.ts` — `POST /api/connect/set-location` full implementation (lines 500–668)
- `backend/src/routes/essentials.ts` — `GET /api/essentials/representatives/me` all paths (lines 453–569)
- `backend/src/lib/essentialsService.ts` — `getRepresentativesByJurisdiction()` signature and join pattern
- `backend/src/middleware/tierGuards.ts` — `requireAuth`, `requireConnected`, `requireInform`
- `backend/src/lib/supabase.ts` — `adminRpc()` implementation (schema → rpc pattern, PostgREST-routed)
- `.planning/phases/69-tiger-schema-data-import/69-01-PLAN.md` — RPC signatures verbatim
- `.planning/phases/69-tiger-schema-data-import/69-02-SUMMARY.md` — layer→district_type mapping, confirmed live data
- `.planning/phases/69-tiger-schema-data-import/69-VERIFICATION.md` — all Phase 69 schema facts verified
- `.planning/phases/66-inform-profiles-backend-foundation/66-RESEARCH.md` — confirms `last_essentials_location` is raw JSONB with no enforced schema

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, all existing patterns
- Architecture: HIGH — read directly from live source files
- RPC signature: HIGH — verbatim from migration 090 (verified in Phase 69)
- Schema facts: HIGH — table columns confirmed from migration 089 and Phase 69 verification report
- Layer→type mapping: HIGH — confirmed via live DB queries in Phase 69
- Pitfalls: HIGH — derived from Memory.md established patterns + Phase 69 deviations
- Open questions: MEDIUM — design decisions that couldn't be fully resolved without user input

**Research date:** 2026-05-09
**Valid until:** 2026-06-09 (schema is stable; TIGER data does not change without redistricting)
