# Architecture Patterns — Location Infrastructure Integration

**Domain:** Encrypted location storage + PostGIS jurisdiction resolution in existing Supabase + Express app
**Researched:** 2026-03-09
**Confidence:** HIGH for integration patterns (verified against actual codebase); MEDIUM for geocoding service choice (verified against official sources); HIGH for RPC signatures (derived from established patterns in codebase)

---

## Overview

This document covers the architectural integration of three new components into the existing empowered-accounts backend:

1. Encrypted lat/lng storage on `connect.connected_profiles` (pgcrypto via Vault key)
2. PostGIS `inform.district_boundaries` table for jurisdiction resolution
3. New RPCs and endpoints following established patterns

The rest of the system — SECURITY DEFINER RPC pattern, dual Supabase client, advisory locks, two-pass validation, `SET search_path = ''` — does not change.

---

## Data Flow

```
User submits address string (e.g. "401 N Morton St, Bloomington IN 47404")
         |
         v
POST /api/connect/set-location
  - requireAuth + requireConnected middleware
  - Zod validation of address string
  - location_consent: true required in request body
         |
         v
locationService.geocodeAddress(addressString)
  - Calls Census Geocoder API (server-side, no user JWT involved)
  - Returns { lat: float, lng: float } or null if not found
  - Address string discarded after this step — never stored
         |
         v (on geocode success)
adminRpc('connect.update_user_location', {
  p_user_id: userId,
  p_lat_plain: lat,
  p_lng_plain: lng,
  p_consent: true
})
         |
         v  [inside SECURITY DEFINER RPC — Postgres]
update_user_location RPC:
  1. Reads vault key: SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'location_encryption_key'
  2. Encrypts: pgp_sym_encrypt(p_lat_plain::text, v_key) → bytea
               pgp_sym_encrypt(p_lng_plain::text, v_key) → bytea
  3. Writes to connect.connected_profiles:
       lat = encrypted bytea
       lng = encrypted bytea
       location_consent = true
       location_set_at = now()
  4. Returns: { success: true }
         |
         v
Response: 200 { location_set: true }
(raw coordinates never leave the system)

---

GET /api/account/me/jurisdiction
  - requireAuth + requireConnected middleware
         |
         v
adminRpc('connect.resolve_user_jurisdiction', { p_user_id: userId })
         |
         v  [inside SECURITY DEFINER RPC — Postgres]
resolve_user_jurisdiction RPC:
  1. Reads connected_profiles: lat bytea, lng bytea, location_consent
  2. If location_consent IS NULL or false → RAISE EXCEPTION 'NO_LOCATION_CONSENT'
  3. If lat IS NULL → RAISE EXCEPTION 'NO_LOCATION_SET'
  4. Reads vault key: SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'location_encryption_key'
  5. Decrypts: pgp_sym_decrypt(cp.lat, v_key)::float8 → v_lat
               pgp_sym_decrypt(cp.lng, v_key)::float8 → v_lng
  6. Constructs point: ST_SetSRID(ST_MakePoint(v_lng, v_lat), 4326)
  7. Queries district_boundaries:
       SELECT district_type, district_id, district_name, state_code
       FROM inform.district_boundaries
       WHERE ST_Contains(boundary::geometry, point::geometry)
  8. Returns jsonb: { city, state, county, districts: [...] }
         |
         v
Route handler serializes RPC result → 200 JSON
(coordinates never appear in the response or logs)

---

Feature consumption (e.g. ZIP candidate discovery, Validation Quests):
  GET /api/account/me/jurisdiction → { state_code, districts: [{ type, id, name }] }
  Feature checks district membership locally — no coordinate access ever
```

---

## Geocoding Service Recommendation

**Recommended: US Census Geocoder API**

**Rationale:**

