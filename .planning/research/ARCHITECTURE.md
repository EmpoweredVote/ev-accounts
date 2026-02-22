# Architecture Research

**Domain:** Civic tech — address verification and BallotReady independence (v1.5)
**Researched:** 2026-02-22
**Confidence:** HIGH — based on direct source inspection of all relevant backend and frontend files

---

## System Overview

Current state (v1.4) annotated to show v1.5 changes:

```
┌──────────────────────────────────────────────────────────────────┐
│                   FRONTEND (essentials React app)                 │
├──────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────┐   ┌──────────────────────────────────┐ │
│  │  Dashboard.jsx        │   │  AddressSearch.jsx  [NEW]        │ │
│  │  plain <input> today  │   │  Google Places Autocomplete      │ │
│  │  [REPLACE input with  │   │  widget → formattedAddress       │ │
│  │   AddressSearch]      │   │  string → onSelect(address)      │ │
│  └───────────────────────┘   └──────────────────────────────────┘ │
│               POST /essentials/politicians/search                  │
│               body: { query: "123 Main St, Bloomington IN 47401" } │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                   GO BACKEND (EV-Backend)                         │
├──────────────────────────────────────────────────────────────────┤
│  SearchPoliticians() handler                                      │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  1. isZip5() check                                       │    │
│  │  2. GeoClient.Geocode(address) → lat, lng    [EXISTING]  │    │
│  │  3. FindGeoIDsByPoint(lat, lng)  [EXISTING PostGIS]      │    │
│  │  4. FindPoliticiansByGeoMatches()  [EXISTING DB join]    │    │
│  │  5. Supplement with federal+state from DB  [EXISTING]    │    │
│  │  6. [REMOVE] BallotReady fallback block                  │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  handleZipLookup()                                                │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  [REMOVE] warmer-kick goroutines (stale check + go func) │    │
│  │  [KEEP] fetchOfficialsFromDB(zip, state)                 │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  Warmers (modified)                                               │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  warmFederal() — [STUB] remove Provider.FetchFederal()   │    │
│  │  warmState()   — [STUB] remove Provider.FetchByState()   │    │
│  │  warmLocal()   — [STUB] remove Provider.FetchByZip()     │    │
│  │  All keep cache timestamp update logic                   │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  setup.go                                                         │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  [REMOVE] _ "ballotready" import side-effect             │    │
│  │  [REMOVE] provider.NewProvider(cfg) initialization       │    │
│  │  Provider = nil  (intentional)                           │    │
│  │  GeoClient init  [UNCHANGED]                             │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  GetCandidatesByZip()                                             │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  [REPLACE] brProvider.Client().FetchRacesByZip()         │    │
│  │  [WITH]    fetchCandidatesFromDB(ctx, zip)               │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ensureCandidacyData()                                            │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  [REMOVE] lazy-fetch goroutine to BallotReady            │    │
│  │  [KEEP] serve profile from whatever is in DB             │    │
│  └──────────────────────────────────────────────────────────┘    │
├──────────────────────────────────────────────────────────────────┤
│  EXTERNAL: Google Maps Geocoding API (backend only)               │
│  maps.googleapis.com/api/geocode — address → lat, lng            │
│  Already implemented in geocoding/google.go — no changes         │
├──────────────────────────────────────────────────────────────────┤
│  DATABASE (Supabase/PostgreSQL + PostGIS)                         │
│  ┌─────────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ geofence_       │  │ politicians  │  │ federal/state/zip  │  │
│  │ boundaries      │  │ offices      │  │ cache tables       │  │
│  │ (PostGIS GIST)  │  │ districts    │  │                    │  │
│  └─────────────────┘  └──────────────┘  └────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Current Responsibility | v1.5 Change |
|-----------|----------------------|-------------|
| `geocoding/google.go` | HTTP client wrapping Geocoding API, returns lat/lng + address components | None — already complete and correct |
| `geofence_lookup.go` | PostGIS ST_Contains query + politician DB join with MTFCC disambiguation | None — already complete and correct |
| `handlers.go: SearchPoliticians()` | ZIP/address detection, GeoClient geocoding, geofence lookup, BallotReady fallback | Delete BallotReady fallback block |
| `handlers.go: handleZipLookup()` | Cache freshness check, kick background warmers, serve from DB | Remove warmer-kick goroutines; keep DB fetch |
| `handlers.go: warmFederal/State/Local()` | Fetch from BallotReady via Provider + upsert + update cache timestamp | Remove Provider.Fetch*() body; keep cache timestamp update |
| `handlers.go: GetCandidatesByZip()` | Live BallotReady races query | Replace with DB-only query against election_records |
| `handlers.go: ensureCandidacyData()` | Lazy-fetch candidacy from BallotReady on profile view | Remove lazy-fetch goroutine; serve from DB or return empty |
| `setup.go: Init()` | Initializes Provider + GeoClient | Remove ballotready import; stop initializing Provider |
| `provider/` package | OfficialProvider interface + registry | No changes — keep for future extensibility |
| `ballotready/` package | GraphQL client + transform + candidacy | Keep in place but unused; remove import from setup.go |
| `AddressSearch.jsx` | Does not exist yet | New component — Places Autocomplete wrapper |
| `Dashboard.jsx` | Plain text input, calls searchPoliticians on submit | Replace input with AddressSearch component |
| `Landing.jsx` | Plain text input | Same swap |
| `api.jsx` | POST /politicians/search with query string | No changes — already sends address string to backend |

---

## Recommended Project Structure

No new directories needed. All changes are within existing files plus one new component file:

```
EV-Backend/internal/essentials/
├── geocoding/
│   └── google.go               # UNCHANGED — already complete
├── ballotready/
│   ├── client.go               # UNCHANGED — kept but unused
│   ├── provider.go             # UNCHANGED — kept but unused
│   ├── transform.go            # UNCHANGED — kept but unused
│   └── transform_candidacy.go  # UNCHANGED — kept but unused
├── geofence_lookup.go          # UNCHANGED — already complete
├── geofence_models.go          # UNCHANGED
├── handlers.go                 # PRIMARY CHANGE TARGET
├── setup.go                    # Remove ballotready import + Provider init
└── routes.go                   # UNCHANGED

