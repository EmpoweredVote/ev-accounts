# Feature Research — v1.5 Address Verification & BallotReady Independence

**Domain:** Civic engagement — address-based politician lookup
**Researched:** 2026-02-22
**Confidence:** HIGH (based on existing codebase + official Google Maps docs; civic UX from market observation)

---

## Scope Note

This file covers only the NEW features for v1.5. Existing features (ZIP code search, 3-tier cache, geofence infrastructure, lazy-load candidacy, X-Data-Status headers) are built and working. Research here addresses: address autocomplete UX, BallotReady removal, coverage gap handling, and cached-only candidates display.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any address-based lookup tool. Missing these = product feels broken or untrustworthy.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Address autocomplete dropdown | Every address input on modern civic sites (Ballotpedia, vote.gov, Google "Who represents me") shows suggestions as you type. A bare text field with a Search button feels like 2010. | MEDIUM | `useGooglePlacesAutocomplete` hook already exists in Results.jsx. Work is removing the ZIP-code path as the primary entry and making address the only path. |
| Confirmed address display after search | After selecting an address, users expect to see the canonical formatted address (e.g., "123 Main St, Bloomington, IN 47401") not their raw typed input. Builds trust that the system understood them. | LOW | Google's `formatted_address` field is already returned in the Places response. Show it above results. |
| Graceful "no coverage" message | If an address geocodes but the geofence has no data, users need to understand why the list is empty — not just see a blank page. Civic apps universally show a message like "We don't have local representatives for this area yet." | LOW | Backend returns `X-Geofence-Count: 0` header already. Frontend can branch on empty results + this header. |
| Federal/state officials shown when local is missing | When local geofence data is absent, users still expect to see their Senators, Representative, and Governor. Not showing federal officials because local coverage is missing is a trust failure. | LOW | Backend `SearchPoliticians` already supplements geofence results with federal/state from DB cache. The gap is what happens when geofences return 0 matches — need to fall back to ZIP-derived state. |
| Candidate toggle still works with cached data | The existing "Show Candidates" toggle must continue to work. Users who have come to rely on it expect it to function. The only change is the source of data — cached instead of live. | MEDIUM | Currently `GetCandidatesByZip` calls BallotReady live. Must convert to a DB read from `essentials.election_records` and related tables, filtered for upcoming elections. |
| No broken experience when BallotReady is unavailable | After cutting BallotReady, address search must not break if Google geocoding fails. Must have a clear error path, not a 502 or blank page. | LOW | Current fallback path already calls BallotReady when geocoding fails or geofences are empty. That fallback path must be removed and replaced with a useful user message. |

### Differentiators (Competitive Advantage)

