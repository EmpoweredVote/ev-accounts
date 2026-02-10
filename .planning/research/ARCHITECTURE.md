# Architecture Patterns: Cache Status Polling Optimization

**Domain:** Political data API with progressive loading
**Researched:** 2026-02-09
**Confidence:** HIGH

## Executive Summary

This architecture focuses on adding a lightweight cache-status endpoint to the existing EV-Backend essentials module and abstracting frontend polling to support future SSE migration. The design maintains the existing module pattern (handlers/routes/models) while introducing minimal new components.

**Key decisions:**
1. **Backend:** New lightweight handler in existing handlers.go, single-query cache status check
2. **Frontend:** React hook abstraction with strategy pattern for poll-to-SSE migration path
3. **Data flow:** Status check → conditional full fetch → progressive rendering

## Recommended Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Frontend (React)                                            │
│                                                             │
│  ┌──────────────────────┐                                  │
│  │ Dashboard/Results/   │                                  │
│  │ Home components      │                                  │
│  └──────────┬───────────┘                                  │
│             │                                               │
│             v                                               │
│  ┌──────────────────────┐    ┌─────────────────────────┐  │
│  │ usePoliticianData()  │───>│ PollingStrategy         │  │
│  │ (custom hook)        │    │ (poll vs SSE)           │  │
│  └──────────┬───────────┘    └─────────────┬───────────┘  │
│             │                               │               │
│             │ 1. Check cache status         │               │
│             v                               v               │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ API Client (api.jsx)                                │  │
│  │ - checkCacheStatus()                                │  │
│  │ - fetchPoliticiansOnce()                            │  │
│  └──────────┬──────────────────────────────────────────┘  │
└─────────────┼──────────────────────────────────────────────┘
              │
              v HTTP/HTTPS
┌─────────────┼──────────────────────────────────────────────┐
│ Backend (Go/Chi)                                           │
│             │                                               │
│  ┌──────────v──────────────────────────────────────────┐  │
│  │ Router (routes.go)                                   │  │
│  │ GET /essentials/cache-status/{type}/{identifier}    │  │
│  │ GET /essentials/politicians/{zip}                    │  │
│  │ POST /essentials/politicians/search                  │  │
│  └──────────┬──────────────────────────────────────────┘  │
│             │                                               │
│             v                                               │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ Handlers (handlers.go)                               │ │
│  │                                                       │ │
│  │ CacheStatusHandler(w, r)                             │ │
│  │  - Parse type + identifier                           │ │
│  │  - Single query to appropriate cache table           │ │
│  │  - Return {fresh: bool, lastFetch: time, ttl: int}   │ │
│  │                                                       │ │
│  │ GetPoliticiansByZIPHandler(w, r)                     │ │
│  │  - Check cache freshness                             │ │
│  │  - Return cached + kick background warmers           │ │
│  └──────────┬───────────────────────────────────────────┘ │
│             │                                               │
│             v                                               │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ Database (PostgreSQL via GORM)                       │ │
│  │                                                       │ │
│  │ essentials.federal_cache (single row)                │ │
│  │ essentials.state_caches (keyed by state)             │ │
│  │ essentials.zip_caches (keyed by ZIP)                 │ │
│  │ essentials.politicians                               │ │
│  │ essentials.zip_politicians                           │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Component Boundaries

### Backend Components

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **CacheStatusHandler** | Parse type/ID, query single cache table, return freshness status | Database (cache tables only) |
| **GetPoliticiansByZIPHandler** | Return cached politicians, trigger background warmers if stale | Database (all essentials tables), BallotReady provider |
| **Router (routes.go)** | Map HTTP paths to handlers | All handlers |
| **Cache Models** | FederalCache, StateCache, ZipCache GORM models | Database |
| **Background Warmers** | Goroutines that call BallotReady API and upsert data | BallotReady provider, Database |

### Frontend Components

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **usePoliticianData** | Custom hook providing {politicians, loading, error} state | PollingStrategy, API Client |
| **PollingStrategy** | Encapsulates poll vs SSE logic, exposes uniform interface | API Client |
| **API Client (api.jsx)** | HTTP requests to backend | Backend handlers |
| **Dashboard/Results/Home** | UI components consuming politician data | usePoliticianData hook |

## Data Flow

### Current Flow (Progressive Loading)

```
User enters ZIP
    │
    v
Dashboard calls fetchPoliticiansProgressive(zip, {maxAttempts: 8, intervalMs: 1500})
    │
    v
Loop (up to 8 times):
    │
    ├─> API: GET /essentials/politicians/{zip}
    │       │
    │       v
    │   Backend: Check cache freshness
    │       │
    │       ├─> Fresh? Return cached politicians
    │       │       │
    │       │       v
    │       │   Frontend: Update state, continue polling
    │       │
    │       └─> Stale? Kick background warmers + return partial
    │               │
    │               v
    │           Frontend: Update state, continue polling
    │
    └─> Wait 1500ms, repeat
```

