# Feature Landscape

**Domain:** Cache Status API & Background Data Loading UX
**Researched:** 2026-02-09

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| HTTP 202 Accepted for async operations | Industry standard for long-running operations | Low | Backend already returns 202, just needs consistency |
| Status endpoint returning current state | Core async pattern - clients need to know if data is ready | Low | New endpoint: GET /essentials/cache/status |
| Overall cache freshness indicator | Users need to know if they're seeing fresh vs stale data | Low | Backend already has this logic (X-Data-Status header) |
| Retry-After header on 202 responses | Standard HTTP mechanism for polling guidance | Low | Backend already returns this, just needs verification |
| Exponential backoff for polling | Prevents server overload, industry best practice | Medium | Client-side implementation, needs tuning per tier |
| Skeleton loading UI | Reduces perceived wait time by 40% vs spinners | Medium | React component with shimmer animation |
| Error state handling | Warmers can fail - users need clear messaging | Low | Display API errors, provide retry action |
| Automatic reconnection on network failure | Mobile users expect resilient connections | Medium | Already handles via polling loop, needs testing |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Granular tier status (federal/state/local) | Shows which data is ready, enables progressive display | Medium | Status per tier: fresh/stale/warming/warmed |
| Progressive result display | Show federal officials immediately while local warms | Medium | Display as each tier completes |
| Progress indication with percentage | Reduces anxiety for longer waits (>5s) | Medium | Track warmer progress, return % complete |
| Time estimate (time anchors) | "About 10 seconds" feels better than spinner | High | Needs historical timing data per tier |
| Estimated completion time in status | Helps clients optimize polling intervals | High | Calculate based on typical BallotReady API latency |
| Partial results flag | Clearly communicate "showing 8 of 15 officials" | Low | Backend already knows this, just expose it |
| Containment status in response | Show which officials fully vs partially cover ZIP | Low | Backend has is_contained field, just expose it |
| Smart polling with dynamic intervals | Faster polls initially, slower if taking long | Medium | Client adjusts based on Retry-After and progress |
| Visual indication of data completeness | Progress bar or badge showing cache coverage | Medium | Requires percentage from status endpoint |
| Optimistic UI for cached data | Show stale data immediately with "updating" indicator | Low | Frontend pattern, backend already returns stale data |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| WebSocket for status updates | Overkill for infrequent updates (every 1-2s) | Stick with HTTP polling with smart intervals |
| Real-time SSE for cache status | Adds complexity, not needed for 90-day TTL cache | Use status endpoint with exponential backoff |
| Per-politician progress tracking | Too granular, adds DB overhead | Track at tier level (federal/state/local) |
| Cache status in main data endpoint | Keeps data endpoint heavy during warming | Separate lightweight status endpoint |
| Sub-second polling intervals | Hammers server, BallotReady API is inherently slow | Minimum 1s, typical 1.5-3s with backoff |
| Manual "refresh" button | Implies broken auto-refresh, confuses users | Auto-polling handles everything |
| Spinner-only loading state | Increases perceived wait time | Use skeleton screens showing expected layout |
| "Loading..." text without context | Doesn't explain what's loading or why | "Finding your elected officials..." with tier context |
| Time remaining countdown to the second | Feels torturous and often inaccurate | Use time anchors (5s, 10s, 15s, 30s) |
| Polling without backoff | Wastes bandwidth, server resources | Exponential backoff with Retry-After hints |

## Feature Dependencies

```
Overall cache status → Granular tier status (tier status enables overall)
Granular tier status → Progressive result display (can't show progressively without knowing tier status)
Granular tier status → Progress indication (needs per-tier completion to calculate %)
Progress indication → Time estimate (% enables remaining time calculation)
Status endpoint → Smart polling (status data informs polling intervals)
Partial results flag → Visual completeness indicator (flag enables UI badge/message)
Skeleton loading → Optimistic UI (skeleton is baseline, optimistic builds on it)
```

## MVP Recommendation

Prioritize:

