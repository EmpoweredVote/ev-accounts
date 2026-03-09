# Project Research Summary

**Project:** empowered-accounts
**Domain:** Location infrastructure — encrypted coordinate storage + PostGIS jurisdiction resolution
**Researched:** 2026-03-09
**Confidence:** HIGH (all primary technology decisions verified against official Supabase, PostGIS, and Census Bureau documentation)

## Executive Summary

This milestone adds civic location infrastructure to the existing three-tier account system: users submit a street address, the server geocodes it to WGS84 coordinates, coordinates are encrypted at rest in the Postgres database, and a PostGIS spatial query resolves those coordinates to Indiana legislative district identifiers. The resulting jurisdiction struct — congressional district, state senate/house, county, place, and school district — is the only location-derived output the system ever surfaces. Raw coordinates never leave the database. This architecture satisfies both the platform's privacy commitments and downstream feature needs (Essentials representative lookup, Validation Quests filtering) without exposing any geolocation PII.

The recommended implementation uses Supabase Vault to store the encryption passphrase and pgcrypto PGP functions (`pgp_sym_encrypt` / `pgp_sym_decrypt`) to encrypt the lat/lng columns as `bytea` on `connect.connected_profiles`. This is the only pattern Supabase currently recommends for column-level encryption: pgsodium Transparent Column Encryption is explicitly deprecated and must not be used. All encryption and decryption happens inside `SECURITY DEFINER` RPCs following the existing project convention (`SET search_path = ''`, fully qualified function calls). The Census Geocoder API is the recommended geocoding service — free, no API key, aligned with federal privacy law, and built on the same TIGER/Line dataset used for boundary storage. Indiana boundaries are loaded from TIGER/Line 2024 shapefiles (SRID 4269) reprojected to 4326 on import via ogr2ogr.

The primary operational risk is Vault key loss, which would make all stored coordinates permanently unreadable. Mitigation is simple: name the key explicitly, document the key name in the deployment runbook, use a dedicated key for location data (not shared with other secrets), and design the schema with a `location_key_version` column for future rotation. The secondary risk cluster involves PostGIS geometry correctness: SRID mismatches, `ST_Contains` boundary exclusion (use `ST_Covers` instead), and `ST_MakePoint` argument order (longitude first, not latitude). These are concrete, one-line mistakes that cause silent wrong results. All three are prevented by code review against the specific patterns documented in this research.

## Key Findings

### Recommended Stack

No new npm packages are required. All location infrastructure lives in SQL (migrations + SECURITY DEFINER RPCs). The TypeScript layer calls two new RPCs via the existing `adminRpc()` wrapper and receives plain JSON. Two Postgres extensions must be enabled: `pgcrypto` (available by default, enable if not already active) and `postgis` (must be explicitly enabled via the Supabase Dashboard). Supabase Vault is available by default on all Supabase projects.

**Core technologies:**

- **Supabase Vault**: stores encryption passphrase as a named secret (`location_encryption_key`) — stable API through pgsodium deprecation, key lives outside the database proper
- **pgcrypto `pgp_sym_encrypt` / `pgp_sym_decrypt`**: PGP-format authenticated encryption for `bytea` lat/lng columns — handles IV internally, includes integrity check, not deprecated
- **PostGIS `ST_Covers`**: point-in-polygon jurisdiction resolution against TIGER/Line boundaries — `ST_Covers` (not `ST_Contains`) correctly handles points on district edges
- **`geometry(MultiPolygon, 4326)`**: SRID 4326 (WGS84) for all stored boundaries — matches GPS coordinate output, no runtime `ST_Transform` needed, `geometry` (not `geography`) correct for state-scoped data
- **US Census Geocoder API**: free REST geocoding, no API key, federal privacy posture, built from TIGER address database — adequate for Alpha scale, no SLA

**Critical version / configuration notes:**

- pgcrypto installs in the `extensions` schema on Supabase — all calls inside `SET search_path = ''` functions must be `extensions.pgp_sym_encrypt(...)`, not bare `pgp_sym_encrypt(...)`
- PostGIS likewise installs in `extensions` — `extensions.ST_Contains()`, `extensions.ST_MakePoint()`, `extensions.ST_SetSRID()` required in RPCs
- Do NOT use `pgsodium` SECURITY LABEL syntax — pending deprecation, removed from Supabase Studio
- Do NOT use raw pgcrypto `encrypt()` / `decrypt()` — no integrity check, IV defaults to all zeros

