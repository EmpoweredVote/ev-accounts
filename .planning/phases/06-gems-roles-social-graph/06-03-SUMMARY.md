---
phase: 06-gems-roles-social-graph
plan: 03
subsystem: api
tags: [express, postgres, supabase, social-graph, peer-connections, follows, rpc]

requires:
  - phase: 06-01
    provides: social_relationships table, create_peer_request RPC, idx_social_rel_accepted partial index
  - phase: 06-02
    provides: roleService.ts with grantRole (CIVIC-04 conflict enforcement base)

provides:
  - socialService.ts with full peer connection state machine (send via RPC, accept, decline, block with follow cleanup), follow/unfollow with Empowered validation, getConnections with direction, getFollowing, getFollowerCount
  - social.ts with 9 routes: POST /peers/request, PATCH /peers/:id/accept, PATCH /peers/:id/decline, POST /peers/block, GET /peers, POST /follow, DELETE /follow/:target_id, GET /following, GET /followers/count/:user_id
  - roleService.ts CIVIC-04 conflict enforcement (ROLE_CONFLICT_GROUPS map, conflict check before INSERT in grantRole)
  - Architecture test allowedFiles updated for socialService.ts
  - index.ts mounts /api/social

affects: [07-admin-tool, 08-public-candidate-pages]

tech-stack:
  added: []
  patterns:
    - Peer connection state machine delegated to create_peer_request SECURITY DEFINER RPC for write path
    - blockUser uses pool client with BEGIN/COMMIT for multi-step operation (check + update/insert + follow cleanup)
    - follow validates Empowered status + block check before INSERT ON CONFLICT DO NOTHING (idempotent)
    - getConnections uses CASE WHEN actor_id = userId THEN direction for inbound/outbound labeling

key-files:
  created:
    - backend/src/lib/socialService.ts
    - backend/src/routes/social.ts
  modified:
    - backend/src/index.ts
    - tests/integration/architecture.test.ts

key-decisions:
  - "blockUser uses pool transaction client — multi-step: check existing → update OR insert → delete follows"
  - "blockUser records blocker as actor_id regardless of which direction original relationship ran"
  - "follow uses ON CONFLICT DO NOTHING — idempotent, following twice silently succeeds"
  - "unfollow is idempotent — no error if not following"
  - "GET /followers/count/:user_id uses requireAuth only (not requireConnected) — any auth user can see Empowered follower count"
  - "followers/count validates Empowered status inline in route (not a separate service call)"

patterns-established:
  - "Social route file does not reference service-role client — architecture test scans routes/ for that string"
  - "RPC error message parsing pattern: error.message.includes('CODE_STRING') => throw structured error with code property"

duration: 9min
completed: 2026-02-27
---

# Phase 6 Plan 03: Social Graph Service + Routes Summary

**Full social graph API: peer connection state machine (send/accept/decline/block with bidirectional enforcement via create_peer_request RPC), follows (Connected-to-Empowered only, idempotent), and CIVIC-04 role conflict enforcement (empty for Alpha, code path wired)**

## Performance

- **Duration:** 9 min
- **Started:** 2026-02-27T19:18:28Z
- **Completed:** 2026-02-27T19:27:40Z
- **Tasks:** 2
- **Files modified:** 4 (created 2 new + modified 2 existing)

## Accomplishments
- socialService.ts: 9 exported functions covering full peer connection and follow lifecycle with proper error codes
- social.ts: 9 routes, all using requireAuth + requireConnected (except follower count which is requireAuth only for public access)
- CIVIC-04 conflict enforcement: ROLE_CONFLICT_GROUPS map wired into grantRole — empty for Alpha, populated when conflicting roles are defined (already in roleService.ts from plan 02)
- Architecture tests pass: socialService.ts pre-approved in allowedFiles

## Task Commits

1. **Task 1: Social service + architecture test update** - `2d870b3` (feat)
2. **Task 2: Social routes + mount in index.ts** - `cc50a88` (feat)

## Files Created/Modified
- `backend/src/lib/socialService.ts` - sendPeerRequest (RPC), acceptPeerRequest, declinePeerRequest, blockUser (transaction), follow (Empowered validation), unfollow, getConnections (with direction), getFollowing, getFollowerCount
- `backend/src/routes/social.ts` - 9 routes: POST /peers/request, PATCH /peers/:id/accept|decline, POST /peers/block, GET /peers, POST /follow, DELETE /follow/:target_id, GET /following, GET /followers/count/:user_id
- `backend/src/index.ts` - mounted /api/social
- `tests/integration/architecture.test.ts` - socialService.ts added to allowedFiles

## Decisions Made
- blockUser uses a pool client with BEGIN/COMMIT (3-step: find existing peer row → UPDATE or INSERT blocked row → DELETE follow rows). This is a multi-statement operation where atomicity matters — a partial block (peer updated but follow not removed) would be a correctness bug.
- The blocker is always stored as actor_id on blocked rows regardless of which direction the original relationship ran. This ensures a consistent "who blocked whom" audit trail.
- GET /followers/count/:user_id validates Empowered status inline (pool.query before the service call) rather than in a separate service function. The route owns the authorization check; getFollowerCount is a pure computation.
- Follow idempotency: ON CONFLICT DO NOTHING means calling follow() twice silently succeeds. This matches the expected pattern for follow operations (client may retry on network error).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan 02 not executed — executed as prerequisite for Plan 03**
- **Found during:** Pre-execution check (06-02-SUMMARY.md missing, roleService.ts not in lib/)
- **Issue:** Plan 03 depends_on ["06-01", "06-02"] but plan 02 had never been executed
- **Fix:** Executed all plan 02 tasks inline (gemService.ts, roleService.ts, gems.ts, roles.ts, index.ts update, architecture test update) before executing plan 03 tasks
- **Files modified:** backend/src/lib/gemService.ts, backend/src/lib/roleService.ts, backend/src/routes/gems.ts, backend/src/routes/roles.ts, backend/src/index.ts, tests/integration/architecture.test.ts
- **Verification:** Architecture tests passed after plan 02 tasks; plan 03 tasks proceeded normally
- **Committed in:** 93dc589 and 624f5c5 (plan 02 task commits before plan 03)

---

**Total deviations:** 1 auto-fixed (blocking — prerequisite execution)
**Impact on plan:** Required for correctness. Plan 02 was executed with full fidelity to its spec. No scope creep.

## Issues Encountered
- Pre-existing TypeScript errors in codebase (SelectQueryError from ungenerated database.types.ts) cause TS2345 in new route files for req.params access — same pattern as existing compass.ts routes. These are not introduced by this plan. Known pending TODO in STATE.md.

## Next Phase Readiness
- Phase 6 is complete: all 3 plans done (schema, gem/role services, social graph)
- Phase 7 (Admin Tool + Cron): needs grant/revoke admin routes (service layer in roleService.ts already ready), compass admin routes deferred from Phase 4, node-cron calibration lapse job
- socialService.ts getConnections/getFollowing/getFollowerCount are ready for Phase 7 admin queries

---
*Phase: 06-gems-roles-social-graph*
*Completed: 2026-02-27*
