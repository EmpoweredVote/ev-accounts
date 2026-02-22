# Pitfalls Research

**Domain:** Address verification, geofence-based district matching, external API removal (civic tech)
**Researched:** 2026-02-22
**Confidence:** HIGH (PostGIS/TIGER behaviors), HIGH (Google Maps billing), MEDIUM (BallotReady cutover patterns — specific to this project)

---

## Critical Pitfalls

### Pitfall 1: SRID Mismatch Between TIGER Data and Stored Points

**What goes wrong:**
TIGER shapefiles ship in NAD83 (SRID 4269), but most geocoding APIs (including Google Maps) return coordinates in WGS84 (SRID 4326). If you load TIGER geometries into PostGIS without re-projecting to 4326, or if you store Google-returned lat/lng as SRID 4326 and your district polygons are SRID 4269, every `ST_Within` call silently fails or throws `ERROR: Operation on mixed SRID geometries`. The query returns zero results for every address. This is not a data gap — it is a configuration bug that looks like a data gap.

**Why it happens:**
Developers load shapefiles with `shp2pgsql` using the default SRID from the `.prj` file (4269 for TIGER data), then store geocoded coordinates as `ST_Point(lng, lat, 4326)`. PostGIS enforces SRID consistency on spatial operations. The mismatch is invisible until a live query fires.

**How to avoid:**
Pick one SRID for the entire pipeline and enforce it at import time. WGS84 (4326) is the right choice because Google Maps returns 4326 coordinates. Load TIGER shapefiles with explicit reprojection:
```bash
shp2pgsql -s 4269:4326 tl_2025_us_cd119.shp districts | psql -d empowered_vote
```
Alternatively, add a geometry column check constraint on the district table:
```sql
ALTER TABLE geofences.districts
  ADD CONSTRAINT enforce_srid CHECK (ST_SRID(geom) = 4326);
```
This fails fast during import if the SRID is wrong, rather than silently producing empty query results.

**Warning signs:**
- PostGIS error: `Operation on mixed SRID geometries (Geometry, 4269) != (Geometry, 4326)` in backend logs
- `ST_Within` or `ST_Contains` queries return 0 rows for all addresses, even major city centers
- QGIS or pgAdmin shows misaligned layers when overlaying district polygons and address points

**Phase to address:**
Geofence data load phase — enforce SRID before a single district polygon enters the database. Run a validation query after every shapefile import:
```sql
SELECT DISTINCT ST_SRID(geom) FROM geofences.districts;
```
Expected result: exactly one row, value `4326`.

---

### Pitfall 2: Abandoned Google Maps Autocomplete Sessions Billed Per-Request

**What goes wrong:**
Google's Places Autocomplete uses session tokens to group keystrokes + final selection into one billable unit. If the user types an address, sees suggestions, then closes the modal or navigates away without selecting a result, that session is "abandoned." Every individual keystroke request is then billed at the per-request Autocomplete rate instead of the session rate. For a civic app with moderate traffic, abandoned sessions are common (users try address search, get distracted, close it). This can 3-10x the actual billing cost.

**Why it happens:**
Two implementation errors cause this:
1. A new session token is generated on each keystroke instead of one per search session
2. Session termination uses `Place Details (IDs Only)` — which is technically free — meaning Google treats it as if no session token was used and reverts all Autocomplete calls in that session to per-request pricing

**How to avoid:**
Generate one UUID session token when the autocomplete input mounts (or when the user first focuses the input). Pass the same token on every keystroke request. Terminate the session with a `Place Details` call that fetches at minimum `geometry/location` and `address_components` (these are billable, which satisfies Google's session termination requirement). Set a hard debounce of 300ms on the input — do not fire an API request on every keystroke. Use `@vis.gl/react-google-maps` (Google's endorsed React library as of 2025) which has built-in hooks for the Place Autocomplete Data API and handles session token lifecycle correctly.

```typescript
// Correct: one token per search session
const sessionToken = useMemo(
  () => new google.maps.places.AutocompleteSessionToken(),
  [] // only one token per component mount
);
```

