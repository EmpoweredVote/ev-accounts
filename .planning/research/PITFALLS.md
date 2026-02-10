# Domain Pitfalls: Cache Polling Optimization

**Domain:** Progressive loading with cache-status endpoints
**Researched:** 2026-02-09

## Critical Pitfalls

Mistakes that cause rewrites, data corruption, or catastrophic user experience degradation.

### Pitfall 1: TOCTOU Race Between Status Check and Data Fetch

**What goes wrong:** Status endpoint says "fresh" but subsequent data fetch returns stale/empty data because warming completed between the two requests.

**Why it happens:** In a TOCTOU (Time-Of-Check-Time-Of-Use) race condition, the status check and data fetch are separate HTTP calls with a time gap between them. Another client could trigger cache invalidation, warming could complete and flip status, or TTL could expire in the window between status check and fetch.

**Consequences:**
- Frontend shows "fresh" spinner/UI state but receives stale data
- User sees incorrect/outdated information with no warning
- Progressive loading logic breaks (expects "warming" but gets "fresh" with old data)
- Silent data corruption if frontend assumes status=fresh guarantees current data

**Prevention:**
- **Option 1 (Atomic):** Return both status AND data in single response (recommended for this codebase)
  ```go
  // Single atomic read
  type StatusResponse struct {
    Status     string        `json:"status"`
    Data       []OfficialOut `json:"data"`
    CachedAt   time.Time     `json:"cached_at"`
    ExpiresAt  time.Time     `json:"expires_at"`
  }
  ```
- **Option 2 (Versioned):** Include cache version token in status response; data fetch validates token
  ```go
  // Status endpoint returns: {"status": "fresh", "version": "abc123"}
  // Data endpoint validates: If-Match: "abc123" → 412 Precondition Failed if changed
  ```
- **Option 3 (Timestamp):** Status includes cached_at timestamp; frontend validates data matches
  ```json
  {"status": "fresh", "cached_at": "2026-02-09T10:00:00Z"}
  // Data response includes same cached_at; frontend rejects mismatches
  ```

**Detection:**
- Monitor for X-Data-Status="fresh" with empty/partial data arrays
- Log status endpoint calls with timestamp; correlate with subsequent data fetch timestamps >200ms apart
- Unit test: warmLocal completes between status check and data fetch
- E2E test: Parallel clients racing status/fetch endpoints

**Phase mapping:** Phase 1 (API design) must address this atomically. Retrofitting after Phase 2 (frontend integration) requires breaking changes.

---

### Pitfall 2: Advisory Lock Held During Network I/O

**What goes wrong:** PostgreSQL advisory lock held while calling BallotReady API causes all warming requests to serialize, destroying concurrency benefits.

**Why it happens:** Current warmLocal pattern acquires lock → fetches from BallotReady (3-5 seconds) → upserts DB → releases lock. If lock is held during the slow network call, only one ZIP can warm at a time across all servers.

**Consequences:**
- Multiple ZIP searches at same time (realistic: 5-10 concurrent users) wait in serial
- First ZIP takes 3 seconds, second takes 6 seconds, third takes 9 seconds, etc.
- Advisory lock meant to dedupe warming now creates bottleneck
- Frontend polling times out (8 attempts × 1.5s = 12 seconds) before warming completes

**Prevention:**
- **Pattern:** Acquire lock → check if warming needed → release lock → fetch external data → re-acquire lock → upsert → release
  ```go
  // WRONG: Lock held during network I/O
  if !tryAcquireLock(ctx, lockKey) { return }
  defer releaseLock(ctx, lockKey)
  data := ballotready.Fetch(zip) // 3-5 seconds with lock held
  upsert(data)

  // CORRECT: Lock only for DB operations
  if !tryAcquireLock(ctx, lockKey) { return }
  needsWarm := checkIfStale(zip)
  releaseLock(ctx, lockKey)
  if !needsWarm { return }

  data := ballotready.Fetch(zip) // No lock during network I/O

  if !tryAcquireLock(ctx, lockKey) { return } // Re-acquire for upsert
  defer releaseLock(ctx, lockKey)
  upsert(data)
  ```
