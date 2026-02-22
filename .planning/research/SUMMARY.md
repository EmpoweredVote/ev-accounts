# Project Research Summary

**Project:** v1.5 — Address Verification & BallotReady Independence
**Domain:** Civic tech — address-based politician lookup with geofence district matching
**Researched:** 2026-02-22
**Confidence:** HIGH

## Executive Summary

This milestone is a focused infrastructure cleanup, not a new product build. The core technical infrastructure is already in place: Google Maps geocoding is wired (`geocoding/google.go`), PostGIS geofence matching works (`geofence_lookup.go`), and the address search endpoint exists (`SearchPoliticians`). The primary work is removing two layers of technical debt — the BallotReady API dependency that sits as a fallback beneath the working geofence flow, and the legacy Google Maps Autocomplete class that needs a forward-compatible replacement. No new Go packages and no new npm packages are required.

The recommended approach is surgical removal in a backend-first, track-parallel build order. Backend work (removing BallotReady fallbacks, replacing live candidate fetch with a cached DB query) is entirely independent of frontend work (migrating from the legacy `Autocomplete` class to `PlaceAutocompleteElement`). Both tracks can proceed simultaneously. The most important architectural decision is what happens when local geofence data is absent for an address — users must still see federal and state officials from cache rather than an empty page, and the response must include a clear explanation of why local data is unavailable.

The key risk is incomplete BallotReady removal. The client is called from at least four distinct locations in `handlers.go`, and any missed call site will silently fire API requests after the key is revoked, producing empty results with no error. Treat removal as an explicit migration checklist with a `grep` verification step, not a casual refactor. Secondary risk is Google Maps billing: session tokens must be correctly scoped to one per search session or autocomplete costs can spike 3-10x. Both risks are well-understood and preventable with discipline.

## Key Findings

### Recommended Stack

No new dependencies are introduced in v1.5. The existing stack handles everything: Go 1.24.3 + Chi + GORM on the backend, React 19 + Vite 7 + Tailwind CSS 4 on the frontend. The only stack change is deprecating BallotReady as a data provider and stopping its initialization in `setup.go`.

**Core technologies:**
- `@googlemaps/js-api-loader` v2.0.2: Google Places Autocomplete — already installed in `essentials/package.json`; supports `PlaceAutocompleteElement` via `importLibrary('places')`; no upgrade needed
- `geocoding/google.go` custom client: backend geocoding via Google Maps REST API — 135-line implementation; zero new Go dependencies; one-line change to remove the ZIP-required check for the geofence-only flow
- PostGIS `ST_Contains` + GiST index: geofence district matching — already implemented and indexed in `geofence_lookup.go`; no changes needed
- `essentials.election_records` table: cached candidate data — populated by previous BallotReady imports (Phase B); queried by new `fetchCandidatesFromDB()` function to replace the live BallotReady call

**Version notes:**
- `PlaceAutocompleteElement` requires `@googlemaps/js-api-loader` v2.x (already installed at `^2.0.2`)
- Legacy `google.maps.places.Autocomplete` class is closed to new API keys as of March 2025 but still works for the existing EV key — migration to `PlaceAutocompleteElement` is a forward-compatibility upgrade, not an emergency fix
- The official Go Maps SDK (`googlemaps.github.io/maps` v1.7.0, last released December 2023) is not worth adding — the custom geocoding client already covers all required fields with 135 lines

### Expected Features

**Must have (table stakes — P1 for v1.5):**
- Address autocomplete as the only primary search input — remove ZIP-specific routing from `Results.jsx`; label the field "Your address"
- Confirmed address display after selection — show Google's `formatted_address` as a results sub-header to build trust that the system understood the input
- Geofence-based politician matching with no BallotReady fallback — the primary flow already works; removal of the fallback block is the deliverable
- Federal/state officials from cache when local geofence returns 0 results — use `geoResult.State` to derive state and serve from cache; prevents blank pages for addresses outside covered geofence areas
- "No local coverage" user message — explicit frontend branch distinguishing "no local data" from "no officials at all"
- Cached-only candidate display — new `fetchCandidatesFromDB()` SQL query replaces the live `brProvider.Client().FetchRacesByZip()` call; filters `election_date >= today`
- BallotReady API key removed from required env vars — `BALLOTREADY_API_KEY` becomes unused after all live call sites are replaced