### Expected Features

**Must have (table stakes):**

- Congressional district resolution — federal representative lookup requires it
- State senate district resolution — state senator lookup requires it
- State house district resolution — state representative lookup requires it
- County resolution — universal coverage, every Indiana address has one
- Place resolution (null for unincorporated) — city/town official lookup; ~30–40% of Indiana addresses will return null here, which is correct
- School district resolution — school board member lookup; the canonical example of why ZIP-based lookup is insufficient (Monroe County has two school districts)
- PO Box rejection — prevents corrupt jurisdiction data at input
- `geocode_accuracy` in response — callers need confidence metadata for school board boundary decisions
- `location_consent` flag — user controls when their address is geocoded; consent must be explicit `true`, not toggleable

**Should have (differentiators for Alpha):**

- Encrypted lat/lng at rest (pgcrypto + Vault) — coordinates are sensitive PII; encryption prevents raw exposure if database is breached
- Raw coordinates never returned in any API response — jurisdiction IDs replace location as the external representation
- `is_stale` flag — allows admin-triggered re-resolution when redistricting occurs without forcing user re-consent
- Out-of-state rejection with clear error — Indiana-scoped Alpha; non-Indiana addresses return 422

**Defer to post-Alpha:**

- County council district, city council ward resolution — not in TIGER/Line; requires per-county GIS portal data
- Township resolution — Indiana civil townships for fire/trustee jurisdiction; lower priority than legislative districts
- Census tract — useful for Validation Quest density routing but not representative lookup
- Special districts (~1,800 in Indiana) — no statewide GIS source; defer indefinitely
- Automated boundary refresh on redistricting — manual admin migration is sufficient for Alpha

**Anti-features (explicit exclusions):**

- ZIP-based lookup as primary method — fails for school board districts
- Return Census Designated Places as municipalities — CDPs have no elected officials
- Return raw lat/lng in any response — violates privacy architecture
- Load ELSD or SCSD shapefiles for Indiana — Indiana uses unified districts (UNSD) only

### Architecture Approach

Location infrastructure is additive to the existing architecture with no changes to existing patterns. A new service layer function (`locationService.geocodeAddress`) handles the external Census API call. Two new `SECURITY DEFINER` RPCs handle the database operations: `connect.update_user_location` (encrypts and writes coordinates) and `connect.resolve_user_jurisdiction` (decrypts and runs PostGIS query). Two new endpoints expose these operations: `POST /api/connect/set-location` (separate from the existing Connect completion flow, to prevent network I/O inside a transaction) and `GET /api/account/me/jurisdiction`. All patterns — `adminRpc()` wrapper, `SET search_path = ''`, two-pass validation, `supabaseAdmin` for writes only — are unchanged.

**Major components:**

1. `locationService.ts` — Census Geocoder call; returns `{lat, lng}` or null; no DB access, no encryption
2. `connect.update_user_location` RPC — consent + range validation, Vault key read, pgcrypto encrypt, writes `bytea` columns to `connect.connected_profiles`
3. `connect.resolve_user_jurisdiction` RPC — decrypts coordinates, constructs SRID 4326 point, `ST_Covers` query against `geo.*` boundary tables, returns jurisdiction JSON
4. `geo` schema boundary tables — one table per district type, `geometry(MultiPolygon, 4326)` with GIST spatial index, loaded from TIGER/Line 2024 via ogr2ogr
5. `POST /api/connect/set-location` — validates address + consent, calls geocoder, calls RPC, never stores address string
6. `GET /api/account/me/jurisdiction` — calls `resolve_user_jurisdiction`, maps error codes to HTTP status, coordinates never touch this layer

**Schema additions to `connect.connected_profiles`:**

```sql
lat               BYTEA        -- encrypted WGS84 latitude (pgcrypto PGP)
lng               BYTEA        -- encrypted WGS84 longitude (pgcrypto PGP)
location_consent  BOOLEAN      -- explicit user consent; NULL treated as false
location_set_at   TIMESTAMPTZ  -- when coordinates were last written
```