essentials/src/
├── components/
│   └── AddressSearch.jsx       # NEW — Places Autocomplete wrapper
├── pages/
│   ├── Dashboard.jsx           # Swap <input> for <AddressSearch>
│   └── Landing.jsx             # Same swap
├── lib/
│   └── api.jsx                 # UNCHANGED
└── index.html                  # Add Maps JS API script tag
```

---

## Architectural Patterns

### Pattern 1: Geocode-Then-Geofence (primary address lookup path)

**What:** Google Maps Geocoding converts an address string to lat/lng. That point is fed into PostGIS `ST_Contains` against preloaded TIGER shapefile polygons. The matching `geo_id` values are joined to the politicians table filtered by MTFCC-compatible district types.

**This path already exists and already works** in `SearchPoliticians()`. The BallotReady fallback beneath it is what gets removed.

**Existing code flow (after BallotReady fallback removed):**
```
POST /politicians/search { query: "123 Main St, Bloomington IN" }
  → isZip5() → false (address query)
  → GeoClient.Geocode(query) → Result{Lat: 39.165, Lng: -86.526, State: "IN", Zip: "47401"}
  → FindGeoIDsByPoint(39.165, -86.526)
      → SELECT geo_id, mtfcc FROM essentials.geofence_boundaries
         WHERE ST_Contains(geometry, ST_SetSRID(ST_MakePoint(-86.526, 39.165), 4326))
      → [{GeoID: "18105", MTFCC: "G4020"}, {GeoID: "1847916", MTFCC: "G4110"}, ...]
  → FindPoliticiansByGeoMatches(matches)
      → WHERE (d.geo_id = '18105' AND d.district_type = ANY({'COUNTY','JUDICIAL'}))
           OR (d.geo_id = '1847916' AND d.district_type = ANY({'LOCAL','LOCAL_EXEC'}))
      → []OfficialOut (local/county politicians)
  → fetchOfficialsFromDB("47401", "IN") to supplement with federal+state from cache
  → deduplicate by ExternalID
  → return []OfficialOut
  → [REMOVED] BallotReady fallback when geofence returns 0 results