**Should have (P2 — v1.5.x polish pass):**
- "Showing results for [City, State]" sub-header — orientation/trust signal; city + state already available in the geocoding response
- Coverage indicator badge (geofence-matched vs. cache-only) — wire to existing `X-Data-Status` response header; frontend-only change
- Candidate data freshness date ("as of [date]") — show import timestamp alongside the candidate toggle

**Defer (v2+):**
- Full `PlaceAutocompleteElement` migration (new Google web component) — existing customers unaffected; migrate when forced by deprecation
- Address Validation API (Google) — separate billing SKU, session complexity; autocomplete self-validates via suggestion selection
- Wider geofence coverage (more TIGER shapefiles) — data import / ops work; currently covers Monroe County IN + LA County CA only
- Geocoding result caching table (`geocoded_addresses`) — optimization worth adding only at 500+ DAU

### Architecture Approach

The architecture follows two independent parallel tracks that converge at deployment. Track A (backend) touches `handlers.go` in five targeted locations and `setup.go` in one location. Track B (frontend) creates one new component (`AddressSearch.jsx`) and one utility (`loadMapsApi.js`), then swaps the `<input>` in `Dashboard.jsx` and `Landing.jsx`. No new API routes are needed. No schema changes are required. No new environment variables are added beyond what already exists.

**Major components:**
1. `SearchPoliticians()` in `handlers.go` — Remove the BallotReady fallback block (~lines 2916-3035); extend the zero-geofence-results path to call `fetchStatewideFromDB(geoResult.State)`; set `X-Data-Status: no-geofence-data` header
2. `GetCandidatesByZip()` in `handlers.go` — Replace live BallotReady call with `fetchCandidatesFromDB(ctx, zip)` querying `essentials.election_records` filtered to upcoming elections
3. `ensureCandidacyData()` in `handlers.go` — Remove the lazy-fetch goroutine; serve profile from whatever candidacy data is already in DB
4. `warmFederal/warmState/warmLocal()` in `handlers.go` — Stub function bodies with log message; remove goroutine-kick from `handleZipLookup` and `GetCacheStatus`; keep cache timestamp infrastructure
5. `setup.go` — Remove `_ ballotready` import side-effect; comment out `Provider` init; log "cached-data-only mode"
6. `AddressSearch.jsx` (new) — `PlaceAutocompleteElement` wrapper (or legacy `Autocomplete` as interim); `onSelect(formattedAddress)` callback; US-only address restriction; graceful degrade to plain `<input>` if Maps API fails to load
7. `loadMapsApi.js` (new) — Dynamic script injection using `import.meta.env.VITE_GOOGLE_MAPS_API_KEY`; avoids Vite env-var limitation in raw HTML files; resolves a Promise when the API is ready

**Key patterns:**
- Frontend sends `formattedAddress` string to existing `POST /politicians/search` endpoint (Option A); backend geocodes again — acceptable at nonprofit traffic scale, avoids a new endpoint
- Warmer functions become no-ops; cache tables remain as the read path; data is populated by admin import, not background warmers
- `ballotready/` package directory is kept in the codebase (not deleted) to preserve historical reference and avoid breaking admin import pipeline

### Critical Pitfalls

1. **BallotReady dead code executes silently after cutover** — The client is called from at least 4 locations in `handlers.go`. Any missed call site fires API requests after the key is revoked, producing empty results silently. Prevention: create an explicit checklist of every call site; verify removal with `grep -r "ballotReadyClient\|FetchRacesByZip\|FetchCandidacy\|BALLOTREADY" EV-Backend/`; delete the BallotReady client struct last, after all consumers are confirmed removed.