- Use finer-grained locks: ZIP-level locks instead of global cache lock
- Document lock holding duration limits (target: <50ms per acquisition)

**Detection:**
- Prometheus metric: advisory_lock_held_duration_seconds{p99} > 1000ms
- Log warning if lock held >500ms
- Load test: 10 concurrent ZIP requests should complete in <5 seconds total (not 30 seconds serial)

**Phase mapping:** Review in Phase 1 (backend architecture). Lock-holding duration must be characterized before adding cache-status endpoint.

---

### Pitfall 3: Frontend Memory Leak from Uncleaned Polling Timers

**What goes wrong:** User navigates away from Results page while polling; setInterval/setTimeout continues firing, updating unmounted component state, causing memory leak and console errors.

**Why it happens:** fetchPoliticiansProgressive uses async/await with sleep() loops. If component unmounts mid-polling, the loop continues executing. Each attempt calls onUpdate callback which tries to setState on unmounted component.

**Consequences:**
- React warning: "Can't perform a state update on an unmounted component"
- Memory accumulates with each navigation (zombie polling loops)
- API spam: abandoned polls continue hitting backend every 1.5 seconds
- User navigates Results → Profile → Results → Profile (5 times) = 5 concurrent polling loops

**Prevention:**
- **Pattern 1 (AbortController):** Cancel in-flight fetch and polling loop on unmount
  ```javascript
  useEffect(() => {
    const abortController = new AbortController();

    fetchPoliticiansProgressive(zip, onUpdate, {
      signal: abortController.signal // Pass to fetch calls
    });

    return () => abortController.abort(); // Cleanup
  }, [zip]);
  ```
- **Pattern 2 (Mounted flag):** Check if component still mounted before setState
  ```javascript
  useEffect(() => {
    let isMounted = true;

    const onUpdate = (result) => {
      if (!isMounted) return; // Ignore updates after unmount
      setList(result.data);
    };

    fetchPoliticiansProgressive(zip, onUpdate);

    return () => { isMounted = false; };
  }, [zip]);
  ```
- **Pattern 3 (Ref-based):** Store abort flag in ref (survives re-renders)
  ```javascript
  const abortRef = useRef(false);

  useEffect(() => {
    abortRef.current = false;
    // Pass abortRef to polling function; check before each iteration
    return () => { abortRef.current = true; };
  }, [zip]);
  ```

**Detection:**
- React DevTools Profiler: component unmounted but re-renders continue
- Console warnings: "Can't perform state update on unmounted component"
- Network tab: requests continue after navigation away
- Memory profiler: heap grows with repeated navigation

**Phase mapping:** Must fix in Phase 2 (frontend refactor) BEFORE adding cache-status endpoint. New polling pattern will inherit the leak if not addressed.

---

### Pitfall 4: Cold Miss Returns Before waitForDataMin Completes

**What goes wrong:** Cache-status endpoint returns "warming" but data endpoint returns empty array because waitForDataMin timeout (10 seconds) hasn't elapsed yet.

**Why it happens:** Current design: data endpoint calls waitForDataMin (polls DB every 200ms for up to 10 seconds). If cache-status endpoint bypasses this wait, it returns "warming" immediately. Frontend then calls data endpoint expecting at least partial data, but warmer hasn't written any rows yet.

**Consequences:**
- Frontend shows "Loading..." spinner indefinitely (status says warming but no data arrives)
- User abandons search thinking it's broken
- Progressive loading UX breaks: designed to show partial results incrementally, but gets empty array
- Race between cache-status "warming" and first DB row insert

