# Phase 53: Service Layer + requireRole Middleware - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the role enforcement layer: `requireRole()` Express middleware, `checkRole()` utility it delegates to, Redis-cached role lookups via `roleService`, and two endpoints — `GET /api/contributor/me` (returns caller's active grants) and `POST /api/roles/check` (external check endpoint for CTC/Civic Spaces). This is the single implementation of role enforcement in the codebase — all downstream phases (55, 56, 57, 58) consume it.

</domain>

<decisions>
## Implementation Decisions

### requireRole() API design
- Accepts a single role slug OR an array of slugs (OR logic — passes if user holds ANY listed role)
- Scope values (`geoid`, `resourceId`) accept either a static string or a resolver function: `(req) => req.params.xxx`
  - Static: `requireRole('compass_stance_editor', { geoid: '18105' })`
  - Dynamic: `requireRole('campaign_manager', { resourceId: (req) => req.params.politicianId })`
- Always fetches roles via `roleService.getUserRoles(userId)` — hits Redis cache first, DB on miss. JWT stays thin.
- Handles unauthenticated requests itself: returns 401 if `req.user` is missing. Safe to use without stacking a separate auth middleware first.

### NULL-scope semantics (checkRole() matching logic)
- NULL `jurisdiction_geoid` on a grant = unrestricted on the geoid dimension — passes ANY geoid check
- NULL `resource_id` on a grant = unrestricted on the resourceId dimension — passes ANY resourceId check
- A route calling `requireRole()` with no geoid/resourceId requirement: ANY active grant for the role passes (scope-blind check)
- Multiple grants for the same role slug: ANY single matching grant is sufficient (OR across all grants)
- Rule summary: NULL on any scope dimension = unrestricted for that dimension

### Cache behavior
- Cache key: `roles:uid:{userId}` — stores full active grant list for the user
- Cache miss: fall through to DB transparently, write result back to Redis, return to caller
- Redis unavailable: log the error, skip cache, query DB directly — Redis is an optimization, not a hard dependency
- On grant or revoke: immediately `DEL roles:uid:{userId}` — do not wait for TTL expiry
- TTL: Claude's discretion within the 60–120s range specified in success criteria

### Error shape + response contract
- `requireRole()` 403 body: `{ error: "forbidden" }` — no role name, no required scope leaked
- `requireRole()` 401 body: `{ error: "unauthorized" }` — returned when no session exists
- `POST /api/roles/check` response: `{ permitted: true }` or `{ permitted: false }` — no additional fields
- `GET /api/contributor/me` roles array shape: `[{ role_slug, feature_scope, jurisdiction_geoid, resource_id }]`
- `GET /api/contributor/me` returns ACTIVE grants only (`is_active = true`) — not revoked history

### Claude's Discretion
- Exact TTL value (60–120s range, planner decides)
- TypeScript generic/overload design for the resolver function signature
- Whether roleService exposes a separate `checkRole(userId, roleSlug, scope)` method or checkRole lives as a module-level utility

</decisions>

<specifics>
## Specific Ideas

- Phase 57 SC3 confirms: NULL-scope `volunteer` grant → `POST /api/roles/check` with any `jurisdiction_geoid` returns `{ permitted: true }`. NULL scope semantics documented here must match that behavior exactly.
- The success criteria integration test pattern (SC3/SC4) verifies scope enforcement at the middleware layer — the planner should include tests for: no role (403), wrong jurisdiction (403), NULL-scope grant (200), exact match (200), wrong resourceId (403).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 53-service-layer-requirerole-middleware*
*Context gathered: 2026-04-03*
