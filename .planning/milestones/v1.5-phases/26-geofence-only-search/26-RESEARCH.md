# Phase 26: Geofence-Only Search - Research

**Researched:** 2026-02-22
**Domain:** Go backend address search, PostGIS geofence lookup, state resolution, HTTP response headers, React frontend search input
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Fallback behavior**
- When geofence returns zero local results, the response includes federal + state officials AND an explicit empty local section (signals to frontend that local was attempted but unavailable)
- Federal/state officials use a new address-aware lookup path that resolves address -> state -> officials in one step (not reusing the existing per-ZIP cache tables)
- Partial local results are returned as-is — if geofence matches county but not city council, show whatever matched. Some data is better than none.

**Response headers & signals**
- `X-Data-Status` header communicates coverage status to the frontend
- Response body contains politician data only — no metadata about coverage in the body. Header is sufficient.
- Response shape stays identical to today's format for the happy path — frontend doesn't need changes for full-coverage results
- Address search endpoint replaces the ZIP search endpoint entirely

**Search flow UX**
- Results grouped by Federal / State / Local tiers. When no local coverage, the Local section is visible but shows an empty-state message instead of cards.
- Same loading UX regardless of how fast geofence responds — keep the existing loading skeleton/spinner pattern
- Partial local results shown as-is with no "incomplete" indicator — users won't know what's missing
- Dashboard switches from ZIP input to address text input in this phase (not waiting for Phase 28 autocomplete)
- Confirmed/formatted search address displayed at the top of results (e.g., "Showing results for Bloomington, IN")

**Geofence coverage messaging**
- Tone: informational and matter-of-fact — "Local representative data is not yet available for this area."
- Placement: message sits inside the empty Local tier section, replacing where politician cards would be
- No call-to-action — just the informational message, keep it clean

### Claude's Discretion

- Handling of unresolvable addresses (invalid, PO box, etc.) — Claude picks based on what makes sense for the API contract
- X-Data-Status header value design (binary vs three-tier) — Claude designs based on what the frontend needs
- Internal geocoding approach for address -> state resolution

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BR-01 | Address search uses geofence-only matching (no BallotReady fallback) | The BallotReady fallback block (lines 2916-3037 of handlers.go) must be deleted. The geofence path already works. The geocoder must not require a ZIP to succeed. |
| BR-02 | User sees federal and state officials from cache when local geofence data is unavailable for their address | `fetchFederalAndStateFromDB(state)` already exists and is tested. State must be resolved from geocoder `State` field even when geofence returns zero matches. Response must include these officials plus an explicit empty local array (no BallotReady needed). |
</phase_requirements>

---

## Summary

Phase 26 is primarily a **deletion + repair** task in the backend, with a small frontend input change. The current `SearchPoliticians` handler already has a working geofence path (Google geocode → PostGIS point-in-polygon → `FindPoliticiansByGeoMatches` → `fetchStatewideFromDB` supplement). The problem is what happens when geofence returns zero results: the handler falls through to a BallotReady API call that must be removed.

Two concrete defects must be fixed before the BallotReady fallback is removed:
1. **Geocoder requires ZIP**: `geocoding/google.go` returns an error when the address has no ZIP component (line 129: `if out.Zip == "" { return nil, fmt.Errorf(...) }`). Phase 26 needs geocoding to succeed for state-only or city-only addresses. This guard must be relaxed — ZIP becomes optional, only `State` and coordinates are required.
2. **No-geofence path is dead-ends today**: When `len(geoMatches) == 0`, the code logs and falls through to BallotReady. This must become an active path: geocoder's `State` field resolves the state → `fetchFederalAndStateFromDB(state)` is called → officials returned with `X-Data-Status: no-geofence-data`.

The frontend change is lightweight: Dashboard switches `?zip=` URL param / ZIP-only input to a general address text input with `?q=` param routing directly to `SearchPoliticians`. The "Showing results for..." display requires the backend to echo the formatted address — this can go in a new response header (`X-Formatted-Address`) or in the existing body pattern. Since the user decided body contains politicians only, a header is the clean choice.

**Primary recommendation:** Relax the geocoder, delete the BallotReady fallback, implement the no-geofence fallback path in `SearchPoliticians`, add `X-Data-Status: no-geofence-data` and `X-Formatted-Address` headers, update the frontend Dashboard to address-only input with formatted address display and local empty-state message.