2. **Autocomplete session billing spikes 3-10x from abandoned sessions** — If the `AutocompleteSessionToken` is regenerated on each keystroke instead of once per search session, Google bills per request rather than per session. Prevention: use `useMemo([], ...)` for the session token (one token per component mount, not per query); add 300ms debounce; verify in Cloud Console that "Autocomplete - Per Session" SKU appears, not "Autocomplete - Per Request" SKU.

3. **TIGER coverage gaps produce blank pages rather than partial results** — Outside the two currently imported geofence areas (Monroe County IN + LA County CA), every address returns zero local geofence matches. Without explicit handling, users see an empty list with no explanation. Prevention: implement the federal/state fallback path in the same phase as BallotReady removal — never ship a search path that can return a blank page.

4. **`ST_Within` vs `ST_Covers` boundary semantics** — Street addresses geocoded to district boundary lines return false for `ST_Within`, producing zero districts for valid addresses. Prevention: use `ST_Covers` from the start (already noted in `geofence_lookup.go` as the correct operator); add a boundary-point test case to confirm.

5. **SRID mismatch between TIGER shapefiles (NAD83/4269) and Google coordinates (WGS84/4326)** — If future TIGER imports are done without the `-s 4269:4326` reprojection flag, all geofence queries silently return zero. Prevention: add a `CHECK` constraint on `geofence_boundaries` enforcing `ST_SRID(geom) = 4326`; run `SELECT DISTINCT ST_SRID(geom)` validation after every shapefile import.

## Implications for Roadmap

Based on combined research, this milestone decomposes naturally into 4 phases. The build order is dependency-driven: BallotReady removal must be phased correctly (remove fallbacks before removing the client itself), and frontend work is fully parallel to backend work. The critical ordering constraint is that the federal/state fallback path must be implemented in the same phase as BallotReady removal — not as a follow-up — because it is the mechanism that prevents blank pages for the vast majority of US addresses that fall outside the two imported geofence areas.

### Phase 1: Backend — BallotReady Fallback Removal

**Rationale:** This is the highest-risk, highest-dependency work. The BallotReady fallback in `SearchPoliticians` is the core of what v1.5 removes. Everything else (frontend autocomplete, candidate endpoint) depends on having a clean backend that does not call BallotReady. Doing this first also validates that the geofence path works correctly as the sole lookup mechanism, and the federal/state fallback prevents blank pages in the uncovered majority of the US.

**Delivers:** A backend that uses geofence-only lookup for address search, with proper empty-state handling (federal/state officials from cache when local geofence returns 0 results), and no BallotReady fallback executing in `SearchPoliticians`.

**Addresses features:** Geofence-only politician matching (P1); federal/state fallback when local unavailable (P1); groundwork for BallotReady key removal (P1)

**Avoids pitfalls:** BallotReady dead code (Pitfall 5, partial); TIGER coverage gaps producing blank pages (Pitfall 6)

**Implementation scope:** Delete the fallback block in `SearchPoliticians()` at ~lines 2916-3035; extend zero-geofence path to call `fetchStatewideFromDB(geoResult.State)`; set `X-Data-Status: no-geofence-data` response header; return federal/state from cache when local geofence is empty.

**Research flag:** Standard patterns — ARCHITECTURE.md documents the exact file locations and line numbers. Skip research-phase.

---

### Phase 2: Backend — Cache-Only Candidates and Warmer Cleanup

**Rationale:** After Phase 1 confirms the geofence path is clean, tackle the two remaining live BallotReady call sites: the candidate endpoint and the lazy-fetch candidacy goroutine. Also stub the warmer functions and remove goroutine-kick from `handleZipLookup`. This completes all backend BallotReady removal and enables the API key to be safely decommissioned.