**Prevention:**
- **Option 1 (Unified endpoint):** Status and data in single response eliminates race
  ```go
  // Always call waitForDataMin with minCount=1
  if warming, ok := waitForDataMin(ctx, zip, "", 10*time.Second, 200*time.Millisecond, 1); ok {
    return StatusResponse{Status: "warming", Data: warming, Count: len(warming)}
  }
  return StatusResponse{Status: "warming", Data: []OfficialOut{}, Count: 0}
  ```
- **Option 2 (Guaranteed minimum):** Status endpoint also waits for minCount=1 before returning "warming"
  ```go
  // Status endpoint logic
  if fresh { return "fresh" }
  if warming, ok := waitForDataMin(ctx, zip, "", 2*time.Second, 200*time.Millisecond, 1); ok {
    return "warming" // Guaranteed at least 1 row exists
  }
  return "cold" // No data yet, caller should wait longer
  ```
- **Option 3 (Count field):** Return count in status; frontend knows whether to expect data
  ```json
  {"status": "warming", "count": 0}  // No data yet, keep polling
  {"status": "warming", "count": 5}  // 5 rows available, fetch now
  ```

**Detection:**
- Log: status="warming" returned but zip_politicians row count = 0
- Frontend logs: onUpdate called with data=[] and status="warming" (should have at least 1)
- E2E test: Cold cache → status endpoint → data endpoint within 500ms → assert data.length > 0

**Phase mapping:** Critical for Phase 1 (API design). Defines contract between status and data endpoints. Frontend polling logic (Phase 2) depends on this guarantee.

---

### Pitfall 5: Backward Incompatibility During Rolling Deployment

**What goes wrong:** Old frontend (expects X-Data-Status header) hits new backend (cache-status endpoint returns JSON); progressive loading breaks for 10-30 minutes during deployment.

**Why it happens:** Rolling deployment deploys new backend instances incrementally. Load balancer routes some requests to old backend (with headers), some to new backend (with JSON endpoint). Frontend doesn't handle mixed responses gracefully.

**Consequences:**
- 50% of users see broken UI during deployment window
- fetchPoliticiansProgressive expects header, gets 404 for new endpoint
- Error handling falls back to timeout, 12-second wait before showing error
- Support tickets spike during every deployment
- Rollback required if not caught in staging

**Prevention:**
- **Option 1 (Dual-mode backend):** New backend supports BOTH header and endpoint
  ```go
  // New backend preserves X-Data-Status header for backward compatibility
  w.Header().Set("X-Data-Status", status)
  writeJSON(w, StatusResponse{Status: status, Data: data})
  ```
- **Option 2 (Feature detection):** Frontend detects which backend version
  ```javascript
  // Try new endpoint; fall back to header-based on 404
  async function getStatus(zip) {
    const res = await fetch(`/api/cache-status/${zip}`);
    if (res.status === 404) {
      return parseHeaderStatus(await fetch(`/api/politicians/${zip}`));
    }
    return await res.json();
  }
  ```
- **Option 3 (Version header):** Backend advertises API version
  ```
  X-API-Version: 2
  X-Data-Status: warming  // Deprecated but still returned for v1 clients
  ```
- **Option 4 (Phased rollout):**
  1. Deploy backend with both header AND endpoint (week 1)
  2. Deploy frontend to use endpoint, falls back to header (week 2)
  3. Remove header from backend (week 3)

**Detection:**
- Canary deployment: 5% of traffic to new backend, monitor error rate
- Feature flag: gradual rollout of new frontend code
- Logs: track header-based vs endpoint-based requests; alert if endpoint 404 rate >1%
- Staging environment: old frontend + new backend, new frontend + old backend (both combos)

**Phase mapping:** Critical for Phase 3 (deployment strategy). Must be designed BEFORE implementing Phase 1 or Phase 2. Backward compatibility is not a refactoring concern; it's an architecture decision.

---

## Moderate Pitfalls

Issues that degrade performance or UX but don't cause data corruption or require rewrites.