---

## Standard Stack

### Core (already in place — no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Go net/http | stdlib | HTTP handlers | Already used throughout |
| PostGIS | existing | Point-in-polygon geofence | Already enabled, spatial index exists |
| `geocoding.Client` | internal | Google Maps Geocoding API wrapper | Already initialized in `setup.go` |
| GORM | existing | DB queries | Already used |
| React | 19 | Frontend | Already used in essentials app |
| React Router v6 | existing | URL param routing | Already used (`useSearchParams`) |
| Tailwind CSS 4 | existing | Styling | Already used |

### Supporting (no new installs needed)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `useSearchParams` | React Router | Sync search state with URL | Already used in Dashboard; just change param name |
| `X-*` HTTP headers | stdlib | Communication channel to frontend | Already pattern in codebase (X-Data-Status, X-Geofence-Count) |

**Installation:** None required. All dependencies are already in place.

---

## Architecture Patterns

### Recommended File Touch Map

```
EV-Backend/internal/essentials/
├── geocoding/google.go         # MODIFY: relax ZIP requirement
├── handlers.go                 # MODIFY: SearchPoliticians fallback path
└── routes.go                   # MODIFY: remove /politicians/{zip} route (ZIP search eliminated)

essentials/src/
├── pages/Dashboard.jsx         # MODIFY: address input, formatted address display, empty-state message
├── lib/api.jsx                 # MODIFY: remove fetchPoliticiansOnce ZIP path for address queries
└── hooks/usePoliticianData.js  # MODIFY: treat all queries as address (no ZIP branch)
```

### Pattern 1: Geocoder ZIP Guard Relaxation

**What:** The `Geocode()` function in `geocoding/google.go` currently returns an error when no ZIP code is present in the geocoded address components. This blocks rural addresses, city-level inputs, and state capitals.

**Current code (lines 129-131):**
```go
// geocoding/google.go
if out.Zip == "" {
    return nil, fmt.Errorf("no ZIP code found in geocoding result for: %s", address)
}
```

**Fix:** Remove this guard. ZIP becomes optional metadata. Only coordinates (Lat, Lng) and State are required:
```go
// geocoding/google.go — after fix
// ZIP is optional — don't require it. State and coordinates are sufficient for Phase 26.
if out.Lat == 0 && out.Lng == 0 {
    return nil, fmt.Errorf("geocoding returned no coordinates for: %s", address)
}
if out.State == "" {
    return nil, fmt.Errorf("geocoding could not determine state for: %s", address)
}
return out, nil
```

**Confidence:** HIGH — direct code inspection of the guard.

### Pattern 2: SearchPoliticians Restructured Flow

**Current structure:**
```
SearchPoliticians
├── isZip5? → handleZipLookup (ZIP path, stays for now; removed in Phase 28)
├── GeoClient != nil?
│   ├── Geocode success?
│   │   ├── len(geoMatches) > 0?
│   │   │   └── len(officials) > 0? → return with supplemental ← HAPPY PATH
│   │   │       └── [empty officials — falls through to BallotReady]
│   │   └── [no geo matches — falls through to BallotReady]
│   └── [geocode failed — falls through to BallotReady]
└── BallotReady fallback ← MUST BE DELETED
```

**Phase 26 target structure:**
```
SearchPoliticians (address-only after ZIP path removed in Phase 28, but ZIP still delegates for now)
├── isZip5? → handleZipLookup (kept until Phase 28)
├── GeoClient nil? → 503 Service Unavailable (geocoding required, no BallotReady escape hatch)
├── Geocode failed? → 400 Bad Request or 422 Unprocessable Entity
├── len(geoMatches) > 0 AND len(officials) > 0?
│   └── Supplement with fetchFederalAndStateFromDB(state)
│       X-Data-Status: fresh-local (already in place)
│       X-Formatted-Address: geoResult.Formatted
│       → return officials
├── len(geoMatches) > 0 AND len(officials) == 0?  [geofences found but no politicians]
│   └── State from geoResult.State
│       fetchFederalAndStateFromDB(state) → federal + state officials
│       X-Data-Status: no-geofence-data
│       X-Formatted-Address: geoResult.Formatted
│       → return federal+state officials (local array is empty, frontend shows message)
└── len(geoMatches) == 0?  [no geofence coverage for this point]
    └── State from geoResult.State
        fetchFederalAndStateFromDB(state) → federal + state officials
        X-Data-Status: no-geofence-data
        X-Formatted-Address: geoResult.Formatted
        → return federal+state officials (local array is empty, frontend shows message)
```