**Warning signs:**
- Google Cloud Console billing shows "Autocomplete - Per Request" SKU charges instead of "Autocomplete - Per Session" SKU
- Session token is generated inside a `useEffect` that depends on the query string (recreates on each character)
- The `PlacesService.getDetails()` call uses `fields: ['place_id']` only (IDs Only tier, voids session benefit)

**Phase to address:**
Google Maps integration phase — before wiring up autocomplete. Test the billing impact with Cloud Console's usage dashboard after the first real integration test. Set a billing alert at $10/month in Google Cloud to catch runaway sessions early.

---

### Pitfall 3: ST_Within Returns No District for Points on Shared Boundaries

**What goes wrong:**
`ST_Within(point, polygon)` requires that the point's interior intersects the polygon's interior — a point exactly on the boundary line returns `false` for both adjacent polygons. In practice, street addresses near district borders (addresses on the edge of a city, or exactly on a county line) match zero districts. The user gets a "no representatives found" error that has nothing to do with data coverage — the address is fully valid and should match.

**Why it happens:**
This is a documented PostGIS behavior difference: `ST_Within` excludes boundary points; `ST_Covers`/`ST_Contains` have different boundary semantics. Geocoded addresses from Google Maps have precision up to 6 decimal places, and Google often places coordinates directly on street centerlines, which frequently coincide with district boundary edges.

**How to avoid:**
Use `ST_Covers` instead of `ST_Within` for the primary query. `ST_Covers` returns true when a point is on the boundary of the polygon. Alternatively, use `ST_DWithin` with a small tolerance (1 meter) to catch near-boundary points:
```sql
SELECT d.*
FROM geofences.districts d
WHERE ST_Covers(d.geom, ST_SetSRID(ST_Point($1, $2), 4326))
   OR ST_DWithin(d.geom, ST_SetSRID(ST_Point($1, $2), 4326)::geography, 1);
```
Run the fallback `ST_DWithin` check only when the primary `ST_Covers` returns zero results.

**Warning signs:**
- Addresses on major roads or county borders return zero districts while nearby addresses work correctly
- Systematic "no results" for addresses in specific neighborhoods, particularly near city boundaries
- Query logs show 0 rows returned for coordinates that visually sit inside a district in QGIS

**Phase to address:**
Geofence matching implementation phase — use `ST_Covers` from day one. Add a test case with a coordinate known to sit exactly on a district boundary line.

---

### Pitfall 4: Missing GiST Index Causes Full-Table Scan on Every Address Search

**What goes wrong:**
PostGIS point-in-polygon queries against `ST_Within` or `ST_Covers` without a spatial index perform a sequential scan of every district polygon. For a table with national-level TIGER districts (Congressional, State Senate, State House, County, School District, Municipal, etc.), this could be 50,000+ polygons per query. Response times exceed 10-30 seconds on even a modest Supabase tier. The app appears broken.

**Why it happens:**
The most common mistake: creating a table and loading data, then running queries, and only adding the index later when slowness is noticed. The GiST index is not created by default on geometry columns. GORM AutoMigrate does not add spatial indexes.

**How to avoid:**
Create the GiST index immediately after defining the geometry column, before loading any data:
```sql
CREATE INDEX idx_districts_geom ON geofences.districts USING GIST (geom);
```
After bulk loading all shapefiles, run `VACUUM ANALYZE geofences.districts;` to update the planner statistics. Without ANALYZE, the query planner may ignore the index even when it exists. Verify the index is used with:
```sql
EXPLAIN ANALYZE SELECT * FROM geofences.districts WHERE ST_Covers(geom, ST_SetSRID(ST_Point(-86.5, 39.2), 4326));
```
The plan should show "Index Scan using idx_districts_geom" not "Seq Scan".

**Warning signs:**
- Address search endpoint takes >3 seconds for any query
- PostgreSQL `pg_stat_user_tables` shows `seq_scan` count climbing on the districts table
- `EXPLAIN ANALYZE` output shows "Seq Scan on districts" instead of "Index Scan"

**Phase to address:**
Geofence data load phase — index is a prerequisite for the first query test. Never run a geofence query against unindexed data in any environment, including development.