Features that distinguish EV from generic tools. Not required for v1.5 to ship, but improve the experience.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Address instead of ZIP as primary input | ZIP codes are not how people think about their address. Street address is more natural and more precise (ZIP codes cross district boundaries). Civic tools that accept street addresses feel more sophisticated. | LOW | The architecture already prefers address. This is a UI framing change — remove the ZIP input path and label the field "Your address" instead of "ZIP code or address." |
| "Showing officials for [City, State]" sub-header | When results load, showing "Showing representatives for Bloomington, IN" confirms the system interpreted the address correctly. Reduces user uncertainty about coverage. | LOW | The `formatted` address is already in the geocoding response. Extract city + state and display as a results header. `ResultsHeader` component in the codebase is the right place. |
| Coverage indicator (geofence vs. cache-only) | For power users, knowing whether local results come from precise geofence matching vs. a ZIP-level cache is useful. A subtle badge or tooltip ("District-matched" vs. "Zip-estimated") builds trust. | LOW | `X-Data-Status: fresh-local` vs `X-Data-Status: stale` already exists. Wire it to a UI indicator. This is a minor polish item. |
| Cached candidates with freshness date | Showing "Candidates as of [date]" when displaying cached candidate data sets honest expectations. Users understand the data may not include last-minute changes. | LOW | `election_records` table has election dates. Show the most recent import timestamp with the candidate toggle. |
| Address validation feedback (not just geocoding) | Google's Address Validation API (distinct from Geocoding) can flag undeliverable addresses before submitting. This prevents users from entering "123 fake street" and getting a confusing empty result. | HIGH | This is the new `PlaceAutocompleteElement` (post-March 2025). Adds session-based billing complexity. Consider deferred to v1.6. See Anti-Features below. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem helpful for v1.5 but create disproportionate cost or complexity.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Google Address Validation API (full validation) | Confirms addresses are real before geocoding, prevents garbage input | Separate billing SKU from Geocoding; requires session token management; adds latency; `PlaceAutocompleteElement` (new web component) requires migrating off the current hook-based approach which already works. As of March 1, 2025, legacy `Autocomplete` class is closed to new customers but existing customers are unaffected — the current hook still works. | Keep existing `useGooglePlacesAutocomplete` hook. Autocomplete suggestions are self-validating (user selects a real address from the dropdown). Only validate backend-side if geocoding fails to return a result. |
| Live BallotReady fallback for uncovered areas | Ensures users in un-imported areas always see data | The entire point of v1.5 is removing BallotReady dependency. A "live fallback" undermines this. It also means the API key must remain active. | Show a clear "coverage unavailable" message with federal/state officials from the cache. Set expectations that local coverage is expanding. |
| Accepting ZIP codes as a second input mode alongside address | Some users know their ZIP, not their address. Having both keeps them happy. | Two input modes = two code paths = two sets of edge cases. ZIP path does not use the geofence lookup. It triggers the old warmer flow. Maintaining both during a migration creates a split implementation that is hard to reason about. | During v1.5, unify on address. The existing ZIP warmer cache remains — a ZIP lookup against the backend still works internally. Users who type a ZIP into the address field will get geocoded results (Google geocodes ZIPs to coordinates, which then hit the geofence). |
| Real-time candidate data for uncached areas | Some candidates will not appear in cached data if they declared recently | Real-time candidate fetching was the BallotReady dependency. The whole point of this milestone is removing it. Keeping real-time for candidates means keeping the API key and all the transform logic. | Show candidates from cache only. Add a "data as of [date]" note. This is the correct trade-off for removing BallotReady dependency. |
| ZIP-code autocomplete suggestions (e.g., "90210 → Beverly Hills, CA") | Some users prefer ZIP. Showing city name for a ZIP helps them confirm they entered the right one. | ZIP autocomplete is a separate API pattern that requires a ZIP-to-city dataset or the Geocoding API. It does not help with district-level matching. | Not needed. Address autocomplete handles this use case entirely. Users who know their ZIP will type it; the geocoding API will resolve it to coordinates. |

---

## Feature Dependencies

```
Google Places Autocomplete (frontend)
    └──provides formatted address──> Backend SearchPoliticians endpoint
            └──requires──> Google Geocoding API (already integrated in geocoding/google.go)
                    └──provides lat/lng──> PostGIS FindGeoIDsByPoint (geofence_lookup.go)
                            └──provides geo matches──> FindPoliticiansByGeoMatches
                                    └──returns──> Officials list (geofence-matched)

Officials list
    └──supplemented by──> Federal/State cache (existing ZIP-based cache)
            └──requires──> State derived from geocoded address (geoResult.State already available)

Candidate toggle
    └──requires──> Cached ElectionRecord data (Phase B already populated this)
            └──filters on──> election_date >= today (future elections)
            └──requires──> New backend endpoint: GET /candidates/search (address-based)
                    OR reuse existing /candidates/{zip} with ZIP from geocoded result

BallotReady removal
    └──blocks until──> Address search path (geofence) covers the primary use case
    └──blocks until──> Candidate cached data endpoint exists
    └──allows removal of──> ballotready/client.go calls in SearchPoliticians
    └──allows removal of──> GetCandidatesByZip live-fetch path
    └──allows removal of──> BALLOTREADY_API_KEY env var dependency
```