```

**After removal:** If geofence returns 0 results (area not imported), return empty array with `X-Data-Status: no-geofence-data` header. Frontend shows a clear message.

### Pattern 2: Warmers as No-Ops (BallotReady removed)

**What:** The three warmer functions (`warmFederal`, `warmState`, `warmLocal`) exist to populate the DB from an external API when caches are stale. With BallotReady removed, there is no external API to call. They become no-ops.

**Recommended approach — remove warmer-kick from request path:**
Do not call warmers from `handleZipLookup` or `GetCacheStatus` at all. The 90-day stale check becomes irrelevant when there's nothing to refresh from. Data is populated via the admin import tool (`POST /admin/import`). Remove the goroutine-spawning blocks from `handleZipLookup`:

```go
// REMOVE these blocks from handleZipLookup:
if !federalFresh {
    if tryAcquireLock(ctx, "federal") {
        go func() { ... warmFederal ... }()
    }
}
// (same for state + local)
```

**Warmer function bodies become:**
```go
func warmFederal(ctx context.Context) error {
    log.Printf("[warmFederal] No-op: BallotReady removed. Use admin import to refresh data.")
    return nil
}
```

**Keep:** The `FederalCache`, `StateCache`, `ZipCache` table models and the `fetchOfficialsFromDB` query that uses them. The cache table approach is still the right architecture — it just gets populated by admin import now instead of background warmers.

### Pattern 3: Google Places Autocomplete Widget (frontend)

**What:** Replace the plain `<input>` in Dashboard.jsx and Landing.jsx with a Google Places Autocomplete widget. On selection the user gets address suggestions; on pick the widget provides a `formattedAddress` string that is sent to the existing `POST /politicians/search` endpoint.

**Design decision — who geocodes?**

Two options exist:

**Option A: Frontend autocomplete for UX, backend geocodes (recommended for v1.5)**
- Frontend: Places Autocomplete widget shows suggestions as user types
- On selection: sends `formattedAddress` string to existing endpoint
- Backend: calls `GeoClient.Geocode(address)` as it already does
- Pros: No change to backend endpoint; consistent with existing flow; backend API key not exposed
- Cons: Two geocoding-equivalent calls per address search (Places API internally geocodes, then backend geocodes again)

**Option B: Frontend resolves lat/lng, backend receives coordinates**
- Frontend: after selection calls `place.fetchFields(['location'])` to get lat/lng
- Sends `{ lat, lng }` to a new backend endpoint `POST /politicians/locate`
- Backend calls `FindGeoIDsByPoint` directly, skips geocoding
- Pros: Eliminates redundant geocoding call; more precise (autocomplete selection = exact point)
- Cons: New endpoint; `VITE_GOOGLE_MAPS_API_KEY` exposes Places key to browser (already needed for autocomplete widget anyway)

**Use Option A for v1.5.** The redundant geocoding call is acceptable at nonprofit traffic scale. Option B is a clean optimization for a future milestone once the address flow is proven stable.

**Implementation for Option A:**

```jsx
// essentials/src/components/AddressSearch.jsx
import { useEffect, useRef } from "react";

export function AddressSearch({ onSelect, placeholder, className }) {
  const inputRef = useRef(null);

  useEffect(() => {
    if (!window.google?.maps?.places || !inputRef.current) return;

    const autocomplete = new window.google.maps.places.Autocomplete(
      inputRef.current,
      {
        types: ["address"],
        componentRestrictions: { country: "us" },
      }
    );

    const listener = autocomplete.addListener("place_changed", () => {
      const place = autocomplete.getPlace();
      if (place?.formatted_address) {
        onSelect(place.formatted_address);
      }
    });

    return () => window.google.maps.event.removeListener(listener);
  }, [onSelect]);

  return (
    <input
      ref={inputRef}
      type="text"
      placeholder={placeholder || "Enter your address"}
      className={className}
    />
  );
}
```

**Load Maps JS API in `essentials/index.html`:**
```html
<script
  src="https://maps.googleapis.com/maps/api/js?key=%VITE_GOOGLE_MAPS_API_KEY%&libraries=places"
  async
  defer