The two "no local data" cases (empty officials after geo match, and no geo match at all) collapse to identical behavior: use `geoResult.State` to fetch from cache.

### Pattern 3: State Resolution from Geocoder (Not ZIP Prefix)

**Current issue:** The no-geofence path currently has no state resolution — it falls through to BallotReady. The geofence happy path uses `geoResult.State`, which is already present.

**Phase 26 approach (per user decision):** Use `geoResult.State` directly. The Google Geocoding API reliably returns the `administrative_area_level_1` short name (2-letter state code) for US addresses. No ZIP prefix lookup needed.

**When `geoResult.State` is empty (e.g., international address):** Return a 400 or 422 — the system only covers US officials.

**Confidence:** HIGH — the geocoder `Result` struct already populates `State` from `administrative_area_level_1`, and this is already used in the geofence happy path (line 2834).

### Pattern 4: X-Data-Status Header Design

**Current values in codebase:**
- `fresh` — ZIP query, all caches fresh
- `stale` — ZIP query, some caches stale
- `warmed` — ZIP query, warmed on demand
- `warming` — ZIP query, still warming (202)
- `fresh-local` — address search, geofence hit

**Phase 26 additions:**
- `no-geofence-data` — address search, no geofence coverage (federal + state only)

This is a three-tier design: `fresh-local` (full data), `no-geofence-data` (partial data, local unavailable).

The frontend needs to distinguish:
1. Full results → no message needed
2. No local coverage → show empty-state message in Local section

`X-Data-Status: no-geofence-data` is the cleanest signal. The frontend reads this header in `searchPoliticians()` (already done via `res.headers.get("X-Data-Status")`) and passes it through as `dataStatus` in `usePoliticianData`.

**Confidence:** HIGH — direct inspection of existing header pattern.

### Pattern 5: X-Formatted-Address Header

**Purpose:** Enables "Showing results for [address]" display in Dashboard without putting metadata in the response body.

**Backend:** `w.Header().Set("X-Formatted-Address", geoResult.Formatted)` on all successful address search responses.

**Frontend in `api.jsx` `searchPoliticians`:**
```javascript
export async function searchPoliticians(query) {
  // ...
  const status = res.headers.get("X-Data-Status") || "";
  const formattedAddress = res.headers.get("X-Formatted-Address") || "";
  const data = await res.json();
  return { status: status || "fresh", data, formattedAddress };
}
```

**Frontend in `usePoliticianData.js`:** Add `formattedAddress` to returned state.

**Confidence:** HIGH — mirrors existing `X-Geofence-Count` header pattern.

### Pattern 6: Dashboard Input and Empty-State Changes

**Input change:** Dashboard currently has ZIP-detection logic:
```javascript
// Current Dashboard.jsx line 44-48
if (/^\d{5}$/.test(normalized)) {
  setSearchParams({ zip: normalized });
} else {
  setSearchParams({ q: normalized });
}
```

Phase 26 removes ZIP detection from the UI — all queries go through `?q=` → `SearchPoliticians`. The placeholder changes from "Enter ZIP code or address" to "Enter your address".

Note: The `isZip5` check inside `SearchPoliticians` still delegates ZIP queries to `handleZipLookup` server-side. This is intentional — it keeps backward compat for direct `?zip=` URL bookmarks until Phase 28 removes it.

**"Showing results for" display:** A new state variable `formattedAddress` populated from `X-Formatted-Address` header. Shown as a small line above the tier tabs.

**Empty-state in Local section:** Current code (Dashboard.jsx line 209-212):
```jsx
{localPols.length == 0 && phase !== "loading" && phase !== "warming" && (
  <p className="mt-4">
    Sorry, we don't have data on local politicians for this location.
  </p>
)}
```

Phase 26 changes:
1. Condition should also check `dataStatus === "no-geofence-data"` to be explicit.
2. Message text changes to: "Local representative data is not yet available for this area."
3. Message sits inside the Local section, keeping the section visible (user decision).

### Anti-Patterns to Avoid