### Pitfall 6: Cache-Status Endpoint Creates N+1 Query Pattern

**What goes wrong:** Frontend checks cache status, then fetches data. For 3 pages using progressive loading (Dashboard, Results, Home), what was 1 request becomes 2 requests per page load.

**Why it happens:** Separating status from data seems cleaner but doubles HTTP overhead. Each page load: OPTIONS (CORS preflight) + cache-status + politicians endpoint = 3 requests instead of 1.

**Prevention:**
- Measure current performance: time-to-first-byte for combined response
- Compare against separate status + data: round-trip latency matters (50-100ms per request)
- Justify separation: "Status checks allow us to skip fetching 200KB JSON when cache is fresh" (but current design already returns empty array when warming, so this benefit is unclear)
- Consider: Does cache-status endpoint enable new UX? (e.g., "Last updated 5 minutes ago") If not, added complexity may not pay off.

**Detection:**
- Network waterfall: sequential requests to cache-status → politicians endpoint
- Backend metric: requests_per_search{p50} increases from 1 to 2

**Phase mapping:** Evaluate in Phase 1 (API design). If status+data in single response meets requirements, skip separate endpoint entirely.

---

### Pitfall 7: Polling Interval Mismatch Creates Stuttering UX

**What goes wrong:** Frontend polls every 1.5 seconds, but backend waitForDataMin polls DB every 200ms. Frontend misses 7 out of 8 updates, making UI appear frozen then suddenly populate.

**Why it happens:** Backend discovers new rows every 200ms (0s, 0.2s, 0.4s, 0.6s...). Frontend checks at 0s, 1.5s, 3s, 4.5s. Most incremental updates are skipped.

**Prevention:**
- Align polling intervals: if backend polls DB every 200ms, frontend should poll API every 200-500ms for smooth incremental updates
- Or change strategy: backend buffers updates, returns batches every 1.5 seconds (aligns with frontend polling)
- Current settings (maxAttempts=8, intervalMs=1500) = 12 seconds max wait; ensure backend TTL and warming time support this

**Detection:**
- User testing: "Politicians appear in chunks, not smoothly"
- Frontend logs: onUpdate called with same data.length multiple times, then jumps from 3 → 15

**Phase mapping:** Tune in Phase 2 (frontend refactor). Requires coordination with backend timing assumptions from Phase 1.

---

### Pitfall 8: Excessive Polling During Coordinated Traffic Spikes

**What goes wrong:** Viral social media post → 500 users search their ZIP simultaneously → 4000 polling requests (500 users × 8 attempts) in 12 seconds overwhelm backend.

**Why it happens:** Progressive polling is exponential under load. Each user generates 8 API calls. Warming is deduplicated (advisory lock) but status checks are not.

**Prevention:**
- Add jitter to polling interval: `intervalMs + random(0, 500)` spreads requests
- Implement backoff after first few attempts: 1.5s → 2s → 3s → 5s
- Backend rate limiting: 429 Too Many Requests if >10 requests/second from same IP
- CDN caching for cache-status endpoint: if status=fresh, cache for 60 seconds at edge

**Detection:**
- Metrics: requests_per_second spikes correlate with warming events
- 500 errors from connection pool exhaustion
- Load test: 100 concurrent ZIP searches, measure total request count

**Phase mapping:** Consider in Phase 1 (API design). Rate limiting and caching headers must be designed upfront.

---

### Pitfall 9: State Normalization Lost During Refactor

**What goes wrong:** Results.jsx uses setList(data), Dashboard.jsx uses setPoliticians(data), Home.jsx uses setData(data). Refactoring fetchPoliticiansProgressive callback signature breaks callers in subtle ways.

**Why it happens:** Each page passes different onUpdate callback shape. Changing callback parameters (e.g., adding retryAfter field) requires updating all 3 callers. Easy to miss one.