></script>
```

Note: Vite doesn't replace env vars in raw HTML. Options:
1. Inject via `vite-plugin-html` (adds a dependency)
2. Use a JS loader in `main.jsx` that reads `import.meta.env.VITE_GOOGLE_MAPS_API_KEY`
3. Set the key via Netlify environment substitution in `_headers` or build plugins

**Recommended: JS dynamic loader in main.jsx:**
```javascript
// essentials/src/loadMapsApi.js
export function loadGoogleMapsApi(key) {
  return new Promise((resolve, reject) => {
    if (window.google?.maps?.places) { resolve(); return; }
    const script = document.createElement("script");
    script.src = `https://maps.googleapis.com/maps/api/js?key=${key}&libraries=places`;
    script.async = true;
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });
}
```

Call in `App.jsx` or `main.jsx`:
```javascript
loadGoogleMapsApi(import.meta.env.VITE_GOOGLE_MAPS_API_KEY)
  .catch(err => console.warn("Maps API failed to load:", err));
```

**Billing note:** The legacy `google.maps.places.Autocomplete` widget manages session tokens automatically. Billing is per session (~$0.017/session in the US) rather than per keystroke. The new `PlaceAutocompleteElement` (Web Component) is still in alpha/beta — avoid it.

### Pattern 4: Candidates from DB Cache Only

**What:** `GetCandidatesByZip` currently calls `brProvider.Client().FetchRacesByZip()` live against the BallotReady API. After removal, it queries the `election_records` table that was populated during the last BallotReady import run.

**What changes:**
```go
// BEFORE: live BallotReady races call
func GetCandidatesByZip(w http.ResponseWriter, r *http.Request) {
    brProvider, ok := Provider.(*ballotready.BallotReadyProvider)
    if !ok {
        writeJSON(w, []CandidateOut{})
        return
    }
    races, err := brProvider.Client().FetchRacesByZip(r.Context(), zip)
    // ...
}

// AFTER: DB-only query
func GetCandidatesByZip(w http.ResponseWriter, r *http.Request) {
    candidates, err := fetchCandidatesFromDB(r.Context(), zip)
    if err != nil {
        log.Printf("[GetCandidatesByZip] db error: %v", err)
        writeJSON(w, []CandidateOut{})
        return
    }
    writeJSON(w, candidates)
}
```

`fetchCandidatesFromDB` queries `essentials.election_records` joined via politician → office → district, filtered to districts whose `geo_id` appears in the geofence lookup result for the ZIP's centroid (or the ZIP cache's state mapping).

---

## Data Flow

### Address Search (v1.5 — geofence path)

```
User types partial address in AddressSearch widget
    ↓
Google Places Autocomplete shows suggestions (session-billed)
    ↓
User selects → place.formatted_address = "123 Main St, Bloomington, IN 47401"
    ↓
onSelect(formattedAddress) → setActiveQuery(formattedAddress) in Dashboard.jsx
    ↓
usePoliticianData(activeQuery) → searchPoliticians(query) in api.jsx
    ↓
POST /essentials/politicians/search { query: "123 Main St, Bloomington, IN 47401" }
    ↓
[SearchPoliticians()] isZip5? NO
    ↓
GeoClient.Geocode("123 Main St...") → { lat: 39.165, lng: -86.526, state: "IN" }
Google Maps Geocoding API: ~200ms, ~$0.005
    ↓
FindGeoIDsByPoint(39.165, -86.526)
PostGIS ST_Contains: ~10-50ms with GiST index
    → matches: [{G4020/18105}, {G4110/1847916}, {G5220/4702}, {G5210/4702}]
    ↓