### Dependency Notes

- **Address autocomplete requires active Google Maps API key:** `VITE_GOOGLE_MAPS_API_KEY` (frontend) and `GOOGLE_MAPS_API_KEY` (backend geocoding). Both already present — no new credentials needed.
- **Cached candidate display requires ElectionRecord population:** Phase B already seeded `essentials.election_records` from BallotReady. The data exists. The work is exposing it via a non-live endpoint that filters for upcoming elections. This is a new SQL query, not a new data collection step.
- **Federal/state supplemental requires state from geocoded address:** The `geoResult.State` field is already returned from `geocoding/google.go` and used in `SearchPoliticians`. When geofence matches are 0 (uncovered area), the backend can still use `geoResult.State` to derive the state and return federal + state officials from cache. This is a small code path extension — the state-from-geocode mechanism already exists.
- **BallotReady removal is a trailing action:** All the fallback paths (live officeholder fetch, live candidate fetch) depend on BallotReady. They can only be removed after the replacement paths are validated. Remove BallotReady last, not first.

---

## MVP Definition

### Launch With (v1.5)

Minimum viable set to achieve the milestone goal: address-only search, BallotReady removed, cached candidates.

- [x] Address autocomplete as the primary (only) search input — remove ZIP-specific input path from Results.jsx UI; address field label reads "Your address"
- [x] Confirmed address display after selection — show `formatted_address` from Google as a results sub-header
- [x] Geofence-based politician matching for covered areas — already works; ensure it is the primary path with no BallotReady fallback
- [x] Federal/state officials from cache when local geofence returns 0 results — extend the "no geofence matches" path in `SearchPoliticians` to still return federal + state for the geocoded state
- [x] "No local coverage" message when local data is unavailable — frontend branch when local politicians = 0 but federal/state present
- [x] Cached-only candidate display — new backend endpoint (or modify `/candidates/{zip}`) to read from `essentials.election_records` instead of calling BallotReady; filter `election_date >= today`
- [x] BallotReady API key removed from required env vars — both the live officeholder path and live candidate path replaced; `BALLOTREADY_API_KEY` becomes optional/unused

### Add After Validation (v1.x)

Features to add once the core v1.5 flow is confirmed working.

- [ ] "Showing results for [City, State]" sub-header — low effort polish once address flow works
- [ ] Coverage indicator badge (geofence-matched vs. cache-only) — uses existing `X-Data-Status` header, frontend only
- [ ] Candidate data freshness date ("as of [date]") — show import timestamp with candidate toggle
- [ ] Address-based candidate endpoint instead of ZIP fallback — currently candidates fetch by ZIP derived from geocoded address; a true address-based candidate endpoint would be more precise

### Future Consideration (v2+)

Features to defer: significant complexity or not needed for stated milestone goal.

- [ ] `PlaceAutocompleteElement` migration (new Google API) — existing customers unaffected until deprecation; current hook still works for EV; migrate when forced
- [ ] Full address validation (undeliverable address detection) — requires `PlaceAutocompleteElement` + Address Validation API; adds session billing complexity
- [ ] Wider geofence coverage (import TIGER shapefiles for more states/counties) — data import work, not feature work; needed before the platform is useful nationally
- [ ] Candidate endorsement/stances display in ZIP results (not just profile) — requires significant frontend rework; currently lazy-loaded on profile view only

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Address autocomplete as primary input | HIGH — reduces friction, removes ZIP guessing | LOW — hook already exists, UI change only | P1 |
| Confirmed address display | MEDIUM — trust signal, UX polish | LOW — `formatted_address` already available | P1 |
| Geofence-only politician matching | HIGH — core milestone requirement | LOW — already works; remove BallotReady fallback | P1 |
| Federal/state when local unavailable | HIGH — prevents blank results outside covered areas | LOW — extend existing `SearchPoliticians` path | P1 |
| "No local coverage" user message | HIGH — prevents confused blank pages | LOW — frontend branch, no backend changes | P1 |
| Cached candidate endpoint | HIGH — removes last live BallotReady call | MEDIUM — new SQL query, endpoint, data mapping | P1 |
| BallotReady key removal | HIGH — the milestone's defining outcome | LOW — env var change + code cleanup after above | P1 |
| "Showing results for [City]" header | MEDIUM — trust/orientation signal | LOW — cosmetic | P2 |
| Coverage indicator badge | LOW — power user only | LOW — uses existing header | P2 |
| Candidate freshness date | MEDIUM — honest about data age | LOW — add import timestamp to response | P2 |
| PlaceAutocompleteElement migration | LOW for existing customers | HIGH — requires hook rewrite, session tokens | P3 |
| Wider geofence coverage | HIGH for national launch | HIGH — data import / ops work | P3 |

