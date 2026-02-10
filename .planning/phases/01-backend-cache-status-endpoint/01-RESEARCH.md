# Phase 1: Backend Cache Status Endpoint - Research

**Researched:** 2026-02-10
**Domain:** Go HTTP endpoint design, PostgreSQL indexed lookups, HTTP response headers
**Confidence:** HIGH

## Summary

This phase implements a fast cache-status endpoint that checks 3-tier cache freshness (federal/state/local) and warming status without expensive JOINs or politician data queries. The existing essentials module already has the foundation: indexed cache tables (FederalCache, StateCache, ZipCache), advisory locks for warming coordination, and Server-Timing/Retry-After header utilities.

The new endpoint will perform only simple primary key lookups against cache tables (under 100ms target) and check for active advisory locks to determine warming status. This follows the existing pattern in handleZipLookup but isolates status checks from data fetching.

**Primary recommendation:** Create a lightweight handler that queries the 3 cache tables, checks advisory lock status via pg_try_advisory_lock (non-blocking), and returns structured JSON with per-tier freshness booleans plus warming status. Use existing httputil helpers for Server-Timing and standard HTTP headers for Retry-After.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Go | 1.24.3 | Language runtime | Project standard, mature stdlib |
| Chi | v5 | HTTP router | Already in use, lightweight, standard net/http compatible |
| GORM | v2 | ORM for PostgreSQL | Already in use, handles migrations and queries |
| PostgreSQL | 14+ | Database | Project standard, advisory locks built-in |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| lib/pq | v1.10+ | PostgreSQL driver | Implicit via GORM, advisory lock support |

**Installation:**
No new dependencies required - all libraries already in EV-Backend.

## Architecture Patterns

### Recommended Handler Structure
Endpoint: `GET /essentials/cache-status/{zip}`

```
internal/essentials/
├── handlers.go         # Add handleCacheStatus function
├── routes.go          # Add route: r.Get("/cache-status/{zip}", GetCacheStatus)
├── models.go          # Uses existing FederalCache, StateCache, ZipCache
├── httputil.go        # Uses existing addServerTiming helper
└── setup.go           # No changes needed
```

### Pattern 1: Indexed Cache Lookup
**What:** Query cache tables by primary key (federal=1, state=code, zip=code)
**When to use:** Every cache status check - these tables have primary key indexes
**Example:**
```go
// Source: EV-Backend/internal/essentials/handlers.go lines 177-210
func checkFederalFreshness(ctx context.Context) (bool, error) {
    var federalCache FederalCache
    err := db.DB.WithContext(ctx).First(&federalCache).Error
    if err != nil {
        return false, err
    }
    maxAge := 90 * 24 * time.Hour
    return time.Since(federalCache.LastFetched) < maxAge, nil
}

func checkStateFreshness(ctx context.Context, state string) (bool, error) {
    var stateCache StateCache
    err := db.DB.WithContext(ctx).Where("state = ?", state).First(&stateCache).Error
    if err != nil {
        return false, err
    }
    maxAge := 90 * 24 * time.Hour
    return time.Since(stateCache.LastFetched) < maxAge, nil
}

func checkLocalFreshness(ctx context.Context, zip string) (bool, error) {
    var zipCache ZipCache
    err := db.DB.WithContext(ctx).Where("zip = ?", zip).First(&zipCache).Error
    if err != nil {
        return false, err
    }
    maxAge := 90 * 24 * time.Hour
    return time.Since(zipCache.LastFetched) < maxAge, nil
}
```

### Pattern 2: Non-Blocking Advisory Lock Check
**What:** Test if warming is in progress without acquiring lock
**When to use:** Determining warming status for response
**Example:**
```go
// Source: EV-Backend/internal/essentials/handlers.go lines 1848-1856
func isWarmingInProgress(ctx context.Context, key string) bool {
    var locked bool
    // Try to acquire - if false, someone else holds it (warming in progress)
    if err := db.DB.WithContext(ctx).
        Raw(`SELECT pg_try_advisory_lock(hashtext(?))`, key).
        Row().Scan(&locked); err != nil {
        return false // Assume not warming on error
    }

    if locked {
        // We acquired it - no one else was warming, release immediately
        var dummy bool
        _ = db.DB.WithContext(ctx).
            Raw(`SELECT pg_advisory_unlock(hashtext(?))`, key).
            Row().Scan(&dummy)
        return false
    }

    // Could not acquire - someone else holds the lock (warming)
    return true
}
```

