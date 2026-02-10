# Project Research Summary

**Project:** Empowered Vote Essentials - Cache Status Polling Optimization
**Domain:** Progressive loading with cache warming for political data API
**Researched:** 2026-02-09
**Confidence:** HIGH

## Executive Summary

This optimization project addresses performance bottlenecks in the existing politician data loading system by introducing a lightweight cache-status endpoint and refactoring frontend polling logic. Currently, the frontend polls a heavyweight endpoint returning full politician datasets (50KB+) every 1.5 seconds during cache warming, resulting in excessive bandwidth usage, database load, and poor user experience during the 8-12 second warming period.

The recommended approach is a three-phase implementation: (1) add a lightweight cache-status endpoint in Go/Chi that returns minimal JSON (~200 bytes) from simple cache table queries, (2) refactor React 19 frontend to poll the status endpoint and fetch full data only once when ready, and (3) abstract the polling pattern using a strategy pattern to enable future SSE migration when moving to AWS infrastructure. This reduces bandwidth by 87%, database load by 62-87%, and perceived load time from 12 seconds to 2-4.5 seconds.

The critical risk is a TOCTOU (Time-Of-Check-Time-Of-Use) race condition where cache status changes between the status check and data fetch. This is mitigated by either returning status and data atomically in a single response, or including cache version tokens for validation. Other key risks include advisory lock contention during BallotReady API calls, frontend memory leaks from uncleaned polling timers, and backward compatibility during rolling deployments. All risks have well-documented prevention strategies.

## Key Findings

### Recommended Stack

The existing stack (Go 1.24.3, Chi router, GORM, PostgreSQL, React 19, Vite) requires no new dependencies for this optimization. The approach leverages Go's stdlib `encoding/json` for minimal JSON responses, GORM's `Select()` with indexed queries for lightweight cache checks, and React's `useEffect` + `AbortController` for proper polling cleanup. For future SSE migration, Go stdlib provides SSE capabilities without additional libraries, and browser-native EventSource API requires no frontend dependencies.

**Core technologies:**
- Chi Router (v5.x) — HTTP routing for status endpoint, already in stack, minimal and composable
- GORM with single-table queries — Lightweight cache status checks avoiding JOINs, <10ms response time
- React hooks (useState/useEffect/useRef) — Custom hook abstraction for poll/SSE strategy swap, zero new dependencies
- Strategy pattern — Enables poll→SSE migration via environment variable without component changes

**Future-ready (SSE migration):**
- Go stdlib `http.Flusher` or `tmaxmax/go-sse` — SSE server implementation when migrating to AWS
- Browser EventSource API — Native SSE client, no library needed

### Expected Features

Research identified clear distinctions between table stakes (must have), competitive differentiators (should have), and anti-features (explicitly avoid). The MVP should focus on core progressive loading improvements while deferring complex features like progress percentages and time estimates.

**Must have (table stakes):**
- Lightweight cache-status endpoint returning freshness state (fresh/warming/stale)
- Granular tier status (federal/state/local) for progressive display
- Exponential backoff polling (1s → 1.5s → 2s → 3s max 6s)
- Skeleton loading UI reducing perceived wait time by 40%
- Proper error handling with retry actions

**Should have (competitive):**
- Progressive result display (show federal/state immediately while local warms)
- Partial results flag ("Showing 8 of 15 officials")
- Containment status (which officials fully vs partially cover ZIP)
- Smart polling respecting Retry-After headers
- Optimistic UI showing stale data with "updating" indicator

**Defer (v2+):**
- Progress percentage tracking (nice-to-have, tier status provides sufficient feedback)
- Time estimates (requires historical data, hard to make accurate)
- Real-time SSE (defer until AWS migration, polling sufficient for 90-day TTL cache)

**Anti-features (do NOT build):**
- WebSocket for status updates (overkill for infrequent updates)
- Sub-second polling intervals (hammers server, BallotReady API is inherently slow)
- Per-politician progress tracking (too granular, adds DB overhead)
- Spinner-only loading (increases perceived wait time vs skeletons)

### Architecture Approach

The architecture maintains existing module patterns in EV-Backend (handlers/routes/models) while introducing minimal new components. Backend adds a single CacheStatusHandler to existing handlers.go with routes for each cache tier (zip/state/federal). Frontend introduces a usePoliticianData custom hook encapsulating polling logic with strategy pattern for future SSE swap. Critical architectural decision: status and data should be returned atomically in a single response to avoid TOCTOU race conditions, rather than separate endpoints.

**Major components:**