**Priority key:**
- P1: Must have for v1.5 launch
- P2: Should have, add in v1.5.x polish pass
- P3: Future milestone

---

## Edge Case Behavior Specifications

These are the specific scenarios that need explicit implementation decisions. Research shows civic apps consistently fail silently on these; explicit handling is what separates polished tools from MVP hacks.

### Case 1: Address geocodes but geofence has no data

**What happens today:** `SearchPoliticians` logs "no politicians found for geo-IDs (area not pre-populated)" and falls through to BallotReady live fetch.

**What must happen in v1.5:** Fall back to federal + state officials from cache using `geoResult.State`. Return them with `X-Data-Status: cache-only`. Frontend shows: "We found your representatives at the federal and state level. Local district data for this address is not yet available."

**Why this matters:** This is the most common case for any address outside Bloomington, IN and Los Angeles, CA (the only areas with imported geofences). Getting this wrong means the vast majority of addresses return an empty page.

### Case 2: Google geocoding fails (bad address, API error)

**What happens today:** Falls through to BallotReady live address lookup.

**What must happen in v1.5:** Return HTTP 400 with message "We could not find this address. Please check the address and try again." Frontend catches this and shows the error. No fallback to BallotReady.

**Why this matters:** Without the BallotReady fallback, a geocoding failure must produce a user-friendly error — not a 502 or silent empty result.

### Case 3: Address autocomplete selection vs. typed ZIP

**What happens today (Results.jsx):** The hook detects ZIP (`/^\d{5}$/.test()`) vs address and routes differently. ZIP goes to `/politicians/{zip}`, address goes to `/politicians/search`.

**What must happen in v1.5:** Typing a ZIP into the address field will work because Google Places Autocomplete converts a ZIP to a formatted address (e.g., "47401" becomes "Bloomington, IN 47401, USA"). The backend geocodes that formatted string and gets coordinates. The geofence lookup then runs. The ZIP warmer cache is not triggered. This is correct behavior — geofence is more precise than ZIP-grid.

**Implementation note:** The frontend `isZip` detection and the `/politicians/{zip}` path can be deprecated in the Results page. The address path handles ZIPs automatically through Google.

### Case 4: Candidate toggle — no cached data exists

**What happens today:** Live BallotReady fetch returns real candidates.

**What must happen in v1.5:** If `essentials.election_records` has no future elections for the inferred ZIP/location, the toggle shows nothing (or a message: "No upcoming election candidates are available for this area"). This is honest and correct — it is not a bug.

**Why this matters:** Election records are only populated for politicians who have been fetched from BallotReady candidacy data. Areas that were never fetched will have no records. This is a data coverage gap, not an application error. The UX must distinguish between "no candidates" and "feature unavailable."

### Case 5: Google Maps API key missing or quota exceeded

**What happens today:** `geocoding/google.go` `NewClient()` returns nil when key is missing — graceful degradation.

**What must happen in v1.5:** When `GeoClient` is nil (no key), the address search endpoint should return a clear error: "Address search is currently unavailable. Please try again later." This path is already handled by the `GeoClient != nil` guard in `SearchPoliticians`. The only change is the error response when it's nil.

---

## Competitor Reference: How Comparable Tools Handle These Cases