| Criterion | Census Geocoder | Google Maps Geocoding | Mapbox Geocoding | Nominatim (public) |
|-----------|----------------|----------------------|-----------------|-------------------|
| Cost | Free, no key required | Pay-per-request ($5/1k) | Free tier (100k/mo) then paid | Free (rate limited) |
| Privacy | US government service; privacy policy states retained data does not include PII | Sends address to Google; TOS restrictions on storing results | Sends address to Mapbox | OSM policy explicitly asks you NOT to submit personal data |
| Indiana accuracy | HIGH — built from TIGER address database, which is the authoritative source for US addresses | HIGH | HIGH | MEDIUM — rural Indiana address coverage is incomplete in OSM |
| TypeScript SDK | None needed — simple REST GET with `fetch` | `@googlemaps/google-maps-services-js` | `@mapbox/mapbox-sdk` | REST only |
| Rate limits | No documented limit for reasonable use | 50 req/s (paid) | 600 req/min (free tier) | 1 req/s (hard limit on public instance) |
| No API key | Yes | No (billing required) | No (token required) | Yes (public instance) |
| Self-host option | No | No | No | Yes (major infra overhead) |

**Why Census wins for this project:**

1. **Privacy alignment**: The Census Bureau's privacy policy states retained data does not include personally identifiable information. For a civic platform collecting civic addresses, using a US government geocoding service operated under FOIA and federal privacy law is the strongest privacy posture available without self-hosting.

2. **Indiana accuracy**: TIGER/Line is the source of truth for US addresses — it is literally what every other geocoder is built from. Indiana addresses are well-covered.

3. **Cost**: Free with no API key. This project is an unfunded nonprofit; billing surprises are unacceptable.

4. **No PII terms violations**: Google Maps TOS prohibits storing geocoded results in conjunction with personally identifiable information. Census has no such restriction.

**Census Geocoder API call:**

```
GET https://geocoding.geo.census.gov/geocoder/locations/onelineaddress
  ?address=401+N+Morton+St%2C+Bloomington+IN+47404
  &benchmark=Public_AR_Current
  &format=json
```

Response path: `result.addressMatches[0].coordinates.{ x: lng, y: lat }`

Returns 200 with empty `addressMatches` array if not found (not a 4xx). TypeScript service must handle the empty-array case and return null.

**Confidence:** MEDIUM. Census Geocoder is a real service and the API format is verified against official documentation. Indiana accuracy claim is inferred from TIGER provenance — no independent test of rural Monroe County addresses performed.

---

## Encryption Architecture

### Why pgcrypto + Vault key (not pgsodium TCE)

**pgsodium is pending deprecation.** Supabase explicitly states it does not recommend new usage of pgsodium. Transparent Column Encryption (TCE) via pgsodium carries "high operational complexity and misconfiguration risk" per Supabase documentation.

**The correct pattern for this project:**

1. Store the encryption passphrase in Supabase Vault (a named secret: `'location_encryption_key'`)
2. In `SECURITY DEFINER` RPCs, read the decrypted secret from `vault.decrypted_secrets`
3. Use `pgcrypto.pgp_sym_encrypt` / `pgp_sym_decrypt` with that passphrase
4. Store encrypted values as `bytea` columns

This pattern is:
- Supported: pgcrypto is available in all Supabase projects
- Stable: Vault's API surface (the `vault.decrypted_secrets` view) is explicitly stable through the pgsodium deprecation
- Aligned with existing project patterns: SECURITY DEFINER + `SET search_path = ''`
- Auditable: key lives in Vault dashboard, not in migrations

**Important: `SET search_path = ''` means pgcrypto functions must be qualified.**

In the Supabase default configuration, pgcrypto lives in the `extensions` schema. With `SET search_path = ''`, all references must be fully qualified:
- `extensions.pgp_sym_encrypt()`
- `extensions.pgp_sym_decrypt()`

This is the same constraint already applied to all post-v1.2 RPCs.

### TypeScript handling of bytea columns

When supabase-js returns a `bytea` column, the value is a PostgreSQL hex-format string prefixed with `\x`, for example `\x7b2274797065223a...`. The `database.types.ts` generated type will show this column as `string`.

**Critical constraint:** The route handler and service code must never read the raw `lat` or `lng` bytea columns. Jurisdiction resolution is entirely in-database. The TypeScript layer only sees the jurisdiction JSON returned by the RPC.