These four columns must be excluded from `connected_profiles_public` view and from all route-level SELECT lists.

### Critical Pitfalls

1. **Vault key loss** — All encrypted location data becomes permanently unreadable if the Vault key is lost. Prevention: use a dedicated named key (`location_encryption_key`), document the key name in the deployment runbook, add a `location_key_version` column to the schema for future rotation.

2. **pgsodium / TCE usage** — Any use of `SECURITY LABEL FOR pgsodium ON COLUMN` or `pgsodium.crypto_aead_det_encrypt()` will require a forced migration as Supabase deprecates pgsodium. Prevention: use only Vault + pgcrypto PGP functions; grep migrations for pgsodium before merge.

3. **`ST_MakePoint` argument order** — `ST_MakePoint(lat, lng)` silently produces geometrically incorrect points. PostGIS convention is `ST_MakePoint(longitude, latitude)` (x then y). This mistake causes `ST_Covers` to return wrong results with no error. Prevention: variable names must be `v_lat` / `v_lng` and the call must always be `ST_MakePoint(v_lng, v_lat)`.

4. **SRID mismatch** — TIGER/Line ships as SRID 4269 (NAD83). Mixing 4269 boundaries with 4326 user points causes PostGIS 3.x to error or return wrong results. Prevention: reproject to 4326 on import with `ogr2ogr -s_srs EPSG:4269 -t_srs EPSG:4326`. Verify with `SELECT DISTINCT ST_SRID(geom) FROM geo.congressional_districts` after load.

5. **`ST_Contains` boundary exclusion** — A point exactly on a district boundary returns `false` from `ST_Contains`, silently producing null jurisdiction for a valid address. Prevention: use `ST_Covers` everywhere in the `resolve_user_jurisdiction` RPC. One-word change; establish as project standard now.

6. **Statement logging leaks plaintext coordinates** — Supabase logs SQL statement parameters by default. An RPC called with float lat/lng parameters will log exact coordinates in plaintext, defeating encryption. Prevention: review Supabase logging configuration before the first production deploy; the geocode-then-RPC pattern (coordinates only reach the DB via the adminRpc call, not via user-visible channels) limits exposure but does not eliminate it.

7. **pgcrypto schema qualification** — Bare `pgp_sym_encrypt()` calls fail with "function not found" inside `SET search_path = ''` functions. Prevention: always use `extensions.pgp_sym_encrypt()` and `extensions.pgp_sym_decrypt()`, consistent with the v1.2 pattern for all SECURITY DEFINER functions.

## Implications for Roadmap

Based on research, the build order follows hard dependencies between infrastructure components.

### Phase 1: Infrastructure Setup (Pre-migration)

**Rationale:** PostGIS extension and Vault key must exist before any migration can reference them. These are dashboard operations, not migrations. Doing them first prevents migration failures.

**Delivers:** PostGIS enabled in `extensions` schema; `location_encryption_key` created in Supabase Vault; local dev Vault seeded with a fixed test passphrase.

**Addresses:** Vault key loss pitfall (document key name in runbook now), PostGIS not installed (add migration guard to boundary table migration), pgcrypto schema (verify extension active).

**No phase research needed** — documented one-time setup steps.

### Phase 2: Schema Migration

**Rationale:** Column additions and new boundary tables must exist before RPCs can be written. All schema changes are additive and safe to apply while the system is running.

**Delivers:** Four new nullable columns on `connect.connected_profiles`; `connected_profiles_public` view updated to explicitly exclude them; `geo` schema created; six boundary tables with GIST spatial indexes (`congressional_districts`, `state_senate_districts`, `state_house_districts`, `counties`, `places`, `school_districts`).

**Addresses:** RLS on encrypted columns (update view now so columns never accidentally appear in existing queries).

**No phase research needed** — schema fully specified in ARCHITECTURE.md and STACK.md.

### Phase 3: TIGER/Line Data Load

**Rationale:** Boundary data must be loaded before the `resolve_user_jurisdiction` RPC can be tested. This is a one-time data operation with its own runbook steps (download, ogr2ogr import, smoke test queries), not a migration.