**Prevention:**
- Define canonical callback interface:
  ```typescript
  type ProgressUpdate = {
    status: 'fresh' | 'warming' | 'stale' | 'timeout';
    data: OfficialOut[];
    error?: string;
    retryAfter?: number;
    cachedAt?: string;
    count?: number;
  };
  type OnUpdateCallback = (update: ProgressUpdate) => void;
  ```
- Extract shared logic into custom hook:
  ```javascript
  function usePoliticianSearch(zip) {
    const [state, setState] = useState({status: 'idle', data: []});

    useEffect(() => {
      fetchPoliticiansProgressive(zip, (update) => setState(update));
    }, [zip]);

    return state;
  }
  // Usage: const {status, data, error} = usePoliticianSearch(zip);
  ```
- TypeScript for compile-time safety (even if rest of codebase is JS, type-check api.jsx)

**Detection:**
- Search codebase: `fetchPoliticiansProgressive` has 3 call sites; verify all updated
- Regression test: navigate to Results, Dashboard, Home in sequence; verify all load correctly
- Console errors: "Cannot read property 'data' of undefined"

**Phase mapping:** Fix in Phase 2 (frontend refactor). Define callback contract in Phase 1 before implementing new endpoint.

---

### Pitfall 10: Cache-Status Endpoint Exposes Internal Implementation Details

**What goes wrong:** Status endpoint returns "warming_local", "warming_state", "warming_federal" exposing 3-tier cache structure. Frontend now depends on internal backend architecture.

**Why it happens:** Temptation to expose granular status for debugging. "Why is it slow? Oh, warming_federal takes longer because it's nationwide."

**Prevention:**
- External API should return abstract states: "fresh", "warming", "stale"
- Internal details in separate debugging endpoint: GET /admin/cache-debug/{zip} (requires auth)
- Server-Timing headers for observability without coupling:
  ```
  Server-Timing: dbread;dur=50, wait;dur=200, ballotready;dur=3000
  ```

**Detection:**
- API documentation review: are internal states documented in public API?
- Frontend code search: if status.includes("warming_") { ... } = coupling to internals
- Contract test: mock backend returns only "fresh"|"warming"|"stale"; frontend handles gracefully

**Phase mapping:** Prevent in Phase 1 (API design). Once exposed, removing fields is breaking change.

---

## Minor Pitfalls

Small issues that cause confusion or require minor fixes but don't significantly impact users.

### Pitfall 11: Inconsistent Status String Casing

**What goes wrong:** Backend returns "Warming", "FRESH", "stale" inconsistently. Frontend uses .toLowerCase() everywhere to normalize but missed one code path.

**Prevention:**
- Define status as enum/constant:
  ```go
  const (
    StatusFresh   = "fresh"
    StatusWarming = "warming"
    StatusStale   = "stale"
  )
  ```
- API tests assert exact casing
- Frontend: define string literal union type (TypeScript) or constants object (JavaScript)

**Detection:**
- Grep codebase for string literals: "fresh", "Fresh", "FRESH"
- Unit test: assert response.status === "fresh" (exact match, not includes/toLowerCase)

**Phase mapping:** Establish in Phase 1 (API design). Trivial fix but prevents bugs.

---

### Pitfall 12: Missing Error Handling for Concurrent Upserts

**What goes wrong:** Two warmers race to upsert politician with same external_id. Unique constraint violation crashes one goroutine, leaving cache partially populated.

**Why it happens:** ON CONFLICT DO UPDATE should handle this, but if transaction isolation is wrong or GORM generates unexpected SQL, uniqueness violations can surface.

**Prevention:**
- Test concurrent upserts: spawn 2 goroutines upserting same ZIP simultaneously
- Log unique constraint violations at INFO level (expected during races), not ERROR
- Verify GORM generates correct SQL:
  ```sql
  INSERT INTO essentials.politicians (...) VALUES (...)
  ON CONFLICT (external_id) DO UPDATE SET ...
  ```
- Idempotent upserts: running twice produces same result

