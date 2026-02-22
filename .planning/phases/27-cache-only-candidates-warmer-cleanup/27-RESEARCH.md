# Phase 27: Cache-Only Candidates & Warmer Cleanup - Research

**Researched:** 2026-02-22
**Domain:** Go backend refactoring — BallotReady provider removal, warmer elimination, DB-only candidate reads
**Confidence:** HIGH — all findings are from direct codebase inspection

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Candidate toggle behavior**
- Keep the toggle on the Essentials dashboard — users opt in to see candidates alongside elected officials
- When toggle is on, candidates appear mixed into their respective tier (Federal/State/Local), not in a separate section
- Candidates are visually distinguished with a small "Candidate" badge/tag on the card — same card style otherwise
- Show candidates even if some data is missing — name, party, office sought are sufficient; missing fields just don't appear
- Only currently running candidates should appear — past candidates are excluded entirely
- Add an `is_active` manual flag column to determine which candidates are currently running (set during data import, manually toggleable)

**Missing data handling**
- Hide empty sections on politician profile pages — if no endorsements/stances/elections are cached, those sections simply don't render
- No lazy-fetch on profile view — profiles read from DB only, no background goroutine
- No fetch attempt of any kind — if data isn't cached, it's not shown

**Warmer and provider removal**
- Remove warmFederal, warmState, warmLocal functions entirely — clean break, no stubs, no dead code
- Remove the BallotReady provider/client completely — delete initialization, config, and all related code
- Remove the lazy-fetch candidacy goroutine and its BallotReady dependency
- Drop cache tracking tables (zip_caches, federal_cache, state_caches) — nothing writes to them anymore
- Phase 29 will verify zero BallotReady references remain via grep audit

**Transition visibility**
- Transition is invisible to users — no freshness indicators, no "last updated" dates
- No coverage gap handling needed for ZIP searches (already removed in Phase 26)
- Address search empty state already handled in Phase 26 ("representative data is not yet available for this area")
- Instant loading expected — all data from DB means no progressive loading needed

### Claude's Discretion
- Exact order of removal operations (warmers vs provider vs lazy-fetch)
- Database migration approach for dropping cache tables and adding is_active column
- How to handle any code that currently reads from cache tracking tables

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BR-03 | Background cache warmers (warmFederal, warmState, warmLocal) no longer call BallotReady API | Warmers deleted entirely — all call sites in handlers.go identified and mapped |
| BR-04 | BallotReady provider is de-registered from setup (no initialization at startup) | Blank import in setup.go and provider init logic in setup.go fully identified |
| CAND-01 | User can view cached candidate/race data from election_records table (no live BallotReady fetch) | New DB-only GetCandidatesByZip handler pattern designed from existing fetchOfficialsFromDB patterns |
</phase_requirements>

---

## Summary

Phase 27 is a removal-heavy backend phase. The goal is to cut every remaining path that calls the BallotReady API live — the three cache warmers, the lazy-fetch candidacy goroutine on profile view, and the `GetCandidatesByZip` handler which currently calls `brProvider.Client().FetchRacesByZip()` — and replace each with database-only reads. No new libraries are needed. The work is entirely within `EV-Backend/internal/essentials/`.

The candidate toggle already exists in the `essentials` frontend (`Results.jsx`). It calls `fetchCandidates()` in `api.jsx`, which POSTs to `/essentials/candidates/{zip}`. The backend handler `GetCandidatesByZip` (line 3572 in `handlers.go`) currently type-asserts `Provider` to `*ballotready.BallotReadyProvider` and calls the live API. This handler needs to be replaced with a SQL query against `essentials.election_records`. An `is_active` boolean column must be added to `ElectionRecord` to filter for current candidates.

The cache tracking tables (`federal_cache`, `state_caches`, `zip_caches`) are referenced throughout `handleZipLookup`, `GetCacheStatus`, `warmFederal`, `warmState`, `warmLocal`, and `getCacheStatus`. After removing the warmers, the only callers remaining for these tables are the stale-data check path inside `handleZipLookup` and `GetCacheStatus`. Since Phase 26 removed ZIP as a user-facing search path (ZIP delegation preserved temporarily inside `SearchPoliticians`), `handleZipLookup` still exists but will eventually be phased out. For now, both `handleZipLookup` (reachable via `/politicians/{zip}`) and `GetCacheStatus` (`/cache-status/{zip}`) can be simplified or removed — but removing the cache tables requires removing or rewriting all code that reads them first.