1. **CacheStatusHandler (backend)** — Queries single cache table (zip_caches/state_caches/federal_cache) with indexed WHERE clause, returns {fresh: bool, lastFetch: time, ttl: int} in ~200 bytes JSON
2. **usePoliticianData hook (frontend)** — Custom React hook exposing {politicians, loading, error} state, internally manages polling lifecycle with AbortController cleanup
3. **PollingStrategy (frontend)** — Encapsulates poll logic (status check → data fetch once ready), designed for easy swap to SSEStrategy via environment variable
4. **Data flow** — Status check (lightweight) → conditional full fetch (once) → progressive rendering, replacing current pattern of 8 full fetches

**Key patterns:**
- Lightweight status queries (single-row SELECT, no JOINs, <10ms)
- Proper cleanup with AbortController (prevents memory leaks)
- Strategy pattern for transport swapping (poll→SSE without component changes)
- Advisory locks only during DB operations (release before BallotReady API calls)

### Critical Pitfalls

Research identified 15 pitfalls across three severity levels. The top 5 critical pitfalls could cause rewrites or data corruption if not addressed upfront.

1. **TOCTOU race between status check and data fetch** — Cache status changes between API calls, user receives stale data marked as fresh. Prevent by returning status+data atomically, or using cache version tokens for validation.

2. **Advisory lock held during network I/O** — PostgreSQL lock held during 3-5 second BallotReady API call serializes all warming requests, destroying concurrency. Release lock before external API calls, re-acquire for DB upserts only.

3. **Frontend memory leak from uncleaned polling timers** — User navigates away mid-polling, setInterval continues firing, updating unmounted component. Use AbortController cleanup in useEffect return function.

4. **Cold miss returns before waitForDataMin completes** — Status endpoint returns "warming" but data endpoint has no rows yet, breaking progressive loading UX. Status and data must be unified or status must guarantee minimum row count.

5. **Backward incompatibility during rolling deployment** — Old frontend expects X-Data-Status header, new backend only returns JSON endpoint, 50% of users see broken UI during deployment. Support both header and endpoint for 1-2 week transition period.

**Moderate pitfalls:**
- N+1 query pattern from separate status+data calls (consider unified response)
- Polling interval mismatch (frontend 1.5s, backend 200ms) causing stuttering UX
- Excessive polling during traffic spikes (add jitter and exponential backoff)
- State normalization lost across Results/Dashboard/Home components (use canonical callback interface)

## Implications for Roadmap

Based on research, this optimization naturally divides into three phases with clear dependencies and incremental value delivery. Each phase addresses specific pitfalls and builds toward SSE-ready infrastructure.

### Phase 1: Lightweight Cache-Status Endpoint (Backend)

**Rationale:** Backend foundation must exist before frontend can be refactored. This phase is fully backward-compatible and can deploy independently without frontend changes. Creates lightweight status-check capability that reduces database load even for existing polling implementation.

**Delivers:**
- New route: `GET /essentials/cache-status/{type}/{identifier}` where type=zip|state|federal
- CacheStatusHandler querying single cache table with indexed lookups
- JSON response: `{fresh: bool, lastFetch: time, ttl: int, identifier: string}`
- Response time <10ms (3 indexed queries, no JOINs)
- Existing endpoints unchanged (maintains backward compatibility)

**Addresses features:**
- Lightweight cache-status endpoint (table stakes)
- Foundation for granular tier status (federal/state/local)