### Pattern 3: Server-Timing Header
**What:** Add performance metrics to response headers
**When to use:** Every cache status response for observability
**Example:**
```go
// Source: EV-Backend/internal/essentials/httputil.go lines 8-22
func handleCacheStatus(w http.ResponseWriter, r *http.Request) {
    t0 := time.Now()

    // ... perform cache checks ...

    // Add Server-Timing with query duration
    queryMs := time.Since(t0).Milliseconds()
    addServerTiming(w, [2]string{"total", fmt.Sprintf("%d", queryMs)})

    writeJSON(w, response)
}
```

### Pattern 4: Retry-After Header
**What:** Signal client when to retry during warming
**When to use:** When warming=true in response
**Example:**
```go
// Source: EV-Backend/internal/essentials/handlers.go line 286
if warming {
    w.Header().Set("Retry-After", "3") // Retry in 3 seconds
}
```

### Anti-Patterns to Avoid

- **Don't JOIN cache tables with politicians table** - Status check should only touch cache tables, not politician data. This is a common mistake when "completing" the picture.

- **Don't block on advisory locks** - Use pg_try_advisory_lock not pg_advisory_lock. Blocking defeats the sub-100ms latency requirement.

- **Don't create new warming coordination** - Reuse existing tryAcquireLock/releaseLock functions and lock key patterns ("federal", "state-{code}", "zip-{code}").

- **Don't compute allFresh in database** - Perform 3 separate indexed queries and compute in application code. Database has no concept of "all fresh" logic.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Server-Timing header formatting | Manual string concat | addServerTiming(w, [2]string{name, dur}) | Already implemented in httputil.go, handles W3C format correctly |
| Advisory lock coordination | Custom locking mechanism | tryAcquireLock/releaseLock from handlers.go | Already implements session-level locks with hashtext for key generation |
| Cache freshness calculation | Repeated time.Since logic | Extract maxAge constant to package level | DRY principle - currently duplicated in handleZipLookup |
| ZIP to state mapping | API call or external lookup | zipPrefixToState(zip) | Already implemented, instant static lookup |

**Key insight:** The essentials module already has all coordination primitives. The cache status endpoint is primarily a **composition** of existing patterns, not new infrastructure.

## Common Pitfalls

### Pitfall 1: Using Transaction-Level Advisory Locks
**What goes wrong:** Lock is released when context/transaction ends, not when function returns
**Why it happens:** PostgreSQL has two advisory lock types - session-level and transaction-level. GORM WithContext may create transaction scope.
**How to avoid:** Use session-level locks (pg_try_advisory_lock) and explicitly call pg_advisory_unlock. Existing code follows this pattern.
**Warning signs:** Locks not visible across requests, "warming" status always false despite background goroutines running.

### Pitfall 2: Advisory Lock Acquisition Creates Lock
**What goes wrong:** "Checking" if warming is in progress by trying to acquire the lock means you now own it, blocking actual warmers
**Why it happens:** pg_try_advisory_lock returns true and ACQUIRES the lock when available
**How to avoid:** If pg_try_advisory_lock returns true, IMMEDIATELY release with pg_advisory_unlock before returning false (not warming). Pattern shown above.
**Warning signs:** Background warmers stop running after first cache-status check, multiple warming processes start simultaneously.

### Pitfall 3: Missing State Derivation
**What goes wrong:** State cache check fails because state is unknown for ZIP
**Why it happens:** New ZIPs won't have state populated in zip_caches table yet
**How to avoid:** Use zipPrefixToState(zip) as fallback when zip_caches.state is empty (existing pattern in handleZipLookup line 202)
**Warning signs:** stateFresh always false for new ZIPs, warm cycles triggered unnecessarily.