**Problem:** 8 full queries to `/politicians/{zip}` even when cache is fresh on first attempt. Each query returns full politician dataset (~1-50 politicians with images/degrees/experiences).

### Proposed Flow (Status Check → Conditional Fetch)

```
User enters ZIP
    │
    v
Dashboard calls usePoliticianData(zip, 'zip')
    │
    v
PollingStrategy.start()
    │
    v
Loop (up to 8 times):
    │
    ├─> API: GET /essentials/cache-status/zip/{zip}
    │       │
    │       v
    │   Backend: Single query to essentials.zip_caches WHERE zip_code = $1
    │       │
    │       v
    │   Return: {fresh: true/false, lastFetch: "2026-02-09T10:00:00Z", ttl: 90}
    │       │
    │       v
    │   Frontend: Check if fresh
    │       │
    │       ├─> Fresh? Call fetchPoliticiansOnce(zip) → Update state → STOP polling
    │       │       │
    │       │       v
    │       │   API: GET /essentials/politicians/{zip}
    │       │       │
    │       │       v
    │       │   Return full politician dataset
    │       │
    │       └─> Stale? Wait 1500ms, continue loop
    │
    └─> Wait 1500ms, repeat
```

**Benefit:** Status endpoint returns ~200 bytes JSON vs ~50KB+ politician dataset. Full fetch only happens once when cache is fresh.

### Future Flow (SSE Push)

```
User enters ZIP
    │
    v
Dashboard calls usePoliticianData(zip, 'zip')
    │
    v
PollingStrategy detects SSE support
    │
    v
SSEStrategy.start()
    │
    ├─> API: GET /essentials/cache-status/zip/{zip}/stream (SSE endpoint)
    │       │
    │       v
    │   Backend: Open SSE connection, emit initial status
    │       │
    │       ├─> Fresh? Emit {event: "cache-ready"}
    │       │       │
    │       │       v
    │       │   Frontend: Call fetchPoliticiansOnce(zip) → Close SSE
    │       │
    │       └─> Stale? Emit {event: "cache-warming"}
    │               │
    │               v
    │           Background warmer completes
    │               │
    │               v
    │           Emit {event: "cache-ready"}
    │               │
    │               v
    │           Frontend: Call fetchPoliticiansOnce(zip) → Close SSE
    │
    └─> Connection closed
```

**Benefit:** No polling loop, immediate notification when cache is ready.

## Patterns to Follow

### Pattern 1: Lightweight Cache Status Handler

**What:** Dedicated handler that queries only cache tables, returns minimal JSON.

**When:** Frontend needs to check if cached data is ready without fetching full dataset.

**Backend Implementation:**

```go
// In internal/essentials/handlers.go (add to existing file)

type CacheStatusResponse struct {
    Fresh      bool      `json:"fresh"`
    LastFetch  time.Time `json:"last_fetch"`
    TTLDays    int       `json:"ttl_days"`
    Identifier string    `json:"identifier"` // zip/state/federal
}

func CacheStatusHandler(w http.ResponseWriter, r *http.Request) {
    cacheType := chi.URLParam(r, "type")       // "zip", "state", "federal"
    identifier := chi.URLParam(r, "identifier") // "12345", "IN", "federal"

    var status CacheStatusResponse
    status.Identifier = identifier
    status.TTLDays = 90

    now := time.Now()
    staleThreshold := now.Add(-90 * 24 * time.Hour)

    switch cacheType {
    case "zip":
        var cache ZipCache
        err := db.DB.Where("zip_code = ?", identifier).First(&cache).Error
        if err != nil {
            // Cache doesn't exist yet
            status.Fresh = false
            status.LastFetch = time.Time{} // zero value
        } else {
            status.Fresh = cache.LastFetched.After(staleThreshold)
            status.LastFetch = cache.LastFetched
        }

    case "state":
        var cache StateCache
        err := db.DB.Where("state_code = ?", strings.ToUpper(identifier)).First(&cache).Error
        if err != nil {
            status.Fresh = false
            status.LastFetch = time.Time{}
        } else {
            status.Fresh = cache.LastFetched.After(staleThreshold)
            status.LastFetch = cache.LastFetched
        }

    case "federal":
        var cache FederalCache
        err := db.DB.First(&cache).Error
        if err != nil {
            status.Fresh = false
            status.LastFetch = time.Time{}
        } else {
            status.Fresh = cache.LastFetched.After(staleThreshold)
            status.LastFetch = cache.LastFetched
        }

    default:
        http.Error(w, "Invalid cache type", http.StatusBadRequest)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(status)
}
```