---

### Pitfall 5: BallotReady Cutover Leaves Silent Dead Code Paths That Execute in Production

**What goes wrong:**
The existing codebase has BallotReady API calls scattered across the `internal/essentials/` package: `warmLocal`, `warmFederal`, `warmState`, background goroutines, and the address search handler. Removing these requires touching many files. If any call site is missed, the code compiles fine but still fires BallotReady API requests in production — after the API key is revoked or the contract expires. These silently fail, triggering fallback logic that returns empty results. Users see no politicians but no clear error.

**Why it happens:**
The BallotReady client is passed as a dependency to warming functions. If a warming function is still being triggered (even if never explicitly called in new code paths), it may fire when the background cache-refresh goroutines run on a schedule. It is not enough to remove the obvious call sites — every goroutine and cache-check trigger must be audited.

**How to avoid:**
Before the cutover, do a full audit: search the entire codebase for every reference to `ballotReadyClient`, `FetchOfficeholders`, `FetchPositionContainmentByZip`, `candidacyQuery`, and related identifiers. Create a checklist of every call site. After removing each one, verify with `go build` that the package compiles, then `grep` for any remaining references. Only delete the BallotReady client struct and API key environment variable after every call site is confirmed removed.

**Warning signs:**
- `BALLOTREADY_API_KEY` environment variable still referenced in `.env` or `apprunner.yaml` after cutover
- Background goroutines for cache warming continue to start on server boot
- Log lines like "BallotReady: fetching officeholders for ZIP..." appear after the cutover deploys
- Errors about BallotReady API authentication in production logs

**Phase to address:**
BallotReady removal phase — treat this as a migration with an explicit checklist, not a "delete some code" task. The BallotReady client struct should be the last thing deleted, after all consumers are removed.

---

### Pitfall 6: TIGER Local District Coverage Gaps Return "No Representatives" for Valid Addresses

**What goes wrong:**
TIGER shapefiles have documented coverage gaps for local districts. Some states assigned "ZZZ" codes to areas without defined State Legislative Districts. School district spatial data has known holes and overlaps in certain counties. Special districts (fire, water, utility) are often not in TIGER at all. When a user enters a valid address in one of these areas, the geofence query returns zero local results. Without explicit handling, the UI shows an empty state with no explanation — the user assumes the platform is broken.

**Why it happens:**
Developers test the geofence system with addresses in well-covered major metros (Chicago, LA, New York) and assume coverage is universal. Edge cases — rural addresses, state-level coverage gaps, special jurisdiction areas — only appear in production with real user traffic.

**How to avoid:**
Design the response to differentiate between "no cached data" and "geofence returned no districts." When geofence returns no local districts, still return federal and state officials from the cache (these are stored nationally and do not depend on local geofence coverage). Show a specific message for the local section: "Local representative data is not yet available for this address" rather than a blank list. Track which addresses return zero local districts so coverage gaps can be identified and addressed with additional data sources (OpenStates, Represent Boundaries, or manual additions).

**Warning signs:**
- Test addresses in rural Indiana, Connecticut, or Illinois return zero local results
- The essentials frontend `classify.js` receives empty local-tier data and renders nothing with no message
- No distinction in API response between "district matched, no officials found" and "no district matched"