### Pitfall 4: Incorrect CORS Header Exposure
**What goes wrong:** Frontend can't read Retry-After or Server-Timing headers
**Why it happens:** Headers must be explicitly exposed in CORS middleware
**How to avoid:** Verify Access-Control-Expose-Headers includes "Server-Timing, Retry-After" (already configured in middleware.go line 88)
**Warning signs:** Headers visible in Network tab but undefined in JavaScript fetch response.

### Pitfall 5: Cache-Control on Fast Responses
**What goes wrong:** CDN caches 5-second-old "warming" responses, defeating polling
**Why it happens:** Default cache headers may apply
**How to avoid:** Set Cache-Control: no-store on ALL cache-status responses - status changes frequently
**Warning signs:** Frontend polls but receives stale "warming" status, never sees "fresh" even after warmers complete.

## Code Examples

Verified patterns from existing codebase:

### Cache Freshness Check (All Tiers)
```go
// Source: EV-Backend/internal/essentials/handlers.go lines 165-237
func getCacheStatus(ctx context.Context, zip string) (CacheStatusResponse, error) {
    const maxAge = 90 * 24 * time.Hour
    now := time.Now()

    // Federal cache - single row, ID=1
    var federalCache FederalCache
    federalErr := db.DB.WithContext(ctx).First(&federalCache).Error
    federalFresh := federalErr == nil && now.Sub(federalCache.LastFetched) < maxAge

    // Derive state from ZIP
    var zipCache ZipCache
    zipCacheErr := db.DB.WithContext(ctx).Where("zip = ?", zip).First(&zipCache).Error

    var state string
    if zipCacheErr == nil && zipCache.State != "" {
        state = zipCache.State
    } else {
        state = zipPrefixToState(zip) // Fallback to static lookup
    }

    // State cache - keyed by 2-letter code
    var stateFresh bool
    if state != "" {
        var stateCache StateCache
        stateErr := db.DB.WithContext(ctx).Where("state = ?", state).First(&stateCache).Error
        stateFresh = stateErr == nil && now.Sub(stateCache.LastFetched) < maxAge
    }

    // Local/ZIP cache - keyed by ZIP code
    localFresh := zipCacheErr == nil && now.Sub(zipCache.LastFetched) < maxAge

    allFresh := federalFresh && (state == "" || stateFresh) && localFresh

    // Check warming status
    warming := isWarmingInProgress(ctx, "federal") ||
               isWarmingInProgress(ctx, "state-"+state) ||
               isWarmingInProgress(ctx, "zip-"+zip)

    return CacheStatusResponse{
        FederalFresh: federalFresh,
        StateFresh:   stateFresh,
        LocalFresh:   localFresh,
        AllFresh:     allFresh,
        Warming:      warming,
    }, nil
}
```

### Response Structure
```go
type CacheStatusResponse struct {
    FederalFresh bool `json:"federalFresh"`
    StateFresh   bool `json:"stateFresh"`
    LocalFresh   bool `json:"localFresh"`
    AllFresh     bool `json:"allFresh"`
    Warming      bool `json:"warming"`
}
```