**Route Registration (routes.go):**

```go
// In internal/essentials/routes.go (add to SetupRoutes function)

func SetupRoutes() http.Handler {
    r := chi.NewRouter()

    // Existing routes...
    r.Get("/politicians/{zip}", GetPoliticiansByZIPHandler)
    r.Post("/politicians/search", SearchPoliticiansByAddressHandler)

    // New cache status endpoint
    r.Get("/cache-status/{type}/{identifier}", CacheStatusHandler)

    return r
}
```

**Why this approach:**
- Single query per check (fast, minimal DB load)
- Reuses existing cache table logic (FederalCache, StateCache, ZipCache)
- No coupling to BallotReady provider (read-only cache tables)
- Returns minimal JSON (~200 bytes vs 50KB+ politician data)

### Pattern 2: React Hook Abstraction with Strategy Pattern

**What:** Custom hook that encapsulates polling logic and provides uniform interface for poll → SSE migration.

**When:** Multiple components need politician data with progressive loading (Dashboard, Results, Home).

**Frontend Implementation:**

```javascript
// essentials/src/hooks/usePoliticianData.js

import { useState, useEffect, useRef } from 'react';
import { checkCacheStatus, fetchPoliticiansOnce } from '../lib/api';

/**
 * Hook for fetching politicians with progressive loading.
 *
 * @param {string} identifier - ZIP code, state code, or "federal"
 * @param {string} type - "zip", "state", or "federal"
 * @param {object} options - Configuration
 * @param {number} options.maxAttempts - Max status checks before giving up (default: 8)
 * @param {number} options.intervalMs - Milliseconds between status checks (default: 1500)
 * @param {boolean} options.autoStart - Start polling on mount (default: true)
 * @returns {{politicians: array, loading: boolean, error: string|null, refetch: function}}
 */
export function usePoliticianData(identifier, type = 'zip', options = {}) {
    const {
        maxAttempts = 8,
        intervalMs = 1500,
        autoStart = true
    } = options;

    const [politicians, setPoliticians] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const attemptCountRef = useRef(0);
    const timeoutIdRef = useRef(null);
    const abortedRef = useRef(false);

    const cleanup = () => {
        if (timeoutIdRef.current) {
            clearTimeout(timeoutIdRef.current);
            timeoutIdRef.current = null;
        }
        abortedRef.current = true;
    };

    const fetchData = async () => {
        try {
            setLoading(true);
            setError(null);
            abortedRef.current = false;
            attemptCountRef.current = 0;

            const pollCacheStatus = async () => {
                if (abortedRef.current) return;

                attemptCountRef.current += 1;

                try {
                    // Step 1: Check cache status (lightweight)
                    const status = await checkCacheStatus(type, identifier);

                    if (status.fresh) {
                        // Step 2: Cache is ready, fetch full data
                        const data = await fetchPoliticiansOnce(identifier, type);
                        if (!abortedRef.current) {
                            setPoliticians(data);
                            setLoading(false);
                        }
                        return; // Stop polling
                    }

                    // Cache is still warming
                    if (attemptCountRef.current >= maxAttempts) {
                        // Give up after max attempts
                        if (!abortedRef.current) {
                            setError('Cache is taking longer than expected. Please try again.');
                            setLoading(false);
                        }
                        return;
                    }

                    // Schedule next check
                    timeoutIdRef.current = setTimeout(pollCacheStatus, intervalMs);

                } catch (err) {
                    if (!abortedRef.current) {
                        setError(err.message || 'Failed to check cache status');
                        setLoading(false);
                    }
                }
            };

            pollCacheStatus();

        } catch (err) {
            if (!abortedRef.current) {
                setError(err.message || 'Failed to fetch politicians');
                setLoading(false);
            }
        }
    };

    useEffect(() => {
        if (autoStart && identifier) {
            fetchData();
        }

        return cleanup;
    }, [identifier, type]);

    return {
        politicians,
        loading,
        error,
        refetch: fetchData
    };
}
```

**API Client Updates (api.jsx):**

