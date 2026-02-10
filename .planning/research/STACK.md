# Technology Stack

**Project:** Empowered Vote Essentials - Cache Status Polling Optimization
**Researched:** 2026-02-09
**Confidence:** HIGH

## Overview

This stack analysis focuses on implementing a lightweight cache status endpoint in Go/Chi and refactoring React 19 frontend polling to be SSE-ready. The existing system uses Go 1.24.3 with Chi router and GORM + PostgreSQL on the backend, and React 19 with Vite on the frontend.

## Backend Patterns

### Lightweight Status Endpoint (Chi Router)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Chi Router | v5.x | HTTP routing | Already in stack; minimal, idiomatic, composable |
| Go stdlib `encoding/json` | Go 1.24.3 | JSON responses | Zero dependencies, produces minimal JSON by default |
| GORM | Existing | Database queries | Already in stack; supports lightweight queries |

**Pattern: Minimal JSON Response Handler**

Chi's handler pattern is simple and lightweight - it accepts standard `http.HandlerFunc`. For status endpoints that return small JSON payloads:

```go
func CacheStatusHandler(w http.ResponseWriter, r *http.Request) {
    // Lightweight query
    status := checkCacheStatus() // Returns struct

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(status)
}
```

**Rationale:** Go's `encoding/json` package produces compact JSON without whitespace by default, which is optimal for status endpoints. The `json.NewEncoder(w).Encode()` pattern streams directly to the ResponseWriter without intermediate buffering. Use struct tags with `omitempty` to exclude zero values and minimize payload size.