**Phase to address:**
Geofence matching phase — design the degradation response before launch. The federal/state fallback must be implemented in the same phase, not as a follow-up. Never ship a search feature that can return an empty page with no explanation.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use one Google Maps API key for both frontend and backend calls | Simpler setup | Key cannot be restricted by both HTTP referrer and IP simultaneously; key exposed in browser if browser-restricted rules aren't applied | Never — use separate keys: one browser-restricted for autocomplete, one IP-restricted for server-side geocoding |
| Skip `VACUUM ANALYZE` after shapefile bulk load | Saves 5 minutes | Query planner uses stale statistics; may ignore GiST index entirely, causing full scans on every query | Never for production or staging environments |
| Load TIGER shapefiles for only a few test counties before launch | Faster initial setup | Users in uncovered areas see empty results; harder to add remaining data retroactively under load | Only in development, never in any user-accessible environment |
| Keep BallotReady warming goroutines running but return early | Safe rollback option | Dead code in production that fires on server boot; if API key lapses, logs fill with auth errors | Never — remove the goroutines entirely at cutover, use feature flags if rollback is needed |
| Store geocoded coordinates as plain float columns instead of PostGIS geometry | No PostGIS dependency | Cannot use spatial indexes or spatial functions; every district query requires client-side distance calculation | Never if PostGIS is already in the stack |
| Use `ST_Within` instead of `ST_Covers` for simplicity | Slightly simpler SQL | Silent failures for addresses on district boundaries, which are disproportionately common for street addresses | Never — the performance difference is zero, correctness difference is significant |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Google Maps Places Autocomplete | Generating a new session token on every keystroke (token in component state that reacts to query changes) | Generate one token per search session using `useMemo([])`; the same token persists until the user selects a result |
| Google Maps Places Autocomplete | Using `Place Details (IDs Only)` to terminate the session cheaply | IDs Only tier voids the session discount entirely; terminate with `geometry` + `address_components` fields instead |
| Google Maps Geocoding API | Using Places autocomplete on the frontend but Geocoding API on the backend with the same API key | Browser-restricted keys cannot make server-side calls; use two keys with separate restrictions |
| PostGIS shp2pgsql | Running shp2pgsql without `-s FROM_SRID:TO_SRID` flag | TIGER data loads as NAD83 (4269); Google Maps coordinates are WGS84 (4326); specify `-s 4269:4326` at import |
| PostGIS bulk load | Creating GiST index after loading data | Create index first, then load data, then `VACUUM ANALYZE` — or at minimum create the index before any query runs |
| TIGER data refresh | Treating TIGER shapefiles as static, permanent data | TIGER releases annually (January cutoff); redistricting data can lag 6 months; Congressional districts change after elections. Plan an annual refresh process |
| Google Maps nonprofit credits | Assuming the $200 monthly credit still applies | Google replaced the universal $200 credit in March 2025 with per-SKU free tiers; apply for the nonprofit program separately ($250+/month additional credits for verified nonprofits via Google for Nonprofits) |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No GiST index on district geometry column | Address search takes 15-30s; backend logs show slow queries | Create GiST index before first query; verify with EXPLAIN ANALYZE | Immediately, even with 100 rows — spatial scans are expensive |
| Querying all district layers simultaneously without limiting scope | Each address triggers 5-7 separate ST_Covers queries (federal, state-upper, state-lower, county, municipal, school, local) | Run a single query joining all relevant district layers; use UNION ALL with LIMIT per tier | At moderate load (50 concurrent users) |
| Loading all TIGER district geometries including high-resolution coastline detail | District query returns full polygon vertex data in response; large memory footprint per query | Store simplified geometries for query (ST_Simplify on import); only use full-res for display | When district polygon has 10,000+ vertices (common for coastal congressional districts) |
| Storing Google Maps autocomplete results in React state without debounce | API called on every keystroke; 5-10 calls per second per user | Debounce at 300ms minimum before firing the autocomplete request | Immediately in development; billing impact shows up in first week of user traffic |
| Not caching geocoded address → district results | Same address triggers a fresh PostGIS query every time; common for shared ZIP code households | Cache geocoded results (lat/lng + district IDs) in a short-TTL table (24 hours); many users in the same building will search the same address | At 500+ daily active users in dense urban areas |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Using one unrestricted Google Maps API key for all environments | Key scraped from frontend JavaScript; attacker runs up billing charges | Create three keys: (1) browser-restricted to production domain for frontend autocomplete, (2) browser-restricted to localhost for dev, (3) IP-restricted for backend geocoding in Go. Never put an unrestricted key in any deployed code |
| Storing the Google Maps API key in React source code without environment variable | Key visible in compiled JS bundle via source maps | Use `VITE_GOOGLE_MAPS_API_KEY` environment variable in Vite; verify the key is not visible in production bundle with browser dev tools |
| No Google Maps API quotas set | Single burst of traffic (or a scraper) consumes monthly budget in hours | Set per-day quotas in Google Cloud Console: start at 1,000 geocodes/day and 500 autocomplete sessions/day; increase only when justified |
| Geocoding user-entered addresses on the frontend | Address strings proxied directly to Google from the browser; no rate limiting | Route geocoding through the Go backend for server-side calls; frontend autocomplete uses session-token approach which is designed for direct browser use |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Replacing ZIP input with address autocomplete without preserving ZIP fallback | Users who know their ZIP but not their full address (common for rural users) cannot search | Keep the ZIP path working in parallel during transition; deprecate only after monitoring shows address search covers >90% of user needs |
| Showing "No representatives found" with no explanation when geofence returns empty | User assumes the platform is broken or their address is invalid | Distinguish three states: (a) federal/state found, local unavailable — show what was found with a note; (b) district matched, no officials cached — show "data coming soon"; (c) no district matched — ask user to check the address |
| Autocomplete suggestions include points of interest (restaurants, parks) not useful for district lookup | Users select "Central Park" and get a coordinate in the middle of a park with no street address | Set `types: ['address']` in the Places Autocomplete request to restrict to street addresses only |
| Showing a full-screen spinner while geocoding completes | Users do not know if the app is working or frozen; abandonment increases | Show inline loading state on the search input itself; display cached federal/state officials immediately while local geofence query runs in parallel |
| No clear indication that the searched address is outside supported coverage | User in a state with known TIGER gaps thinks the platform is broken | Add an explicit "Coverage is best for [covered regions]" note during the transition period; plan a coverage status page |
| Autocomplete dropdown disappears before user can tap on mobile | Mobile keyboard dismiss event triggers blur on the input, closing suggestions before touch registers | Add a 150ms delay to the `onBlur` handler that closes the suggestion list; test on iOS Safari specifically |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **TIGER data loaded:** Verify SRID is exactly 4326 with `SELECT DISTINCT ST_SRID(geom) FROM geofences.districts;` — do not trust the import command's success message alone
- [ ] **GiST index active:** Confirm `EXPLAIN ANALYZE` shows "Index Scan" not "Seq Scan" on a live point-in-polygon query before declaring geofence complete
- [ ] **ST_Covers boundary test:** Run a test query with a coordinate known to sit exactly on a district boundary — it must return a result, not zero rows
- [ ] **Autocomplete session tokens:** Confirm in Google Cloud Console that "Autocomplete - Per Session" SKU is being charged, not "Autocomplete - Per Request" SKU — they appear separately in the billing report
- [ ] **BallotReady fully removed:** `grep -r "ballotReadyClient\|BallotReady\|BALLOTREADY" EV-Backend/` returns zero results across all Go files
- [ ] **API key restrictions set:** Verify in Google Cloud Console that the browser key has HTTP referrer restriction to `*.empowered.vote` and the server key has IP restriction to the App Runner egress IP
- [ ] **Nonprofit credits applied:** Confirm the Google for Nonprofits application is approved and credits appear in the billing account before going live
- [ ] **Federal/state fallback works:** Search an address in a known TIGER coverage gap — federal and state officials must still appear
- [ ] **Empty-state messaging present:** The UI shows a meaningful message (not a blank list) when local geofence returns no results
- [ ] **VACUUM ANALYZE run after load:** Run `VACUUM ANALYZE geofences.districts;` after each shapefile import and verify with `pg_stat_user_tables` that `last_analyze` is recent

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| SRID mismatch discovered in production (all queries return zero results) | MEDIUM | Re-run shapefile imports with `-s 4269:4326`; no data is lost, only reimport time. Add constraint and redeploy. Typical recovery: 2-4 hours |
| Abandoned session billing spike discovered | LOW-MEDIUM | Immediately add debounce and fix token generation; billing already occurred but stops immediately on fix. Review Cloud Console for the billing period impact |
| BallotReady goroutines still running after cutover | LOW | Remove remaining call sites, redeploy. No data corruption risk since goroutines only read from API. Recovery: same-day |
| PostGIS full-table scan (missing GiST index) discovered under load | LOW | `CREATE INDEX CONCURRENTLY idx_districts_geom ON geofences.districts USING GIST (geom);` — runs without table lock; queries slow during build but service stays up. Recovery: minutes to hours depending on data size |
| TIGER coverage gap causes empty results for real users | MEDIUM | Immediate: deploy federal/state fallback if not already present. Medium-term: add missing district data from alternative source (OpenStates, Represent Boundaries). No database corruption, only data gap |
| Google Maps API key compromised and billing abuse detected | HIGH | Immediately rotate key in Google Cloud Console; update environment variables in Netlify and App Runner; redeploy both frontend and backend. Add restrictions to new key. Review billing for dispute eligibility |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| SRID mismatch (Pitfall 1) | Geofence data load | Query `SELECT DISTINCT ST_SRID(geom)` returns single row with value 4326 |
| Autocomplete session billing (Pitfall 2) | Google Maps integration | Cloud Console shows "Per Session" SKU not "Per Request" SKU in billing breakdown |
| Boundary point returns no district (Pitfall 3) | Geofence matching implementation | Test case: coordinate on a known district boundary returns at least one district |
| Missing GiST index (Pitfall 4) | Geofence data load | `EXPLAIN ANALYZE` shows Index Scan; query returns in <200ms |
| BallotReady dead code (Pitfall 5) | BallotReady removal phase | Zero grep matches for BallotReady client references; no BallotReady log lines in production |
| TIGER coverage gaps (Pitfall 6) | Geofence matching + degradation phase | Rural test address returns federal/state officials with explicit local-unavailable message |