**Primary recommendation:** Work in three clean passes: (1) add `is_active` migration and rewrite `GetCandidatesByZip` to read from DB, (2) delete `warmFederal`/`warmState`/`warmLocal` and all their call sites including the Cicero fallback paths, then drop the cache tracking tables and related GORM models and `GetCacheStatus` endpoint, (3) remove `ensureCandidacyData` / lazy-fetch goroutine, and remove the BallotReady provider blank import and initialization block from `setup.go`.

---

## Standard Stack

### Core (no new dependencies required)

| Component | Version | Purpose | Note |
|-----------|---------|---------|------|
| GORM | existing | DB queries and migrations | Already in use |
| Chi router | existing | HTTP routing | Already in use |
| PostgreSQL | existing | Data store | Already in use |

No new libraries needed. This phase only removes code and adds a DB migration.

---

## Architecture Patterns

### Where the Code Lives

```
EV-Backend/internal/essentials/
├── handlers.go          # ~3,650 lines — all warmers, GetCandidatesByZip, ensureCandidacyData, handleZipLookup, GetCacheStatus
├── setup.go             # Provider init, AutoMigrate — BallotReady blank import lives here
├── models.go            # ElectionRecord model needs is_active column
├── routes.go            # Routes — /cache-status/{zip} may be removed
├── ballotready/         # Entire directory gets blank-import removed from setup.go (NOT deleted yet — Phase 29)
│   ├── provider.go      # init() registers ballotready in provider registry
│   ├── client.go        # FetchRacesByZip, FetchCandidacyData
│   └── transform_candidacy.go
└── provider/            # Config, types — may retain for cicero
```

### Pattern 1: DB-Only GetCandidatesByZip

**What:** Replace the live BallotReady race fetch with a SQL query joining `election_records` to `politicians` and `offices`.

**When to use:** The user toggles "Show Candidates" on the Results page; the frontend calls `/essentials/candidates/{zip}`.

**Current behavior (to remove):**
```go
// handlers.go:3581
brProvider, ok := Provider.(*ballotready.BallotReadyProvider)
if !ok {
    writeJSON(w, []CandidateOut{})
    return
}
races, err := brProvider.Client().FetchRacesByZip(r.Context(), zip)
```

**New behavior:**
Query `essentials.election_records` joined with `essentials.politicians`/`offices`/`districts` filtering `is_active = true` and `withdrawn = false`. Results are shaped into the existing `CandidateOut` struct.

The `CandidateOut` struct (line 3506) already has all the fields needed — `ExternalID`, `FullName`, `PhotoOriginURL`, `OfficeTitle`, `DistrictType`, `Party`, `PartyShortName`, `IsCandidate`, `ElectionDate`, `ElectionName`, `IsPrimary`, `IsRunoff`, `RepresentingState`, `ChamberName`.

**Key design question: how to relate candidates to a ZIP?**

`election_records` does not have a ZIP column. Options:
1. Join through `zip_politicians` (politician → zip_politicians → zip). This table is still present and populated for local officials. For federal/state candidates, there's no zip_politicians row. This means a ZIP filter would miss federal/state candidates.
2. Use `representing_state` from the `offices` table joined from the politician's current office, not their candidacy position. For ZIP → state mapping, use the `zip_state_map.go` static lookup or derive from the politician's office.
3. Return all active candidates with no ZIP filter, let the frontend classify/filter by tier. This is simpler and matches how the toggle currently works — the frontend already classifies by `district_type` using `classifyCategory()`.
4. Accept a query parameter `?state=XX` derived from the geocoded ZIP on the frontend side, and filter `election_records` where the joined district's state matches.