### Complete Handler
```go
func GetCacheStatus(w http.ResponseWriter, r *http.Request) {
    zip := chi.URLParam(r, "zip")
    if !isZip5(zip) {
        http.Error(w, "Invalid zip parameter", http.StatusBadRequest)
        return
    }

    t0 := time.Now()
    ctx := r.Context()

    status, err := getCacheStatus(ctx, zip)
    if err != nil {
        log.Printf("[GetCacheStatus] error: %v", err)
        http.Error(w, "Internal server error", http.StatusInternalServerError)
        return
    }

    // Add timing header
    queryMs := time.Since(t0).Milliseconds()
    addServerTiming(w, [2]string{"total", fmt.Sprintf("%d", queryMs)})

    // Add Retry-After if warming
    if status.Warming {
        w.Header().Set("Retry-After", "3")
    }

    // Always no-store for status endpoint
    w.Header().Set("Cache-Control", "no-store, no-cache, must-revalidate")

    writeJSON(w, status)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polling /politicians/{zip} repeatedly | Dedicated /cache-status/{zip} endpoint | Phase 1 (this phase) | Reduces load - status checks don't trigger JOINs or politician serialization |
| X-Data-Status header only | Structured JSON with per-tier flags | Phase 1 (this phase) | Frontend can make smarter decisions (e.g., show "federal data ready" even if local still warming) |
| Client guesses retry timing | Server sends Retry-After header | Already implemented | Standards-compliant backoff signaling |
| Advisory locks session-level | (No change) | N/A | Session-level locks survive transaction boundaries - correct for background goroutines |

**Deprecated/outdated:**
- None - this is a new endpoint, not a replacement

## Open Questions

1. **Should cache-status trigger warmers if caches are stale?**
   - What we know: handleZipLookup triggers warmers on stale cache, cache-status endpoint is meant to be read-only
   - What's unclear: Whether read-only status check should be strictly idempotent or allowed to have side effects
   - Recommendation: **Do NOT trigger warmers** from cache-status endpoint. Frontend should call /politicians/{zip} if it wants to kick warming. Keep status check pure read-only for predictability.

2. **What retry timing should Retry-After recommend?**
   - What we know: Current code uses "3" seconds, warmers typically complete in 2-8 seconds for local, faster for federal/state
   - What's unclear: Whether 3 seconds is optimal for user experience vs server load
   - Recommendation: **Keep 3 seconds** initially (matches existing pattern), make it configurable in future if needed. Too fast = excessive polling, too slow = poor UX.

3. **Should state/local freshness be nullable when unknown?**
   - What we know: Federal always queryable (single row), state derivable from ZIP via zipPrefixToState, local always queryable by ZIP
   - What's unclear: Edge cases where state cannot be derived
   - Recommendation: **Use booleans, false = not fresh/unknown**. Simplifies frontend logic. If zipPrefixToState returns empty string, stateFresh=false is correct (no state cache to check).

## Sources

### Primary (HIGH confidence)
- EV-Backend/internal/essentials/handlers.go - Lines 162-289 (handleZipLookup cache check pattern), lines 1848-1863 (advisory lock functions)
- EV-Backend/internal/essentials/models.go - Lines 150-171 (cache table definitions)
- EV-Backend/internal/essentials/httputil.go - Lines 8-22 (Server-Timing helper)
- EV-Backend/internal/essentials/routes.go - Routing pattern reference
- EV-Backend/internal/middleware/middleware.go - Line 88 (CORS header exposure)

### Secondary (MEDIUM confidence)
- [Chi Router Documentation](https://pkg.go.dev/github.com/go-chi/chi) - HTTP handler patterns
- [GORM Indexes Documentation](https://gorm.io/docs/indexes.html) - Primary key indexing
- [GORM Query Documentation](https://gorm.io/docs/query.html) - First() method for primary key lookups
- [Server-Timing W3C Specification](https://www.w3.org/TR/server-timing/) - Header format and syntax
- [Server-Timing MDN Reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Server-Timing) - Browser support and examples
- [Retry-After MDN Reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Retry-After) - Header format specification
- [PostgreSQL Advisory Locks Documentation](https://www.postgresql.org/docs/current/explicit-locking.html) - Session vs transaction-level locks
- [Advisory Locks in PostgreSQL (Medium)](https://medium.com/thefreshwrites/advisory-locks-in-postgres-1f993647d061) - Practical usage patterns
- [go-server-timing Package](https://pkg.go.dev/github.com/mitchellh/go-server-timing) - Go implementation reference

### Tertiary (LOW confidence)
- [REST API Caching Best Practices (Speakeasy)](https://www.speakeasy.com/api-design/caching) - General patterns, not Go-specific
- [JSON Boolean Design Considerations](https://apidog.com/blog/json-boolean-understanding-and-implementing-boolean-values-in-json/) - API response structure guidance
- [Go High Performance API Design](https://idatamax.com/blog/high-load-api-services-in-go) - Sub-100ms latency strategies

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in use, versions confirmed from codebase
- Architecture: HIGH - Patterns extracted directly from existing handlers.go implementation
- Pitfalls: HIGH - Based on PostgreSQL advisory lock behavior and existing GORM patterns
- Performance: MEDIUM - 100ms target based on indexed lookups (PRIMARY KEY on cache tables), not benchmarked yet

**Research date:** 2026-02-10
**Valid until:** 2026-03-12 (30 days - stable Go/PostgreSQL patterns)