**Delivers:** All six Indiana TIGER/Line 2024 boundary shapefiles loaded into `geo.*` tables, reprojected to SRID 4326. Post-load verification confirms correct row counts (9 congressional districts, 50 state senate, 100 state house, 92 counties, ~583 places) and correct SRID.

**Addresses:** SRID mismatch pitfall (use `ogr2ogr -s_srs EPSG:4269 -t_srs EPSG:4326`), stale boundaries (document TIGER/Line vintage in migration comments), SRID 0 geometry (post-load SRID verification query).

**Special note:** The county shapefile is national (80 MB); import with `-where "STATEFP = '18'"`. Indiana has no SCSD file — use UNSD only for school districts.

**No phase research needed** — all file URLs, ogr2ogr flags, and verification queries are specified in STACK.md.

### Phase 4: RPCs

**Rationale:** RPCs require the schema (Phase 2), Vault key (Phase 1), boundary data (Phase 3), and PostGIS (Phase 1). Both RPCs are written in the same migration.

**Delivers:** `connect.update_user_location(p_user_id, p_lat_plain, p_lng_plain, p_consent)` — validates, reads Vault key, encrypts, writes. `connect.resolve_user_jurisdiction(p_user_id)` — checks consent, decrypts, `ST_Covers` query, returns jurisdiction JSON.

**Critical implementation checklist:**
- `ST_Covers` not `ST_Contains` (boundary exclusion pitfall)
- `ST_MakePoint(v_lng, v_lat)` — longitude first (argument order pitfall)
- `extensions.pgp_sym_encrypt/decrypt` — fully qualified (schema pitfall)
- `extensions.ST_SetSRID(extensions.ST_MakePoint(...), 4326)` — explicit SRID (SRID 0 pitfall)
- `IF v_cp.location_consent IS NOT TRUE` — covers NULL and false

**No phase research needed** — full RPC signatures specified in ARCHITECTURE.md.

### Phase 5: Service Layer and Endpoints

**Rationale:** Express layer is straightforward once RPCs exist. Geocoding is isolated in `locationService.ts` to keep external network I/O out of RPC execution.

**Delivers:** `locationService.geocodeAddress(address)` using Census Geocoder REST API; `POST /api/connect/set-location` with PO Box rejection, consent enforcement, and address string disposal after geocoding; `GET /api/account/me/jurisdiction` with error code mapping.

**Addresses:** Geocoding inside transaction anti-pattern (separate endpoint, geocode before RPC call), encrypting in Express layer anti-pattern (pass plaintext floats to RPC — Vault key never leaves the DB), out-of-state coordinates (check state FIPS in geocoder response before calling RPC).

**No phase research needed** — endpoint design, Zod schema, error mapping, and Census Geocoder API call format specified in ARCHITECTURE.md.

### Phase 6: Tests and Validation

**Rationale:** Integration tests are the only way to confirm geometry and encryption logic is correct end-to-end.

**Delivers:** Integration test confirming known Bloomington address resolves to Indiana's 9th congressional district. RPC error handling tests (no consent → 403, no location → 404, key not found → 500). Architecture test asserting `lat`/`lng` bytea columns never appear in any route-level SELECT list. RLS test confirming encrypted columns are inaccessible via user-scoped client.

**No phase research needed** — test scenarios specified in ARCHITECTURE.md build order section.

### Phase Ordering Rationale

- Infrastructure before schema — dashboard operations cannot be expressed as migrations
- Schema before data load — tables must exist before shapefiles are imported
- Data load before RPCs — RPC tests require boundary data to be queryable
- RPCs before endpoints — endpoints have nothing to call without RPCs
- The smoke test queries in Phase 3 provide early signal on geometry correctness before any application code is written

### Research Flags

All phases use well-documented patterns. No `/gsd:research-phase` calls needed before planning begins.

Items to validate during implementation (not blocking planning):