FindPoliticiansByGeoMatches(matches)
DB join with MTFCC-restricted district types: ~20-100ms
    → localOfficials: []OfficialOut (county + city + school board...)
    ↓
fetchOfficialsFromDB("47401", "IN")
    → federalOfficials + stateOfficials from cache tables
    ↓
Deduplicate by ExternalID, merge results
    ↓
Return []OfficialOut (local + state + federal)

Total backend time: ~250-400ms (mostly geocoding API call)
```

### ZIP Search (largely unchanged)

```
User types "47401"
    ↓
AddressSearch widget shows no suggestions (not an address)
User presses Enter or clicks search
    ↓
POST /essentials/politicians/search { query: "47401" }
    ↓
[SearchPoliticians()] isZip5? YES → handleZipLookup("47401")
    ↓
Check cache tables (federal, state, zip)
[NO WARMERS TRIGGERED — warmers removed from request path]
    ↓
fetchOfficialsFromDB("47401", "IN")
    → politicians from zip_politicians JOIN politicians JOIN offices JOIN districts
    ↓
Return []OfficialOut
[If empty, return [] with X-Data-Status: no-cache-data]
```

### Profile View (candidacy data)

```
GET /essentials/politician/{id}
    ↓
fetchPoliticianFromDB(id) → OfficialOut
    ↓
[REMOVED] ensureCandidacyData() lazy-fetch goroutine
    ↓
