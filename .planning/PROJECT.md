# Essentials Cache Polling Optimization

## What This Is

A targeted improvement to the Essentials politician lookup flow. Replaces the current heavy polling loop (up to 12 full Postgres queries while waiting for cache warming) with a lightweight status-check endpoint and a single data fetch. Touches EV-Backend (Go) and essentials (React).

## Core Value

When a user searches a ZIP code, they get their politicians fast — without the backend being hammered by redundant expensive queries during cache warming.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ 3-tier cache warming (federal/state/local) with 90-day TTL — existing
- ✓ Progressive loading with X-Data-Status headers (fresh/stale/warming/warmed) — existing
- ✓ PostgreSQL advisory locks for warming deduplication — existing
- ✓ Backend waitForDataMin (10s, 200ms tick) for cold misses — existing
- ✓ Frontend fetchPoliticiansProgressive with retry loop — existing
- ✓ Address search returns immediately via BallotReady API (no polling needed) — existing

### Active

- [ ] Lightweight cache status endpoint (`GET /essentials/cache-status/{zip}`)
- [ ] Frontend polls status endpoint instead of full politicians endpoint during warming
- [ ] Single full data fetch after status confirms all caches fresh
- [ ] Frontend structured for future SSE swap (EventSource replaces polling with minimal changes)

### Out of Scope

- Server-Sent Events implementation — Render.com doesn't reliably support SSE streaming; deferred to AWS migration
- Redis for cache status — adds operational complexity for marginal gain over a lightweight Postgres check
- WebSocket infrastructure — overkill for unidirectional cache status updates
- Changes to cache TTL or warming logic — current 90-day TTL and advisory lock pattern are working well
- Changes to address search flow — already returns immediately, no polling issue

## Context

**Current polling behavior:** When a user searches a ZIP with stale/missing cache, `fetchPoliticiansProgressive` calls `GET /essentials/politicians/{zip}` up to 8 times at 1.5s intervals. Each call runs a multi-table JOIN across politicians, offices, districts, chambers, images, degrees, and experiences. The backend returns partial data with `X-Data-Status: "stale"` or 202 with `"warming"` until cache completes.

**The fix:** Add a `GET /essentials/cache-status/{zip}` endpoint that checks only the three cache tables (federal_cache, state_caches, zip_caches) — no JOINs, no politician data. Frontend polls this cheap endpoint, then makes one full fetch when ready.

**Backend location:** `EV-Backend/internal/essentials/` — new handler + route for cache-status endpoint.

**Frontend location:** `essentials/src/lib/api.jsx` — refactor `fetchPoliticiansProgressive` to poll status endpoint, then fetch data once.

**Deployment:** Backend on Render, frontend on Netlify. No SSE support on Render currently.

**Future path:** When migrating to AWS, replace the status polling with SSE. Frontend should be structured so swapping `pollCacheStatus()` for `subscribeCacheStatus()` is a minimal change.

## Constraints

- **Hosting:** Render (backend) and Netlify (frontend) — no SSE or WebSocket support on Render
- **No new infrastructure:** No Redis, no message queues — keep it to Go + Postgres
- **Backward compatibility:** Existing `fetchPoliticiansProgressive` behavior must still work for any callers (Results.jsx, Home.jsx)
- **Scope:** Only the essentials module — no changes to other backend modules

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Lightweight status endpoint over SSE | Render doesn't reliably support SSE; status endpoint works everywhere | — Pending |
| No Redis | Postgres check on 3 small cache tables is fast enough; avoids new infra dependency | — Pending |
| Structure frontend for SSE swap | AWS migration planned; minimize rework when SSE becomes viable | — Pending |

---
*Last updated: 2026-02-09 after initialization*