```javascript
// essentials/src/lib/api.jsx

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://api.empowered.vote';

/**
 * Check cache status without fetching full dataset.
 *
 * @param {string} type - "zip", "state", or "federal"
 * @param {string} identifier - ZIP code, state code, or "federal"
 * @returns {Promise<{fresh: boolean, lastFetch: string, ttlDays: number}>}
 */
export async function checkCacheStatus(type, identifier) {
    const response = await fetch(
        `${API_BASE_URL}/essentials/cache-status/${type}/${identifier}`,
        { credentials: 'include' }
    );

    if (!response.ok) {
        throw new Error(`Cache status check failed: ${response.statusText}`);
    }

    return response.json();
}

/**
 * Fetch politicians once (no polling).
 *
 * @param {string} identifier - ZIP code or address
 * @param {string} type - "zip" or "address"
 * @returns {Promise<array>}
 */
export async function fetchPoliticiansOnce(identifier, type = 'zip') {
    if (type === 'address') {
        const response = await fetch(
            `${API_BASE_URL}/essentials/politicians/search`,
            {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'include',
                body: JSON.stringify({ address: identifier })
            }
        );

        if (!response.ok) {
            throw new Error(`Search failed: ${response.statusText}`);
        }

        return response.json();
    }

    // ZIP code
    const response = await fetch(
        `${API_BASE_URL}/essentials/politicians/${identifier}`,
        { credentials: 'include' }
    );

    if (!response.ok) {
        throw new Error(`Fetch failed: ${response.statusText}`);
    }

    return response.json();
}

/**
 * DEPRECATED: Use usePoliticianData hook instead.
 * Legacy progressive loading function.
 */
export async function fetchPoliticiansProgressive(zip, options = {}) {
    console.warn('fetchPoliticiansProgressive is deprecated. Use usePoliticianData hook.');
    // ... existing implementation for backward compatibility
}
```

**Component Migration Example (Dashboard.jsx):**

```javascript
// Before:
import { fetchPoliticiansProgressive } from '../lib/api';

function Dashboard() {
    const [politicians, setPoliticians] = useState([]);
    const [loading, setLoading] = useState(false);

    const handleSearch = async (zip) => {
        setLoading(true);
        const data = await fetchPoliticiansProgressive(zip, {
            maxAttempts: 8,
            intervalMs: 1500
        });
        setPoliticians(data);
        setLoading(false);
    };

    // ... rest of component
}

// After:
import { usePoliticianData } from '../hooks/usePoliticianData';

function Dashboard() {
    const [currentZip, setCurrentZip] = useState('');
    const { politicians, loading, error } = usePoliticianData(currentZip, 'zip', {
        maxAttempts: 8,
        intervalMs: 1500,
        autoStart: false // Wait for user input
    });

    const handleSearch = (zip) => {
        setCurrentZip(zip); // Triggers hook to fetch
    };

    // ... rest of component
}
```

**Why this approach:**
- Single source of truth for polling logic (DRY)
- Familiar React hooks API (useState, useEffect patterns)
- Easy migration for existing components (minimal changes)
- Future SSE support via strategy swap (hook internals change, API stays same)

### Pattern 3: Strategy Pattern for Poll → SSE Migration

**What:** Encapsulate polling/SSE logic in interchangeable strategies with uniform interface.

**When:** Preparing for SSE migration without breaking existing functionality.

**Implementation:**

```javascript
// essentials/src/strategies/DataFetchStrategy.js

/**
 * Base interface for data fetching strategies.
 */
export class DataFetchStrategy {
    /**
     * @param {object} config
     * @param {string} config.identifier - ZIP/state/federal
     * @param {string} config.type - "zip"/"state"/"federal"
     * @param {function} config.onData - Callback when data arrives
     * @param {function} config.onError - Callback on error
     */
    constructor(config) {
        this.config = config;
    }

    /** Start fetching data */
    start() {
        throw new Error('Must implement start()');
    }

    /** Stop fetching data */
    stop() {
        throw new Error('Must implement stop()');
    }
}

/**
 * Polling strategy (current implementation).
 */
export class PollingStrategy extends DataFetchStrategy {
    constructor(config) {
        super(config);
        this.attemptCount = 0;
        this.maxAttempts = config.maxAttempts || 8;
        this.intervalMs = config.intervalMs || 1500;
        this.timeoutId = null;
        this.aborted = false;
    }

    async start() {
        this.aborted = false;
        this.attemptCount = 0;
        await this.poll();
    }

    stop() {
        this.aborted = true;
        if (this.timeoutId) {
            clearTimeout(this.timeoutId);
            this.timeoutId = null;
        }
    }

    async poll() {
        if (this.aborted) return;

        this.attemptCount += 1;

        try {
            const status = await checkCacheStatus(this.config.type, this.config.identifier);

            if (status.fresh) {
                const data = await fetchPoliticiansOnce(this.config.identifier, this.config.type);
                if (!this.aborted) {
                    this.config.onData(data);
                }
                return;
            }

            if (this.attemptCount >= this.maxAttempts) {
                this.config.onError(new Error('Cache warming timeout'));
                return;
            }

            this.timeoutId = setTimeout(() => this.poll(), this.intervalMs);

        } catch (err) {
            if (!this.aborted) {
                this.config.onError(err);
            }
        }
    }
}

/**
 * SSE strategy (future implementation).
 */
export class SSEStrategy extends DataFetchStrategy {
    constructor(config) {
        super(config);
        this.eventSource = null;
    }

    start() {
        const { type, identifier } = this.config;
        const url = `${API_BASE_URL}/essentials/cache-status/${type}/${identifier}/stream`;

        this.eventSource = new EventSource(url, { withCredentials: true });

        this.eventSource.addEventListener('cache-ready', async () => {
            try {
                const data = await fetchPoliticiansOnce(identifier, type);
                this.config.onData(data);
                this.stop();
            } catch (err) {
                this.config.onError(err);
            }
        });

        this.eventSource.addEventListener('error', (err) => {
            this.config.onError(err);
            this.stop();
        });
    }

    stop() {
        if (this.eventSource) {
            this.eventSource.close();
            this.eventSource = null;
        }
    }
}

/**
 * Factory to select strategy based on feature flags.
 */
export function createFetchStrategy(config) {
    // Feature flag: check if SSE is enabled
    const useSSE = import.meta.env.VITE_FEATURE_SSE === 'true';

    if (useSSE && typeof EventSource !== 'undefined') {
        return new SSEStrategy(config);
    }

    return new PollingStrategy(config);
}
```