1. **Status endpoint with overall cache state** (table stakes, low complexity)
   - GET /essentials/cache/status?zip={zip}
   - Returns: { status: "fresh"|"stale"|"warming"|"warmed", retry_after: 2 }

2. **Granular tier status** (differentiator, medium complexity)
   - Extends status endpoint: { tiers: { federal: "fresh", state: "fresh", local: "warming" } }

3. **Skeleton loading UI** (table stakes, medium complexity)
   - Shows 3 cards (Federal/State/Local) with shimmer animation
   - Much better perceived performance than spinner

4. **Progressive result display** (differentiator, medium complexity)
   - Display federal/state immediately if fresh
   - Show "Loading local officials..." skeleton for warming tier
   - Update when local tier completes

5. **Smart polling with exponential backoff** (table stakes, medium complexity)
   - Start: 1s interval
   - If still warming: 1.5s → 2s → 3s → 4s → 6s (max)
   - Respect Retry-After header when provided
   - Max 8 attempts (16-20s total) then show "Taking longer than expected" message

6. **Partial results flag** (differentiator, low complexity)
   - Status returns: { partial: true, loaded: 8, expected: 15 }
   - UI shows: "Showing 8 of 15 officials (updating...)"

Defer:

- **Progress percentage** (differentiator, medium complexity) - Nice to have, but tier status gives enough feedback
- **Time estimates** (differentiator, high complexity) - Requires historical data collection, accuracy is hard
- **Optimistic UI with stale data** (differentiator, low complexity) - MVP can work with skeleton only, add later for smoother UX

## Implementation Phases

### Phase 1: Core Status Endpoint (Week 1)
- Backend: Create /essentials/cache/status endpoint
- Returns overall status + granular tier status
- Includes partial results metadata
- Respects existing X-Data-Status header logic

### Phase 2: Frontend Polling Refactor (Week 1-2)
- Replace data endpoint polling with status endpoint polling
- Implement exponential backoff (1s → 1.5s → 2s → 3s → max 6s)
- Respect Retry-After header
- Max 8 polls then fetch data regardless

### Phase 3: Progressive Loading UX (Week 2)
- Skeleton loading for each tier (Federal/State/Local cards)
- Display ready tiers immediately
- Show loading skeleton for warming tiers
- Update as each tier completes

### Phase 4: Polish (Week 3)
- Visual indicators for partial results
- "Taking longer than expected" message after 20s
- Error states with retry action
- Automatic reconnection testing

## UX Flow Example

**User searches ZIP 12345, cache is stale:**

1. **T=0s**: Dashboard shows 3 skeleton cards (Federal/State/Local with shimmer)
   - Status: POST /search → 202 Accepted, Retry-After: 2
   - Backend: Kicks warmers for all 3 tiers

2. **T=1s**: Poll 1 → Status endpoint
   - Response: { status: "warming", tiers: { federal: "warming", state: "warming", local: "warming" } }
   - UI: Continue showing skeletons

3. **T=2.5s**: Poll 2 (1.5s interval)
   - Response: { status: "warming", tiers: { federal: "warmed", state: "warmed", local: "warming" } }
   - UI: Replace Federal/State skeletons with actual official cards, keep Local skeleton

4. **T=4.5s**: Poll 3 (2s interval)
   - Response: { status: "warming", tiers: { federal: "warmed", state: "warmed", local: "warming" }, partial: true, loaded: 10, expected: 15 }
   - UI: Show banner "Showing 10 of 15 local officials (updating...)"

5. **T=7.5s**: Poll 4 (3s interval)
   - Response: { status: "warmed", tiers: { federal: "warmed", state: "warmed", local: "warmed" } }
   - UI: Fetch full data, update Local section with all 15 officials, remove banner

**User searches ZIP 54321, cache is fresh:**

1. **T=0s**: Dashboard shows 3 skeleton cards
   - Status: POST /search → 200 OK with data
   - UI: Immediately replace skeletons with actual officials (no polling needed)

## API Design Specification

### Status Endpoint

**Request:**
```
GET /essentials/cache/status?zip=12345
```