**Avoids pitfalls:**
- TOCTOU race (design decision: atomic response vs separate endpoints)
- Advisory lock contention (audit lock-holding duration during BallotReady calls)
- Backward compatibility (new endpoint doesn't break old clients)
- Cache-status response cacheability (add Cache-Control headers from start)

**Implementation notes:**
- Add CacheStatusHandler to existing `internal/essentials/handlers.go` (don't create new file)
- Register route in `internal/essentials/routes.go`
- Reuse existing cache models (ZipCache, StateCache, FederalCache)
- Add unit tests for fresh/stale/missing cache scenarios
- Deploy backend independently, frontend continues using old pattern

**Estimated effort:** 1-2 hours (handler + route + tests)

### Phase 2: Frontend Polling Refactor (React)

**Rationale:** With backend endpoint available, frontend can optimize polling to check lightweight status instead of fetching full datasets. This phase delivers immediate UX improvements (87% bandwidth reduction, 2-4.5s load times vs 12s) and prepares for SSE migration by abstracting polling logic.

**Delivers:**
- Custom hook: `usePoliticianData(identifier, type, options)` exposing {politicians, loading, error}
- API client functions: `checkCacheStatus()`, `fetchPoliticiansOnce()`
- Exponential backoff polling (1s → 1.5s → 2s → 3s → max 6s)
- AbortController cleanup preventing memory leaks
- Strategy pattern structure (PollingStrategy) for future SSE swap
- Migration of Dashboard.jsx, Results.jsx, Home.jsx to new hook

**Addresses features:**
- Exponential backoff polling (table stakes)
- Smart polling with Retry-After header respect (table stakes)
- Skeleton loading UI foundation (table stakes)
- Progressive result display readiness (differentiator)

**Avoids pitfalls:**
- Frontend memory leaks (AbortController cleanup in useEffect)
- State normalization issues (canonical ProgressUpdate callback interface)
- Polling interval mismatch (configurable intervals per component)
- Prop drilling (hook encapsulation with sensible defaults)

**Implementation notes:**
- Create `essentials/src/hooks/usePoliticianData.js`
- Add `checkCacheStatus()` and `fetchPoliticiansOnce()` to `essentials/src/lib/api.jsx`
- Keep `fetchPoliticiansProgressive()` for backward compatibility, mark deprecated
- Migrate components one-by-one: Dashboard → Results → Home
- Test cleanup: verify AbortController prevents memory leaks on navigation
- Measure performance: network tab should show 1-4 status checks + 1 data fetch (not 8 data fetches)

**Estimated effort:** 4-6 hours (hook + API + migration + testing)

### Phase 3: SSE Preparation (Future-Ready Abstraction)

**Rationale:** While SSE implementation is deferred until AWS migration, the abstraction layer should be designed now to avoid future refactoring. This phase doesn't change behavior (still uses polling) but structures code for easy transport swap via environment variable.

**Delivers:**
- Strategy interface: `DataFetchStrategy` with `start()`, `stop()` methods
- PollingStrategy implementation (current behavior extracted)
- SSEStrategy stub implementation (documented, not deployed)
- Factory function: `createFetchStrategy()` selecting based on `VITE_FEATURE_SSE` env var
- Updated `usePoliticianData` hook using strategy pattern
- Documentation for SSE backend endpoint specification

**Addresses features:**
- Future SSE readiness (enables instant cache-ready notifications)
- Transport-agnostic abstraction (easy A/B testing of poll vs SSE)

**Avoids pitfalls:**
- Future refactoring when adding SSE (abstraction exists upfront)
- Component coupling to transport mechanism (strategy swap via config only)

**Implementation notes:**
- Create `essentials/src/strategies/DataFetchStrategy.js` with base class
- Extract polling logic from hook into PollingStrategy class
- Create SSEStrategy stub with EventSource (not deployed, documented only)
- Update hook to use `createFetchStrategy()` factory
- No behavior change: VITE_FEATURE_SSE defaults to false, uses PollingStrategy
- Document SSE backend endpoint contract for future Phase 4 implementation

**Estimated effort:** 2-3 hours (strategy extraction + abstraction + documentation)

### Phase 4: SSE Implementation (Future - AWS Migration)

**Rationale:** Deferred until AWS infrastructure migration (current Render deployment may not support long-lived SSE connections reliably). When ready, SSE reduces polling overhead to single persistent connection with sub-second cache-ready notifications. This phase is fully non-breaking: strategy swap happens via environment variable, components unchanged.

**Delivers:** (future)
- Backend SSE endpoint: `GET /essentials/cache-status/{type}/{identifier}/stream`
- Go stdlib SSE implementation with `http.Flusher` or `tmaxmax/go-sse` library
- Event emission: `cache-ready`, `cache-warming`, `error` events
- Frontend SSEStrategy activation via `VITE_FEATURE_SSE=true`
- Gradual rollout with feature flag (5% → 50% → 100%)

**Phase dependencies:** Requires Phase 1 (backend endpoint) and Phase 3 (strategy abstraction) complete. Can skip Phase 3 and implement SSE directly, but requires refactoring hook at that time.

### Phase Ordering Rationale

- **Backend before frontend:** Phase 1 must complete before Phase 2 integration testing, but development can be parallel if OpenAPI spec or mock endpoint provided.
- **Polling optimization before SSE:** Phase 2 delivers immediate value (87% improvement) without architectural risk of SSE. Validates assumptions about cache warming patterns before committing to SSE.
- **Abstraction before implementation:** Phase 3 structures code for SSE while still using proven polling transport. De-risks Phase 4 by ensuring component decoupling works correctly.
- **Backward compatibility first:** Each phase maintains compatibility with previous versions, enabling safe incremental rollout and easy rollback.
- **Pitfall prevention early:** Critical pitfalls (TOCTOU, lock contention, memory leaks) addressed in Phase 1-2 design, not retrofitted later.

### Research Flags

**Phases with standard patterns (skip additional research):**
- **Phase 1 (Backend endpoint):** Well-documented Chi + GORM patterns, matches existing handlers.go conventions. Research complete.
- **Phase 2 (Frontend hook):** Standard React hooks patterns, polling abstraction widely used. Research complete.
- **Phase 3 (Strategy pattern):** Common JavaScript/React pattern, well-established. Research complete.

**Phases needing deeper research during implementation:**
- **Phase 4 (SSE implementation):** Research provided Go SSE patterns but codebase-specific integration (Chi middleware, CORS, authentication with cookies) needs validation during implementation. Test SSE cookie authentication in Render environment vs AWS environment. May need to defer until AWS migration.

**Validation points during implementation:**
- Phase 1: Measure actual cache status query performance (target <10ms). Verify advisory lock holding duration during BallotReady calls (should release before external I/O).
- Phase 2: Load test frontend with 10 concurrent ZIP searches. Verify memory doesn't leak on repeated navigation (Chrome DevTools memory profiler).
- Phase 3: Verify strategy swap works via env var without component changes. Document SSE endpoint contract for future implementation.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Standard library patterns, matches existing codebase conventions, zero new dependencies |
| Features | HIGH | Clear distinctions between table stakes/differentiators/anti-features based on UX research and async API patterns |
| Architecture | HIGH | Backend handler pattern matches existing EV-Backend modules, React hooks are standard, strategy pattern widely used |
| Pitfalls | HIGH | Well-documented race conditions, lock contention, memory leaks with clear prevention strategies and detection methods |

**Overall confidence:** HIGH

Research is comprehensive with official documentation sources (Go stdlib, GORM docs, React docs), industry best practices (async REST patterns, polling best practices, SSE patterns), and project-specific context (existing handlers.go patterns, cache architecture). All recommendations map directly to existing codebase patterns.

### Gaps to Address

While overall confidence is high, these areas need validation during implementation:

- **Advisory lock holding duration:** Research identifies lock contention risk but doesn't measure actual duration in current codebase. Phase 1 must audit warmLocal functions to verify locks are released before BallotReady API calls. Add logging to measure lock hold time.

- **TOCTOU race mitigation decision:** Research presents three options (atomic response, version tokens, timestamp validation). Architecture document recommends atomic response (single endpoint returning status+data), but this conflicts with separate status endpoint approach. **Decision needed in Phase 1:** Unified response (status+data) vs separate endpoints with versioning. Recommendation: Start with separate endpoints + cached_at timestamp validation, consolidate if TOCTOU issues observed.

- **Polling interval optimization:** Frontend polls every 1.5s, backend waitForDataMin polls DB every 200ms. Research notes potential mismatch but doesn't validate optimal intervals. Phase 2 should A/B test intervals (500ms, 1000ms, 1500ms) to balance UX smoothness vs server load.

- **SSE authentication with cookies:** Research confirms EventSource supports cookies but doesn't validate with EV-Backend's current session-based auth (HTTP-only cookies). Phase 4 must verify SSE connections include cookies automatically or require URL-based token authentication.

- **Connection pool impact under load:** Research identifies potential exhaustion (waitForDataMin polls every 200ms) but doesn't measure current pool utilization. Phase 1 should baseline DB connection pool metrics before optimization to validate improvement.

**How to handle during implementation:**
- Phase 1: Add observability (lock hold time, query performance, connection pool metrics) BEFORE implementing optimization to establish baseline.
- Phase 1 decision point: TOCTOU race mitigation strategy (atomic vs separate endpoints) based on measured race frequency in staging.
- Phase 2: Gradual rollout (Dashboard first, Results second, Home last) with performance monitoring to validate improvements match research estimates.
- Phase 4: Feature flag SSE in staging environment for 1-2 weeks to validate cookie authentication before production rollout.

## Sources

### Primary (HIGH confidence)

**Go/Chi backend patterns:**
- Go Chi router documentation: https://go-chi.io (official routing patterns)
- Go encoding/json package: https://pkg.go.dev/encoding/json (minimal JSON output)
- GORM Performance Documentation: https://gorm.io/docs/performance.html (Select() optimization)
- GORM Advanced Query: https://gorm.io/docs/advanced_query.html (lightweight queries)
- GORM GitHub Discussion #6000: https://github.com/go-gorm/gorm/discussions/6000 (Exists() method status)

**React patterns:**
- React useEffect documentation: https://react.dev/reference/react/hooks (official patterns)
- React useEffect Cleanup: https://refine.dev/blog/useeffect-cleanup/ (cleanup function best practices)
- AbortController Complete Guide: https://www.localcan.com/blog/abortcontroller-nodejs-react-complete-guide-examples
- Preventing Memory Leaks in React: https://www.c-sharpcorner.com/article/preventing-memory-leaks-in-react-with-useeffect-hooks/

**SSE patterns (future):**
- Writing SSE Server in Go - Thoughtbot: https://thoughtbot.com/blog/writing-a-server-sent-events-server-in-go
- Go Real-time Applications with SSE - OneUpTime: https://oneuptime.com/blog/post/2026-02-01-go-realtime-applications-sse/view
- alexandrevicenzi/go-sse GitHub: https://github.com/alexandrevicenzi/go-sse (Chi integration example)
- tmaxmax/go-sse GitHub: https://github.com/tmaxmax/go-sse (spec-compliant library)
- MDN EventSource API: https://developer.mozilla.org/en-US/docs/Web/API/EventSource (browser support)

**Async API patterns:**
- Microsoft Asynchronous Request-Reply pattern: https://learn.microsoft.com/en-us/azure/architecture/patterns/async-request-reply
- REST API Design for Long-Running Tasks: https://restfulapi.net/rest-api-design-for-long-running-tasks/
- Adidas API Guidelines Polling: https://adidas.gitbook.io/api-guidelines/rest-api-guidelines/execution/long-running-tasks/polling

**Loading UX patterns:**
- Nielsen Norman Group: Skeleton Screens 101: https://www.nngroup.com/articles/skeleton-screens/
- LogRocket: Skeleton Loading Screen Design: https://blog.logrocket.com/ux-design/skeleton-loading-screen-design/
- Carbon Design: Loading Patterns: https://carbondesignsystem.com/patterns/loading-pattern/

### Secondary (MEDIUM confidence)

**Race conditions and caching:**
- Race Conditions in REST APIs Developer's Guide: https://medium.com/@mgaurang123/race-conditions-in-rest-apis-a-developers-guide-to-building-reliable-systems-42d4f8eabc1e
- When Caches Collide Solving Race Conditions: https://dzone.com/articles/fare-cache-race-conditions-troubleshooting
- Ultimate Caching Definition: https://stack.convex.dev/caching-in

**TOCTOU (Time-of-Check-Time-of-Use):**
- Wikipedia TOCTOU: https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use
- CWE-367 TOCTOU Race Condition: https://cwe.mitre.org/data/definitions/367.html
- TOCTOU Leads to Broken Authentication: https://infosecwriteups.com/time-of-check-time-of-use-toctou-race-condition-leads-to-broken-authentication-critical-finding-b55993c92abc

**PostgreSQL advisory locks:**
- Using PostgreSQL Advisory Locks to Avoid Race Conditions: https://firehydrant.com/blog/using-advisory-locks-to-avoid-race-conditions-in-rails/
- How to Use Advisory Locks in PostgreSQL: https://oneuptime.com/blog/post/2026-01-25-use-advisory-locks-postgresql/view
- PostgreSQL Advisory Locks: https://www.netguru.com/blog/advisory-locks

**API versioning and backward compatibility:**
- API Versioning Best Practices: https://www.gravitee.io/blog/api-versioning-best-practices
- Handling API Versioning and Backward Compatibility: https://dev.to/neelendra_tomar_27/handling-api-versioning-and-backward-compatibility-on-the-frontend-297p
- Avoiding Backward Compatibility Breaks: https://medium.com/carvago-development/avoiding-backward-compatibility-breaks-in-api-design-a-developers-guide-b6b4d280d423

**Cache warming:**
- Cache Warming Explained Aerospike: https://aerospike.com/blog/cache-warming-explained
- Cache Warming Strategies OneUpTime: https://oneuptime.com/blog/post/2026-01-30-cache-warming-strategies/view
- Cold and Warm Cache in System Design: https://www.geeksforgeeks.org/system-design/cold-and-warm-cache-in-system-design/

### Tertiary (contextual references)

**Project-specific patterns:**
- EV-Backend module structure: internal/essentials/, internal/compass/, internal/treasury/ (established patterns)
- Existing progressive loading: essentials/src/lib/api.jsx fetchPoliticiansProgressive() (current implementation)
- Cache architecture: federal_cache, state_caches, zip_caches with 90-day TTL (verified in codebase)

---

*Research completed: 2026-02-09*
*Ready for roadmap: yes*