- **Do not 404 or 503 when geofence returns zero results.** The response must be a 200 with federal+state officials. A blank page is worse than a partial page.
- **Do not use the ZIP prefix map for address-based state resolution.** `geoResult.State` from the geocoder is authoritative. The prefix map is a fallback for the ZIP path only.
- **Do not add coverage metadata to the response body.** The user decided header-only. Body shape stays identical.
- **Do not remove the ZIP delegation inside `SearchPoliticians` yet.** That happens in Phase 28. Removing the `isZip5` branch now breaks ZIP bookmark URLs.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| State resolution from address | Custom geocoding, BallotReady geocoder | `geoResult.State` already in geocoder response | Already wired, authoritative, zero additional API calls |
| Invalid address detection | Custom validation | Let Google Geocoding API return ZERO_RESULTS status | Google already handles malformed addresses, PO boxes, international addresses |
| Geofence polygon lookup | Custom geometry math | `FindGeoIDsByPoint` via PostGIS `ST_Contains` | Already implemented and indexed |
| Federal+state from cache | New query | `fetchFederalAndStateFromDB(state)` | Already implemented, tested in the geofence happy path |

**Key insight:** Nearly everything needed for Phase 26 already exists in the codebase. The primary work is **routing the no-geofence code path correctly** rather than building new infrastructure.

---

## Common Pitfalls

### Pitfall 1: Geocoder Fails for Addresses Without ZIP

**What goes wrong:** `geocoding/google.go` line 129 returns an error when the address has no postal code (e.g., "Bloomington, Indiana", "rural county road addresses"). With the BallotReady fallback removed, this becomes a silent 503.

**Why it happens:** The ZIP guard was added when ZIP was needed to determine state. Now state comes from `geoResult.State`.

**How to avoid:** Remove the ZIP guard. Add a `State` requirement check instead. Return `out` as long as coordinates and state are present.

**Warning signs:** Test "Bloomington, Indiana" — if it errors, the guard is still in place.

### Pitfall 2: geoResult.State Empty for International Addresses

**What goes wrong:** A user enters "London, UK" — geocoder succeeds, coordinates exist, but `State` is empty (UK has no administrative_area_level_1 short code that maps to a US state). `fetchFederalAndStateFromDB("")` returns everything, or worse, panics.

**How to avoid:** Check `geoResult.State == ""` after geocoding. If empty, return HTTP 422 with message "Address must be within the United States."

**Warning signs:** Test an international address and verify it returns 422, not 200 with garbage data.

### Pitfall 3: `fetchStatewideFromDB` vs `fetchFederalAndStateFromDB` — Wrong Function Called

**What goes wrong:** The geofence happy path currently calls `fetchStatewideFromDB(state)` (only NATIONAL_EXEC, NATIONAL_UPPER, STATE_EXEC) but the no-geofence fallback should call `fetchFederalAndStateFromDB(state)` (all federal + all state types: NATIONAL_UPPER, NATIONAL_LOWER, STATE_EXEC, STATE_UPPER, STATE_LOWER).

**Why it matters:** When local data is unavailable, users still need to see their US Representatives (NATIONAL_LOWER) and state legislators (STATE_UPPER, STATE_LOWER). The statewide-only function omits these.

**How to avoid:** The no-geofence fallback must use `fetchFederalAndStateFromDB` (the fuller function). The geofence hit path already correctly uses `fetchStatewideFromDB` as supplemental (local geofence provides the rest).

**Confidence:** HIGH — confirmed by reading both function bodies at lines 2374 and 2381.

### Pitfall 4: Duplicate Officials When Supplementing Geofence Hits

**What goes wrong:** `fetchStatewideFromDB` returns officials that are already in the geofence-matched set. Duplicates appear in the response.

**How to avoid:** Already handled — the geofence happy path builds `seenExtIDs` and deduplicates (lines 2846-2860). Same pattern must be used in no-geofence path when supplementing. No change needed if the no-geofence path calls `fetchFederalAndStateFromDB` directly (local array is empty, no geofence results to deduplicate against).

### Pitfall 5: Frontend Reading X-Data-Status from Non-Search Responses

**What goes wrong:** `usePoliticianData` uses `dataStatus` from `fetchPoliticiansOnce` (ZIP path). The ZIP path returns different status values (`fresh`, `stale`, `warmed`). Adding `no-geofence-data` handling to the wrong branch causes confusion.

