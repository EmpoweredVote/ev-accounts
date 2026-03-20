# Phase 37: Express Ports Wave 2 — Staging - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Port the Staging volunteer review workflow to ev-accounts — role-gated submission, review, and approval of three entity types: politicians, stances, and building photos. Six staging tables. All access is privileged (reviewer/admin only). Approved records auto-promote to production tables. The Go server is no longer needed for staging routes after this phase.

</domain>

<decisions>
## Implementation Decisions

### Role model
- Add `staging_reviewer` as a named role in the existing roles table (same pattern as existing roles infrastructure)
- **All** staging route access (reads AND writes) requires `staging_reviewer` or `admin` role — no plain authenticated user access
- No public or unauthenticated access at any level
- Submission of new records requires `staging_reviewer` or `admin` — not open to general authenticated users
- Data enters staging either via VQ consensus (system/service role) or direct reviewer/admin entry

### State machine
- Three valid statuses: `pending | approved | rejected`
- `rejected` is terminal — no resubmit path. Submit a new record if corrections are needed
- `approved` is terminal — once approved, record is locked and auto-promotes to production
- Politicians have a `merged_to_id` column — implement a merge endpoint: `POST /api/staging/politicians/:id/merge` sets `merged_to_id` and marks the source as `rejected`
- Stances are reviewed independently of their parent politician — no approval-gate dependency enforced in the API

### Locking
- Advisory locking only — `locked_by`/`locked_at` is a courtesy signal; review actions (approve/reject) are NOT blocked by another reviewer's lock
- Explicit release only — no auto-expiry; reviewer calls `DELETE /api/staging/:type/:id/lock` to release
- Any `staging_reviewer` or `admin` can unlock any lock (not restricted to the lock holder)
- Acquiring a lock (`POST /api/staging/:type/:id/lock`) returns **409 Conflict** if another reviewer currently holds the lock — caller can see who holds it and decide whether to release first

### Submission authorship
- `added_by` and `reviewer_name` fields are always derived from `req.user.display_name` (JWT) — never trusted from request body
- Promotion authorship: record which user triggered auto-promote (store in review log at time of approval action)

### Auto-promotion on approval
- Approving a `staging.politician` → auto-upsert into `essentials.politicians`; record the approving user's display name in the promotion log
- Approving a `staging.stance` → auto-upsert into the appropriate answers table (essentials politician_answers); record the approving user
- Building photos: approval marks `approved_at` — promotion behavior for photos deferred to planner (no direct essentials target identified)

### Claude's Discretion
- Exact route path structure (e.g., `/api/staging/politicians` vs `/api/staging/review/politicians`)
- Error message wording for 403/409/422 responses
- Building photo promotion destination (no clear essentials target — planner to investigate)
- `review_count` increment logic (whether to auto-increment on every review action or only on approve/reject)

</decisions>

<specifics>
## Specific Ideas

- The `reviewer_name` columns in review log tables are plain text — this is legacy Go server behavior. Preserve column type but populate from JWT, never from request body.
- Politicians have additional rich fields (`contacts`, `degrees`, `experiences`, `urls`, `images`, `addresses` as JSONB) — these should pass through as-is in create/update bodies without server-side validation beyond JSON parsing.
- `staging.stances` has both `topic_key` (text) and `topic_id` (uuid, nullable) — approval promotion should resolve `topic_id` from `topic_key` if `topic_id` is null.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope.

</deferred>

---

*Phase: 37-express-ports-wave-2-staging*
*Context gathered: 2026-03-20*