- **Phase 1, local dev:** Verify PostGIS is present in the Supabase local Docker image (`supabase start`). If not, `config.toml` may need a declaration.
- **Phase 1, local dev:** Confirm Vault is accessible in local dev and a seed script can pre-populate `location_encryption_key` before tests run.
- **Phase 3, Census Geocoder:** Test against 2–3 real Monroe County addresses (including a rural route) before committing to it as the sole geocoder. Fallback: Mapbox free tier (100k/month).
- **Phase 2, geometry type:** Confirm TIGER/Line Indiana files use `MULTIPOLYGON` via `ogrinfo` before writing CREATE TABLE migrations — simplify to `POLYGON` if that's what the shapefiles contain.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All three primary decisions (Vault+pgcrypto, geometry+SRID 4326, TIGER/Line 2024) verified against official docs and live Census FTP directory listing |
| Features | HIGH | District types and TIGER/Line file names verified via live Census FTP index; Indiana FIPS codes and school district structure verified via NCES |
| Architecture | HIGH for integration patterns; MEDIUM for Census Geocoder | RPC signatures derived from established codebase patterns; Census Geocoder accuracy in rural Monroe County not independently tested |
| Pitfalls | HIGH | All critical pitfalls (Vault key loss, pgsodium deprecation, `ST_MakePoint` order, SRID mismatch, `ST_Covers` vs `ST_Contains`) are verified failure modes from official documentation |

**Overall confidence:** HIGH

### Gaps to Address

- **Census Geocoder rural Indiana accuracy:** Confidence is MEDIUM. Indiana address coverage is inferred from TIGER provenance, not tested. Validate with 3–5 real Monroe County addresses (including rural routes) before Alpha pilot launch. Fallback: Mapbox free tier.
- **PostGIS in local Supabase Docker:** Verify with `SELECT 1 FROM pg_extension WHERE extname = 'postgis'` after `supabase start` before writing the boundary migration.
- **Vault in local dev seed:** The test suite needs a `seed.sql` or setup script that creates `location_encryption_key` in the local Vault before tests run. Use a fixed test passphrase (not the production value).
- **MULTIPOLYGON vs POLYGON in TIGER files:** Confirm with `ogrinfo tl_2024_18_cd119.shp` before writing CREATE TABLE migrations.

## Sources

### Primary (HIGH confidence)

- [Supabase Vault Documentation](https://supabase.com/docs/guides/database/vault) — `vault.create_secret()`, `vault.decrypted_secrets` view, SECURITY DEFINER pattern
- [pgsodium Pending Deprecation](https://supabase.com/docs/guides/database/extensions/pgsodium) — explicit "do not recommend" statement for new projects
- [PostgreSQL pgcrypto documentation](https://www.postgresql.org/docs/current/pgcrypto.html) — `pgp_sym_encrypt` / `pgp_sym_decrypt` function signatures and PGP-format integrity guarantees
- [Supabase PostGIS documentation](https://supabase.com/docs/guides/database/extensions/postgis) — enable steps, SRID 4326, `extensions` schema install location
- [PostGIS ST_Covers documentation](https://postgis.net/docs/ST_Covers.html) — boundary semantics, use over ST_Contains for point-in-polygon
- [PostGIS Workshop: Geography](http://postgis.net/workshops/postgis-intro/geography.html) — `geometry` vs `geography`: "geographically compact → use geometry type"
- [Census Bureau TIGER/Line 2024](https://www2.census.gov/geo/tiger/TIGER2024/) — verified all six Indiana shapefile URLs via live directory listing
- [NCES Monroe County CSD (LEAID 1800630)](https://nces.ed.gov/ccd/districtsearch/) — Monroe County school district structure confirmed

### Secondary (MEDIUM confidence)

- [Census Geocoder API](https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html) — API format verified; Indiana rural accuracy inferred from TIGER provenance
- [pgcrypto in extensions schema (Supabase)](https://github.com/orgs/supabase/discussions/627) — community confirmation; consistent with official install behavior
- [pgsodium/TCE not recommended discussion](https://github.com/orgs/supabase/discussions/27109) — community confirmation of deprecation and dashboard removal

### Tertiary (requires validation)

- Census Geocoder rural Monroe County accuracy — inferred, not tested against real addresses
- PostGIS availability in Supabase local Docker — assumed based on Supabase docs; requires local verification

---
*Research completed: 2026-03-09*
*Ready for roadmap: yes*