Return politician — endorsements, stances, elections served from DB
(populated by last admin import run)
```

---

## New vs Modified Components

### New (create from scratch)

| Component | File | What It Does |
|-----------|------|-------------|
| AddressSearch | `essentials/src/components/AddressSearch.jsx` | Google Places Autocomplete input wrapper; calls `onSelect(formattedAddress)` on pick; US-only address type restriction |
| Maps API loader | `essentials/src/loadMapsApi.js` | Dynamic script tag injection using `VITE_GOOGLE_MAPS_API_KEY`; resolves Promise when ready |

### Modified (targeted changes)

| Component | File | Change | Scope |
|-----------|------|--------|-------|
| SearchPoliticians handler | `handlers.go` | Delete BallotReady fallback block | ~lines 2916-3035 |
| handleZipLookup | `handlers.go` | Remove warmer-kick goroutines (3 blocks); keep fetchOfficialsFromDB | ~lines 266-323 |
| GetCacheStatus | `handlers.go` | Remove warmer-kick goroutines; keep status check | ~lines 192-232 |
| GetCandidatesByZip | `handlers.go` | Replace live BallotReady call with fetchCandidatesFromDB() | ~lines 3662-3750 |
| ensureCandidacyData | `handlers.go` | Remove lazy-fetch goroutine; keep DB-only serve logic | ~lines 1250-1290 |
| warmFederal | `handlers.go` | Remove Provider.FetchFederal() body; keep cache timestamp update | ~lines 1294-1343 |
| warmState | `handlers.go` | Remove Provider.FetchByState() body; keep cache timestamp update | ~lines 1348-1400 |
| warmLocal | `handlers.go` | Remove Provider.FetchByZip() body + containment logic; keep cache timestamp update | ~lines 1404-1530 |
| Init() | `setup.go` | Remove `_ ballotready` import; comment out Provider init; log "cached-data-only mode" | lines 11-92 |
| Dashboard.jsx | `essentials/src/pages/Dashboard.jsx` | Import AddressSearch; replace `<input>` with `<AddressSearch onSelect={setZip} />` | ~lines 130-150 |
| Landing.jsx | `essentials/src/pages/Landing.jsx` | Same swap | ~lines 50-65 |
| main.jsx or App.jsx | `essentials/src/main.jsx` | Call loadGoogleMapsApi() on mount | top-level |

### Kept Unchanged

| Component | Why |
|-----------|-----|
| `geocoding/google.go` | Already fully implemented — no changes needed |
| `geofence_lookup.go` | Already fully implemented — no changes needed |
| `geofence_models.go` | No schema changes needed |
| `provider/` package | Interface + registry kept for future extensibility |
| `ballotready/` directory | Code retained for historical reference; just not imported |
| `routes.go` | No new routes needed |
| `api.jsx` | Already POSTs address string to correct endpoint |
| All DB models and schemas | No schema changes required |

---

## Build Order (dependency-aware)

Two independent tracks. Track A (backend) has no dependencies on Track B (frontend), so they can proceed in parallel.

### Track A: Backend

**Step A1 — Remove BallotReady fallback from SearchPoliticians()**
- Delete the fallback block starting at the comment `/ Fallback: BallotReady address lookup`
- Verify: when geofence returns 0 results, the handler returns `[]OfficialOut{}` with `X-Data-Status: no-geofence-data`
- Test: POST a Bloomington IN address → returns politicians from existing geofence data

**Step A2 — Disable Provider initialization in setup.go**
- Remove the `_ "github.com/EmpoweredVote/EV-Backend/internal/essentials/ballotready"` import line
- Remove or comment out the `provider.NewProvider(cfg)` call
- Set `Provider = nil` explicitly with a log: `[essentials] Running in cached-data-only mode`
- Keep `GeoClient` initialization unchanged

**Step A3 — Remove warmer-kick goroutines from request handlers**
- In `handleZipLookup`: delete the three `if !xFresh { if tryAcquireLock... { go func()... } }` blocks
- In `GetCacheStatus`: delete the same three blocks
- Keep the cache freshness check reads (they're informational; used in X-Data-Status header)
- Stub warmer function bodies with a log message

**Step A4 — Replace GetCandidatesByZip with DB-only query**
- Implement `fetchCandidatesFromDB(ctx context.Context, zip string) ([]CandidateOut, error)`
- Query `essentials.election_records` joined to politicians via standard joins
- Filter to upcoming elections (election_date >= today) and districts that cover the ZIP
- Return empty slice gracefully if no data exists (election_records may be empty for most ZIPs initially)

**Step A5 — Remove ensureCandidacyData lazy-fetch**
- Delete the goroutine that calls `brProvider.Client().FetchCandidacy()`
- Profile views return whatever candidacy data is in the DB from the last import

### Track B: Frontend

**Step B1 — Add VITE_GOOGLE_MAPS_API_KEY to Netlify environment**
- Set in Netlify UI under essentials site environment variables
- This is a blocking dependency for B2 and B3 — do first
- Use a key restricted to `places` library and HTTP referrer `essentials.empowered.vote`

**Step B2 — Create loadMapsApi.js and wire into App.jsx**
- Dynamic script injection using env var
- AddressSearch component checks `window.google?.maps?.places` before attaching widget

**Step B3 — Build AddressSearch.jsx**
- `types: ["address"]` for street-level autocomplete
- `componentRestrictions: { country: "us" }` — US addresses only
- `onSelect(place.formatted_address)` callback on `place_changed` event
- Graceful degrade: if `window.google` not loaded, render plain `<input>` (identical UX to current)

**Step B4 — Swap input in Dashboard.jsx and Landing.jsx**
- Import and render `<AddressSearch>` where `<input>` exists today
- Pass `onSelect={val => { setZip(val); setActiveQuery(val); }}` or equivalent
- Keep existing `onSearchClick` / `setSearchParams` logic for Enter key and button click

### Blocking Dependencies

```
A1 → A2 → A3   (sequential, each builds on previous)
A4             (independent of A1-A3, can be done in parallel)
A5             (independent, can be done in parallel)

B1 → B2 → B3 → B4   (sequential)