**Updated Hook with Strategy:**

```javascript
// essentials/src/hooks/usePoliticianData.js

import { useState, useEffect, useRef } from 'react';
import { createFetchStrategy } from '../strategies/DataFetchStrategy';

export function usePoliticianData(identifier, type = 'zip', options = {}) {
    const [politicians, setPoliticians] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const strategyRef = useRef(null);

    useEffect(() => {
        if (!identifier || !options.autoStart) return;

        setLoading(true);
        setError(null);

        strategyRef.current = createFetchStrategy({
            identifier,
            type,
            maxAttempts: options.maxAttempts || 8,
            intervalMs: options.intervalMs || 1500,
            onData: (data) => {
                setPoliticians(data);
                setLoading(false);
            },
            onError: (err) => {
                setError(err.message);
                setLoading(false);
            }
        });

        strategyRef.current.start();

        return () => {
            if (strategyRef.current) {
                strategyRef.current.stop();
            }
        };
    }, [identifier, type]);

    return { politicians, loading, error };
}
```

**Why this approach:**
- Swap poll → SSE via environment variable (VITE_FEATURE_SSE=true)
- No changes to components (hook API stays the same)
- Easy to test each strategy in isolation
- Clear migration path (enable SSE per environment, not per component)

## Anti-Patterns to Avoid

### Anti-Pattern 1: Inline Cache Freshness Logic in Existing Handlers

**What:** Adding cache status checks directly to GetPoliticiansByZIPHandler.