**Delivers:** `GetCandidatesByZip` reads from `essentials.election_records` (no live API call); `ensureCandidacyData` serves profile from DB only; warmer functions are stubs with log messages; `handleZipLookup` no longer kicks background goroutines; `_ ballotready` import removed from `setup.go`.

**Addresses features:** Cached-only candidate display (P1); BallotReady key removal (P1 — backend side complete)

**Avoids pitfalls:** BallotReady dead code (Pitfall 5, complete — all call sites removed and verified via grep)

**Implementation scope:** Write `fetchCandidatesFromDB(ctx, zip)` querying `election_records` with upcoming-election filter; delete goroutine in `ensureCandidacyData`; stub warmer bodies; remove warmer-kick blocks from `handleZipLookup` and `GetCacheStatus`; remove `_ ballotready` import from `setup.go`.

**Research flag:** The exact SQL for `fetchCandidatesFromDB` needs brief implementation research — `election_records` must join through politician → office → district → `zip_politicians` for a ZIP-scoped filter. Inspect the table schemas and join keys before writing this function. Otherwise standard patterns.

---

### Phase 3: Frontend — Address Autocomplete

**Rationale:** Fully parallel to Phases 1-2 on the backend. Sequenced here for narrative clarity. `VITE_GOOGLE_MAPS_API_KEY` must be confirmed set in the Netlify environment before the component can be tested in a deployed preview — that env var check is the blocking dependency for this track, not any backend work.

**Delivers:** `AddressSearch.jsx` wrapping `PlaceAutocompleteElement` (or legacy `Autocomplete` as interim for existing key); `loadMapsApi.js` dynamic loader reading from `VITE_GOOGLE_MAPS_API_KEY`; `Dashboard.jsx` and `Landing.jsx` using `<AddressSearch>` instead of plain `<input>`; graceful degrade to plain `<input>` if the Maps API fails to load.

**Addresses features:** Address autocomplete as primary input (P1); confirmed address display after selection (P1)

**Avoids pitfalls:** Autocomplete session billing spike (Pitfall 2 — session token in `useMemo([])`; 300ms debounce); hardcoded API key in HTML (Anti-Pattern 5 from ARCHITECTURE.md — use `loadMapsApi.js` dynamic loader, not raw HTML script tag)

**Stack notes:** Use `importLibrary('places')` from `@googlemaps/js-api-loader` v2.0.2 (already installed). `PlaceAutocompleteElement` preferred for forward compatibility; legacy `Autocomplete` class is acceptable as an interim since the existing API key predates the March 2025 cutoff. Use two separate API keys: browser-restricted key for frontend autocomplete, IP-restricted key for backend geocoding.

**Research flag:** Standard patterns — ARCHITECTURE.md includes complete component code examples for both `AddressSearch.jsx` and `loadMapsApi.js`. Skip research-phase.

---

### Phase 4: Validation, Polish, and Key Removal

**Rationale:** Only after Phases 1-3 are confirmed working in a deployed preview can the BallotReady API key be safely removed from App Runner and Netlify environment variables. This phase also covers the P2 polish items and the explicit "looks done but isn't" verification checklist from PITFALLS.md. It is strictly last because it depends on all prior phases being stable.

**Delivers:** `BALLOTREADY_API_KEY` removed from all environment configurations (App Runner + Netlify); frontend "no local coverage" message for addresses outside geofence areas; "Showing results for [City, State]" sub-header (P2); coverage badge wired to `X-Data-Status` header (P2); Google Cloud billing alert configured; Google for Nonprofits credits confirmed.

**Addresses features:** BallotReady key removal (P1 — final step); city/state sub-header (P2); coverage indicator badge (P2)

**Avoids pitfalls:** Missed BallotReady call sites (Pitfall 5 — final grep verification); Google API cost spike (Pitfall 2 — billing alert at $10/month)