A track and B track are fully parallel.
B1 (Netlify env var) must be set before B3/B4 can be tested in deployed preview.
```

---

## Integration Points

### Google Maps Geocoding API (backend)

| Aspect | Details |
|--------|---------|
| File | `internal/essentials/geocoding/google.go` — already complete |
| Auth | `GOOGLE_MAPS_API_KEY` environment variable |
| API restriction | Backend key: restrict to Geocoding API only in Google Cloud Console |
| Graceful degrade | `GeoClient == nil` when key not set → SearchPoliticians falls through to empty result with appropriate status header |
| Billing | ~$5 per 1,000 geocoding calls; free tier covers first $200/month |
| Error handling | Already implemented: HTTP error codes, status != "OK", missing ZIP in result |

### Google Maps Places Autocomplete (frontend)

| Aspect | Details |
|--------|---------|
| Integration | Dynamic script tag injection in `loadMapsApi.js` using `VITE_GOOGLE_MAPS_API_KEY` |
| Auth | `VITE_GOOGLE_MAPS_API_KEY` in Netlify environment variables |
| API restriction | Frontend key: restrict to Places API; HTTP referrer to `essentials.empowered.vote` |
| Session billing | Legacy Autocomplete widget manages session tokens automatically; ~$0.017 per session |
| Widget version | Use legacy `google.maps.places.Autocomplete`, not new PlaceAutocompleteElement (alpha) |
| Graceful degrade | If Maps API fails to load, component renders a plain `<input>` — existing UX preserved |

### PostGIS (existing, unchanged)

| Aspect | Details |
|--------|---------|
| Function | `FindGeoIDsByPoint(lat, lng)` → `ST_Contains` query in `geofence_lookup.go` |
| Index | `idx_geofence_boundaries_geometry` — GiST index created in `setup.go` |
| MTFCC disambiguation | Existing logic in `FindPoliticiansByGeoMatches` handles SLDU vs SLDL correctly |
| Coverage gap | Areas without imported TIGER data → 0 geofence results → empty response with clear header |

### BallotReady API (removed)

| Aspect | Where Removed |
|--------|--------------|
| `SearchPoliticians` fallback | Delete the fallback block in handlers.go |
| `GetCandidatesByZip` live call | Replace with fetchCandidatesFromDB() |
| `ensureCandidacyData` lazy-fetch | Delete the BallotReady goroutine |
| `warmFederal/State/Local` API calls | Stub function bodies |
| Import side-effect | Remove `_ ballotready` from setup.go |
| `BALLOTREADY_API_KEY` env var | Can be removed from App Runner config after cutover |
| `ballotready/` package | Kept in codebase but unused |

---

## Anti-Patterns

### Anti-Pattern 1: Moving Geocoding to the Frontend

**What people do:** Call `place.fetchFields(['location'])` in the frontend to get lat/lng, then send coordinates directly to a new backend endpoint.

**Why it's wrong (for v1.5):** It requires a new backend endpoint and splits address-resolution responsibility across two systems. The existing `POST /politicians/search` already works end-to-end. The redundant geocoding call (Places autocomplete internally geocodes, then backend geocodes again) costs a few cents per day at nonprofit scale — not worth the added complexity in this milestone.

**Do this instead:** Send `formattedAddress` to the existing endpoint. Add Option B (frontend resolves lat/lng → new endpoint) in a future milestone when addressing a scaling or cost concern.

### Anti-Pattern 2: Deleting the ballotready/ Package

**What people do:** Remove the entire `internal/essentials/ballotready/` directory for cleanliness.

**Why it's wrong:** The admin import tool (`StartBulkImport`, `GetImportStatus`) uses the `upsertNormalizedOfficial` pipeline which references BallotReady transform types. The DB already contains BallotReady-sourced data. The transform logic documents the data model. Deletion creates unnecessary risk and loses the historical reference.

**Do this instead:** Remove only the import side-effect in `setup.go` (`_ "github.com/EmpoweredVote/EV-Backend/internal/essentials/ballotready"`). The package compiles but is not registered in the provider registry and never called at runtime.

### Anti-Pattern 3: Removing Warmer Infrastructure Entirely

**What people do:** Delete `warmFederal`, `warmState`, `warmLocal`, the lock functions, and all cache table references.

**Why it's wrong:** The cache tables (`federal_cache`, `state_caches`, `zip_caches`) are read by `fetchOfficialsFromDB` to build accurate queries. The lock functions (`tryAcquireLock`/`releaseLock`) prevent thundering herd and are used elsewhere. Removing the cache tables would require restructuring the entire DB fetch query.

**Do this instead:** Remove only the API-call body inside each warmer function. Keep the function signatures, the cache timestamp updates, and the lock infrastructure intact. If a future data source is wired in, the infrastructure is already there.

### Anti-Pattern 4: Loading Maps JS API via npm Package

**What people do:** `npm install @vis.gl/react-google-maps` or `react-google-autocomplete` to avoid a `<script>` tag.

**Why it's wrong:** Adds bundle weight and a maintenance dependency. The native `google.maps.places.Autocomplete` widget loaded via script tag is lighter, handles session tokens automatically, and requires no npm package. The new `@vis.gl/react-google-maps` PlaceAutocompleteElement is still alpha/beta and not production-ready.

**Do this instead:** Load via dynamic script injection in `loadMapsApi.js`. Wrap in a React component using `useRef` + `useEffect` to attach after mount. This is the established pattern for Places Autocomplete in vanilla JS apps.

### Anti-Pattern 5: Hardcoding the Maps API Key in index.html

**What people do:** Put the API key directly in the `<script src>` URL in `index.html`.

**Why it's wrong:** Vite does not perform env var substitution in raw HTML files. The literal `%VITE_GOOGLE_MAPS_API_KEY%` string would be sent to the browser, breaking the widget.

**Do this instead:** Use the `loadMapsApi.js` dynamic loader that reads `import.meta.env.VITE_GOOGLE_MAPS_API_KEY`. This runs through Vite's env var system at build time.

---

## Scaling Considerations

| Scale | Architecture Notes |
|-------|-------------------|
| Current (100-1k users) | Single backend; PostGIS queries <50ms with GiST index; geocoding adds ~200ms per address search; total response ~400ms |
| 1k-10k users | Geocoding API cost becomes notable (~$30-300/month at 10k searches/day); consider caching geocoding results keyed on normalized address string |
| 10k+ users | Add `geocoded_addresses` table (normalized_input, lat, lng, formatted); check cache before calling Google; PostGIS read replicas for geofence queries |

**First bottleneck at scale:** Google Maps API cost and rate limits. The free tier covers $200/month. Geocoding is ~$5/1k calls; Places Autocomplete sessions are ~$17/1k sessions. At 1k daily unique searches: ~$600/month in API costs without caching.

**Mitigation before that point:** Cache geocoding results. A `geocoded_addresses` table keyed on `lower(trim(input_address))` turns repeated searches (same city) into a single API call.

---

## Sources

- Source inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geocoding/google.go` — HIGH confidence
- Source inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — HIGH confidence
- Source inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — HIGH confidence (full review)
- Source inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — HIGH confidence
- Source inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/provider/provider.go` — HIGH confidence
- Source inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/ballotready/provider.go` — HIGH confidence
- Source inspection: `/Users/chrisandrews/Documents/GitHub/essentials/src/pages/Dashboard.jsx` — HIGH confidence
- Source inspection: `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/api.jsx` — HIGH confidence
- [Google Maps Place Autocomplete Widget (legacy)](https://developers.google.com/maps/documentation/javascript/legacy/place-autocomplete) — HIGH confidence
- [Google Maps Place Autocomplete Data API](https://developers.google.com/maps/documentation/javascript/place-autocomplete-data) — HIGH confidence
- [Autocomplete session pricing](https://developers.google.com/maps/documentation/places/web-service/session-pricing) — HIGH confidence
- [Google Maps Geocoding API overview](https://developers.google.com/maps/documentation/geocoding/overview) — HIGH confidence
- [PostGIS point-in-polygon for civic representative lookup](https://medium.com/@nidhipandya1606/from-zip-codes-to-point-in-polygon-architecting-accurate-representative-lookup-for-voice-463c8f70a9ea) — MEDIUM confidence (external blog, aligns with existing implementation)

---

*Architecture research for: Address Verification & BallotReady Independence (v1.5)*
*Researched: 2026-02-22*