In strict TypeScript, if a query ever needs to select `lat` or `lng` (it should not), annotate the type as `string` (the hex representation) and do not attempt to parse it in application code:

```typescript
// The bytea type in generated types:
// lat: string   ← hex-encoded, e.g. '\x...'
// lng: string   ← hex-encoded, e.g. '\x...'

// NEVER do this in route code — decryption is in-database only:
// const lat = parseFloat(hexToFloat(connectedProfile.lat)); // WRONG
```

---

## Exact RPC Signatures

### `connect.update_user_location`

```sql
CREATE OR REPLACE FUNCTION connect.update_user_location(
  p_user_id    UUID,
  p_lat_plain  FLOAT8,
  p_lng_plain  FLOAT8,
  p_consent    BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key TEXT;
BEGIN
  -- Validate consent must be explicit true
  IF p_consent IS NOT TRUE THEN
    RAISE EXCEPTION 'CONSENT_REQUIRED';
  END IF;

  -- Validate coordinate range
  IF p_lat_plain < -90 OR p_lat_plain > 90 THEN
    RAISE EXCEPTION 'INVALID_LAT';
  END IF;
  IF p_lng_plain < -180 OR p_lng_plain > 180 THEN
    RAISE EXCEPTION 'INVALID_LNG';
  END IF;

  -- Read encryption key from Vault
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'location_encryption_key';

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'ENCRYPTION_KEY_NOT_FOUND';
  END IF;

  -- Encrypt and persist — address string is already discarded by caller
  UPDATE connect.connected_profiles
  SET
    lat              = extensions.pgp_sym_encrypt(p_lat_plain::text, v_key),
    lng              = extensions.pgp_sym_encrypt(p_lng_plain::text, v_key),
    location_consent = true,
    location_set_at  = now(),
    updated_at       = now()
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PROFILE_NOT_FOUND';
  END IF;

  RETURN jsonb_build_object('success', true);

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**TypeScript call:**

```typescript
const { data, error } = await adminRpc('update_user_location', {
  p_user_id: userId,
  p_lat_plain: lat,      // number (float)
  p_lng_plain: lng,      // number (float)
  p_consent: true,
}, 'connect');

