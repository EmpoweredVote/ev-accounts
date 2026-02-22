# Stack Research — v1.5 Address Verification & BallotReady Independence

**Domain:** Civic engagement platform — address-based politician lookup
**Researched:** 2026-02-22
**Confidence:** HIGH

---

## Scope

This document covers only *new or changed* stack decisions for v1.5. The existing stack (Go 1.24.3 + Chi + GORM, React 19 + Vite 7 + Tailwind CSS 4) is retained as-is. Research focuses on three areas:

1. Google Maps Places autocomplete on the frontend (`essentials` app)
2. Google Maps Geocoding API on the backend (Go)
3. Removing BallotReady API dependency

---

## 1. Frontend: Google Maps Places Autocomplete

### Current State (Already Implemented)

The `essentials` app already has a working Places autocomplete implementation:

- **Package:** `@googlemaps/js-api-loader` `^2.0.2` (already installed in `essentials/package.json`)
- **Hook:** `src/hooks/useGooglePlacesAutocomplete.js` — custom hook using `setOptions` + `importLibrary('places')`
- **Usage:** `Landing.jsx` attaches autocomplete to an `inputRef` via the hook
- **API used:** `google.maps.places.Autocomplete` (legacy class, attached to existing `<input>`)

### Critical Finding: Deprecation of Legacy Autocomplete