**Detection:**
- Logs: "duplicate key value violates unique constraint" errors
- Missing politicians after warming (partial cache population)
- DB query: `SELECT external_id, COUNT(*) FROM essentials.politicians GROUP BY external_id HAVING COUNT(*) > 1` (should be empty)

**Phase mapping:** Verify in Phase 1 (backend warming logic audit). Should already be correct, but high-concurrency scenarios may reveal bugs.

---

### Pitfall 13: Cache-Status Response Not Cacheable

**What goes wrong:** Every status check hits backend, even if cache-status would be identical for 60 seconds. CDN/browser can't cache response without headers.

**Prevention:**
- Add Cache-Control header when status=fresh:
  ```go
  if status == StatusFresh && age < 30*time.Minute {
    w.Header().Set("Cache-Control", "public, max-age=60")
  } else {
    w.Header().Set("Cache-Control", "no-store")
  }
  ```
- ETags for conditional requests: `If-None-Match` → 304 Not Modified

**Detection:**
- Network tab: cache-status requests show (from disk cache) or (from memory cache)
- CDN logs: cache hit ratio for /cache-status/* endpoint

**Phase mapping:** Add in Phase 1 (API implementation). Caching headers are part of API contract.

---

### Pitfall 14: Misleading Status During TTL Window

**What goes wrong:** Cache is 89 days old (TTL=90 days). Status returns "fresh" but data is 3 months stale. User expects current information.

**Prevention:**
- Define "fresh" more strictly: cache age <7 days = fresh, 7-90 days = stale (but usable)
- Add staleness indicator in response:
  ```json
  {
    "status": "fresh",
    "cached_at": "2025-11-10T10:00:00Z",
    "age_days": 89,
    "is_stale": true
  }
  ```
- Frontend shows "Last updated 89 days ago" warning

**Detection:**
- User feedback: "Why is my representative from 2024 showing?"
- Logs: status=fresh but age >30 days

**Phase mapping:** Decide in Phase 1 (API semantics). "Fresh" definition is core to API contract.

---

### Pitfall 15: Database Connection Pool Exhaustion from Polling

**What goes wrong:** waitForDataMin polls DB every 200ms. Under load, 50 concurrent polls × 10 seconds = 2500 DB queries in 10 seconds. Connection pool (max 25 connections) exhausted.

**Prevention:**
- Use single connection with long-polling query (LISTEN/NOTIFY in PostgreSQL)
- Limit concurrent waitForDataMin calls: semaphore with max 10 concurrent
- Increase connection pool size if DB server can handle it
- Reduce polling frequency: 500ms instead of 200ms (5 queries/second instead of 5)

**Detection:**
- Metrics: db_connection_pool_wait_time_seconds > 100ms
- Logs: "database connection pool exhausted"
- Load test: 50 concurrent ZIP searches trigger connection errors

**Phase mapping:** Audit in Phase 1 (backend scalability). May require architectural change (LISTEN/NOTIFY) if issue confirmed.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 1: API Design | TOCTOU race (status check → data fetch) | Return status+data in single atomic response |
| Phase 1: Locking Strategy | Advisory lock held during BallotReady API call | Release lock before network I/O; re-acquire for DB upsert |
| Phase 1: Backward Compatibility | Breaking header-based clients | Support both header and endpoint for 1-2 weeks |
| Phase 2: Frontend Refactor | Memory leak from uncleaned polling timers | AbortController cleanup in useEffect return |
| Phase 2: Callback Contract | Breaking Results.jsx/Dashboard.jsx/Home.jsx | Define canonical ProgressUpdate type; use custom hook |
| Phase 2: Polling Tuning | Interval mismatch (frontend 1.5s, backend 200ms) | Align intervals or batch backend updates |
| Phase 3: Deployment | Old frontend + new backend incompatibility | Feature detection or dual-mode backend |
| Phase 3: Load Testing | Connection pool exhaustion under concurrent polling | Semaphore to limit concurrent waitForDataMin calls |

---

## Sources

### Race Conditions and Caching
- [Race Conditions in REST APIs: A Developer's Guide](https://medium.com/@mgaurang123/race-conditions-in-rest-apis-a-developers-guide-to-building-reliable-systems-42d4f8eabc1e)
- [When Caches Collide: Solving Race Conditions in Fare Updates](https://dzone.com/articles/fare-cache-race-conditions-troubleshooting)
- [The Ultimate Caching Definition: Invalidation, Optimization, and Layers](https://stack.convex.dev/caching-in)

### TOCTOU (Time-of-Check-Time-of-Use)
- [Time-of-check to time-of-use - Wikipedia](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use)
- [CWE-367: Time-of-check Time-of-use (TOCTOU) Race Condition](https://cwe.mitre.org/data/definitions/367.html)
- [Time-of-check Time-of-use (TOCTOU) Race Condition Leads to Broken Authentication](https://infosecwriteups.com/time-of-check-time-of-use-toctou-race-condition-leads-to-broken-authentication-critical-finding-b55993c92abc)

### PostgreSQL Advisory Locks
- [Using PostgreSQL advisory locks to avoid race conditions](https://firehydrant.com/blog/using-advisory-locks-to-avoid-race-conditions-in-rails/)
- [How to Use Advisory Locks in PostgreSQL](https://oneuptime.com/blog/post/2026-01-25-use-advisory-locks-postgresql/view)
- [PostgreSQL Advisory Locks](https://www.netguru.com/blog/advisory-locks)
- [PostgreSQL: How to use with_advisory_lock to prevent race conditions](https://makandracards.com/makandra/482969-postgresql-how-to-use-with_advisory_lock-to-prevent-race-conditions)

### React Memory Leaks and useEffect Cleanup
- [Preventing Memory Leaks in React with useEffect Hooks](https://www.c-sharpcorner.com/article/preventing-memory-leaks-in-react-with-useeffect-hooks/)
- [Understanding React's useEffect cleanup function](https://blog.logrocket.com/understanding-react-useeffect-cleanup-function/)
- [How to Fix Memory Leaks in React Applications](https://www.freecodecamp.org/news/fix-memory-leaks-in-react-apps/)
- [5 React Memory Leaks That Kill Performance (Fix Them Now)](https://www.codewalnut.com/insights/5-react-memory-leaks-that-kill-performance)

### API Versioning and Backward Compatibility
- [API Versioning Best Practices: How to Manage Changes Effectively](https://www.gravitee.io/blog/api-versioning-best-practices)
- [Handling API Versioning and Backward Compatibility on the Frontend](https://dev.to/neelendra_tomar_27/handling-api-versioning-and-backward-compatibility-on-the-frontend-297p)
- [Avoiding Backward Compatibility Breaks in API Design: A Developer's Guide](https://medium.com/carvago-development/avoiding-backward-compatibility-breaks-in-api-design-a-developers-guide-b6b4d280d423)

### Polling and Cache Patterns
- [How to Implement Long Polling Without WebSockets in Go](https://oneuptime.com/blog/post/2026-01-25-long-polling-without-websockets-go/view)
- [How to Implement Cache Warming Strategies](https://oneuptime.com/blog/post/2026-01-30-cache-warming-strategies/view)
- [Cache Warming Explained: Benefits, Pitfalls, and Alternatives](https://aerospike.com/blog/cache-warming-explained)

### Progressive Loading and Refactoring
- [Progressive loading for modern web applications via code splitting](https://medium.com/@lavrton/progressive-loading-for-modern-web-applications-via-code-splitting-fb43999735c6)
- [The Death of useCallback: Refactoring Event Handlers for the React Compiler Era](https://sameerthite.medium.com/the-death-of-usecallback-refactoring-event-handlers-for-the-react-compiler-era-6fd2e2814145)