**Response (warming):**
```json
{
  "status": "warming",
  "retry_after": 2,
  "tiers": {
    "federal": "warmed",
    "state": "warmed",
    "local": "warming"
  },
  "partial": true,
  "counts": {
    "federal": 5,
    "state": 8,
    "local": 10,
    "expected_local": 15
  },
  "timestamp": "2026-02-09T10:30:45Z"
}
```

**Response (fresh):**
```json
{
  "status": "fresh",
  "tiers": {
    "federal": "fresh",
    "state": "fresh",
    "local": "fresh"
  },
  "counts": {
    "federal": 5,
    "state": 8,
    "local": 15
  },
  "cached_at": "2026-02-08T14:20:00Z",
  "timestamp": "2026-02-09T10:30:45Z"
}
```

**Status values:**
- `fresh` - Cache is current (< 90 days old)
- `stale` - Cache exists but expired, returning stale data
- `warming` - Background warmers are actively fetching from BallotReady
- `warmed` - Warming completed, fresh data available

### Modified Search Endpoint Behavior

**Address Search:**
```
POST /essentials/politicians/search
Body: { "address": "123 Main St, Anytown, ST 12345" }
```

**Response when fresh:**
```
Status: 200 OK
X-Data-Status: fresh
X-Cache-Age: 2d

[...politician data...]
```

**Response when stale (kicks warmers):**
```
Status: 202 Accepted
X-Data-Status: warming
Retry-After: 2

[...stale politician data or empty array...]
```

## Polling Algorithm (Client)

```javascript
async function pollCacheStatus(zip, maxAttempts = 8) {
  const intervals = [1000, 1500, 2000, 3000, 4000, 6000, 6000, 6000]; // ms

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const status = await fetch(`/essentials/cache/status?zip=${zip}`);
    const data = await status.json();

    if (data.status === 'warmed' || data.status === 'fresh') {
      return data; // Done!
    }

    // Respect Retry-After if provided
    const delay = data.retry_after
      ? data.retry_after * 1000
      : intervals[attempt];

    await sleep(delay);
  }

  // Max attempts reached, fetch data anyway
  return { status: 'timeout' };
}
```

## Complexity Assessment

| Feature | Backend Effort | Frontend Effort | Risk |
|---------|---------------|-----------------|------|
| Status endpoint | 2-3 hours | - | Low (reuses existing cache logic) |
| Granular tier status | 2-4 hours | - | Low (cache tables already separated) |
| Polling refactor | - | 4-6 hours | Medium (needs careful state management) |
| Skeleton loading | - | 3-4 hours | Low (UI component only) |
| Progressive display | 1 hour | 4-5 hours | Medium (coordinate tier updates) |
| Partial results | 1-2 hours | 2 hours | Low (straightforward counting) |
| Smart backoff | - | 2-3 hours | Low (well-established pattern) |

**Total MVP estimate:** 6-12 hours backend, 15-20 hours frontend = 21-32 hours

## Success Metrics

**Performance:**
- Status endpoint responds in < 100ms (database query only, no external API)
- Average time to display first results: < 2s (federal/state tiers)
- Average time to complete display: < 8s (all tiers)
- Reduced API calls during warming: 8+ polls to data endpoint → 3-4 polls to status endpoint

**UX:**
- Perceived wait time reduction: 40% (skeleton vs spinner)
- User sees partial results within 2-3s instead of waiting 8-10s
- Clear communication when data is incomplete
- No confused users wondering if page is broken

## Sources

