# Phase 19: Location Schema & RPCs - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Encrypted coordinate storage and PostGIS jurisdiction resolution — the data layer only. Delivers:
1. `connected_profiles` gains `encrypted_lat`, `encrypted_lng`, `location_consent` columns
2. `inform.district_boundaries` table created with geometry column (populated via runbook, not migration)
3. `connect.upsert_user_location(user_id)` RPC — writes pgcrypto-encrypted coords, sets `location_consent = true`
4. `connect.resolve_user_jurisdiction(user_id)` RPC — decrypts coords, runs ST_Covers against boundaries, returns jurisdiction JSON

Phase 20 builds the API endpoints (`POST /api/connect/set-location`, `GET /api/account/me/jurisdiction`) on top of this layer.

</domain>

<decisions>
## Implementation Decisions

### Jurisdiction return shape
- Return ID only per district — no names in the RPC return value (names are in `district_boundaries` for lookup)
- Struct keyed by district_type: `{ congressional, state_senate, state_house, county, school_district }`
- `null` per district type when no boundary match (partial results allowed; Phase 20 decides error handling)
- `resolve_user_jurisdiction(user_id uuid)` — accepts user_id only; decrypts stored coords internally. Plaintext coordinates never appear in the call signature or return value.

### Encryption key management
- Key stored in **Supabase Vault** — fetched via `vault.decrypted_secrets` inside the RPC
- Use **`pgp_sym_encrypt` / `pgp_sym_decrypt`** (high-level PGP symmetric; handles IV generation automatically)
- Vault secret name: Claude's discretion (document the chosen name in the runbook)
- `upsert_user_location` returns **void** — Phase 20 calls `resolve_user_jurisdiction` separately

### District boundary scope
- **All 5 district types** loaded in Phase 19's runbook step: congressional, state_senate, state_house, county, school_district
- Table lives in **`inform` schema**: `inform.district_boundaries`
- District identifier: **TIGER/Line GEOID** (raw, no transformation — what ogr2ogr outputs natively)
- Include **name column** (NAMELSAD or equivalent from TIGER/Line) alongside geoid and geometry — no separate lookup table needed downstream

### connected_profiles columns
- Three columns added in Phase 19 migration: `encrypted_lat bytea`, `encrypted_lng bytea`, `location_consent boolean`
- `location_consent` lives in Phase 19 — `upsert_user_location` sets it to `true` atomically when writing coords
- No `jurisdiction_cache` column — Phase 19 resolves on demand; caching is a Phase 20+ decision
- Column type `bytea` for encrypted values (Claude's discretion — natural pgp_sym_encrypt output)

### Claude's Discretion
- Vault secret name for the encryption key
- Exact pgcrypto cipher options (e.g., `cipher-algo=aes256` in the pgp options string)
- ogr2ogr flags and load order for the 5 boundary layers
- PostGIS spatial index creation (type, naming)
- RPC SET search_path = '' + SECURITY DEFINER conventions (follow existing project pattern)

</decisions>

<specifics>
## Specific Ideas

- Both RPCs must follow the project SECURITY DEFINER convention: `SET search_path = ''` with fully-qualified table refs
- Success criteria verification: direct DB inspection of `encrypted_lat` must show ciphertext (not plaintext float); `resolve_user_jurisdiction` tested against a known Bloomington, IN address → confirmed Indiana 9th congressional district GEOID
- TIGER/Line runbook must document: ogr2ogr flags, Indiana FIPS filter, SRID reprojection 4269→4326, post-load SRID verification query
- PostGIS and pgcrypto extensions already documented in DEPLOY.md Step 1 (Phase 17 decision) — no second deploy window needed

</specifics>

<deferred>
## Deferred Ideas

- Jurisdiction caching on `connected_profiles` — Phase 20+ optimization
- Out-of-Indiana address handling policy (user-facing error message) — Phase 20 decides
- Geocoding service selection (which API converts address string → lat/lng) — Phase 20

</deferred>

---

*Phase: 19-location-schema-rpcs*
*Context gathered: 2026-03-10*