As of March 1, 2025, `google.maps.places.Autocomplete` is **not available to new API keys** (MEDIUM confidence, from official Google docs and GitHub issue #736 on visgl/react-google-maps). The recommended replacement is `PlaceAutocompleteElement`.

**However:** The existing Google Cloud project has an API key created before March 1, 2025. The legacy `Autocomplete` class continues working for existing keys with at least 12 months notice before discontinuation. The current implementation is functional.

### Recommendation: Migrate to PlaceAutocompleteElement (Do in v1.5)

**Confidence: HIGH**

Migrate `useGooglePlacesAutocomplete.js` from `google.maps.places.Autocomplete` to `google.maps.places.PlaceAutocompleteElement`. This is a forward-compatible upgrade that avoids future breakage.

**Key differences:**
- `PlaceAutocompleteElement` is a Web Component with its own shadow DOM — it **cannot attach to an existing `<input>` element**
- Use `includedRegionCodes: ['us']` instead of `componentRestrictions: { country: 'us' }`
- Listen for `'gmp-select'` event instead of `'place_changed'`
- Call `place.fetchFields(['formattedAddress'])` to get the address string

**Migration approach** (no new npm packages needed):

```javascript
// useGooglePlacesAutocomplete.js — updated hook
import { useEffect, useRef } from 'react';
import { setOptions, importLibrary } from '@googlemaps/js-api-loader';

const API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

export default function useGooglePlacesAutocomplete(containerRef, { onPlaceSelected }) {
  const callbackRef = useRef(onPlaceSelected);
  callbackRef.current = onPlaceSelected;

  useEffect(() => {
    if (!API_KEY || !containerRef.current) return;

    if (!window.google?.maps?.importLibrary) {
      setOptions({ key: API_KEY });
    }

    let placeAutocomplete = null;

    importLibrary('places').then((placesLib) => {
      if (!containerRef.current) return;

      placeAutocomplete = new placesLib.PlaceAutocompleteElement({
        includedRegionCodes: ['us'],
      });

      containerRef.current.appendChild(placeAutocomplete);

      placeAutocomplete.addEventListener('gmp-select', async ({ placePrediction }) => {
        const place = placePrediction.toPlace();
        await place.fetchFields({ fields: ['formattedAddress'] });
        if (place.formattedAddress) {
          callbackRef.current(place.formattedAddress);
        }
      });
    });

    return () => {
      if (placeAutocomplete && containerRef.current?.contains(placeAutocomplete)) {
        containerRef.current.removeChild(placeAutocomplete);
      }
    };
  }, [containerRef]);
}
```

**Styling:** `PlaceAutocompleteElement` uses shadow DOM. Outer container CSS applies normally; internal input requires `gmp-place-autocomplete::part(input)` CSS parts selector (limited). For Tailwind-styled designs, wrap in a `div` container and style the container.

**No new npm packages required.** `@googlemaps/js-api-loader` v2.0.2 (already installed) supports `PlaceAutocompleteElement` via `importLibrary('places')`.

### What NOT to Do

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `@vis.gl/react-google-maps` | Adds a new dependency for a use case already covered by the existing hook pattern | Continue with custom hook + `@googlemaps/js-api-loader` |
| `use-places-autocomplete` npm package | Adds a third-party wrapper; the hook pattern is already working | Keep custom hook |
| `react-google-autocomplete` | Uses legacy `Autocomplete` class internally; will deprecate | `PlaceAutocompleteElement` directly |
| Keeping legacy `Autocomplete` class long-term | Not available to new API keys; Google will eventually remove it | `PlaceAutocompleteElement` |

---

## 2. Backend: Google Maps Geocoding (Go)

### Current State (Already Implemented)

The backend already has a complete, working geocoding implementation:

- **Location:** `internal/essentials/geocoding/google.go`
- **Approach:** Raw `net/http` calls to the Geocoding REST API — no Go SDK
- **Client:** `geocoding.Client` with 5-second timeout, initialized from `GOOGLE_MAPS_API_KEY` env var
- **Entry point:** `GeoClient` package-level var in `setup.go`, initialized in `Init()`
- **Used in:** `SearchPoliticians` handler — geocodes the query string, feeds lat/lng to `FindGeoIDsByPoint()`

The implementation is complete. The geocoding flow is:

```
POST /essentials/politicians/search { query: "123 Main St, City, IN" }
  → geocoding.Client.Geocode()   (Google Maps REST API)
  → FindGeoIDsByPoint()           (PostGIS ST_Contains)
  → FindPoliticiansByGeoMatches() (DB lookup by geo_id + MTFCC)
  → supplemental fetch from DB cache (federal + state)
  → return []OfficialOut
```

### Recommendation: Do NOT Add googlemaps/google-maps-services-go

**Confidence: HIGH**

The official Go SDK (`googlemaps.github.io/maps`, v1.7.0, last released December 2023) provides geocoding via `maps.Client.Geocode()`. However, the existing `net/http` implementation in `geocoding/google.go` already does everything needed:

- Parses `postal_code`, `administrative_area_level_1`, `administrative_area_level_2`, `locality`
- Returns structured `Result{Zip, State, County, City, Formatted, Lat, Lng}`
- Has graceful nil-client degradation when `GOOGLE_MAPS_API_KEY` is unset
- Has a passing test in `geocoding/google_test.go`

Adding the SDK introduces a new `go.mod` dependency for zero additional capability. The custom client is 135 lines and covers exactly the fields needed. Keep it.

**If the geocoding needs were more complex** (rate limiting, retry with backoff, reverse geocoding, elevation, etc.), the SDK would be worth it. For a single-endpoint REST call, it is not.

### What IS Needed: Extend Geocoding for Geofence-Only Flow

The geocoding client needs one targeted change to support v1.5: **remove the ZIP requirement**.

Currently `Geocode()` returns an error if no `postal_code` is found:
```go
if out.Zip == "" {
    return nil, fmt.Errorf("no ZIP code found in geocoding result for: %s", address)
}
```

For geofence-only lookups, a lat/lng is sufficient — ZIP is not needed. The fix is to make ZIP optional and return the result regardless:

```go
// Remove the ZIP check — lat/lng is all the geofence lookup needs
return out, nil
```

This is a one-line change to `geocoding/google.go`. No new packages.

### Integration Points with Existing PostGIS Infrastructure

The `SearchPoliticians` handler already wires geocoding → PostGIS → DB correctly:

```
GeoClient.Geocode(query) → (lat, lng)
FindGeoIDsByPoint(lat, lng) → []GeoMatch{GeoID, MTFCC}
FindPoliticiansByGeoMatches(matches) → []OfficialOut
fetchStatewideFromDB(state) → supplemental federal + state officials
```

The only infrastructure gap is geofence coverage: `geofence_boundaries` currently has TIGER 2024 data for Monroe County IN and LA County CA. Expanding coverage is a data problem, not a code problem.

---

## 3. Removing BallotReady API Dependency

### Current BallotReady Usage (What Needs Removal)

BallotReady is used in four places in the backend:

| Usage | File | Location | Purpose |
|-------|------|----------|---------|
| Fallback address lookup | `handlers.go` | `SearchPoliticians()` line 2917 | Address search when geofence misses |
| Candidacy lazy-fetch | `handlers.go` | `ensureCandidacyData()` line 1266 | Fetch endorsements/stances on profile view |
| Candidate races | `handlers.go` | `GetCandidatesByZip()` line 3674 | Live candidate/race data by ZIP |
| Cache warmers | `handlers.go` | `warmFederal/warmState/warmLocal()` | Populate politicians from BallotReady API |

### Recommendation: Phased Removal

**Confidence: HIGH**

**Phase 1 — Remove address search fallback (core of v1.5):**

In `SearchPoliticians()` at line 2916, the code falls back to BallotReady when geofence returns no results. Replace this with a clean error response:

```go
// Replace BallotReady fallback with informative error
if len(geoMatches) == 0 {
    w.Header().Set("X-Data-Status", "no-geofence-coverage")
    writeJSON(w, []OfficialOut{})
    return
}
```

The frontend should handle empty results gracefully (already does for the warming case).

**Phase 2 — Remove live candidate fetching:**

`GetCandidatesByZip()` calls `brProvider.Client().FetchRacesByZip()` for live race data. Replace with DB-only:

```go
// Instead of live BallotReady call, query essentials.election_records
// for future elections in the given ZIP's districts
```

This requires a `GET /candidates/{zip}` DB-backed query using `election_records` + `essentials.zip_politicians`. The data is already stored from previous BallotReady imports — the live call is just a freshness mechanism.

**Phase 3 — Remove candidacy lazy-fetch:**

`ensureCandidacyData()` calls BallotReady on first profile view. Once BallotReady is removed, this becomes a no-op. The data already stored in `endorsements`, `politician_stances`, `election_records` is the source of truth.

**Phase 4 — Remove Provider interface from warmers:**

`warmFederal/warmState/warmLocal` currently call `Provider.FetchFederal/FetchByState/FetchByZip`. When BallotReady is removed, these become no-ops (or removed entirely). The cached data in the DB is permanent.

### What to Keep

- `internal/essentials/ballotready/` package — keep as dead code until all imports are removed (avoids breaking the build mid-migration)
- `provider/` package interface — keep as scaffolding; set `Provider = nil` at startup
- All DB tables and cached politician data — the data is the asset; only the live API calls go away

### No New Go Packages Needed

The removal is subtractive. No new dependencies are introduced. The geofence lookup (`FindGeoIDsByPoint`, `FindPoliticiansByGeoMatches`) and DB cache queries already cover the replacement functionality.

---

## 4. New Environment Variables

| Variable | Used By | Status |
|----------|---------|--------|
| `GOOGLE_MAPS_API_KEY` | Backend geocoding client | Already in use |
| `VITE_GOOGLE_MAPS_API_KEY` | Frontend Places autocomplete | Already in use (via `useGooglePlacesAutocomplete.js`) |
| `BALLOTREADY_API_KEY` | BallotReady provider | Remove after full cutover |

---

## Recommended Stack (New Additions Only)

### Core Technologies

No new core technologies. All required infrastructure is already in place:
- Google Maps Geocoding REST API (already calling via `geocoding/google.go`)
- Google Maps Places JavaScript API (already loaded via `@googlemaps/js-api-loader`)
- PostGIS ST_Contains queries (already implemented in `geofence_lookup.go`)
- TIGER 2024 geofence data (already imported for Monroe County IN + LA County CA)

### Supporting Libraries

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| `@googlemaps/js-api-loader` | `^2.0.2` | Load Google Maps JS API dynamically | Already installed |

No new npm or Go packages are required for this milestone.

---

## Installation

No new packages to install. Verify the existing package is current:

```bash
# In essentials/
npm list @googlemaps/js-api-loader
# Should show 2.0.2 or higher

# In EV-Backend/ — no new packages
go list -m all | grep google  # No google packages should appear
```

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Custom `geocoding.Client` (existing) | `googlemaps.github.io/maps` Go SDK | SDK is v1.7.0 (Dec 2023, limited recent activity); custom client already works and covers all needed fields with 135 lines |
| Custom hook + `@googlemaps/js-api-loader` | `@vis.gl/react-google-maps` | Adds dependency for use case already covered by existing hook pattern |
| `PlaceAutocompleteElement` | Keep legacy `Autocomplete` class | Legacy class not available to new API keys since March 2025; forward-compat migration costs nothing |
| Empty response for uncovered geofence areas | BallotReady fallback for uncovered areas | Removing the fallback is the whole point of v1.5; uncovered areas return empty with a clear status header |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `googlemaps.github.io/maps` Go package | Zero benefit over existing `net/http` implementation; v1.7.0 last released Dec 2023 | Existing `geocoding/google.go` custom client |
| `use-places-autocomplete` npm | Third-party wrapper around a deprecated class (uses `AutocompleteService`); adds an npm dependency | `@googlemaps/js-api-loader` + `PlaceAutocompleteElement` directly |
| `react-google-autocomplete` npm | Uses legacy `Autocomplete` class; will break on new API keys | Custom hook with `PlaceAutocompleteElement` |
| Google Address Validation API | Adds billing complexity; Places autocomplete + Geocoding is sufficient for point-in-polygon matching | Existing Geocoding API |
| Any new Go web framework or router | Existing Chi router handles all needed routes | Keep Chi |
| PostGIS Go helper libraries | Raw SQL queries in `geofence_lookup.go` are clear, tested, and cover the use case | Existing `db.DB.WithContext(ctx).Raw(query, ...)` pattern |

---

## Version Compatibility

| Package | Version | Compatible With | Notes |
|---------|---------|-----------------|-------|
| `@googlemaps/js-api-loader` | `^2.0.2` | React 19, Vite 7 | v2.x is ESM-first; works with Vite without config changes |
| `@googlemaps/js-api-loader` | `^2.0.2` | `PlaceAutocompleteElement` | `importLibrary('places')` exposes `PlaceAutocompleteElement` |
| Google Maps JS API | `weekly` channel | `PlaceAutocompleteElement` | `weekly` channel always has latest stable |

---

## Integration Map: How Components Connect

```
Frontend (essentials)
  Landing.jsx / Results.jsx
    └─ useGooglePlacesAutocomplete hook
         └─ @googlemaps/js-api-loader v2.0.2
              └─ google.maps.places.PlaceAutocompleteElement
                   └─ gmp-select event → formattedAddress string
                        └─ navigate('/results?q=<address>')

Backend (EV-Backend)
  POST /essentials/politicians/search { query: "<address>" }
    └─ geocoding.Client.Geocode(address)
         └─ Google Maps Geocoding REST API
              └─ { lat, lng, state, zip, formatted }
                   └─ FindGeoIDsByPoint(lat, lng)
                        └─ PostGIS ST_Contains on essentials.geofence_boundaries
                             └─ []GeoMatch{GeoID, MTFCC}
                                  └─ FindPoliticiansByGeoMatches(matches)
                                       └─ DB join: politicians → offices → districts
                                            └─ + fetchStatewideFromDB(state)
                                                 └─ []OfficialOut → JSON response
```

The entire flow is already wired. v1.5 work is:
1. Migrate frontend hook from legacy `Autocomplete` to `PlaceAutocompleteElement`
2. Remove ZIP-required check from `geocoding/google.go`
3. Remove BallotReady fallback from `SearchPoliticians()`
4. Replace live BallotReady candidate call with DB-backed query
5. Remove `ensureCandidacyData` BallotReady live-fetch

---

## Sources

- `essentials/package.json` — confirmed `@googlemaps/js-api-loader: ^2.0.2` already installed
- `essentials/src/hooks/useGooglePlacesAutocomplete.js` — existing hook implementation
- `EV-Backend/internal/essentials/geocoding/google.go` — existing custom geocoding client
- `EV-Backend/internal/essentials/geofence_lookup.go` — existing PostGIS integration
- `EV-Backend/internal/essentials/handlers.go` — confirmed BallotReady usage locations (lines 1266, 2917, 3674)
- [Google Maps JS API Loader GitHub](https://github.com/googlemaps/js-api-loader) — v2.0.2 confirmed latest release (October 2025), HIGH confidence
- [PlaceAutocompleteElement docs](https://developers.google.com/maps/documentation/javascript/place-autocomplete-new) — replacement for legacy Autocomplete, HIGH confidence
- [visgl/react-google-maps issue #736](https://github.com/visgl/react-google-maps/issues/736) — legacy Autocomplete not available to new API keys since March 2025, MEDIUM confidence
- [pkg.go.dev/googlemaps.github.io/maps](https://pkg.go.dev/googlemaps.github.io/maps) — Go SDK v1.7.0, last released December 2023, MEDIUM confidence
- [Google Geocoding API overview](https://developers.google.com/maps/documentation/geocoding/overview) — Geocoding vs Address Validation API distinction, HIGH confidence

---

*Stack research for: v1.5 Address Verification & BallotReady Independence*
*Researched: 2026-02-22*