| Tool | Address input type | No coverage handling | Candidate display |
|------|--------------------|----------------------|-------------------|
| Ballotpedia "Who Represents Me" | Google Places autocomplete (legacy widget) | "We encountered an error determining your location. Please go back and try again." — unhelpful generic error | Shows candidates inline with incumbents, labeled with "Candidate" badge; grouped by race |
| Google "Who represents me" | Native Google Maps search with full Places | Falls back to county/state level if local data absent; shows what it has | Election-specific; not a permanent feature |
| My Reps (datamade.us) | Free-text address, no autocomplete | "We couldn't find any representatives for that address. Please try again." | Does not show candidates |
| vote.gov | Address input with autocomplete | Redirects to state election office if no data | No candidates; links to state ballot lookup |
| EV Essentials (current) | ZIP or address (both accepted) | Empty result list + loading spinner | Live BallotReady fetch via toggle (v1.0+) |
| EV Essentials (v1.5 target) | Address only (ZIP still works via geocode) | Federal/state from cache + coverage message | Cached election records, toggle opt-in |

**Key observation:** Every tool uses Google Places Autocomplete (or equivalent) for address input. None show a blank page on no coverage — they all show partial data or an explanatory message. EV's approach of showing federal/state from cache when local is unavailable is more useful than competitor error messages.

---

## Google Maps Places API: Critical Notes for v1.5

**Current implementation (HIGH confidence — from codebase):**
- Frontend: `useGooglePlacesAutocomplete` hook uses `@googlemaps/js-api-loader`, `importLibrary('places')`, `placesLib.Autocomplete` (legacy class), restricted to US, `types: ['geocode']`
- Backend: `geocoding/google.go` uses Geocoding API (not Places) to convert address strings to lat/lng

**API status (HIGH confidence — Google official docs, March 2025):**
- `google.maps.places.Autocomplete` (legacy class) is closed to NEW customers as of March 1, 2025
- Existing customers (EV is an existing customer) are unaffected — the legacy class still works, still receives bug fixes for major regressions
- `PlaceAutocompleteElement` (new web component) is the recommended replacement but is not required for existing customers
- Migration to `PlaceAutocompleteElement` is a v2+ concern unless forced by deprecation

**Billing (MEDIUM confidence — Google docs, current pricing page):**
- Session-based billing: ~$2.83 per 1,000 autocomplete requests without sessions; session pricing bundles requests
- For EV's scale (nonprofit, low volume), autocomplete costs are minimal — Google provides $200/month free credit which covers ~70,000 session-based autocomplete interactions
- Backend Geocoding API (server-side) is billed separately: $5/1,000 requests, covered by the same $200 credit
- Risk: cost spike if search volume grows unexpectedly — monitor with billing alerts

---

## Sources

- Google Maps Platform — Place Autocomplete Widget (New): https://developers.google.com/maps/documentation/javascript/place-autocomplete-new
- Google Maps Platform — Session Pricing: https://developers.google.com/maps/documentation/javascript/session-pricing
- Google Maps Platform — Legacy Autocomplete (status): https://developers.google.com/maps/documentation/javascript/legacy/place-autocomplete
- visgl/react-google-maps Issue #736 — March 2025 legacy Autocomplete deprecation notice: https://github.com/visgl/react-google-maps/issues/736
- Ballotpedia "Who Represents Me" tool (observed behavior): https://ballotpedia.org/lookup/elected-officials.php
- My Reps (DataMade) — no-coverage fallback message: https://myreps.datamade.us/
- EV Codebase: `essentials/src/hooks/useGooglePlacesAutocomplete.js`, `EV-Backend/internal/essentials/geocoding/google.go`, `EV-Backend/internal/essentials/geofence_lookup.go`, `EV-Backend/internal/essentials/handlers.go` (SearchPoliticians, GetCandidatesByZip)
- EV PROJECT.md — v1.5 milestone definition

---

*Feature research for: v1.5 Address Verification & BallotReady Independence*
*Researched: 2026-02-22*