**Source:** [Go encoding/json package documentation](https://pkg.go.dev/encoding/json) shows that by default, no whitespace is added, producing minimal JSON representation per RFC 7493.

**Confidence:** HIGH - Standard library patterns, well-documented, proven in production.

---

### GORM Lightweight Queries

| Technique | Purpose | Performance Impact |
|-----------|---------|-------------------|
| `Select()` with specific fields | Query only needed columns | Reduces I/O, smaller result sets |
| Avoid JOINs for status checks | Query cache tables directly | Eliminates multi-table scan overhead |
| Use indexes on cache key columns | Fast lookups on ZIP/state/federal keys | Sub-millisecond query times |

**Pattern: Minimal Cache Status Query**

```go
type CacheStatus struct {
    ZipFresh    bool `json:"zip_fresh"`
    StateFresh  bool `json:"state_fresh"`
    FederalFresh bool `json:"federal_fresh"`
}

func checkCacheStatus(zip string, state string) CacheStatus {
    var status CacheStatus

    // Check each cache table independently (no JOINs)
    db.DB.Model(&ZipCache{}).
        Select("updated_at").
        Where("zip_code = ? AND updated_at > ?", zip, cutoff).
        Take(&zipTime) // Returns error if not found or stale

    status.ZipFresh = (zipTime != nil && !isStale(zipTime))
    // Repeat for state and federal

    return status
}
```

**Rationale:** Cache status tables (`zip_caches`, `state_caches`, `federal_cache`) are small lookup tables. Direct queries with indexed WHERE clauses are faster than JOINs with politician tables. GORM's `Select()` reduces result set size. Use `Take()` instead of `First()` when you don't need ordering.

**Source:** [GORM Performance Documentation](https://gorm.io/docs/performance.html) recommends selecting only needed fields and avoiding JOINs when filtering. [GORM Advanced Query](https://gorm.io/docs/advanced_query.html) shows `Select()` optimization patterns.

**Note:** GORM currently lacks a built-in `Exists()` method (as of [GitHub Discussion #6000](https://github.com/go-gorm/gorm/discussions/6000)), but `Take()` with `Select("1")` achieves similar performance for existence checks.

**Confidence:** HIGH - Well-documented GORM patterns, matches existing codebase patterns.

---

### SSE-Ready Backend Design (Future Migration)

| Library | Purpose | Chi Compatibility | Maturity |
|---------|---------|-------------------|----------|
| `alexandrevicenzi/go-sse` | SSE server implementation | Native Chi support via `r.Mount()` | Stable, Go 1.9+ |
| `tmaxmax/go-sse` | Spec-compliant SSE with replayer | Standard `http.Handler` interface | Fully featured, newer |
| Go stdlib only | Manual SSE with `http.Flusher` | Native Chi compatibility | Zero dependencies |

**Pattern: SSE Endpoint Structure (For Future Reference)**

When migrating from polling to SSE, the Go stdlib provides all necessary tools:

```go
func SSECacheStatusHandler(w http.ResponseWriter, r *http.Request) {
    // Type assert for flusher support
    flusher, ok := w.(http.Flusher)
    if !ok {
        http.Error(w, "Streaming unsupported", http.StatusInternalServerError)
        return
    }

    // Set SSE headers
    w.Header().Set("Content-Type", "text/event-stream")
    w.Header().Set("Cache-Control", "no-cache")
    w.Header().Set("Connection", "keep-alive")
    w.WriteHeader(http.StatusOK)

    // Stream events
    for {
        select {
        case <-r.Context().Done():
            return // Client disconnected
        case event := <-eventChan:
            fmt.Fprintf(w, "data: %s\n\n", event)
            flusher.Flush() // Send immediately
        }
    }
}
```

**Rationale for SSE Libraries:**
- **alexandrevicenzi/go-sse:** Simplest integration with Chi via `r.Mount("/events/", sseServer)`. Good for basic use cases. [Example with Chi](https://github.com/alexandrevicenzi/go-sse/blob/master/_examples/chi.go) shows direct mounting pattern.
- **tmaxmax/go-sse:** More feature-rich with event replaying (send missed events to reconnecting clients), spec-compliant, better for production. Implements `http.Handler` so works with any router.
- **Stdlib only:** Zero dependencies, full control, but requires manual implementation of reconnection logic and event buffering.

**Recommendation:** Start with stdlib polling → polling optimization → stdlib SSE → upgrade to `tmaxmax/go-sse` if replay/persistence needed.

**Sources:**
- [Writing SSE Server in Go (Thoughtbot)](https://thoughtbot.com/blog/writing-a-server-sent-events-server-in-go)
- [Go Real-time Applications with SSE](https://oneuptime.com/blog/post/2026-02-01-go-realtime-applications-sse/view)
- [go-sse Chi Example](https://github.com/alexandrevicenzi/go-sse/blob/master/_examples/chi.go)
- [tmaxmax/go-sse GitHub](https://github.com/tmaxmax/go-sse)

**Confidence:** HIGH for stdlib pattern, MEDIUM for library recommendations (limited production usage data for this specific stack).

---

## Frontend Patterns (React 19)

### Polling with Cleanup (Current Implementation)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| React | 19.x | UI framework | Already in stack |
| `useEffect` + `setInterval` | React 19 stdlib | Polling loop | Native, zero dependencies |
| `AbortController` | Browser API | Request cancellation | Prevents memory leaks, built-in |
| Custom Hook | React pattern | Abstraction | Reusability, testability, swap-ability |

**Pattern: Polling with Proper Cleanup**

```javascript
function usePolling(endpoint, interval, shouldPoll) {
  const [data, setData] = React.useState(null);
  const [error, setError] = React.useState(null);

  React.useEffect(() => {
    if (!shouldPoll) return;

    const abortController = new AbortController();

    const poll = async () => {
      try {
        const response = await fetch(endpoint, {
          signal: abortController.signal,
          credentials: 'include'
        });
        const json = await response.json();
        setData(json);
      } catch (err) {
        if (err.name !== 'AbortError') {
          setError(err);
        }
      }
    };

    poll(); // Initial fetch
    const intervalId = setInterval(poll, interval);

    // Cleanup function
    return () => {
      clearInterval(intervalId);
      abortController.abort();
    };
  }, [endpoint, interval, shouldPoll]);

  return { data, error };
}
```

**Critical Details:**

1. **Store interval ID inside useEffect:** Don't store at component scope. The cleanup function needs access to the specific interval created by this effect.

2. **Always return cleanup function:** Clears interval when component unmounts or dependencies change. Without this, intervals stack and cause memory leaks.

3. **Use AbortController for fetch:** Create fresh instance per effect. Abort in cleanup. Prevents "Can't perform state update on unmounted component" warnings.

4. **Check error name:** `AbortError` is expected when cleanup runs. Don't treat it as a real error.

5. **Fresh AbortController per effect:** AbortControllers are single-use. Once aborted, they cannot be reused.

**Sources:**
- [React useEffect Cleanup Best Practices](https://www.dhiwise.com/post/a-guide-to-real-time-applications-with-react-polling)
- [AbortController in React - Complete Guide](https://www.localcan.com/blog/abortcontroller-nodejs-react-complete-guide-examples)
- [Preventing Memory Leaks in React with useEffect](https://www.c-sharpcorner.com/article/preventing-memory-leaks-in-react-with-useeffect-hooks/)
- [React useEffect Cleanup Function](https://refine.dev/blog/useeffect-cleanup/)

**Confidence:** HIGH - Official React patterns, well-documented, critical for memory leak prevention.

---

### SSE-Ready Polling Abstraction (Migration Strategy)

**Pattern: Transport-Agnostic Hook**

The key to making polling swappable for SSE is to abstract the transport mechanism behind a consistent interface:

```javascript
// Abstract interface
function useRealtimeData(endpoint, options = {}) {
  const [data, setData] = React.useState(null);
  const [error, setError] = React.useState(null);

  React.useEffect(() => {
    let cleanup;

    if (options.transport === 'sse') {
      // SSE transport
      const eventSource = new EventSource(endpoint);

      eventSource.onmessage = (event) => {
        setData(JSON.parse(event.data));
      };

      eventSource.onerror = (err) => {
        setError(err);
      };

      cleanup = () => {
        eventSource.close();
      };
    } else {
      // Polling transport (default)
      const abortController = new AbortController();

      const poll = async () => {
        try {
          const response = await fetch(endpoint, {
            signal: abortController.signal,
            credentials: 'include'
          });
          setData(await response.json());
        } catch (err) {
          if (err.name !== 'AbortError') setError(err);
        }
      };

      poll();
      const intervalId = setInterval(poll, options.interval || 1500);

      cleanup = () => {
        clearInterval(intervalId);
        abortController.abort();
      };
    }

    return cleanup;
  }, [endpoint, options.transport, options.interval]);

  return { data, error };
}
```

**Usage:**

```javascript
// Current: Polling
const { data } = useRealtimeData('/api/cache-status', {
  transport: 'polling',
  interval: 1500
});

// Future: SSE (change one prop)
const { data } = useRealtimeData('/api/cache-status', {
  transport: 'sse'
});
```

**Rationale for Abstraction:**

1. **Single Responsibility:** Each transport implementation handles its own lifecycle.
2. **Consistent Interface:** Component using the hook doesn't care about transport.
3. **Easy Migration:** Change transport via prop/config, no component refactor.
4. **Type Safety:** Both transports return same data shape.

**EventSource Details:**

- Browser-native API, zero dependencies
- Automatic reconnection on disconnect (default 3-second retry)
- Cannot set custom headers in constructor (authentication via URL params or cookies)
- For authenticated SSE, use `credentials: 'include'` on server endpoint or pass token in URL

**Sources:**
- [How to Implement SSE in React](https://oneuptime.com/blog/post/2026-01-15-server-sent-events-sse-react/view)
- [Using EventSource (SSE) with React Query](https://rustedcompiler.medium.com/using-eventsource-sse-with-react-query-b72e20923d8c)
- [SSE, WebSockets, or Polling? Build Real-Time Stock App](https://dev.to/itaybenami/sse-websockets-or-polling-build-a-real-time-stock-app-with-react-and-hono-1h1g)
- [Developing Real-Time Web Apps with SSE](https://auth0.com/blog/developing-real-time-web-applications-with-server-sent-events/)

**Confidence:** MEDIUM-HIGH - Pattern is sound and well-documented, but project-specific edge cases may require adjustments during SSE migration.

---

## Recommended Implementation Order

### Phase 1: Lightweight Status Endpoint (Go/Chi)
1. Create new route in `essentials` package: `GET /essentials/cache-status?zip={zip}`
2. Handler queries 3 cache tables (zip, state, federal) with GORM `Select("updated_at")`
3. Returns minimal JSON: `{"zip_fresh": bool, "state_fresh": bool, "federal_fresh": bool}`
4. Add indexes on `zip_code`, `state_code` if not present

**Expected Performance:** <10ms response time (3 indexed lookups, no JOINs)

### Phase 2: Frontend Polling Refactor (React)
1. Create `usePolling` custom hook with proper cleanup
2. Change Dashboard to poll `/cache-status` instead of `/politicians`
3. When all caches fresh → abort polling, fetch full `/politicians` once
4. Maintain existing AbortController for cleanup

**Expected Impact:** Reduces backend load by 95% during warming period (3 small table queries vs 1 multi-JOIN query)

### Phase 3: SSE Preparation (Optional - Future)
1. Refactor `usePolling` → `useRealtimeData` with transport param
2. Default to `transport: 'polling'` (no behavior change)
3. Update tests to verify both transports
4. When migrating to AWS: flip transport to 'sse', implement SSE handler

**Migration Risk:** LOW - Abstraction layer isolates changes, polling remains functional fallback

---

## Alternative Approaches Considered

| Approach | Why Not Recommended |
|----------|-------------------|
| WebSockets | Bidirectional overkill for unidirectional cache status. More complex than SSE. |
| GraphQL Subscriptions | Heavy dependency, requires new server setup. SSE simpler for single-direction updates. |
| Long Polling | More complex than short polling for this use case, no advantage over SSE for future migration. |
| Third-party SSE libraries on frontend | EventSource is browser-native and sufficient. Libraries add bundle size without value. |
| GORM `Exists()` helper | Doesn't exist yet ([Discussion #6000](https://github.com/go-gorm/gorm/discussions/6000)). `Take()` pattern achieves same performance. |

---

## Dependencies

### Current (No New Dependencies)
```bash
# Backend - Already in stack
go get github.com/go-chi/chi/v5
go get gorm.io/gorm

# Frontend - Already in stack
npm install react@19
```

### Future (SSE Migration - Optional)
```bash
# Backend - If stdlib SSE insufficient
go get github.com/tmaxmax/go-sse

# Frontend - Zero new dependencies (EventSource is browser-native)
```

---

## Performance Benchmarks (Expected)

| Scenario | Current (8 polls × full query) | Optimized (8 polls × status) | Improvement |
|----------|-------------------------------|------------------------------|-------------|
| Backend CPU per poll | ~50ms (multi-JOIN) | ~5ms (3 indexed lookups) | 10x faster |
| Network payload per poll | ~50KB JSON (politicians array) | ~50 bytes JSON (status object) | 1000x smaller |
| Total warming overhead | 400ms CPU, 400KB network | 40ms CPU, 400 bytes network | 10x reduction |

**Assumptions:** 8 polls during 12-second warming period, 50 politicians average per ZIP, indexed cache tables.

---

## Sources

### Go/Chi Backend
- [Chi Router GitHub](https://github.com/go-chi/chi)
- [Chi Router Documentation](https://go-chi.io/)
- [Go encoding/json Package](https://pkg.go.dev/encoding/json)
- [GORM Performance Documentation](https://gorm.io/docs/performance.html)
- [GORM Advanced Query](https://gorm.io/docs/advanced_query.html)

### Go SSE (Future Reference)
- [Writing SSE Server in Go - Thoughtbot](https://thoughtbot.com/blog/writing-a-server-sent-events-server-in-go)
- [Go Real-time Applications with SSE - OneUpTime](https://oneuptime.com/blog/post/2026-02-01-go-realtime-applications-sse/view)
- [alexandrevicenzi/go-sse GitHub](https://github.com/alexandrevicenzi/go-sse)
- [go-sse Chi Integration Example](https://github.com/alexandrevicenzi/go-sse/blob/master/_examples/chi.go)
- [tmaxmax/go-sse GitHub](https://github.com/tmaxmax/go-sse)

### React Polling
- [Best Practices for React Polling - DhiWise](https://www.dhiwise.com/post/a-guide-to-real-time-applications-with-react-polling)
- [Implementing Polling in React - Medium](https://medium.com/@sfcofc/implementing-polling-in-react-a-guide-for-efficient-real-time-data-fetching-47f0887c54a7)
- [AbortController Complete Guide - LocalCan](https://www.localcan.com/blog/abortcontroller-nodejs-react-complete-guide-examples)
- [Preventing Memory Leaks in React with useEffect](https://www.c-sharpcorner.com/article/preventing-memory-leaks-in-react-with-useeffect-hooks/)
- [React useEffect Cleanup Function - Refine](https://refine.dev/blog/useeffect-cleanup/)

### React SSE (Future Reference)
- [How to Implement SSE in React - OneUpTime](https://oneuptime.com/blog/post/2026-01-15-server-sent-events-sse-react/view)
- [Using EventSource (SSE) with React Query - Medium](https://rustedcompiler.medium.com/using-eventsource-sse-with-react-query-b72e20923d8c)
- [SSE, WebSockets, or Polling? - DEV](https://dev.to/itaybenami/sse-websockets-or-polling-build-a-real-time-stock-app-with-react-and-hono-1h1g)
- [Developing Real-Time Web Apps with SSE - Auth0](https://auth0.com/blog/developing-real-time-web-applications-with-server-sent-events/)
- [How to Implement EventSource and SSE - DEV](https://dev.to/lagoni/how-to-implement-eventsource-and-sse-in-your-frontend-and-backend-18co)

---

## Confidence Assessment

| Area | Confidence | Reasoning |
|------|------------|-----------|
| Go Chi status endpoint pattern | HIGH | Standard library patterns, matches existing codebase, well-documented |
| GORM lightweight queries | HIGH | Official GORM documentation, proven optimization techniques |
| React polling with cleanup | HIGH | Critical React patterns, extensively documented, prevents memory leaks |
| SSE-ready abstraction pattern | MEDIUM-HIGH | Sound architectural pattern, but untested in this specific codebase |
| Go SSE libraries | MEDIUM | Limited production usage data for this stack combination |
| EventSource browser support | HIGH | Native browser API, widely supported (IE11+, all modern browsers) |

**Overall Confidence:** HIGH for current optimization (Phases 1-2), MEDIUM-HIGH for future SSE migration preparation (Phase 3).