// error.message will be 'CONSENT_REQUIRED' | 'INVALID_LAT' | 'INVALID_LNG'
// | 'ENCRYPTION_KEY_NOT_FOUND' | 'PROFILE_NOT_FOUND' on failure
```

Note: `adminRpc` already accepts a schema parameter (third argument). Pass `'connect'` since the function lives in the `connect` schema.

---

### `connect.resolve_user_jurisdiction`

```sql
CREATE OR REPLACE FUNCTION connect.resolve_user_jurisdiction(
  p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_cp     connect.connected_profiles;
  v_key    TEXT;
  v_lat    FLOAT8;
  v_lng    FLOAT8;
  v_point  geometry;
  v_result JSONB;
BEGIN
  -- Fetch connected profile (FOR UPDATE not needed — read-only path)
  SELECT * INTO v_cp
  FROM connect.connected_profiles
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PROFILE_NOT_FOUND';
  END IF;

  IF v_cp.location_consent IS NOT TRUE THEN
    RAISE EXCEPTION 'NO_LOCATION_CONSENT';
  END IF;

  IF v_cp.lat IS NULL THEN
    RAISE EXCEPTION 'NO_LOCATION_SET';
  END IF;

  -- Read encryption key from Vault
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'location_encryption_key';

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'ENCRYPTION_KEY_NOT_FOUND';
  END IF;

  -- Decrypt coordinates (text → float8)
  v_lat := extensions.pgp_sym_decrypt(v_cp.lat, v_key)::FLOAT8;
  v_lng := extensions.pgp_sym_decrypt(v_cp.lng, v_key)::FLOAT8;

  -- Construct WGS84 point (ST_MakePoint takes lng, lat — note order)
  v_point := extensions.ST_SetSRID(
    extensions.ST_MakePoint(v_lng, v_lat),
    4326
  );

  -- Query district boundaries
  SELECT jsonb_agg(
    jsonb_build_object(
      'district_type', db.district_type,
      'district_id',   db.district_id,
      'district_name', db.district_name,
      'state_code',    db.state_code
    )
  )
  INTO v_result
  FROM inform.district_boundaries db
  WHERE extensions.ST_Contains(
    db.boundary::extensions.geometry,
    v_point
  );

  RETURN jsonb_build_object(
    'districts', COALESCE(v_result, '[]'::jsonb),
    'state_code', (
      SELECT state_code FROM inform.district_boundaries
      WHERE extensions.ST_Contains(boundary::extensions.geometry, v_point)
      LIMIT 1
    )
  );

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**TypeScript call and return type:**

```typescript
// In locationService.ts
export type JurisdictionDistrict = {
  district_type: string;   // 'congressional' | 'state_house' | 'state_senate' | 'county'
  district_id: string;
  district_name: string;
  state_code: string;
};

export type JurisdictionResult = {
  state_code: string | null;
  districts: JurisdictionDistrict[];
};

const { data, error } = await adminRpc('resolve_user_jurisdiction', {
  p_user_id: userId,
}, 'connect');

// error.message codes:
// 'PROFILE_NOT_FOUND' → 404
// 'NO_LOCATION_CONSENT' → 403
// 'NO_LOCATION_SET' → 404
// 'ENCRYPTION_KEY_NOT_FOUND' → 500
```

---

## Schema Changes

### `connect.connected_profiles` additions

```sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS lat              BYTEA,
  ADD COLUMN IF NOT EXISTS lng              BYTEA,
  ADD COLUMN IF NOT EXISTS location_consent BOOLEAN,
  ADD COLUMN IF NOT EXISTS location_set_at  TIMESTAMPTZ;
```

All four columns are nullable. Null `lat`/`lng` means location not yet set. Null `location_consent` is treated identically to `false` in the RPC (explicit `IS NOT TRUE` check covers both).

**These columns must never appear in any SELECT that feeds an API response.** They must be excluded from `connected_profiles_public` view and from any explicit column list in route queries.

---

### `inform.district_boundaries` table

```sql
CREATE TABLE IF NOT EXISTS inform.district_boundaries (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  district_type  TEXT        NOT NULL,  -- 'congressional' | 'state_house' | 'state_senate' | 'county'
  district_id    TEXT        NOT NULL,  -- e.g. 'IN-09' or '60'
  district_name  TEXT        NOT NULL,
  state_code     TEXT        NOT NULL,  -- 'IN'
  boundary       extensions.geography(MULTIPOLYGON, 4326) NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Spatial index — required for ST_Contains performance
CREATE INDEX IF NOT EXISTS idx_district_boundaries_boundary
  ON inform.district_boundaries USING GIST (boundary);

-- Lookup index
CREATE INDEX IF NOT EXISTS idx_district_boundaries_type_state
  ON inform.district_boundaries (district_type, state_code);
```

**SRID 4326** (WGS84) is required — this is the coordinate system used by GPS devices and the Census Geocoder API response. TIGER shapefiles must be reprojected to 4326 before loading.

**MULTIPOLYGON** not POLYGON because district boundaries often contain non-contiguous areas (islands, separated precincts). Using MULTIPOLYGON handles both cases.

**Boundary data source:** US Census Bureau TIGER/Line 2024 shapefiles.

- Congressional districts (119th): https://www.census.gov/cgi-bin/geo/shapefiles/index.php?year=2024&layergroup=Congressional+Districts+(119)
- State legislative districts: available from the same interface by selecting the appropriate layer group
- County boundaries: also available from TIGER/Line

Load using `shp2pgsql` (part of PostGIS) or Python `geopandas` → `psycopg2` pipeline. This is a one-time data load for Indiana at pilot scale.

---

## Connect Flow Integration Point

**Where:** `POST /api/connect/set-location` — a new endpoint, NOT an extension of `POST /api/connect/complete`.

**Rationale for separate endpoint (not folding into `complete`):**

1. `complete_connect_flow` is an atomic RPC that already has a locked schema and well-tested behavior. Adding location to it requires geocoding (a network call to Census API) inside what is currently a pure DB transaction. Network calls inside DB transactions are an anti-pattern — if Census API is slow or down, the entire connect flow would hang or fail.

2. Location consent is a separate, deliberate user action (consent moment should be distinct from account creation).

3. Location can be updated post-Connect (user moves). Making it part of `complete` would create an artificial "must geocode on day-1" requirement.

**Endpoint:**

```
POST /api/connect/set-location
Authorization: Bearer <jwt>

Request body:
{
  "address": "401 N Morton St, Bloomington IN 47404",
  "consent": true
}

Validation (Zod):
{
  address: z.string().min(5).max(500),
  consent: z.literal(true)   // must be explicit true — not a toggle
}
```

**Middleware chain:**

```typescript
router.post('/set-location',
  requireAuth,
  requireConnected,   // Connected tier required — Inform users cannot set location
  async (req, res) => { ... }
);
```

**Flow in route handler:**

```typescript
1. Validate body (Zod)
2. locationService.geocodeAddress(body.address)
   - Returns { lat, lng } or null
   - On null: 422 { code: 'ADDRESS_NOT_FOUND', message: '...' }
3. adminRpc('update_user_location', { p_user_id, p_lat_plain, p_lng_plain, p_consent: true }, 'connect')
   - On RPC error: map error codes to HTTP status
4. 200 { location_set: true }
```

**Error mapping:**

| RPC error code | HTTP status | User-facing meaning |
|----------------|------------|-------------------|
| `ADDRESS_NOT_FOUND` (geocoder null) | 422 | Address could not be geocoded |
| `CONSENT_REQUIRED` | 422 | consent: true is required |
| `INVALID_LAT` / `INVALID_LNG` | 422 | Geocoder returned out-of-range coordinates |
| `PROFILE_NOT_FOUND` | 404 | Connected profile missing (unexpected) |
| `ENCRYPTION_KEY_NOT_FOUND` | 500 | Vault key not configured — infrastructure issue |

---

## `GET /api/account/me/jurisdiction` Endpoint

**Location:** New file `backend/src/routes/location.ts`, mounted at `/api/account/me/jurisdiction` in `index.ts` (not inside `account.ts` — location is its own domain, and the route path is slightly misleading; consider `/api/location/jurisdiction` as an alternative if the project prefers cleaner namespace).

OR, add to `account.ts` router as:

```typescript
router.get('/me/jurisdiction', requireAuth, requireConnected, async (req, res) => { ... });
```

**Middleware:** `requireAuth` + `requireConnected`. The RPC itself enforces `location_consent` check and returns `NO_LOCATION_CONSENT` — the route handler maps that to 403.

**Response shape:**

```json
{
  "state_code": "IN",
  "districts": [
    { "district_type": "congressional", "district_id": "IN-09", "district_name": "Indiana 9th Congressional District", "state_code": "IN" },
    { "district_type": "state_house",   "district_id": "61",    "district_name": "Indiana House District 61",           "state_code": "IN" },
    { "district_type": "state_senate",  "district_id": "40",    "district_name": "Indiana Senate District 40",          "state_code": "IN" },
    { "district_type": "county",        "district_id": "055",   "district_name": "Monroe County",                       "state_code": "IN" }
  ]
}
```

Coordinates never appear in this response or any log line. The RPC decrypts in-database and returns only the resolved identifiers.

---

## Vault Key Setup

The Vault key is a one-time setup step — not a migration. It must be performed in the Supabase dashboard before the RPCs are deployed.

**Step 1 — Supabase Dashboard:**

```
Supabase Dashboard → Database → Vault → Add Secret
  Name: location_encryption_key
  Value: [strong random passphrase, e.g. 64 hex chars from openssl rand -hex 32]
```

**Step 2 — Confirm key is accessible:**

```sql
-- Run in SQL Editor (as postgres role):
SELECT name, created_at FROM vault.decrypted_secrets WHERE name = 'location_encryption_key';
-- Should return 1 row
```

**Step 3 — Grant the SECURITY DEFINER functions can read vault:**

The `vault.decrypted_secrets` view is accessible to the `postgres` role by default (which is what SECURITY DEFINER functions run as in Supabase). No additional grants are needed, but verify in local dev with:

```sql
SET ROLE postgres;
SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'location_encryption_key';
```

**Important:** Never put the passphrase in a migration file. The migration creates the RPC functions; the key lives in Vault only. The passphrase must also go into `.env` for local development testing with the env var name `LOCATION_ENCRYPTION_KEY` (used only by the local Vault setup script, not the application code — the application reads from Vault via the RPC).

---

## PostGIS Extension Setup

PostGIS is not currently enabled in this project. It must be enabled before the `inform.district_boundaries` table can be created.

**Enable via Supabase Dashboard:**

```
Database → Extensions → search "postgis" → Enable
(create in the "extensions" schema — Supabase default)
```

**Verify in migration:**

```sql
-- In the migration that creates district_boundaries, add a guard:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'postgis'
  ) THEN
    RAISE EXCEPTION 'PostGIS extension must be enabled before this migration. Enable it in the Supabase Dashboard under Database → Extensions.';
  END IF;
END;
$$;
```

**`SET search_path = ''` and PostGIS:**

PostGIS functions live in the `extensions` schema. With `SET search_path = ''` on SECURITY DEFINER functions, all PostGIS calls must be qualified:
- `extensions.ST_Contains()`
- `extensions.ST_MakePoint()`
- `extensions.ST_SetSRID()`
- `extensions.geometry` (type cast)
- `extensions.geography(MULTIPOLYGON, 4326)` (column type — in migration, not in function body)

This is consistent with the pattern already established for all post-v1.2 RPCs.

---

## Build Order

This ordering respects all dependencies between components.

```
1. Enable PostGIS extension (Supabase Dashboard)
   └── Required before district_boundaries table can be created
   └── Required before ST_Contains can be called in any function

2. Create Vault encryption key (Supabase Dashboard)
   └── Required before update_user_location or resolve_user_jurisdiction can run
   └── Must exist in BOTH local dev Vault and production Vault

3. Migration: ALTER connected_profiles (add lat, lng, location_consent, location_set_at)
   └── Additive — safe to apply while system is running
   └── All new columns are nullable; no default values needed
   └── Update connected_profiles_public view to explicitly exclude new columns

4. Migration: CREATE inform.district_boundaries table + spatial index
   └── Requires PostGIS (Step 1)
   └── Table is empty until Step 5 populates it

5. Load boundary data into district_boundaries
   └── One-time data load: Indiana TIGER/Line shapefiles
       - Congressional districts (119th, 2024)
       - State house districts (2024)
       - State senate districts (2024)
       - County boundaries
   └── Use shp2pgsql pipeline or Python geopandas → psycopg2
   └── All polygons must be in SRID 4326 before INSERT

6. Migration: CREATE connect.update_user_location RPC
   └── Requires connected_profiles columns (Step 3)
   └── Requires Vault key to exist (Step 2)
   └── Requires pgcrypto extension (available by default in Supabase)

7. Migration: CREATE connect.resolve_user_jurisdiction RPC
   └── Requires connected_profiles columns (Step 3)
   └── Requires district_boundaries table (Step 4)
   └── Requires Vault key (Step 2)
   └── Requires PostGIS (Step 1)

8. Backend: locationService.ts
   └── geocodeAddress(address: string): Promise<{ lat: number; lng: number } | null>
   └── Uses Census Geocoder API with fetch (no npm package needed)

9. Backend: POST /api/connect/set-location route
   └── Requires locationService (Step 8)
   └── Requires update_user_location RPC (Step 6)
   └── Add to connect.ts router

10. Backend: GET /api/account/me/jurisdiction route
    └── Requires resolve_user_jurisdiction RPC (Step 7)
    └── Add to account.ts router (or new location.ts router)

11. Integration test coverage
    └── set-location: address geocodes → encrypted storage (verify bytea non-null, never raw coords)
    └── jurisdiction: resolve returns correct district IDs for known Bloomington address
    └── jurisdiction: 403 when location_consent is null/false
    └── jurisdiction: 404 when location not set (consent true but lat null)
    └── Architecture test: lat/lng bytea columns never appear in any route query SELECT list
```

---

## Component Boundaries

| Component | Responsibility | Does NOT own |
|-----------|---------------|--------------|
| `locationService.ts` | Census Geocoder API call; returns `{lat,lng}` or null | Encryption; storage; any DB access |
| `connect.update_user_location` RPC | Validates range; reads Vault key; encrypts; writes to connected_profiles | Geocoding; address parsing |
| `connect.resolve_user_jurisdiction` RPC | Decrypts; constructs PostGIS point; ST_Contains query; returns jurisdiction JSON | Returning coordinates; caching |
| `GET /api/account/me/jurisdiction` | Auth/tier middleware; calls RPC; maps error codes; serializes result | Any knowledge of encryption or coordinates |
| `POST /api/connect/set-location` | Validates address string; calls geocoder; calls RPC; consent enforcement | Any knowledge of encryption algorithm |
| `inform.district_boundaries` | Stores boundary polygons for jurisdiction lookup | User location data; any user PII |

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Geocoding Inside the DB Transaction

**What:** Adding address geocoding to the `complete_connect_flow` RPC or any existing RPC.

**Why wrong:** The Census Geocoder is an external HTTP call. External I/O inside a Postgres transaction holds locks and creates a hard dependency on third-party availability. If Census API is slow (measured in seconds), the transaction holds a row lock on `verification_sessions` for that duration.

**Do instead:** Geocode in the Express service layer before calling the RPC. The RPC receives only the resolved float8 coordinates.

---

### Anti-Pattern 2: Returning Coordinates in Any API Response

**What:** Adding `lat` or `lng` fields to `/api/account/me` or any other endpoint.

**Why wrong:** The product decision (confirmed in STATE.md) is that raw coordinates never leave the accounts system. The jurisdiction endpoint is the only exit path. Exposing coordinates even to the owning user creates audit/privacy risk.

**Do instead:** The route handler calls `resolve_user_jurisdiction` and returns only the jurisdiction struct. The `lat`/`lng` columns are excluded from all SELECT lists in route code.

---

### Anti-Pattern 3: Encrypting in the Express Layer

**What:** Calling `pgp_sym_encrypt` equivalent via Node.js crypto, sending the result to Supabase as a hex string.

**Why wrong:** The encryption key would need to be available in the Express process environment. This means it lives in environment variables accessible to all application code. The Vault pattern keeps the key inside the database, never accessible to the application tier.

**Do instead:** Pass plaintext coordinates to the `SECURITY DEFINER` RPC. The RPC reads the Vault key and encrypts inside Postgres. The key never crosses the DB boundary.

---

### Anti-Pattern 4: Using `.is('location_consent', null)` for the Jurisdiction Gate

**What:** Checking `location_consent IS NULL` to mean "no consent."

**Why wrong:** This would allow a row with `location_consent = false` to slip through.

**Do instead:** The RPC uses `IF v_cp.location_consent IS NOT TRUE` — this correctly handles NULL, false, and any unexpected value as "no consent." The route handler maps the resulting `NO_LOCATION_CONSENT` exception to 403.

---

### Anti-Pattern 5: ST_Contains With Mixed geometry/geography Types

**What:** Calling `ST_Contains(boundary, point)` where `boundary` is `geography` and `point` is `geometry` (or vice versa) without explicit casting.

**Why wrong:** PostGIS does not automatically coerce between `geometry` and `geography`. The query will either error or silently produce wrong results.

**Do instead:** Explicitly cast both operands to the same type. The RPC above casts `boundary::extensions.geometry` and creates the point as `geometry` via `ST_SetSRID(ST_MakePoint(...), 4326)`. Consistent casting is required.

---

## Integration With Existing Patterns

This section confirms how the new components align with the patterns already established in the codebase.

| Existing pattern | How location components comply |
|-----------------|-------------------------------|
| SECURITY DEFINER + `SET search_path = ''` | Both RPCs use this. All table refs and function calls are fully qualified. |
| Two-pass validation in atomic RPCs | `update_user_location` validates consent and coordinate range before reading the Vault key or writing any data. |
| `adminRpc()` wrapper for RPC calls | Both RPCs are called via `adminRpc('function_name', args, 'connect')` — the schema parameter routes to `connect` schema. |
| Service role never used for reads in routes | `resolve_user_jurisdiction` result is opaque JSON — no route code reads raw `connected_profiles` columns. |
| Sensitive columns excluded from SELECT lists | `lat`, `lng` must be added to the exclusion list alongside `tolerance_rating`, `legal_name`. |
| Additive migration strategy | All schema changes are additive (`ADD COLUMN IF NOT EXISTS`, new tables). |
| `connected_profiles_public` view excludes PII | `lat`, `lng`, `location_consent`, `location_set_at` must be explicitly excluded from this view in the migration that adds them. |

---

## Open Questions

1. **PostGIS in local dev:** Supabase local development via `supabase start` uses a Docker image that may not have PostGIS enabled by default. Verify `extensions.postgis` exists in local dev before writing the boundary migration. Run `supabase db reset` after enabling.

2. **Vault in local dev:** The Vault extension is available in Supabase local dev but requires manual key setup. The development workflow needs a `seed.sql` or setup script that creates the `location_encryption_key` in the local Vault before tests run. This key value can be a fixed test passphrase in dev (not the production value).

3. **Census Geocoder reliability:** The Census Geocoder has no SLA and is rate-limited informally. For Alpha (small cohort, rare location-setting events), this is acceptable. If the API is unavailable, `set-location` fails gracefully with 503. Plan to evaluate alternatives at scale.

4. **Boundary data refresh cadence:** Indiana redistricting happened in 2022 for the current legislative session (effective 2023). The 2024 TIGER files reflect the current boundaries. Next redistricting is post-2030 census. Boundary data can be treated as static for the Alpha period.

5. **MULTIPOLYGON vs POLYGON:** Most Indiana districts are single polygons, but a MULTIPOLYGON type handles edge cases (non-contiguous districts) without schema change. Verify TIGER data uses `MULTIPOLYGON` in the shapefile geometry type before writing the CREATE TABLE migration — if it is `POLYGON`, use that type and avoid unnecessary complexity.

---

## Sources

- Supabase Vault documentation: https://supabase.com/docs/guides/database/vault
- pgsodium deprecation notice: https://supabase.com/docs/guides/database/extensions/pgsodium
- pgcrypto function signatures: https://www.postgresql.org/docs/current/pgcrypto.html
- PostGIS in Supabase: https://supabase.com/docs/guides/database/extensions/postgis
- Census Geocoder API: https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html
- Census 2024 TIGER/Line shapefiles: https://www.census.gov/cgi-bin/geo/shapefiles/index.php
- bytea return type in supabase-js: https://github.com/orgs/supabase/discussions/2441
- Supabase Vault blog: https://supabase.com/blog/supabase-vault
- Indiana redistricting data: https://thearp.org/state/indiana/
- Nominatim usage policy (privacy): https://operations.osmfoundation.org/policies/nominatim/
- Actual `complete_connect_flow` RPC: `C:/EV-Accounts/backend/migrations/025_rpc_pool_migration.sql` (lines 1286–1354)
- Existing SECURITY DEFINER RPC pattern: `C:/EV-Accounts/supabase/migrations/20260224000010_rpc_functions.sql`
- `adminRpc` wrapper: `C:/EV-Accounts/backend/src/lib/supabase.ts`

---

*Architecture research for: location infrastructure integration — Supabase Vault + pgcrypto + PostGIS*
*Researched: 2026-03-09*
