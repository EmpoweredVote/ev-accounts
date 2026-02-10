# Requirements: Essentials Cache Polling Optimization

**Defined:** 2026-02-09
**Core Value:** When a user searches a ZIP code, they get their politicians fast without the backend being hammered by redundant expensive queries during cache warming.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Backend Status Endpoint

- [ ] **BKND-01**: Backend exposes `GET /essentials/cache-status/{zip}` that returns per-tier freshness (federal, state, local) as booleans plus an overall `allFresh` flag
- [ ] **BKND-02**: Cache status endpoint responds in under 100ms using only indexed cache table lookups (no JOINs, no politician data)
- [ ] **BKND-03**: Cache status endpoint returns `warming` boolean indicating if background warming is in progress
- [ ] **BKND-04**: Cache status response includes `Retry-After` header when warming is in progress
- [ ] **BKND-05**: Cache status response includes `Server-Timing` header with query duration
- [ ] **BKND-06**: Existing `/essentials/politicians/{zip}` endpoint behavior is unchanged (backward compatible)

### Frontend Polling Refactor

- [ ] **FRNT-01**: Frontend polls `cache-status/{zip}` endpoint instead of full politicians endpoint during cache warming
- [ ] **FRNT-02**: Frontend makes a single full data fetch to `/essentials/politicians/{zip}` only after status confirms `allFresh: true`
- [ ] **FRNT-03**: All polling uses AbortController with proper cleanup on component unmount to prevent memory leaks
- [ ] **FRNT-04**: Polling uses exponential backoff (1s, 1.5s, 2s, 3s) instead of fixed 1.5s intervals
- [ ] **FRNT-05**: Custom `usePoliticianData` hook encapsulates status polling, data fetching, and state management
- [ ] **FRNT-06**: Hook exposes consistent API that can be swapped from polling to SSE transport in the future
- [ ] **FRNT-07**: Dashboard.jsx, Results.jsx, and Home.jsx all use the new hook (no callers left on old polling pattern)
- [ ] **FRNT-08**: Cold miss case (no cached data, warmer in progress) shows appropriate loading state without errors

## v2 Requirements

Deferred to future milestone (AWS migration).

- **SSE-01**: Backend exposes SSE endpoint for real-time cache status updates
- **SSE-02**: Frontend hook supports SSE transport via environment variable toggle
- **SSE-03**: Progressive display shows federal/state data immediately while local cache warms

## Out of Scope

| Feature | Reason |
|---------|--------|
| Redis for cache status | Postgres indexed lookup is fast enough; avoids new infrastructure dependency |
| WebSocket infrastructure | Overkill for unidirectional status updates |
| Changes to cache TTL (90-day) | Current TTL is working well |
| Changes to warming logic or advisory locks | Current concurrency pattern is sound |
| Changes to address search flow | Already returns immediately, no polling issue |
| Mobile-specific polling optimizations | Can be added later if needed |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BKND-01 | Phase 1 | Pending |
| BKND-02 | Phase 1 | Pending |
| BKND-03 | Phase 1 | Pending |
| BKND-04 | Phase 1 | Pending |
| BKND-05 | Phase 1 | Pending |
| BKND-06 | Phase 1 | Pending |
| FRNT-01 | Phase 2 | Pending |
| FRNT-02 | Phase 2 | Pending |
| FRNT-03 | Phase 2 | Pending |
| FRNT-04 | Phase 2 | Pending |
| FRNT-05 | Phase 2 | Pending |
| FRNT-06 | Phase 3 | Pending |
| FRNT-07 | Phase 2 | Pending |
| FRNT-08 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0

---
*Requirements defined: 2026-02-09*
*Last updated: 2026-02-10 after roadmap creation (traceability added)*