### Async API Patterns
- [Asynchronous Operations in REST APIs](https://zuplo.com/learning-center/asynchronous-operations-in-rest-apis-managing-long-running-tasks)
- [Microsoft: Asynchronous Request-Reply pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/async-request-reply)
- [REST API Design for Long-Running Tasks](https://restfulapi.net/rest-api-design-for-long-running-tasks/)
- [Adidas API Guidelines: Polling](https://adidas.gitbook.io/api-guidelines/rest-api-guidelines/execution/long-running-tasks/polling)

### HTTP Headers
- [HTTP Headers: Retry-After Patterns](https://thelinuxcode.com/http-headers-retry-after-practical-patterns-pitfalls-and-production-ready-use/)
- [Retry-After Header Guide](https://http.dev/retry-after)
- [MDN: Retry-After header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Retry-After)
- [Retry-After in Practice](https://nurkiewicz.com/2015/02/retry-after-http-header-in-practice.html)

### Caching Best Practices
- [Speakeasy: Caching Best Practices in REST API Design](https://www.speakeasy.com/api-design/caching)
- [API Caching Strategies](https://blog.dreamfactory.com/api-caching-strategies-challenges-and-examples)
- [CloudThat: API Gateway Caching Strategies](https://www.cloudthat.com/resources/blog/api-gateway-caching-strategies-for-high-performance-apis)

### Loading UX Patterns
- [NN/G: Skeleton Screens 101](https://www.nngroup.com/articles/skeleton-screens/)
- [LogRocket: Skeleton Loading Screen Design](https://blog.logrocket.com/ux-design/skeleton-loading-screen-design/)
- [Carbon Design: Loading Patterns](https://carbondesignsystem.com/patterns/loading-pattern/)
- [Medium: 6 Loading State Patterns That Feel Premium](https://medium.com/uxdworld/6-loading-state-patterns-that-feel-premium-716aa0fe63e8)

### Progress Indication
- [UserGuiding: Progress Trackers and Indicators](https://userguiding.com/blog/progress-trackers-and-indicators)
- [NN/G: Progress Indicators Make a Slow System Less Insufferable](https://www.nngroup.com/articles/progress-indicators/)
- [Prototypr: Guidelines for Time Indication and Progress Bars](https://blog.prototypr.io/guidelines-for-time-indication-and-progress-bars-in-user-interaction-design-4d5038084c84)
- [Mobbin: Progress Indicator UI Design](https://mobbin.com/glossary/progress-indicator)

### Real-Time Updates
- [SSE vs WebSockets vs Long Polling 2025](https://dev.to/haraf/server-sent-events-sse-vs-websockets-vs-long-polling-whats-best-in-2025-5ep8)
- [RxDB: WebSockets vs SSE vs Polling](https://rxdb.info/articles/websockets-sse-polling-webrtc-webtransport.html)
- [ByteByteGo: Short/Long Polling, SSE, WebSocket](https://bytebytego.com/guides/shortlong-polling-sse-websocket/)
- [Ably: WebSockets vs SSE](https://ably.com/blog/websockets-vs-sse)

### Cache Warming
- [Cache Warming Explained: Aerospike](https://aerospike.com/blog/cache-warming-explained)
- [OneUpTime: Cache Warming Strategies 2026](https://oneuptime.com/blog/post/2026-01-30-cache-warming-strategies/view)
- [GeeksforGeeks: Cold and Warm Cache in System Design](https://www.geeksforgeeks.org/system-design/cold-and-warm-cache-in-system-design/)
- [Fasterize: Cache Warming Why and How](https://www.fasterize.com/en/blog/cache-warming-why-and-how/)

### API Design Granularity
- [Medium: API Design Granularity Concerns](https://medium.com/@mikolunar/api-design-granularity-concerns-part-1-da596eda3696)
- [DZone: RESTful API Design Principle Granularity](https://dzone.com/articles/restful-api-design-principle-deciding-levels-of-gr)
- [Nordic APIs: How Granular Should You Design APIs](https://nordicapis.com/how-granular-should-you-design-apis/)

### Optimistic UI
- [React: useOptimistic](https://react.dev/reference/react/useOptimistic)
- [LogRocket: Understanding Optimistic UI React Hook](https://blog.logrocket.com/understanding-optimistic-ui-react-useoptimistic-hook/)
- [FreeCodeCamp: Optimistic UI Pattern](https://www.freecodecamp.org/news/how-to-use-the-optimistic-ui-pattern-with-the-useoptimistic-hook-in-react/)
- [RxDB: Building Optimistic UI](https://rxdb.info/articles/optimistic-ui.html)
