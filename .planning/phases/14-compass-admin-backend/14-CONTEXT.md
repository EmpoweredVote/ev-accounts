# Phase 14: Compass Admin Backend - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver all admin API routes required by the Compass Admin React UI (Phase 15), so Phase 15 has a complete and tested backend to call. Scope: topics CRUD, stances update, politicians CRUD, categories CRUD, topic-category assignment, and admin action logging. The React UI itself is Phase 15.

</domain>

<decisions>
## Implementation Decisions

### Topic management
- `POST /api/admin/compass/topics` — create topic with optional stances array, atomically (CADM-02)
- `PATCH /api/admin/compass/topics/:id` — update topic (title, question text, is_live toggle); needed for Phase 15's is_live toggle and text edits
- `GET /api/admin/compass/topics` — list all topics including non-live drafts (CADM-01)
- No DELETE route — soft-disable via `is_live = false` is sufficient; hard delete risks orphaned user response data
- `PATCH /api/admin/compass/stances/:id` — update stance text; single route handles all stance edits (CADM-09 backend requirement)

### Politicians management
- `POST /api/admin/compass/politicians` — create politician (CADM-03)
- `PATCH /api/admin/compass/politicians/:id` — update name, office title, photo URL, active status (CADM-04)
- Politician answers route (`PUT /api/admin/compass/politicians/:id/answers`) — verify if exists from Phase 7; add/repair if missing
- Politician context route (reasoning + sources per topic) — verify if exists from Phase 7; add/repair if missing

### Categories management
- `GET /api/admin/compass/categories` — list all (CADM-05)
- `POST /api/admin/compass/categories` — create (CADM-06)
- `PUT /api/admin/compass/topics/:id/categories` — assign categories to topic (CADM-07)

### Admin action log
- ALL mutations logged: topics (create/update), stances (update), politicians (create/update), categories (create), topic-category assignment
- Each entry captures: authenticated admin's real user_id from JWT, action type, entity type + ID, timestamp
- Payload snapshot shape: Claude's discretion during planning
- Log table existence: researcher must verify against live DB before planning (may exist from Phase 7)

### Response contracts
- `POST /admin/compass/topics` returns full topic + stances array (no second fetch needed by UI)
- `GET /admin/compass/topics` returns topic metadata only (id, title, is_live, created_at) — stances fetched on detail view
- `PATCH` and other mutation endpoints return the updated record
- HTTP status: 201 for creates, 200 for updates, 400 for validation errors, 404 for not found — consistent with existing API
- Error shape: Claude's discretion, matching whatever pattern existing admin endpoints use

### Route completeness
- Phase 14 must produce a complete route manifest (documented endpoint table) in its PLAN.md so Phase 15 can reference it without reading source
- Phase 14 is done only when Phase 15 can build against it with no gaps

### Claude's Discretion
- Admin action log payload snapshot format (full payload vs. before/after diff vs. summary)
- Error response shape — match existing admin endpoint pattern
- Exact validation logic for stance payload during atomic create

</decisions>

<specifics>
## Specific Ideas

- "Soft-disable via is_live = false is sufficient — hard delete risks orphaned user response data" (user's words on topic deletion)
- Route manifest in PLAN.md is explicitly requested so Phase 15 doesn't need to read source to know what to call

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 14-compass-admin-backend*
*Context gathered: 2026-03-06*