**Recommendation (Claude's discretion):** For the initial DB-only implementation, derive the state from the ZIP using `zipPrefixToState()` (already exists in `zip_state_map.go`) and filter candidates where the politician's `representing_state` (from `offices`) matches. For local candidates (district_type = LOCAL, COUNTY, etc.), use `zip_politicians` join. Return all tiers in one query, using UNION or a LEFT JOIN with a state match condition. This avoids frontend changes and matches the existing zip-based API contract.

**Simpler alternative (recommended):** Return all `is_active = true` candidates regardless of ZIP and let the frontend's existing `classifyCategory()` put them in the right tier. The frontend already filters federal candidates by user state (`federalFiltered` useMemo in `Results.jsx`). The candidate toggle only shows candidates within the current result set — same logic. Since there are no thousands of active candidates, the all-candidates approach is practical. The ZIP endpoint then becomes a simple "return all active candidates" endpoint, consistent with the existing empty behavior for address queries in `fetchCandidates()`.

### Pattern 2: Warmer Removal

**What:** Delete `warmFederal`, `warmState`, `warmLocal` (and `warmZip` legacy) and all their call sites.

**Call sites to remove (all in handlers.go):**

| Location | Context | Lines (approx) |
|----------|---------|----------------|
| `GetCacheStatus` | goroutines for all three warmers | 196–230 |
| `handleZipLookup` | goroutines for all three warmers | 267–323 |
| `SearchPoliticians` | goroutines for warmFederal and warmState | 2884–2912 |

After removing warmer call sites:
- `handleZipLookup` still reads from `federal_cache`, `state_caches`, `zip_caches` to determine freshness — all of this logic becomes dead code once cache tables are dropped. The entire `handleZipLookup` function can be simplified to just call `fetchOfficialsFromDB` and return.
- `GetCacheStatus` entire function becomes unnecessary once cache tables drop — can be removed and its route deleted.
- `getCacheStatus` (internal helper) also becomes unnecessary.
- Lock functions (`tryAcquireLock`, `releaseLock`, `isWarmingInProgress`, `tryAcquireZipWarmLock`, `releaseZipWarmLock`) become unused — remove.
- `waitForDataMin` becomes unused — remove.
- `CacheStatusResponse` struct becomes unused — remove.

### Pattern 3: Cache Table Migration

**What:** Drop `federal_cache`, `state_caches`, `zip_caches` tables AND remove their GORM models from `setup.go` AutoMigrate and from `models.go`.

**Migration approach:** Use `db.DB.Exec("DROP TABLE IF EXISTS essentials.federal_cache")` etc. inside a raw SQL migration block, NOT via AutoMigrate (which would try to re-create them). This is the same pattern used for `geofence_boundaries` (which is also manually managed).

**Important:** Remove from `setup.go` AutoMigrate list first, then run the DROP. Order:
1. Remove `&FederalCache{}`, `&StateCache{}`, `&ZipCache{}` from AutoMigrate slice in `setup.go`
2. Add `DROP TABLE IF EXISTS` statements in `Init()` after schema creation
3. Remove `FederalCache`, `StateCache`, `ZipCache` struct definitions and `TableName()` from `models.go`

**Warning — zip_caches used for state derivation:** `getCacheStatus` and `handleZipLookup` both read `zip_caches` to derive state from ZIP. Once the table is dropped, this read silently returns "not found" which is already handled by the `zipPrefixToState()` fallback. No functional regression — the static `zip_state_map.go` covers all ZIPs already.

**Warning — zip_politicians table stays:** `zip_politicians` is NOT a cache table — it's the mapping used by `fetchOfficialsFromDB` for local queries. Keep it. Only drop `federal_cache`, `state_caches`, `zip_caches`.

### Pattern 4: Provider Removal from setup.go

**What:** Remove the blank import of the `ballotready` package from `setup.go`, remove the `Provider` variable and its initialization block.

```go
// setup.go — REMOVE these lines:
import (
    _ "github.com/EmpoweredVote/EV-Backend/internal/essentials/ballotready"  // REMOVE
    _ "github.com/EmpoweredVote/EV-Backend/internal/essentials/cicero"       // keep if cicero still used
)

var Provider provider.OfficialProvider  // REMOVE

// In Init() — REMOVE the entire provider initialization block:
cfg := provider.LoadFromEnv()
var err error
Provider, err = provider.NewProvider(cfg)
if err != nil { ... }
```

**Impact on GeoClient:** `var GeoClient` and its initialization block are separate — keep. The geocoding client is still used in `SearchPoliticians` for address search.

**Compiler verification:** Removing the blank import means the `ballotready` package `init()` function no longer registers with the provider registry. The `provider` package itself can stay (used by `provider.LocalDistrictTypes` etc. in handlers). If nothing else references the `provider` package after removing warmers, check if those constants are still used in `fetchOfficialsFromDB`.

### Pattern 5: ensureCandidacyData Removal

**What:** Remove the `ensureCandidacyData` function and its single call site in `GetPoliticianByID`.

```go
// In GetPoliticianByID (line 3122) — REMOVE:
ensureCandidacyData(r.Context(), parsedID, r0.ExternalGlobalID, r0.ExternalID)
```

After removing the call site, remove the entire `ensureCandidacyData` function (lines 1239–1290).

Also remove `ExternalGlobalID` from the `row` struct in `GetPoliticianByID` (line 2972) and from the SQL query (line 3020) since it's no longer needed.

**Profile page behavior:** Endorsements, stances, and elections endpoints (`GetPoliticianEndorsements`, `GetPoliticianStances`, `GetPoliticianElections`) already read from DB only — they were never changed to lazy-fetch. They just return empty arrays if no data is cached. This is already correct behavior — no changes needed to these three handlers.

### Pattern 6: is_active Column Migration

**What:** Add `IsActive bool` to the `ElectionRecord` model in `models.go` and run AutoMigrate (or a manual ALTER TABLE).

```go
type ElectionRecord struct {
    // ... existing fields ...
    IsActive bool `json:"is_active" gorm:"default:false"` // NEW: manually set to true for current candidates
}
```

**AutoMigrate behavior:** GORM AutoMigrate adds columns but does not remove them. Adding `IsActive` to the model and re-running `db.DB.AutoMigrate(&ElectionRecord{})` will ALTER TABLE to add the column with `DEFAULT false`. All existing rows will be `false`, which is correct — no existing election records represent currently running candidates until manually set.

**Who sets is_active?** Not this phase — the admin import pipeline or manual SQL UPDATE. This phase only adds the column and filters on it.

### Anti-Patterns to Avoid

- **Stubbing warmers instead of deleting them:** The decision is a full clean break. No `log.Printf("warming disabled")` stubs.
- **Keeping the BallotReady blank import "just in case":** Remove it. Phase 29 audits for zero references.
- **Dropping zip_politicians:** Do NOT drop this table. It maps local politicians to ZIP codes and is used by `fetchOfficialsFromDB` for local tier queries.
- **Forgetting the `raceChamberName` and `levelToDistrictType` helpers:** These are used only by `GetCandidatesByZip`. When `GetCandidatesByZip` is rewritten to DB-only, these functions become unused. The new DB version derives `district_type` from the `districts` table directly, so delete these helpers.
- **Forgetting `SearchPoliticians` warmer calls:** There are two warmer goroutines inside `SearchPoliticians` (lines 2884–2912). These must be removed as part of warmer cleanup.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| State from ZIP lookup | Custom geocoding | `zipPrefixToState()` in zip_state_map.go | Already exists, static, no API |
| is_active filtering | Date comparison logic | Simple `is_active = true` boolean | Manual flag, no date math needed |
| Candidate district_type | levelToDistrictType() (currently ballotready-specific) | Direct from `districts.district_type` in DB join | DB already has correct types |

---

## Common Pitfalls

### Pitfall 1: Compiler errors from unused imports after removal

**What goes wrong:** After removing the `ballotready` blank import from `setup.go`, if any other file in the `essentials` package still directly imports `ballotready`, the build succeeds but the intent is wrong. More critically, removing the `Provider` variable may cause compile errors in `handlers.go` where `Provider` is referenced in warmer functions and `ensureCandidacyData`.

**Why it happens:** Go's strict unused import rules and the `Provider` variable usage are spread across handlers.go.

**How to avoid:** Remove warmer functions and `ensureCandidacyData` from `handlers.go` BEFORE removing the `Provider` variable from `setup.go`. Then the `ballotready` import references in the deleted functions are gone too. Check `handlers.go` imports — `ballotready` is imported at line 17; once `ensureCandidacyData`, `warmLocal`, `GetCandidatesByZip` are rewritten/removed, there should be no remaining direct reference to `ballotready` in `handlers.go`.

**Warning signs:** `go build` errors referencing `Provider` or `ballotready` undefined.

### Pitfall 2: Dropping cache tables before removing all reads

**What goes wrong:** If `federal_cache`, `state_caches`, or `zip_caches` are dropped while `handleZipLookup` or `getCacheStatus` still queries them, the queries return errors, not empty results. GORM `.First()` returns `gorm.ErrRecordNotFound` on empty, but a `relation does not exist` PostgreSQL error on a missing table.

**Why it happens:** The cache table reads are deeply embedded in `handleZipLookup` (lines 262–323) and `getCacheStatus` (lines 1990–2051).

**How to avoid:** Remove or simplify `handleZipLookup` and eliminate `GetCacheStatus`/`getCacheStatus` BEFORE running the DROP TABLE migration. Recommended order:
1. Simplify `handleZipLookup` to just call `fetchOfficialsFromDB` directly (no cache checks)
2. Remove `GetCacheStatus` handler and its route
3. Remove `getCacheStatus` internal function
4. Then run the DROP TABLE migration
5. Then remove the GORM models

### Pitfall 3: Frontend fetchCandidates silently returns [] for address queries

**What goes wrong:** `fetchCandidates()` in `api.jsx` (line 143) already special-cases non-ZIP queries — it returns `[]` immediately without calling the backend. The new DB-only backend only affects ZIP queries. But since Phase 26 moves users to address-based search, most users will never trigger the candidate endpoint.

**Why it happens:** The candidate toggle was built assuming ZIP as the primary input.

**How to avoid:** The DB-only backend still serves the ZIP path. For the toggle to work with address search, a future change would be needed in `fetchCandidates()` to pass the address to a new endpoint. But per CONTEXT.md, this is not in scope for Phase 27. Leave `fetchCandidates()` as-is — it still works for ZIP input.

**Impact:** The candidate toggle will silently show nothing for address-based searches after Phase 27. This is acceptable behavior for now — users who entered a ZIP will still see candidates; address users won't. Phase 28 could add a search-by-address candidate endpoint.

### Pitfall 4: getStatewideFromDB / fetchStatewideFromDB confusion

**What goes wrong:** Inside `SearchPoliticians` there are calls to both `fetchStatewideFromDB` and `fetchFederalAndStateFromDB`. After removing warmers from that function, the remaining DB reads need to stay.

**Why it happens:** The warmer goroutines in `SearchPoliticians` are embedded inside the geofence-match success branch (lines 2880–2912) but are surrounded by legitimate DB reads. Care is needed to remove only the goroutine blocks, not the surrounding state supplemental fetch.

**How to avoid:** In `SearchPoliticians`, remove only these goroutine blocks:
```go
// REMOVE only these blocks:
if err := db.DB.First(&federalCache).Error; err != nil || ... {
    if tryAcquireLock(...) {
        go func() { defer releaseLock(...); warmFederal(...) }()
    }
}
var stateCache StateCache
if err := db.DB.Where(...).First(&stateCache).Error; err != nil || ... {
    if tryAcquireLock(...) {
        go func() { defer releaseLock(...); warmState(...) }()
    }
}
```
Keep `fetchStatewideFromDB(geoState)` and everything around it — that's a DB read, not a warmer call.

### Pitfall 5: warmZip legacy function

**What goes wrong:** `warmZip` (line 1584) is a legacy Cicero-era function that calls `fetchAllCiceroOfficials`. It's referenced in comments as "kept for backwards compatibility" but its only live references are internal (no external callers). It should be deleted along with the warmers.

**How to avoid:** Check for any remaining callers of `warmZip` — there are none in the current routes or main.go. Delete it along with `warmFederal`, `warmState`, `warmLocal`.

---

## Code Examples

### New GetCandidatesByZip (DB-only)

```go
// GetCandidatesByZip returns active candidates from the election_records table.
// No live API call is made. Candidates are filtered by is_active = true and withdrawn = false.
// Results include candidates of all geographic tiers; frontend classify.js handles tier grouping.
func GetCandidatesByZip(w http.ResponseWriter, r *http.Request) {
    zip := chi.URLParam(r, "zip")
    if !isZip5(zip) {
        http.Error(w, "Missing or invalid zip parameter", http.StatusBadRequest)
        return
    }

    // Derive state from ZIP for state-level candidate filtering
    state := zipPrefixToState(zip)

    type candidateRow struct {
        PoliticianID    uuid.UUID
        FirstName       string
        LastName        string
        FullName        string
        PhotoOriginURL  string
        OfficeTitle     string
        DistrictType    string
        Party           string
        PartyShortName  string
        ElectionDate    string
        ElectionName    string
        IsPrimary       bool
        IsRunoff        bool
        RepresentingState string
        ChamberName     string
    }

    var rows []candidateRow
    // Join election_records → politicians → offices → districts → chambers
    // Filter: is_active=true, withdrawn=false
    // For local candidates: join zip_politicians for ZIP filtering
    // For state/federal: filter by representing_state matching derived state
    if err := db.DB.Raw(`
        SELECT
          p.id AS politician_id,
          p.first_name, p.last_name, p.full_name,
          COALESCE(p.photo_custom_url, NULLIF(p.photo_origin_url, '')) AS photo_origin_url,
          o.title AS office_title,
          d.district_type,
          COALESCE(p.party, '') AS party,
          COALESCE(p.party_short_name, '') AS party_short_name,
          er.election_date,
          er.election_name,
          er.is_primary,
          er.is_runoff,
          COALESCE(o.representing_state, '') AS representing_state,
          COALESCE(c.name, '') AS chamber_name
        FROM essentials.election_records er
        JOIN essentials.politicians p ON p.id = er.politician_id
        JOIN essentials.offices o ON o.politician_id = p.id
        JOIN essentials.districts d ON d.id = o.district_id
        JOIN essentials.chambers c ON c.id = o.chamber_id
        WHERE er.is_active = true
          AND er.withdrawn = false
          AND (
            -- Local: politician has a zip_politicians entry for this ZIP
            (d.district_type IN ('LOCAL_EXEC','LOCAL','COUNTY','SCHOOL','JUDICIAL')
             AND EXISTS (
               SELECT 1 FROM essentials.zip_politicians zp
               WHERE zp.politician_id = p.id AND zp.zip = ?
             ))
            OR
            -- State and federal: match by state
            (d.district_type IN ('STATE_EXEC','STATE_UPPER','STATE_LOWER','NATIONAL_EXEC','NATIONAL_UPPER','NATIONAL_LOWER')
             AND (o.representing_state = ? OR ? = ''))
          )
        ORDER BY er.election_date ASC
    `, zip, state, state).Scan(&rows).Error; err != nil {
        log.Printf("[GetCandidatesByZip] DB error: %v", err)
        writeJSON(w, []CandidateOut{})
        return
    }

    candidates := make([]CandidateOut, 0, len(rows))
    for _, row := range rows {
        candidates = append(candidates, CandidateOut{
            // ExternalID: not available from election_records directly — use 0 or add to query
            FirstName:         row.FirstName,
            LastName:          row.LastName,
            FullName:          row.FullName,
            PhotoOriginURL:    row.PhotoOriginURL,
            OfficeTitle:       row.OfficeTitle,
            DistrictType:      row.DistrictType,
            Party:             row.Party,
            PartyShortName:    row.PartyShortName,
            IsCandidate:       true,
            ElectionDate:      row.ElectionDate,
            ElectionName:      row.ElectionName,
            IsPrimary:         row.IsPrimary,
            IsRunoff:          row.IsRunoff,
            RepresentingState: row.RepresentingState,
            ChamberName:       row.ChamberName,
        })
    }

    writeJSON(w, candidates)
}
```

**Note on `ExternalID`:** `CandidateOut.ExternalID` is an `int` typed as the BallotReady integer ID. This was used by the frontend for keying (`id: \`candidate-${c.external_id}\``). In the DB version, use `p.external_id` from the politicians table. Add `p.external_id AS external_id` to the SQL query.

**Note on `id` field:** The frontend currently synthesizes IDs for candidates as `candidate-${c.external_id}` — this avoids UUID collisions with politicians. Since `CandidateOut` doesn't have a UUID field, the frontend generates it from `external_id`. This pattern continues to work with `p.external_id`.

### is_active Migration

```go
// In models.go — add to ElectionRecord:
type ElectionRecord struct {
    // ... existing fields ...
    IsActive bool `json:"is_active" gorm:"default:false"`
}

// AutoMigrate handles the column addition automatically.
// Existing rows get is_active = false (default).
// No data loss — additive column only.
```

### Simplified handleZipLookup (after removing cache checks)

After removing warmers and dropping cache tables, `handleZipLookup` simplifies to:

```go
func handleZipLookup(w http.ResponseWriter, r *http.Request, zip string) {
    state := zipPrefixToState(zip)
    officials, err := fetchOfficialsFromDB(zip, state)
    if err != nil {
        http.Error(w, "DB fetch error", http.StatusInternalServerError)
        return
    }
    w.Header().Set("X-Data-Status", "fresh")
    writeJSON(w, officials)
}
```

The `Retry-After`, `Cache-Control`, `X-Data-Status: stale`, `X-Data-Status: warming`, and `waitForDataMin` polling logic all become unnecessary since there are no background warmers.

---

## State of the Art

| Old Approach | New Approach | Phase | Impact |
|-------------|--------------|-------|--------|
| Live BallotReady API in GetCandidatesByZip | DB-only read from election_records + is_active flag | Phase 27 | Candidates are static; only appear if is_active=true |
| warmFederal/warmState/warmLocal goroutines | Deleted entirely | Phase 27 | No background work; data comes only from initial import |
| ensureCandidacyData lazy-fetch | Deleted; profile reads DB directly | Phase 27 | No goroutine on profile view |
| Provider.(*ballotready.BallotReadyProvider) type assertions | Deleted | Phase 27 | handlers.go no longer depends on ballotready package |
| federal_cache/state_caches/zip_caches tables | Dropped | Phase 27 | No staleness tracking; DB is source of truth |
| Progressive loading (202 warming responses) | Simplified to direct DB read | Phase 27 | No Retry-After, no warmers = instant responses |

---

## Open Questions

1. **CandidateOut.ExternalID source**
   - What we know: Currently populated from BallotReady's integer `DatabaseID` on the race candidacy. The frontend uses `candidate-${c.external_id}` as the React key.
   - What's unclear: In the DB version, `external_id` on `politicians` is the BallotReady integer ID. If a candidate is in `election_records` with a `politician_id`, we can join to `politicians.external_id`. Confirm this path is valid (a candidate in election_records always has a politicians row).
   - Recommendation: Add `p.external_id` to the new query. Based on how candidacy data is stored (Phase B upsert always creates/updates a politicians row), this should always be valid.

2. **handleZipLookup and /politicians/{zip} route fate**
   - What we know: Phase 28 removes ZIP as the search path. Until then, the ZIP endpoint is preserved.
   - What's unclear: After dropping cache tables, `handleZipLookup` no longer has freshness logic. Should the route return a 404 now, or keep serving DB-only results?
   - Recommendation: Keep the route but simplify `handleZipLookup` to DB-only (no cache check, no warmers, no progressive loading). Phase 28 can fully remove it.

3. **GetCacheStatus route fate**
   - What we know: `GET /cache-status/{zip}` is a frontend-visible endpoint. `api.jsx` exports `checkCacheStatus()` but it is NOT called anywhere in `Results.jsx` or `usePoliticianData.js` (confirmed by inspection). The hook uses `fetchPoliticiansOnce` + `searchPoliticians` only.
   - Conclusion: `/cache-status/{zip}` is dead from the frontend's perspective.
   - Recommendation: Remove `GetCacheStatus`, `getCacheStatus`, and the route entirely. No frontend impact.

4. **Cicero package and provider infrastructure**
   - What we know: The `cicero` package is still blank-imported in `setup.go`. The `provider` package is still used for type constants (`LocalDistrictTypes` etc.).
   - What's unclear: Does removing the BallotReady blank import implicitly require removing Cicero too?
   - Recommendation: Leave `_ "github.com/EmpoweredVote/EV-Backend/internal/essentials/cicero"` in place if there are legacy Cicero-era handlers still in use (like `upsertOfficial` via `warmZip` if warmZip is deleted — actually warmZip IS being deleted). After deleting all warmer functions including warmZip, check if `upsertOfficial` and `fetchCiceroOfficialsByTypes` are still called. If not, those can be deleted too, and the cicero blank import can be removed. Phase 29 handles the full grep audit.

5. **State blocking: fetchCandidates() returns [] for address queries in frontend**
   - Already noted in pitfalls. Accepting as-is per CONTEXT.md.

---

## Affected Files Inventory

Comprehensive list of all files requiring changes:

### Backend — EV-Backend/internal/essentials/

| File | Change Type | Description |
|------|-------------|-------------|
| `models.go` | Edit | Add `IsActive bool` to `ElectionRecord`. Remove `FederalCache`, `StateCache`, `ZipCache` structs and `TableName()` methods |
| `setup.go` | Edit | Remove `_ ballotready` blank import. Remove `var Provider` declaration. Remove `provider.LoadFromEnv()` + `provider.NewProvider()` block. Remove `&FederalCache{}`, `&StateCache{}`, `&ZipCache{}` from AutoMigrate. Add `DROP TABLE IF EXISTS` for the three cache tables. |
| `handlers.go` | Edit (large) | Delete `warmFederal`, `warmState`, `warmLocal`, `warmZip` functions. Remove all call sites (in `handleZipLookup`, `GetCacheStatus`, `SearchPoliticians`). Delete `ensureCandidacyData`. Rewrite `GetCandidatesByZip`. Simplify `handleZipLookup`. Remove/simplify `GetCacheStatus` and `getCacheStatus`. Remove `CacheStatusResponse` struct. Remove unused lock functions. Remove `raceChamberName` and `levelToDistrictType` helpers. |
| `routes.go` | Edit | Remove `r.Get("/cache-status/{zip}", GetCacheStatus)` if endpoint removed |

### Frontend — essentials/src/

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/api.jsx` | No change needed | `fetchCandidates()` still calls `/candidates/{zip}` — backend now reads DB |
| `pages/Results.jsx` | No change needed | Toggle, fetch, and classification logic unchanged |

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — warmer functions, GetCandidatesByZip, ensureCandidacyData, all call sites
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — provider init, AutoMigrate list
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — ElectionRecord, cache table models
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/routes.go` — registered routes
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/essentials/src/pages/Results.jsx` — candidate toggle implementation
- Direct codebase inspection of `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/api.jsx` — fetchCandidates function

### Secondary (MEDIUM confidence)
- GORM AutoMigrate behavior for additive columns (adding columns does not drop existing data; known pattern from prior phases in this codebase)
- PostgreSQL advisory lock behavior — `pg_try_advisory_lock` cleanup when functions are removed (locks are session-scoped; removing warmer code means no new locks acquired, existing sessions clean up naturally)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, existing patterns
- Architecture (warmer/provider removal): HIGH — all call sites located via grep
- Architecture (DB-only candidates): HIGH — ElectionRecord schema inspected, SQL pattern designed from existing fetchOfficialsFromDB
- Pitfalls: HIGH — each pitfall traced to specific code locations
- Open questions: MEDIUM — 5 minor ambiguities, all with clear recommendations

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (stable Go codebase; no external API changes relevant)