**How to avoid:** The `no-geofence-data` status only comes from `searchPoliticians()` (the address path). The frontend branch in `usePoliticianData` that handles non-ZIP queries is already separate (lines 113-128). Only update the address branch logic.

### Pitfall 6: Empty Response Array vs Non-Empty With No Locals

**What goes wrong:** When geofence has no coverage, returning `[]` causes `localPols.length == 0` — same as an error state. But `federalPols` and `statePols` would also be 0, making it look like a complete failure.

**How to avoid:** The no-geofence path must return federal + state officials (non-empty). The frontend differentiates: `localPols.length == 0` + `dataStatus === "no-geofence-data"` = known coverage gap. `localPols.length == 0` + no special status = loading or error.

---

## Code Examples

### Backend: Relaxed Geocoder

```go
// geocoding/google.go — replace the ZIP guard block
// Source: direct codebase inspection

// ZIP is optional; only coordinates and state are required for Phase 26.
if out.Lat == 0 && out.Lng == 0 {
    return nil, fmt.Errorf("geocoding returned no usable coordinates for: %s", address)
}
// State is required for federal/state fallback resolution
if out.State == "" {
    return nil, fmt.Errorf("geocoding could not determine US state for: %s", address)
}
return out, nil
```

### Backend: SearchPoliticians No-Geofence Fallback

```go
// handlers.go — replace the BallotReady fallback block (after line 2914)
// Source: direct codebase inspection of existing patterns

// No BallotReady fallback. Use federal + state from cache.
// State was resolved by the geocoder above.
geoState := strings.ToUpper(geoResult.State)
if geoState == "" {
    http.Error(w, "Address must be within the United States", http.StatusUnprocessableEntity)
    return
}

officials, err := fetchFederalAndStateFromDB(geoState)
if err != nil {
    log.Printf("[SearchPoliticians] no-geofence DB fetch error for state=%s: %v", geoState, err)
    http.Error(w, "Internal server error", http.StatusInternalServerError)
    return
}

log.Printf("[SearchPoliticians] no-geofence fallback: returned %d federal+state officials for state=%s", len(officials), geoState)
w.Header().Set("X-Data-Status", "no-geofence-data")
w.Header().Set("X-Formatted-Address", geoResult.Formatted)
writeJSON(w, officials)
```

### Backend: X-Formatted-Address on Happy Path

```go
// handlers.go — geofence happy path, before writeJSON call
// Source: direct codebase inspection

w.Header().Set("X-Data-Status", "fresh-local")
w.Header().Set("X-Geofence-Count", fmt.Sprintf("%d", len(geoMatches)))
w.Header().Set("X-Formatted-Address", geoResult.Formatted)
writeJSON(w, officials)
```

### Frontend: searchPoliticians with formattedAddress

```javascript
// api.jsx — searchPoliticians
// Source: direct codebase inspection

export async function searchPoliticians(query) {
  try {
    const res = await fetch(`${API}/essentials/politicians/search`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query }),
    });

    const status = res.headers.get("X-Data-Status") || res.headers.get("x-data-status") || "";
    const formattedAddress = res.headers.get("X-Formatted-Address") || res.headers.get("x-formatted-address") || "";

    if (!res.ok) {
      const text = await res.text();
      console.error(`Search API error: ${res.status}`, text);
      return { status: "error", data: [], error: `${res.status} ${res.statusText}` };
    }

    const data = await res.json();
    return { status: status || "fresh", data, formattedAddress };
  } catch (error) {
    console.error("Search error:", error);
    return { status: "error", data: [], error: error.message };
  }
}
```

### Frontend: Dashboard Address Input and Empty-State

