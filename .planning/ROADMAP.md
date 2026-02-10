# Roadmap: Essentials Cache Polling Optimization

## Overview

This optimization transforms the Essentials politician lookup flow from heavyweight polling (8 full queries during cache warming) to lightweight status checks with a single data fetch. Three phases deliver incremental value: backend gains a fast cache-status endpoint, frontend refactors polling logic into a custom hook with exponential backoff, and the architecture prepares for future SSE migration with a strategy pattern abstraction.

## Phases

- [x] **Phase 1: Backend Cache Status Endpoint** - Lightweight status-check endpoint for cache freshness *(completed 2026-02-10)*
- [ ] **Phase 2: Frontend Polling Optimization** - Custom hook with status polling and single data fetch
- [ ] **Phase 3: SSE Preparation** - Strategy pattern for future transport swap

## Phase Details

### Phase 1: Backend Cache Status Endpoint
**Goal**: Backend provides fast cache-status checks without expensive JOIN queries

**Depends on**: Nothing (first phase)

**Requirements**: BKND-01, BKND-02, BKND-03, BKND-04, BKND-05, BKND-06

**Success Criteria** (what must be TRUE):
  1. Backend responds to cache-status requests in under 100ms
  2. Backend returns per-tier freshness data (federal/state/local) with warming status
  3. Backend includes Retry-After and Server-Timing headers in cache-status responses
  4. Existing /essentials/politicians/{zip} endpoint behavior is unchanged (backward compatible)

**Plans:** 1 plan

Plans:
- [x] 01-01-PLAN.md — Implement cache status endpoint (handler, helpers, route registration)

### Phase 2: Frontend Polling Optimization
**Goal**: Users experience 2-4x faster load times with 80%+ reduction in network traffic

**Depends on**: Phase 1

**Requirements**: FRNT-01, FRNT-02, FRNT-03, FRNT-04, FRNT-05, FRNT-07, FRNT-08

**Success Criteria** (what must be TRUE):
  1. Users see appropriate loading states during cold cache warming without errors
  2. Network traffic reduced by 80%+ during cache warming (1 data fetch instead of 8)
  3. Components unmount cleanly without memory leaks from polling timers
  4. All three components (Dashboard.jsx, Results.jsx, Home.jsx) use the optimized hook
  5. Polling uses exponential backoff (1s -> 1.5s -> 2s -> 3s) instead of fixed intervals

**Plans**: TBD (to be determined during phase planning)

Plans:
- [ ] 02-01: TBD
- [ ] 02-02: TBD
- [ ] 02-03: TBD

### Phase 3: SSE Preparation
**Goal**: Codebase is ready for SSE migration with minimal future changes

**Depends on**: Phase 2

**Requirements**: FRNT-06

**Success Criteria** (what must be TRUE):
  1. Hook API remains stable when swapping polling for SSE transport
  2. Strategy pattern documented and tested with mock SSE implementation
  3. Environment variable toggles transport mechanism without code changes

**Plans**: TBD (to be determined during phase planning)

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Backend Cache Status Endpoint | 1/1 | ✓ Complete | 2026-02-10 |
| 2. Frontend Polling Optimization | 0/TBD | Not started | - |
| 3. SSE Preparation | 0/TBD | Not started | - |

---
*Roadmap created: 2026-02-10*
*Last updated: 2026-02-10 — Phase 1 complete*
