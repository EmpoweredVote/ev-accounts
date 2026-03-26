# Phase 49: Stored Jurisdiction & Cross-App Location Profile - Research

**Researched:** 2026-03-26
**Domain:** Postgres schema migration, Express backend, multi-app TypeScript/React frontend integration
**Confidence:** HIGH — all findings from direct codebase inspection

## Summary

This phase stores the 5 district GEO IDs (plus `state` and `city`) directly on `connect.connected_profiles` at set-location time, so every app can read the user's jurisdiction from `/api/account/me` without asking for their address again. The current architecture re-runs the `resolve_user_jurisdiction` RPC on every `/api/account/me` call, which decrypts coordinates and does a PostGIS spatial query every request. Storing GEO IDs eliminates that per-request cost and also enables cross-app access without each app needing to call a separate endpoint.

The core work is: (1) add 7 columns to `connect.connected_profiles`, (2) update `set-location` to write those columns directly from the geocoder + jurisdiction RPC results, (3) update `/api/account/me` to read from the new columns instead of calling `resolve_user_jurisdiction` at read time, (4) add `state` and `city` to the `jurisdiction` response shape, (5) update the 3 consuming apps minimally. `home_address` stays on the profile (it's the fallback path for `/representatives/me` and is currently stored there — Phase 49 does NOT change that, it just adds GEO ID columns alongside it).

**Primary recommendation:** Store GEO IDs at write time (set-location) not read time. The `jurisdiction` object on `/account/me` already exists and is consumed by all 3 apps — extend it in place with `state` and `city` fields.

---

## Key Findings (Answers to the 10 Research Questions)

### Q1: What does `geocodeAddress()` currently return?

`geocodeAddress()` returns `{ lat, lng, matchedAddress, state }` — source: `C:/EV-Accounts/backend/src/lib/geocodingService.ts` line 71 and 143.

- `state` = 2-letter abbreviation (e.g. `"IN"`) from `addressComponents.state`
- `city` = available as `addressComponents.city` in the Census response but is NOT currently extracted or returned
- GEO IDs are NOT returned — those come from the PostGIS `resolve_user_jurisdiction` RPC via the encrypted coordinates

**Implication for Phase 49:** `state` is already available from the geocoder. `city` needs to be added to the `geocodeAddress()` return value. GEO IDs are not in the geocoder response — they come from `resolve_user_jurisdiction` after coordinate storage.

### Q2: What does `resolve_user_jurisdiction` return?

Source: `C:/EV-Accounts/supabase/migrations/20260310000032_location_rpcs.sql`

Returns a `jsonb` object with exactly 10 keys:
```
congressional, congressional_name,
state_senate, state_senate_name,
state_house, state_house_name,
county, county_name,
school_district, school_district_name
```

Values are `text | null`. GEO IDs are TIGER/Line format (e.g. `congressional = "1807"`, `county = "18097"`). The RPC does NOT return `state` or `city`.

**Implication:** `state` comes from `geocodeAddress()`, `city` must be extracted from `geocodeAddress()`. The 5 GEO IDs (`congressional`, `state_senate`, `state_house`, `county`, `school_district`) come from the RPC. The current `set-location` route already calls both sequentially — we just need to write the results to new columns.

### Q3: What columns does `connect.connected_profiles` currently have?

From the migration history (no GEO ID columns exist yet):

**Original columns** (migration 004): `id, user_id, display_name, account_standing, verification_status, verification_method, verified_region, xp, gem_balance, gem_reserve_cap, veracity_rating, tolerance_rating, deleted_at, created_at, updated_at`

**Added in Phase 3** (migration 014): `home_address TEXT`

**Added in Phase 17** (migration 031): `encrypted_lat bytea, encrypted_lng bytea, location_consent boolean, location_set_at timestamptz`

**Added in other phases** (via column adds in subsequent migrations): `total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, verification_rating, vq_hold_until`

**No GEO ID columns exist.** Phase 49 must add:
- `congressional_geo_id TEXT`
- `state_senate_geo_id TEXT`
- `state_house_geo_id TEXT`
- `county_geo_id TEXT`
- `school_district_geo_id TEXT`
- `jurisdiction_state TEXT` (2-letter state abbreviation — not `state` to avoid SQL reserved word collision)
- `jurisdiction_city TEXT`

### Q4: What does GET /account/me currently return for jurisdiction?

Source: `C:/EV-Accounts/backend/src/routes/account.ts` lines 106–132

**Current behavior:** When `connected?.location_consent` is true, the route calls `adminRpc('resolve_user_jurisdiction', { p_user_id: authReq.userId }, 'connect')` every request. This decrypts coordinates (Vault + pgcrypto), does a PostGIS spatial query, and builds the jurisdiction object.

**Current `jurisdiction` shape returned:**
```typescript
{
  congressional_district: string | null,        // GEO ID e.g. "1807"
  congressional_district_name: string | null,   // district name
  state_senate_district: string | null,
  state_senate_district_name: string | null,
  state_house_district: string | null,
  state_house_district_name: string | null,
  county: string | null,
  county_name: string | null,
  school_district: string | null,
  school_district_name: string | null,
}
```

Note: The GEO IDs use `*_district` suffix in the response (e.g. `congressional_district` not `congressional_geo_id`). The `*_name` fields come from `resolve_user_jurisdiction` — these will still require the RPC when building the stored response, OR the names could also be stored. **Decision needed:** store names or re-query?

**Current `jurisdiction` is also called in:**
- `PATCH /api/account/me` (same pattern, same code, lines 413–440)
- `GET /api/account/me/jurisdiction` (dedicated endpoint, lines 225–269)

**After Phase 49:** Replace the `resolve_user_jurisdiction` call in GET and PATCH `/account/me` with a direct `pool.query()` read of the new columns. The dedicated `/account/me/jurisdiction` endpoint could also be updated.

### Q5: What does `getRepresentativesByJurisdiction` expect?

Source: `C:/EV-Accounts/backend/src/lib/essentialsService.ts` lines 1300–1310

```typescript
export interface JurisdictionGeoIds {
  congressional: string | null;
  state_senate: string | null;
  state_house: string | null;
  county: string | null;
  school_district: string | null;
}

export async function getRepresentativesByJurisdiction(
  jurisdiction: JurisdictionGeoIds
): Promise<PoliticianFlatRecord[]>
```

Input is the 5 GEO ID strings (no names needed). Matches directly against `essentials.districts.geo_id`. Currently in `/representatives/me`, the route calls `resolve_user_jurisdiction` RPC to get these GEO IDs, then passes them to `getRepresentativesByJurisdiction`. After Phase 49, it can read the stored GEO IDs directly from `connected_profiles`.

### Q6: Do existing Connected users have encrypted coordinates for backfill?

From the phase description: "11 existing Connected users." The `resolve_user_jurisdiction` RPC only works when `encrypted_lat` and `encrypted_lng` are non-null AND `location_consent = true` (line 119 of the RPC migration). Users without location consent will have null GEO IDs after backfill — that is correct behavior.

The backfill SQL would be something like:
```sql
UPDATE connect.connected_profiles cp
SET
  congressional_geo_id    = (j->>'congressional'),
  state_senate_geo_id     = (j->>'state_senate'),
  state_house_geo_id      = (j->>'state_house'),
  county_geo_id           = (j->>'county'),
  school_district_geo_id  = (j->>'school_district')
FROM (
  SELECT user_id, connect.resolve_user_jurisdiction(user_id) AS j
  FROM connect.connected_profiles
  WHERE location_consent = true
) sub
WHERE cp.user_id = sub.user_id;
```

**Caveat:** `resolve_user_jurisdiction` is a `SECURITY DEFINER` function that requires the Vault key. It can be called inside a migration as long as the Vault secret exists in production. The backfill will NOT populate `jurisdiction_state` or `jurisdiction_city` because those come from the geocoder, not from the RPC — those columns will be null for existing users until they re-set their location.

### Q7: What is the `JurisdictionGeoIds` type in essentialsService.ts?

Documented in Q5 above. It uses short field names (`congressional`, `state_senate`, `state_house`, `county`, `school_district`) — not the `*_district` naming convention used in the API response shape.

### Q8: Does Read & Rank use `jurisdiction` from AuthState?

Source: `C:/read-rank/src/hooks/useAuthState.ts` and `C:/read-rank/src/lib/auth.ts`

Read & Rank's `AuthState` interface is minimal:
```typescript
interface AuthState {
  isLoggedIn: boolean;
  userName: string | null;
  loading: boolean;
}
```

It calls `/account/me` and reads only `data.display_name`. **`jurisdiction` is not in `AuthState` and is not read.**

The phase description says "Read & Rank reads `jurisdiction.state`" — this is a planned addition, not current behavior. Read & Rank will need to:
1. Add a `state` field or `jurisdiction` field to its auth state
2. Fetch `/account/me` and extract `jurisdiction.state` (or the new `state` field directly)

The purpose would be to pre-filter politicians by state. The `AddressFilterInput.tsx` already calls `/essentials/browse/states` to populate a state dropdown — Read & Rank could pre-select the user's state from `jurisdiction.state`.

### Q9: Does CTC's `AccountProfile` type include `jurisdiction`?

Source: `C:/Project Test/frontend/src/types/auth.ts`

Current `AccountProfile`:
```typescript
export interface AccountProfile {
  id: string;
  email: string;
  display_name: string;
  avatar_url: string | null;
  tier: Tier;
  account_standing: string;
  connected_profile?: {
    xp: number | { total?: number; total_xp?: number; level?: number; xp_in_level?: number; xp_to_next_level?: number };
    gem_balance: number;
    display_name: string;
    verification_status?: string;
    completed_onboarding?: boolean;
  };
}
```

**`jurisdiction` is not in `AccountProfile`.** CTC would need to add it if Phase 49 requires CTC to consume jurisdiction data. The phase description says "CTC extends `AccountProfile` type" — this means adding a `jurisdiction` field to the interface.

### Q10: In Essentials, what triggers the auto-redirect to /results?

Source: `C:/Transparent Motivations/essentials/src/pages/Landing.jsx` lines 15–19 and `C:/Transparent Motivations/essentials/src/contexts/CompassContext.jsx`

**Auto-redirect condition** (Landing.jsx):
```jsx
useEffect(() => {
  if (!compassLoading && isLoggedIn && myRepresentatives && myRepresentatives.length > 0) {
    navigate('/results?prefilled=true', { replace: true });
  }
}, [compassLoading, isLoggedIn, myRepresentatives, navigate]);
```

**How `myRepresentatives` is populated** (CompassContext.jsx lines 115–124):
```jsx
const [answersResult, selectedResult, repsResult] = await Promise.all([
  fetchUserAnswers(),
  fetchSelectedTopics(),
  fetchMyRepresentatives(),  // calls /essentials/representatives/me
]);
if (!cancelled && !repsResult.error && repsResult.data.length > 0) {
  setMyRepresentatives(repsResult.data);
  setMyRepresentativesAddress(repsResult.formattedAddress || null);
}
```

**`fetchMyRepresentatives`** (api.jsx lines 140–148) calls `GET /api/essentials/representatives/me`.

**The auto-redirect already works** when `representatives/me` returns data. Phase 49 changes the backend path `representatives/me` takes — it will read stored GEO IDs instead of calling `resolve_user_jurisdiction` — but the Essentials frontend change is minimal or zero if the response shape is unchanged.

The phase description says "Essentials uses prefilled jurisdiction on load" — this is already the case. The change is that the backend path becomes faster (stored GEO ID lookup vs. decrypt + PostGIS spatial query).

---

## Standard Stack

No new libraries needed. All work uses existing patterns.

### Core (unchanged)
| Tool | Version | Purpose |
|------|---------|---------|
| `pool.query()` | pg (existing) | All `connect.*` schema reads/writes — NEVER PostgREST |
| `adminRpc()` | supabase-js (existing) | RPC calls to `connect.*` functions |
| `z` (Zod) | existing | Input validation on routes |
| PostgreSQL ALTER TABLE | production Supabase | Adding GEO ID columns |

### No Installation Required
No new packages. Phase 49 is schema + code changes only.

---

## Architecture Patterns

### Pattern 1: Write at set-location, Read from columns

**Current flow (read-time computation):**
```
GET /account/me → resolve_user_jurisdiction RPC → decrypt coords → PostGIS query → return jurisdiction
```

**New flow (stored):**
```
POST /connect/set-location → geocodeAddress → upsert_user_location → pool.query UPDATE geo_id columns
GET /account/me → pool.query SELECT geo_id columns → return jurisdiction (no RPC, no PostGIS)
```

**Where to write in set-location (connect.ts):**
```typescript
// After upsert_user_location succeeds, call resolve_user_jurisdiction
// then write GEO IDs + state + city directly to connected_profiles

// Already available: coords.state from geocodeAddress()
// Need to add: coords.city from geocodeAddress() (minor geocodingService change)
// GEO IDs: from resolve_user_jurisdiction call (already made in set-location)

pool.query(
  `UPDATE connect.connected_profiles
   SET congressional_geo_id   = $2,
       state_senate_geo_id    = $3,
       state_house_geo_id     = $4,
       county_geo_id          = $5,
       school_district_geo_id = $6,
       jurisdiction_state     = $7,
       jurisdiction_city      = $8,
       updated_at             = now()
   WHERE user_id = $1`,
  [userId, j.congressional, j.state_senate, j.state_house, j.county, j.school_district,
   coords.state, coords.city]
)
```

### Pattern 2: account.ts reads GEO IDs from profile row

The `connected_profiles` SELECT in `/account/me` already fetches many columns. Add the 7 new columns to that SELECT. Build the jurisdiction object from the columns instead of calling the RPC.

**One important decision:** `*_name` fields (e.g. `congressional_district_name`) are currently returned by `resolve_user_jurisdiction`. If we stop calling the RPC on reads, we lose the names unless we also store them. Options:
- **Option A (recommended):** Also store the 5 `_name` fields at write time — add 5 more columns (`congressional_name`, `state_senate_name`, `state_house_name`, `county_name`, `school_district_name`). This gives full parity with the current response shape.
- **Option B:** Keep calling the RPC only for names. Defeats the purpose.
- **Option C:** Drop `_name` fields from the response. Breaking change for consuming apps.

**Recommendation: Option A** — store all 10 jurisdiction fields (5 GEO IDs + 5 names) + state + city = 12 new columns total. The planner should make this explicit in the migration task.

### Pattern 3: representatives/me reads from stored columns

Current `/representatives/me` (essentials.ts lines 328–344):
```typescript
const { data, error } = await adminRpc('resolve_user_jurisdiction', { p_user_id: userId }, 'connect');
const politicians = await getRepresentativesByJurisdiction({
  congressional: jurisdictionData.congressional ?? null,
  ...
});
```

After Phase 49: Skip the RPC call. Read GEO IDs directly from `connected_profiles`:
```typescript
const { rows } = await pool.query(
  `SELECT congressional_geo_id, state_senate_geo_id, state_house_geo_id,
          county_geo_id, school_district_geo_id, home_address
   FROM connect.connected_profiles WHERE user_id = $1`,
  [userId]
);
// Path 1: stored GEO IDs present
if (rows[0]?.congressional_geo_id || rows[0]?.county_geo_id) {
  const politicians = await getRepresentativesByJurisdiction({
    congressional: rows[0].congressional_geo_id,
    state_senate: rows[0].state_senate_geo_id,
    state_house: rows[0].state_house_geo_id,
    county: rows[0].county_geo_id,
    school_district: rows[0].school_district_geo_id,
  });
  // ...
}
// Path 2: fallback to home_address geocoding (existing behavior for users without stored GEO IDs)
```

### Pattern 4: Backfill via SQL migration

The backfill for existing users must be done inside a migration that calls `resolve_user_jurisdiction` for each user with `location_consent = true`. The function is already SECURITY DEFINER and accessible from migrations.

```sql
-- Backfill GEO IDs for existing users with location consent
UPDATE connect.connected_profiles cp
SET
  congressional_geo_id    = (j->>'congressional'),
  state_senate_geo_id     = (j->>'state_senate'),
  state_house_geo_id      = (j->>'state_house'),
  county_geo_id           = (j->>'county'),
  school_district_geo_id  = (j->>'school_district'),
  congressional_name      = (j->>'congressional_name'),
  state_senate_name       = (j->>'state_senate_name'),
  state_house_name        = (j->>'state_house_name'),
  county_name             = (j->>'county_name'),
  school_district_name    = (j->>'school_district_name')
FROM (
  SELECT user_id, connect.resolve_user_jurisdiction(user_id) AS j
  FROM connect.connected_profiles
  WHERE location_consent = true
    AND encrypted_lat IS NOT NULL
) sub
WHERE cp.user_id = sub.user_id;
-- Note: jurisdiction_state and jurisdiction_city NOT backfilled (geocoder required)
-- They will be null for existing users until re-set-location
```

### Anti-Patterns to Avoid

- **Calling `resolve_user_jurisdiction` at read time** — this is the pattern being replaced; defeats the purpose of Phase 49
- **Using PostgREST to write to `connect.*` schema** — must use `pool.query()` for all `connected_profiles` writes
- **Returning raw coordinates in any API response** — privacy invariant; never expose lat/lng
- **Spreading DB rows into responses** — existing codebase rule; always use explicit field whitelists

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema migration | Custom migration runner | Supabase migrations (`.sql` file) | Existing pattern; applied via `apply_migration` MCP |
| Backfill logic | JS loop over users | Single SQL UPDATE with subquery | Atomic, server-side, no N+1 |
| GEO ID lookup | New PostGIS query | Existing `resolve_user_jurisdiction` RPC (for backfill + set-location) | Already battle-tested |
| `city` extraction | New geocoder API call | Extend existing `geocodeAddress()` return | Census API already returns city in `addressComponents.city` |

---

## Common Pitfalls

### Pitfall 1: Forgetting to store `_name` fields
**What goes wrong:** The `jurisdiction` object returned by `/account/me` currently includes `congressional_district_name`, `county_name`, etc. These come from `resolve_user_jurisdiction`. If we stop calling the RPC at read time but don't store the names, consumers like `DashboardPage.tsx` (accounts app) will lose the name display (they show `jurisdiction[key]` from `DISTRICT_LABELS` mapping).
**How to avoid:** Store all 10 fields (5 GEO IDs + 5 names) at write time. Add all 10 as columns.

### Pitfall 2: `pool.query()` required for connected_profiles writes
**What goes wrong:** `supabaseAdmin.schema('connect').from('connected_profiles').update()` fails via PostgREST. Must use `pool.query()`.
**Why it happens:** `connect` schema is not in PostgREST's exposed schema list (see project memory: "every write to a non-public schema must use `pool.query()`").

### Pitfall 3: Backfill RPC call may fail for users without boundaries loaded
**What goes wrong:** If a user's lat/lng doesn't fall within any loaded `inform.district_boundaries` polygon, `resolve_user_jurisdiction` returns a jsonb with all-null values — that is fine. But if the Vault key is missing (dev environment without Vault configured), the RPC raises an exception.
**How to avoid:** The backfill SQL should be safe in prod (Vault exists). Add a `WHERE encrypted_lat IS NOT NULL` guard. Document that `jurisdiction_state` / `jurisdiction_city` will be null after backfill (requires re-set-location to populate).

### Pitfall 4: `city` is NOT currently extracted in `geocodeAddress()`
**What goes wrong:** The Census geocoder response includes `addressComponents.city` but `geocodeAddress()` currently only extracts `state` (added in the Census migration). If `city` is needed in Phase 49, it must be added to the function return type AND the cache serialization.
**How to avoid:** Add `city: string` to the `geocodeAddress()` return type and extraction logic. Update the cache key format if needed (or just add `city` to the cached object — backward-compatible since cache hits return it).

### Pitfall 5: `home_address` must NOT be removed
**What goes wrong:** The `representatives/me` fallback path (Path 2) geocodes `home_address` directly for users without encrypted coordinates. `home_address` is also shown in `X-Formatted-Address` header. Removing it breaks the fallback.
**How to avoid:** Keep `home_address` column as-is. Phase 49 only ADDS new GEO ID columns alongside it. The privacy constraint in the phase description means "don't store home_address for NEW Connected tier users" — but the column exists and is used; removing it is out of scope.

### Pitfall 6: Read & Rank `AuthState` doesn't have `jurisdiction`
**What goes wrong:** Read & Rank's `useAuthState.ts` only stores `isLoggedIn`, `userName`, `loading`. The `jurisdiction` field from `/account/me` is discarded. The plan must add a `state` field (or full `jurisdiction` object) to the Read & Rank auth state.
**How to avoid:** Update `loadProfile()` in `useAuthState.ts` to extract `data.jurisdiction?.state` (or add it to the state shape). Update the `AuthState` interface.

### Pitfall 7: CTC's `AccountProfile` is incomplete
**What goes wrong:** `C:/Project Test/frontend/src/types/auth.ts` does not include `jurisdiction`. If CTC needs to read jurisdiction from `/account/me`, the type must be extended.
**How to avoid:** Add `jurisdiction?: { state?: string; ... } | null` to `AccountProfile`. Since CTC currently doesn't use jurisdiction for anything, verify the scope — the phase description says "CTC extends AccountProfile type" but doesn't say CTC uses jurisdiction for any actual feature.

---

## Code Examples

### geocodeAddress() extended return type
```typescript
// Source: C:/EV-Accounts/backend/src/lib/geocodingService.ts (current line 71)
// Add `city` to return and cache
export async function geocodeAddress(address: string): Promise<{
  lat: number;
  lng: number;
  matchedAddress: string;
  state: string;
  city: string;   // ADD THIS
}>
// Extraction: matches[0].addressComponents.city ?? ''
// Cache: include city in the stored object
```

### set-location: write GEO IDs after resolve_user_jurisdiction
```typescript
// Source: C:/EV-Accounts/backend/src/routes/connect.ts (current lines 566-596)
// After the existing adminRpc('resolve_user_jurisdiction') call succeeds:
const j = (jurisdictionData ?? {}) as Record<string, string | null>;
const coords = await geocodeAddress(address); // already called earlier — pass city through

// Write GEO IDs + names + state + city to connected_profiles (fire-and-forget, non-fatal)
pool.query(
  `UPDATE connect.connected_profiles
   SET congressional_geo_id    = $2,
       congressional_name      = $3,
       state_senate_geo_id     = $4,
       state_senate_name       = $5,
       state_house_geo_id      = $6,
       state_house_name        = $7,
       county_geo_id           = $8,
       county_name             = $9,
       school_district_geo_id  = $10,
       school_district_name    = $11,
       jurisdiction_state      = $12,
       jurisdiction_city       = $13,
       updated_at              = now()
   WHERE user_id = $1`,
  [userId, j.congressional, j.congressional_name, j.state_senate, j.state_senate_name,
   j.state_house, j.state_house_name, j.county, j.county_name,
   j.school_district, j.school_district_name, coords.state, coords.city]
).catch((err: Error) => console.error('[set-location] failed to write geo_ids:', err.message));
```

### account.ts: read GEO IDs from profile instead of RPC
```typescript
// Source: C:/EV-Accounts/backend/src/routes/account.ts
// Replace the resolve_user_jurisdiction RPC call in GET /account/me:

// REMOVE this (lines 107-132):
// const { data: jData, error: jError } = await adminRpc('resolve_user_jurisdiction', ...)

// ADD to the connected_profiles SELECT (line 62):
// 'congressional_geo_id, congressional_name, state_senate_geo_id, state_senate_name,
//  state_house_geo_id, state_house_name, county_geo_id, county_name,
//  school_district_geo_id, school_district_name, jurisdiction_state, jurisdiction_city'

// Build jurisdiction from columns:
jurisdictionData = connected?.location_consent ? {
  congressional_district: connected.congressional_geo_id ?? null,
  congressional_district_name: connected.congressional_name ?? null,
  state_senate_district: connected.state_senate_geo_id ?? null,
  state_senate_district_name: connected.state_senate_name ?? null,
  state_house_district: connected.state_house_geo_id ?? null,
  state_house_district_name: connected.state_house_name ?? null,
  county: connected.county_geo_id ?? null,
  county_name: connected.county_name ?? null,
  school_district: connected.school_district_geo_id ?? null,
  school_district_name: connected.school_district_name ?? null,
  state: connected.jurisdiction_state ?? null,           // NEW field
  city: connected.jurisdiction_city ?? null,             // NEW field
} : null;
```

### Essentials CompassContext: already works with current response
```jsx
// Source: C:/Transparent Motivations/essentials/src/contexts/CompassContext.jsx line 113
// setUserJurisdiction(authedUser.jurisdiction ?? null);  <-- already reads jurisdiction from /account/me
// No change needed if jurisdiction response shape is additive (new state/city fields are just extras)
```

### Read & Rank: add state to AuthState
```typescript
// Source: C:/read-rank/src/hooks/useAuthState.ts
export interface AuthState {
  isLoggedIn: boolean;
  userName: string | null;
  loading: boolean;
  jurisdictionState: string | null;   // ADD: 2-letter state abbreviation
}

// In loadProfile():
const data = await res.json();
setState({
  isLoggedIn: true,
  userName: data.display_name ?? null,
  loading: false,
  jurisdictionState: data.jurisdiction?.state ?? null,  // ADD
});
```

---

## Current Jurisdiction Response Shape vs. Extended Shape

| Field | Current | After Phase 49 |
|-------|---------|---------------|
| `congressional_district` | GEO ID or null | Same |
| `congressional_district_name` | name or null | Same |
| `state_senate_district` | GEO ID or null | Same |
| `state_senate_district_name` | name or null | Same |
| `state_house_district` | GEO ID or null | Same |
| `state_house_district_name` | name or null | Same |
| `county` | GEO ID or null | Same |
| `county_name` | name or null | Same |
| `school_district` | GEO ID or null | Same |
| `school_district_name` | name or null | Same |
| `state` | absent | 2-letter abbrev or null (NEW) |
| `city` | absent | city string or null (NEW) |

Adding `state` and `city` is backward-compatible (additive) for all consumers.

---

## State of the Art

| Old Approach | New Approach (Phase 49) | Impact |
|--------------|------------------------|--------|
| `resolve_user_jurisdiction` called on every `/account/me` | Read stored GEO IDs from columns | Eliminates Vault access + pgcrypto decrypt + PostGIS spatial query per request |
| `home_address` only stored reference | GEO IDs stored directly | Any app reading `/account/me` gets full jurisdiction without extra calls |
| `representatives/me` calls `resolve_user_jurisdiction` | Reads stored GEO IDs | Path 1 becomes a simple column read; Path 2 (address fallback) unchanged |

---

## Open Questions

1. **Should `state` and `city` be top-level on the response or inside `jurisdiction`?**
   - What we know: `jurisdiction` is an object on `/account/me`; `state` and `city` logically belong there
   - Recommendation: Put both inside the `jurisdiction` object as `jurisdiction.state` and `jurisdiction.city`

2. **Should `/account/me/jurisdiction` (dedicated endpoint) also be updated?**
   - What we know: It calls `resolve_user_jurisdiction` today; after Phase 49 it could just read from columns
   - Recommendation: Yes, update it to read from columns — consistent with Phase 49 goal

3. **Is `home_address` removal actually in scope?**
   - Phase description says "home_address is NOT stored for Connected tier" but the column already exists and is used for the fallback path in `representatives/me`
   - Recommendation: Do NOT remove `home_address`. Scope is "don't pass home_address back in API responses" (already not done) and the privacy goal is met by storing GEO IDs instead of passing the raw address cross-app. The column stays.

4. **What exactly does CTC do with `jurisdiction`?**
   - The phase description says "CTC extends AccountProfile type" but doesn't specify a feature
   - Recommendation: CTC task is just a type extension (add `jurisdiction?: {...} | null` to `AccountProfile`) — no CTC feature behavior changes unless specified

---

## Sources

All findings are from direct codebase inspection — no external sources needed for this domain.

### Primary (HIGH confidence)
- `C:/EV-Accounts/backend/src/routes/connect.ts` — set-location route, current flow
- `C:/EV-Accounts/backend/src/routes/account.ts` — GET/PATCH /account/me, jurisdiction building
- `C:/EV-Accounts/backend/src/routes/essentials.ts` — representatives/me route
- `C:/EV-Accounts/backend/src/lib/geocodingService.ts` — geocodeAddress() return type
- `C:/EV-Accounts/backend/src/lib/essentialsService.ts` — JurisdictionGeoIds interface, getRepresentativesByJurisdiction
- `C:/EV-Accounts/supabase/migrations/20260310000032_location_rpcs.sql` — resolve_user_jurisdiction return shape
- `C:/EV-Accounts/supabase/migrations/20260310000031_location_schema.sql` — current location columns on connected_profiles
- `C:/EV-Accounts/supabase/migrations/20260224000004_connect_connected_profiles.sql` — original schema
- `C:/Transparent Motivations/essentials/src/contexts/CompassContext.jsx` — Essentials auth + jurisdiction + auto-redirect
- `C:/Transparent Motivations/essentials/src/pages/Landing.jsx` — auto-redirect trigger condition
- `C:/Transparent Motivations/essentials/src/lib/api.jsx` — fetchMyRepresentatives()
- `C:/read-rank/src/hooks/useAuthState.ts` — Read & Rank AuthState (no jurisdiction)
- `C:/Project Test/frontend/src/types/auth.ts` — CTC AccountProfile (no jurisdiction)
- `C:/EV-Accounts/app/src/pages/DashboardPage.tsx` — accounts app jurisdiction display

---

## Metadata

**Confidence breakdown:**
- Schema (new columns needed): HIGH — confirmed no GEO ID columns exist in any migration
- Backend changes (set-location, account.ts): HIGH — read all relevant source files
- Backfill approach: HIGH — `resolve_user_jurisdiction` RPC is callable from SQL
- Geocoder `city` field: HIGH — Census response shape confirmed in geocodingService.ts
- Frontend changes (Read & Rank, CTC, Essentials): HIGH — read all three app auth files
- `_name` column recommendation: MEDIUM — based on analysis of current response consumers; planner should confirm whether names must be stored or can be dropped

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (stable codebase — no fast-moving dependencies)