---

## Sources

- PostGIS official documentation: [ST_Within](https://postgis.net/docs/ST_Within.html), [ST_Covers](https://postgis.net/docs/ST_ContainsProperly.html), [Spatial Indexing](http://postgis.net/workshops/postgis-intro/indexing.html)
- PostGIS SRID mismatch: [PostGIS ticket #771](https://trac.osgeo.org/postgis/ticket/771), [Hasura issue #7665](https://github.com/hasura/graphql-engine/issues/7665)
- [Google Places API Session Pricing](https://developers.google.com/maps/documentation/places/web-service/session-pricing) — abandoned session billing behavior
- [Google Maps Platform Public Programs](https://developers.google.com/maps/billing-and-pricing/public-programs) — nonprofit credits ($250+/month for verified nonprofits)
- [Google Maps Platform March 2025 Billing Changes](https://developers.google.com/maps/billing-and-pricing/march-2025) — universal $200 credit replaced by per-SKU free tiers
- [Google Maps API Security Best Practices](https://developers.google.com/maps/api-security-best-practices) — separate browser/server keys
- [@vis.gl/react-google-maps](https://visgl.github.io/react-google-maps/) — Google-endorsed React library for Maps JavaScript API
- [TIGER/Line Shapefiles](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html) — Census Bureau, 2025 release (January 1, 2025 boundaries)
- [TIGER Boundary Files — Redistricting Data Hub](https://redistrictingdatahub.org/data/about-our-data/tiger-boundary-files/) — known coverage gaps documentation
- [Census TIGER errata (2008)](https://www.census.gov/programs-surveys/geography/technical-documentation/user-note/tiger-geo-line.2008.html) — documented school district boundary holes and county subdivision bleeds
- [PostGIS Performance — Crunchy Data](https://www.crunchydata.com/blog/postgis-performance-indexing-and-explain) — GiST index gotchas, VACUUM ANALYZE requirements
- [ST_Contains vs ST_Covers — Medium](https://mentin.medium.com/which-predicate-cb608b470471) — boundary semantics comparison
- [BallotReady API Documentation](https://github.com/BallotReady/api-documentation) — existing integration reference
- [Google Civic API shutdown notice](https://groups.google.com/g/google-civicinfo-api/c/9fwFn-dhktA) — civic API migration context
- [Geocoding Address Validation — Google](https://developers.google.com/maps/architecture/geocoding-address-validation) — Places vs Geocoding API difference for real-time input

---
*Pitfalls research for: v1.5 Address Verification & BallotReady Independence*
*Researched: 2026-02-22*