**Verification checklist (from PITFALLS.md):**
- `grep -r "ballotReadyClient\|BallotReady\|BALLOTREADY" EV-Backend/` returns zero matches in Go files
- Cloud Console shows "Autocomplete - Per Session" SKU, not "Autocomplete - Per Request" SKU in billing breakdown
- Searching an address in a known non-geofence area (e.g., rural Iowa) returns federal and state officials with an explicit local-unavailable message
- Blank/empty-state message is present and visible when local geofence returns 0 results
- Google Maps API key restrictions set: browser key scoped to `*.empowered.vote`, server key IP-restricted to App Runner egress IP
- `VACUUM ANALYZE geofences.districts` run after any new TIGER shapefile import

**Research flag:** Standard patterns — mostly configuration and UI polish. Skip research-phase.

---

### Phase Ordering Rationale

- Backend phases (1 and 2) are ordered by dependency: the `SearchPoliticians` fallback must be removed before the backend can be considered BallotReady-independent; the candidate endpoint and warmer cleanup are independent of each other but logically follow Phase 1 so the main lookup path is proven clean first.
- Frontend (Phase 3) is fully parallel to Phases 1-2. It is listed third for narrative clarity only. `B1 → B2 → B3 → B4` is the internal frontend sequence per ARCHITECTURE.md.
- Phase 4 is strictly last: the BallotReady API key cannot be safely removed until all call sites are confirmed gone and the replacement paths are validated in production preview.
- The most critical ordering constraint: the federal/state fallback path must be in Phase 1 alongside BallotReady removal. Deferring it to Phase 4 would mean that after Phase 1 deploys, any address outside Monroe County IN or LA County CA returns a blank page. That is not acceptable for a deployed product.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (fetchCandidatesFromDB SQL):** The join path from `election_records` to `zip_politicians` for a ZIP-scoped candidate query is not fully spelled out in the research files. Inspect actual table schemas before writing this query to confirm join keys and the correct filter for "upcoming elections."

Phases with standard patterns (skip research-phase):
- **Phase 1:** Documented in ARCHITECTURE.md with exact file, function names, and approximate line numbers.
- **Phase 3:** ARCHITECTURE.md includes complete code for `AddressSearch.jsx` and `loadMapsApi.js`.
- **Phase 4:** Configuration changes and UI polish; no research needed.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Research is based on direct codebase inspection of the actual implementation files; no new packages reduces uncertainty to near-zero |
| Features | HIGH | Feature boundaries are clear; all P1 features map directly to named functions and existing code locations; P2/P3 boundaries are well-justified |
| Architecture | HIGH | ARCHITECTURE.md was produced from source inspection of `handlers.go`, `setup.go`, `geofence_lookup.go`, `geocoding/google.go`, and frontend files; exact line number ranges cited |
| Pitfalls | HIGH (PostGIS/billing), MEDIUM (BallotReady cutover) | PostGIS SRID and billing pitfalls sourced from official documentation; BallotReady cutover patterns are project-specific inferences from codebase review rather than external documentation |

**Overall confidence:** HIGH

### Gaps to Address

- **`fetchCandidatesFromDB` join path:** The exact SQL to join `election_records` to `zip_politicians` for a ZIP-scoped candidate query was not fully resolved in research. Inspect `essentials.election_records` schema columns before writing this function — particularly how election records link to districts, and how districts link to ZIP coverage.

- **`PlaceAutocompleteElement` shadow DOM styling:** The new web component uses shadow DOM, which limits Tailwind CSS targeting to the outer container only. Internal input styling requires `gmp-place-autocomplete::part(input)` CSS selector (limited browser support). If EV's design requires precise styling of the autocomplete input field internals, this may require a design tradeoff decision during Phase 3.