```jsx
// Dashboard.jsx — key changes

// Input: address-only, no ZIP detection
const onSearchClick = () => {
  const normalized = (address || "").trim();
  if (!normalized) return;
  setSearchParams({ q: normalized });
  setActiveQuery(normalized);
};

// "Showing results for" display (above the tier tabs)
{formattedAddress && (
  <p className="text-center text-sm text-zinc-500 mt-2">
    Showing results for <span className="font-medium">{formattedAddress}</span>
  </p>
)}

// Local empty-state message (inside the Local tier section)
{localPols.length === 0 && phase !== "loading" && phase !== "warming" && activeQuery && (
  <p className="mt-4 text-zinc-500">
    Local representative data is not yet available for this area.
  </p>
)}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| BallotReady address lookup | Geofence + DB cache | Phase 26 | Removes live API dependency for address search |
| ZIP-required geocoder | State + coordinates required | Phase 26 | Enables rural/city-only addresses |
| No-coverage = BallotReady fallback | No-coverage = federal+state from cache | Phase 26 | Never returns empty list for valid US address |

**Deprecated/outdated after Phase 26:**
- BallotReady address lookup code block in `SearchPoliticians` (lines 2916-3037): deleted
- ZIP guard in `geocoding/google.go` (lines 129-131): replaced with state+coordinate guard
- "ZIP code or address" placeholder text in Dashboard: replaced with "Enter your address"

---

## Open Questions

1. **What happens when GeoClient is nil (no GOOGLE_MAPS_API_KEY set)?**
   - What we know: Currently the code falls through to BallotReady. After Phase 26, there is no fallback.
   - What's unclear: Should a nil GeoClient return 503 (service unavailable) or 400?
   - Recommendation: Return 503 with a clear message: "Address search requires Google Maps API key configuration." This is a server configuration error, not a user input error. The key should always be set in production.

2. **Should `fetchStatewideFromDB` or `fetchFederalAndStateFromDB` be used in the no-geofence path?**
   - What we know: `fetchStatewideFromDB` returns NATIONAL_EXEC + NATIONAL_UPPER + STATE_EXEC only. `fetchFederalAndStateFromDB` additionally returns NATIONAL_LOWER + STATE_UPPER + STATE_LOWER.
   - What's unclear: Per user decision (BR-02), "federal and state officials from cache" — this means the fuller set.
   - Recommendation: Use `fetchFederalAndStateFromDB`. When there's no local coverage, users need their US Representatives and state legislators, not just the President and Senators.

3. **Is `fetchStatewideFromDB` still the right supplement for the geofence happy path?**
   - What we know: Today it supplements local geofence results with NATIONAL_EXEC + NATIONAL_UPPER + STATE_EXEC only (not NATIONAL_LOWER/STATE_UPPER/STATE_LOWER).
   - What's unclear: Should US Representatives (NATIONAL_LOWER) and state legislators come from geofence or from `fetchStatewideFromDB`?
   - Recommendation: Leave the happy path as-is. NATIONAL_LOWER districts (congressional) are in the geofence data (MTFCC G5200). STATE_UPPER and STATE_LOWER also have geofence entries. They come from geofence matches, not from `fetchStatewideFromDB`. The current happy path logic is correct.

4. **Does the `X-Formatted-Address` header need CORS exposure?**
   - What we know: Custom `X-*` headers must be explicitly exposed in CORS `Access-Control-Expose-Headers` to be readable by browser JavaScript.
   - What's unclear: The current CORS middleware config needs inspection.
   - Recommendation: Check `internal/middleware/middleware.go` for `Access-Control-Expose-Headers`. Add `X-Formatted-Address` alongside any existing exposed headers.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — SearchPoliticians handler, fetchStatewideFromDB, fetchFederalAndStateFromDB
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geocoding/google.go` — ZIP guard, Result struct
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — FindGeoIDsByPoint, FindPoliticiansByGeoMatches
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/essentials/src/pages/Dashboard.jsx` — current input, tier display, empty-state
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/api.jsx` — searchPoliticians, X-Data-Status reading
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/essentials/src/hooks/usePoliticianData.js` — ZIP vs address branch logic
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/routes.go` — route registration
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — GeoClient initialization, provider setup

### Secondary (MEDIUM confidence)
- Google Maps Geocoding API behavior: `administrative_area_level_1` reliably returns US state abbreviation for US addresses. International addresses either return full name or are absent. (Based on well-documented API behavior, consistent with existing code that already uses `ShortName` for state.)

---

## Metadata

**Confidence breakdown:**
- Backend flow: HIGH — all code directly inspected
- Geocoder change: HIGH — the guard and its consequence are clear from source
- State resolution: HIGH — `geoResult.State` is already populated and used in happy path
- CORS header exposure: MEDIUM — middleware not inspected yet (open question 4)
- Frontend changes: HIGH — Dashboard and hook code directly inspected

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (stable codebase, 30-day window)