**Why bad:**
- Violates single responsibility (handler already does cache check, fetch, background warm)
- No way to check status without triggering full fetch
- Couples status check to politician data serialization
- Makes testing harder (can't test status endpoint independently)

**Instead:** Dedicated CacheStatusHandler that only queries cache tables.

### Anti-Pattern 2: Fetching Full Politician Data on Every Poll

**What:** Continuing to call `/politicians/{zip}` in polling loop.

**Why bad:**
- Wasteful: 50KB+ response when only need boolean "is cache ready?"
- DB load: Joins across politicians, offices, chambers, districts, images, degrees, experiences
- Bandwidth: 8 attempts × 50KB = 400KB+ for same data

**Instead:** Call `/cache-status/{type}/{identifier}` until fresh, then fetch once.

### Anti-Pattern 3: Multiple Queries Per Status Check

**What:** Joining across all essentials tables to compute freshness.

```go
// BAD: Over-fetching
var count int64
db.DB.Table("essentials.zip_politicians").
    Joins("JOIN essentials.politicians ON ...").
    Joins("JOIN essentials.offices ON ...").
    Where("zip_code = ?", zip).
    Count(&count)
```

**Why bad:**
- Unnecessary joins for simple timestamp check
- Slower query execution
- Higher DB load

**Instead:** Single query to cache table only.

```go
// GOOD: Minimal query
var cache ZipCache
db.DB.Where("zip_code = ?", zip).First(&cache)
```

### Anti-Pattern 4: Creating New Files for Tiny Features

**What:** Creating `internal/essentials/cache_status.go` with 50 lines.

**Why bad:**
- Fragment codebase (harder to navigate)
- Breaks existing convention (handlers.go is 2700 lines, adding handlers there is normal)
- Adds cognitive overhead (is this a new module? separate concern?)

**Instead:** Add CacheStatusHandler to existing handlers.go with clear comment separator.

### Anti-Pattern 5: Prop Drilling Polling Config

**What:** Passing `{maxAttempts, intervalMs}` through multiple component layers.

```javascript
// BAD: Prop drilling
<App maxAttempts={8} intervalMs={1500}>
  <Router maxAttempts={8} intervalMs={1500}>
    <Dashboard maxAttempts={8} intervalMs={1500} />
  </Router>
</App>
```

**Why bad:**
- Tight coupling between parent and child components
- Hard to change defaults globally
- Component reuse becomes difficult

**Instead:** Encapsulate in hook with sensible defaults, override only when needed.

```javascript
// GOOD: Hook with defaults
const { politicians, loading } = usePoliticianData(zip, 'zip'); // Uses defaults
const { politicians, loading } = usePoliticianData(zip, 'zip', { maxAttempts: 12 }); // Override
```

## Migration Path for Existing Components

### Step 1: Add Backend Endpoint (No Breaking Changes)

1. Add `CacheStatusHandler` to `internal/essentials/handlers.go`
2. Add route to `internal/essentials/routes.go`: `r.Get("/cache-status/{type}/{identifier}", CacheStatusHandler)`
3. Deploy backend (new endpoint available, existing endpoints unchanged)

**Impact:** None. Existing frontend continues to work.

### Step 2: Add Frontend Hook (Parallel Implementation)

1. Create `essentials/src/hooks/usePoliticianData.js`
2. Add `checkCacheStatus` to `essentials/src/lib/api.jsx`
3. Keep `fetchPoliticiansProgressive` for backward compatibility (mark deprecated)

**Impact:** None. Existing components continue using old API.

### Step 3: Migrate Components One-by-One

**Order:**
1. **Dashboard.jsx** (highest traffic, most benefit)
2. **Results.jsx** (similar usage pattern)
3. **Home.jsx** (lowest traffic, least critical)

**Per component:**
1. Replace `fetchPoliticiansProgressive` with `usePoliticianData` hook
2. Update loading states to use hook's `loading` prop
3. Update error handling to use hook's `error` prop
4. Test polling behavior (8 attempts, 1500ms interval)
5. Verify network tab shows cache-status calls instead of full fetches

**Impact:** Progressive migration. Each component can be tested independently.

### Step 4: Remove Deprecated Code (After All Components Migrated)

1. Remove `fetchPoliticiansProgressive` from `api.jsx`
2. Remove any unused polling logic
3. Update any tests referencing old API

**Impact:** Cleanup only. All components already migrated.

### Step 5: Add SSE Support (Future)

1. Implement SSE endpoint in backend: `GET /essentials/cache-status/{type}/{identifier}/stream`
2. Add `SSEStrategy` to `essentials/src/strategies/DataFetchStrategy.js`
3. Update `createFetchStrategy` to detect SSE support
4. Enable via environment variable: `VITE_FEATURE_SSE=true`
5. Test with feature flag in staging
6. Roll out to production

**Impact:** Zero changes to components. Hook internals swap strategies automatically.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| **Cache status queries** | Negligible (~10 QPS) | Low (~1K QPS, single-row SELECT) | Cache in Redis, 1s TTL per ZIP |
| **Full politician fetches** | Minimal DB load | Moderate (after cache fresh) | Add read replicas, CDN for images |
| **Background warmers** | Rarely triggered | Concurrent goroutines (current) | Queue system (Redis/SQS) |
| **Polling overhead** | Acceptable | Network bandwidth concern | SSE reduces to single connection |
| **BallotReady API rate limits** | No issue | Monitor rate limits | Cache aggressively, batch warmers |

### Optimization Triggers

**When to add Redis caching:**
- Cache status queries exceed 5K QPS
- Latency for status checks > 50ms p95

**When to implement SSE:**
- Polling bandwidth exceeds 10GB/day
- User complaints about "loading" delays
- Infrastructure costs for polling > $100/month

**When to add read replicas:**
- Full politician fetch queries exceed 2K QPS
- DB CPU utilization > 70%
- Latency for politician fetches > 200ms p95

## Build Order Implications

### Backend Build Order

1. **CacheStatusHandler** (independent, no dependencies)
2. **Route registration** (depends on handler)
3. **Deployment** (no schema changes, safe to deploy)

**Estimated effort:** 1-2 hours (handler + route + manual testing)

### Frontend Build Order

1. **API client function** (`checkCacheStatus` in api.jsx)
2. **Hook implementation** (`usePoliticianData`)
3. **Strategy pattern** (optional for Phase 1, required for SSE)
4. **Component migration** (one at a time)

**Estimated effort:** 3-4 hours (hook + API + migration + testing)

### Dependencies

```
Backend:
  CacheStatusHandler
    ├─> No new dependencies
    └─> Uses existing: GORM models (ZipCache, StateCache, FederalCache)

Frontend:
  usePoliticianData hook
    ├─> checkCacheStatus (api.jsx)
    ├─> fetchPoliticiansOnce (api.jsx, already exists)
    └─> React hooks (useState, useEffect, useRef)

  PollingStrategy (optional)
    ├─> checkCacheStatus (api.jsx)
    └─> fetchPoliticiansOnce (api.jsx)

  SSEStrategy (future)
    ├─> SSE backend endpoint (not yet implemented)
    └─> Browser EventSource API
```

**Critical path:** Backend endpoint must deploy before frontend hook can be tested. Hook can be built in parallel with backend, but integration testing requires backend deployment.

**Parallel work:** Backend and frontend teams can work simultaneously if backend provides OpenAPI spec or mock endpoint.

## Testing Strategy

### Backend Tests

**Unit tests (handlers_test.go):**
```go
func TestCacheStatusHandler_ZipFresh(t *testing.T) {
    // Setup: Insert fresh cache entry
    // Call: CacheStatusHandler
    // Assert: {fresh: true, lastFetch: recent, ttl: 90}
}

func TestCacheStatusHandler_ZipStale(t *testing.T) {
    // Setup: Insert stale cache entry (91 days old)
    // Call: CacheStatusHandler
    // Assert: {fresh: false, lastFetch: old, ttl: 90}
}

func TestCacheStatusHandler_ZipMissing(t *testing.T) {
    // Setup: No cache entry
    // Call: CacheStatusHandler
    // Assert: {fresh: false, lastFetch: zero, ttl: 90}
}
```

**Integration tests:**
```bash
# Manual testing with curl
curl https://api.empowered.vote/essentials/cache-status/zip/47408
# Expect: {"fresh": true, "last_fetch": "2026-02-09T10:00:00Z", "ttl_days": 90}

curl https://api.empowered.vote/essentials/cache-status/state/IN
# Expect: {"fresh": true, "last_fetch": "2026-02-09T09:00:00Z", "ttl_days": 90}

curl https://api.empowered.vote/essentials/cache-status/federal/federal
# Expect: {"fresh": true, "last_fetch": "2026-02-08T10:00:00Z", "ttl_days": 90}
```

### Frontend Tests

**Unit tests (usePoliticianData.test.js):**
```javascript
import { renderHook, waitFor } from '@testing-library/react';
import { usePoliticianData } from './usePoliticianData';
import * as api from '../lib/api';

jest.mock('../lib/api');

test('fetches politicians when cache is fresh on first check', async () => {
    api.checkCacheStatus.mockResolvedValue({ fresh: true });
    api.fetchPoliticiansOnce.mockResolvedValue([{ id: 1, name: 'Test' }]);

    const { result } = renderHook(() => usePoliticianData('12345', 'zip'));

    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(api.checkCacheStatus).toHaveBeenCalledTimes(1);
    expect(api.fetchPoliticiansOnce).toHaveBeenCalledTimes(1);
    expect(result.current.politicians).toHaveLength(1);
});

test('polls multiple times when cache is stale', async () => {
    api.checkCacheStatus
        .mockResolvedValueOnce({ fresh: false })
        .mockResolvedValueOnce({ fresh: false })
        .mockResolvedValueOnce({ fresh: true });
    api.fetchPoliticiansOnce.mockResolvedValue([{ id: 1, name: 'Test' }]);

    const { result } = renderHook(() =>
        usePoliticianData('12345', 'zip', { intervalMs: 100 })
    );

    await waitFor(() => expect(result.current.loading).toBe(false), { timeout: 5000 });

    expect(api.checkCacheStatus).toHaveBeenCalledTimes(3);
    expect(api.fetchPoliticiansOnce).toHaveBeenCalledTimes(1);
});
```

**Integration tests:**
```javascript
// Manual testing in browser console
const { checkCacheStatus, fetchPoliticiansOnce } = await import('./lib/api.js');

// Test status check
const status = await checkCacheStatus('zip', '47408');
console.log('Status:', status); // {fresh: true, ...}

// Test full fetch
const politicians = await fetchPoliticiansOnce('47408', 'zip');
console.log('Politicians:', politicians.length);
```

**E2E tests (Playwright/Cypress):**
```javascript
test('Dashboard progressive loading with cache status', async ({ page }) => {
    await page.goto('http://localhost:5173');

    // Enter ZIP
    await page.fill('input[placeholder="Enter ZIP"]', '47408');
    await page.click('button:has-text("Search")');

    // Verify loading state appears
    await page.waitForSelector('text=Loading...');

    // Verify cache status API called (network tab)
    const statusRequest = await page.waitForRequest(
        req => req.url().includes('/cache-status/zip/47408')
    );
    expect(statusRequest).toBeTruthy();

    // Verify politicians loaded
    await page.waitForSelector('[data-testid="politician-card"]', { timeout: 10000 });

    // Verify only ONE full fetch happened (not 8)
    const politicianRequests = page.requests().filter(
        req => req.url().includes('/politicians/47408')
    );
    expect(politicianRequests.length).toBe(1);
});
```

## Performance Metrics

### Before Optimization (Current State)

**Per ZIP search:**
- 8 API calls to `/politicians/{zip}` (1 every 1.5s)
- 8 × ~50KB = ~400KB transferred
- 8 DB queries with joins across 7+ tables
- Total time: ~12 seconds (8 attempts × 1.5s interval)

### After Optimization (Status Check Pattern)

**Per ZIP search (cache fresh on first check):**
- 1 API call to `/cache-status/zip/{zip}` (~200 bytes)
- 1 API call to `/politicians/{zip}` (~50KB)
- 1 cache table query (single row SELECT)
- 1 full politician query
- Total time: ~2 seconds (status check + full fetch)

**Savings:**
- 83% reduction in API calls (8 → 1 status + 1 full = 2 total)
- 87% reduction in bandwidth (400KB → 50.2KB)
- 87% reduction in DB load (8 full queries → 1 cache + 1 full)
- 83% reduction in time (12s → 2s)

**Per ZIP search (cache stale, warms on 3rd attempt):**
- 3 API calls to `/cache-status/zip/{zip}` (~600 bytes)
- 1 API call to `/politicians/{zip}` (~50KB)
- 3 cache table queries
- 1 full politician query
- Total time: ~4.5 seconds (3 × 1.5s + fetch time)

**Savings:**
- 50% reduction in API calls (8 → 4 total)
- 87% reduction in bandwidth (400KB → 50.6KB)
- 62% reduction in DB load (8 full queries → 3 cache + 1 full)
- 62% reduction in time (12s → 4.5s)

### SSE Future State

**Per ZIP search:**
- 1 SSE connection to `/cache-status/zip/{zip}/stream` (minimal overhead)
- 1 API call to `/politicians/{zip}` (~50KB)
- SSE push when cache ready (sub-second notification)
- Total time: ~1-2 seconds (SSE latency + full fetch)

**Savings over polling:**
- 50% reduction in API calls (4 → 2 total, even in stale case)
- Near-instant notification when cache ready (no polling interval waste)
- Persistent connection reduces HTTP overhead

## Confidence Assessment

| Area | Confidence | Rationale |
|------|------------|-----------|
| **Backend handler design** | HIGH | Standard Chi + GORM pattern, similar to existing handlers, single-query approach proven |
| **Frontend hook pattern** | HIGH | React hooks are standard, polling abstraction is well-established pattern, strategy pattern widely used |
| **Cache status query** | HIGH | Simple SELECT with WHERE clause, indexed columns (zip_code, state_code), minimal DB impact |
| **Migration path** | HIGH | Backward-compatible, components migrate independently, no breaking changes |
| **SSE feasibility** | MEDIUM | SSE supported by all modern browsers, but backend SSE implementation in Go/Chi requires research (not in scope for this milestone) |
| **Performance estimates** | MEDIUM | Based on current payload sizes and query counts, actual savings may vary with data growth |

## Sources

**Go/Chi backend patterns:**
- Go-Chi documentation: https://go-chi.io (official router patterns)
- GORM documentation: https://gorm.io/docs (query optimization, single-table queries)
- Existing codebase patterns: EV-Backend/internal/essentials/handlers.go (2700 lines, established conventions)

**React polling patterns:**
- React hooks documentation: https://react.dev/reference/react/hooks (useEffect, useState patterns)
- MDN EventSource API: https://developer.mozilla.org/en-US/docs/Web/API/EventSource (SSE browser support)
- Strategy pattern: Design Patterns (GoF), widely used in JavaScript/React ecosystems

**Performance patterns:**
- HTTP polling vs SSE: https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events (official comparison)
- Cache-aside pattern: Standard caching architecture (check cache, fetch if miss, update cache)

**Project-specific:**
- EV-Backend module structure: internal/essentials/, internal/compass/, internal/treasury/ (consistent pattern across modules)
- Existing progressive loading: essentials/src/lib/api.jsx fetchPoliticiansProgressive implementation
- Cache architecture: federal_cache, state_caches, zip_caches with 90-day TTL