- **Google for Nonprofits application status:** Research flagged that the universal $200/month credit was replaced in March 2025 with per-SKU free tiers. Whether EV has applied for or received Google for Nonprofits credits ($250+/month additional) is unknown. Confirm before Phase 4 ships to production to avoid unexpected billing.

- **Boundary-point test coverage:** No test coordinates are currently documented for Monroe County IN or LA County CA district boundary edges. Phase 1 validation should include at minimum one coordinate known to sit exactly on a district boundary line to confirm `ST_Covers` (not `ST_Within`) behavior.

## Sources

### Primary (HIGH confidence)
- Direct source inspection: `EV-Backend/internal/essentials/geocoding/google.go` — geocoding client implementation, ZIP-required check that needs removal
- Direct source inspection: `EV-Backend/internal/essentials/geofence_lookup.go` — PostGIS ST_Contains query, GiST index usage
- Direct source inspection: `EV-Backend/internal/essentials/handlers.go` — BallotReady call site locations (lines 1266, 2917, 3674) and warmer function implementations
- Direct source inspection: `EV-Backend/internal/essentials/setup.go` — Provider initialization, GeoClient init pattern
- Direct source inspection: `essentials/src/hooks/useGooglePlacesAutocomplete.js` — existing autocomplete hook implementation
- Direct source inspection: `essentials/src/pages/Dashboard.jsx` — current plain input implementation
- Direct source inspection: `essentials/package.json` — confirmed `@googlemaps/js-api-loader: ^2.0.2` already installed
- [Google Maps Place Autocomplete Widget (legacy)](https://developers.google.com/maps/documentation/javascript/legacy/place-autocomplete) — API status and deprecation timeline for existing keys
- [Google Maps Place Autocomplete (new)](https://developers.google.com/maps/documentation/javascript/place-autocomplete-new) — PlaceAutocompleteElement specification
- [Google Maps Session Pricing](https://developers.google.com/maps/documentation/places/web-service/session-pricing) — abandoned session billing behavior and per-session vs per-request SKU distinction
- [Google Maps Security Best Practices](https://developers.google.com/maps/api-security-best-practices) — separate browser/server keys recommendation
- [PostGIS ST_Covers docs](https://postgis.net/docs/ST_ContainsProperly.html) — boundary semantics vs ST_Within
- [PostGIS Spatial Indexing](http://postgis.net/workshops/postgis-intro/indexing.html) — GiST index requirements and VACUUM ANALYZE necessity
- [TIGER/Line Shapefiles](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html) — SRID documentation and annual release cadence

### Secondary (MEDIUM confidence)
- [visgl/react-google-maps issue #736](https://github.com/visgl/react-google-maps/issues/736) — legacy Autocomplete unavailable to new API keys since March 2025
- [pkg.go.dev/googlemaps.github.io/maps](https://pkg.go.dev/googlemaps.github.io/maps) — Go SDK v1.7.0 last release date (December 2023), informing the "do not add" recommendation
- [Google Maps Platform March 2025 Billing Changes](https://developers.google.com/maps/billing-and-pricing/march-2025) — $200 universal credit replaced by per-SKU free tiers
- [TIGER Boundary Files — Redistricting Data Hub](https://redistrictingdatahub.org/data/about-our-data/tiger-boundary-files/) — documented TIGER coverage gaps for local districts
- [Ballotpedia "Who Represents Me"](https://ballotpedia.org/lookup/elected-officials.php) — competitor no-coverage handling patterns

### Tertiary (LOW confidence)
- [PostGIS Performance — Crunchy Data](https://www.crunchydata.com/blog/postgis-performance-indexing-and-explain) — GiST index and VACUUM ANALYZE behavior (aligns with PostGIS official docs)
- [ST_Contains vs ST_Covers — Medium](https://mentin.medium.com/which-predicate-cb608b470471) — boundary semantics comparison (aligns with PostGIS official docs)

---
*Research completed: 2026-02-22*
*Ready for roadmap: yes*
