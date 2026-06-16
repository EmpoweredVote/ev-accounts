# Project Research Summary

**Project:** ev-accounts — v1.9 Delegated Authority / Scoped Roles
**Domain:** Civic platform contributor role system with geo-scoped authorization and audit trail
**Researched:** 2026-04-02
**Confidence:** HIGH — all findings from direct source inspection of this repository and Civic Spaces

---

## Executive Summary

v1.9 adds a scoped role system on top of the existing flat `public.user_roles` table. The core work is schema evolution — adding three nullable columns (`feature_scope`, `jurisdiction_geoid`, `resource_id`) and creating three SQL functions (`grant_role`, `revoke_role`, `get_user_roles`) that do not yet exist in any migration. Everything downstream — middleware, endpoints, admin UI, contributor portal — follows patterns already proven in the codebase. Zero new backend runtime dependencies are required.

The recommended approach is strictly layered: schema first (gates everything), then the `requireRole` middleware and `checkRole` utility, then role-gated endpoints, then UI surfaces in parallel (admin UI updates and contributor portal). The Civic Spaces integration via `POST /api/roles/check` lands last and must not drive architecture decisions — it is a consumer of the role system, not a co-designer.

The primary risks are security, not technical. Campaign Manager requires two-layer enforcement (role presence + resource boundary check on every response). Audit completeness has no automatic enforcement mechanism — inline SECURITY DEFINER writes are the only reliable prevention. Feature scope strings currently have three definition points (DB CHECK, Zod enum, portal route guards) and will drift without a single-source-of-truth constant. These three risks must be addressed during the schema and service layer phases, not retrofitted later.

---

## Key Findings

### Recommended Stack

The existing stack handles all v1.9 requirements with no new runtime dependencies. `pg` (raw pool), `express`, `zod`, and `jose` cover every backend need. The contributor portal is a new Vite + React app scaffolded by copying `app/`, using the same `ev_token` localStorage key, the same `apiFetch` pattern from `app/src/lib/api.ts`, and the same Tailwind v4 `ev-*` theme tokens. No monorepo build tooling (`nx`, `turborepo`) is warranted at this scale.

The one deliberate non-decision worth recording: roles must NOT be baked into JWT claims. Role grants live in `public.user_roles`. Fetching from `GET /api/roles/me` on session init is correct — revocations propagate immediately. JWT claim embedding would create up to a 1-hour revocation lag for high-trust actions like Campaign Manager.

**Core technologies:**
- `pg` (pool.query): all non-public schema reads and writes — required for nullable `IS NOT DISTINCT FROM` comparisons that PostgREST cannot express
- `zod`: input validation for new scope fields on grant/revoke endpoints — use a single exported constant as source of truth for both enum and DB CHECK
- `@upstash/redis`: short-TTL (60–120 second) cache for role grant lookups — follow existing revocation-check pattern in `authService.ts`; TTL must not exceed 120s for Campaign Manager
- Vite + React + Tailwind v4: contributor portal — copy `app/` exactly, dev port 5176, deploy as Render Static Site at `contributors.empowered.vote`

### Expected Features

The role system has five role types. Two (CTC Content Editor, Volunteer) are integration patterns only — accounts provides the grant data, the consuming app enforces the restriction. Three (Compass Stance Editor, Campaign Manager, Essentials Data Editor) require new API surfaces in accounts.

**Must have (table stakes):**
- Schema migration: `feature_scope`, `jurisdiction_geoid`, `resource_id` columns on `user_roles`, drop/replace `idx_user_roles_active_unique` — gates all other work
- `grant_role`, `revoke_role`, `get_user_roles` SQL functions — pre-existing gap in roleService.ts; these RPCs are called but not defined in any migration
- `requireRole(featureScope, geoid?, resourceId?)` middleware — the `IS NULL OR IS NOT DISTINCT FROM` pattern is required for nullable geo-scope; bare equality silently fails when geoid is NULL
- `POST /api/roles/check` endpoint — Civic Spaces calls this; uses the same `checkRole()` utility as the middleware, not a second SQL query
- Five new role slugs seeded in `public.roles`: `compass_stance_editor`, `campaign_manager`, `ctc_content_editor`, `essentials_data_editor`, `volunteer`
- `role_audit_log` table with `actor_id` + `target_user_id` columns (two-actor pattern) — single `user_id` column would make "all changes to user X" queries require JSON scanning instead of indexed lookup
- Admin grant form: conditional fields by role slug (Campaign Manager hides jurisdiction, shows politician picker; others show jurisdiction picker)
- Admin revoke: must target scoped row by ID — a user may hold the same role slug for two jurisdictions simultaneously
- Per-user Roles tab in admin account detail
- `GET /api/contributor/me` — returns active scoped grants; used by portal home screen, CTC, and Civic Spaces
- Contributor portal (new React app, `contributor/` at repo root)
- ESSENTIALS-PROV: add `ESSENTIALS_SERVICE_KEY` to Render + `.env.example` (zero code, independent)

**Should have (v1.9 value-adds):**
- Global audit dashboard in admin — filters `admin_audit_log` by `details->>'feature_scope'`; reads from existing log data, low implementation risk
- Notification to contributor on role grant/revoke — use existing Supabase email; low complexity
- Contributor-facing audit trail ("Your recent edits") — filter `admin_audit_log` by `actor_id`; low complexity
- `cache_until` field on `GET /api/roles/me` response — prevents Civic Spaces volunteer lockout during API cold starts
- `Cache-Control: private, no-store` on `/api/roles/me` — one-line addition, prevents authorization cache poisoning

**Defer to v2+:**
- Multi-jurisdiction grant in a single row (one grant per jurisdiction for v1.9)
- Grant expiry date (`valid_through` field)
- Campaign Manager read-only landscape view
- Contributor self-service grant requests
- Revision history on politician answers (old values in audit log)
- JWT claim embedding for high-frequency role reads

**Anti-features — do not build:**
- Trivia CRUD API routes in accounts (CTC owns the trivia schema; CTC enforces its own check using accounts role grant data)
- Campaign Manager "landscape view" showing all politicians' stances (even read-only violates the resource boundary model)
- Single mega-endpoint mixing feature scopes
- `feature_scope` as freeform text with no validation constraint

### Architecture Approach

The build follows a strict dependency chain: schema migration (one transaction, all DDL) → service layer + middleware in parallel → API endpoints → admin UI and contributor portal in parallel → Civic Spaces integration. The schema migration is the single gate; nothing else can be coded until it is merged. Within that constraint, (service layer, middleware) and (admin UI, contributor portal) are parallelizable pairs.

The critical architectural pattern is the NULL-scope `IS NULL OR IS NOT DISTINCT FROM` query idiom, which appears identically in two places with opposite semantics: the `requireRole` middleware EXISTS check (NULL means "unrestricted — covers any request") and the `grant_role` duplicate-check (`IS NOT DISTINCT FROM` means "exact match — are these two grants identical"). The migration author must not conflate them.

**Major components:**
1. Schema migration (one transaction) — adds scope columns, replaces unique index, creates 3 RPCs + `role_audit_log` table with 4 indexes; the atomic foundation for everything else
2. `roleService.ts` + `roleAuditService.ts` — updated grantRole/revokeRole/getUserRoles signatures; new `checkRole()` utility (shared by middleware and `/api/roles/check`); `logRoleAction()` called inside grantRole/revokeRole so audit fires regardless of call origin
3. `requireRole` middleware (`src/middleware/requireRole.ts`) — `pool.query()` with IS NULL OR IS NOT DISTINCT FROM pattern; calls `checkRole()`, never inlines SQL; mounted after `requireAuth`
4. Role-gated API endpoints (compass contributor, essentials contributor, `GET /api/contributor/me`, `POST /api/roles/check`) — Campaign Manager routes enforce two-layer auth: middleware for role presence + handler for resource_id boundary check
5. Admin UI additions (existing admin tool) — updated grant/revoke forms with conditional scope fields, per-user Roles tab, global audit dashboard; admin route handlers still call `logAdminAction()` alongside `logRoleAction()` in the service (double logging is intentional: different query patterns)
6. Contributor portal (`contributor/` Vite app) — new React app copied from `app/`; `AuthGuard` + `RoleGuard` guard chain; `DashboardPage` routes to role-type views; portal is informational for CTC and Volunteer roles (links out to those apps)
7. Civic Spaces integration — `POST /api/roles/check` endpoint; Civic Spaces backend calls it before privileged volunteer writes and caches the response using `cache_until` TTL

### Critical Pitfalls

1. **Campaign Manager sees opponent data (Pitfall 13)** — Two-layer enforcement is mandatory. Layer 1: `requireRole('compass_stance_editor')` checks role presence. Layer 2: handler or RPC loads the user's grant row and cross-references `resource_id` (Campaign Manager) or `jurisdiction_geoid` (Stance Editor) against the requested politician's home jurisdiction. Any route with `requireRole` that uses a path-parameter ID without a second DB lookup is a security gap. Establish the politician-to-jurisdiction schema join during the schema phase — before any routes are written.

2. **Audit log has silent gaps (Pitfall 14)** — Inline the audit write inside the SECURITY DEFINER RPC so grant/revoke and its log entry are one atomic transaction. This cannot be omitted by a route author because it never goes through the route layer. If inline RPC writes are not feasible for a given operation, add an architecture test asserting that route files touching `user_roles` writes reference the audit utility.

3. **CORS blocks contributor portal session (Pitfall 15)** — Add `https://contributors.empowered.vote` to `CORS_ORIGIN` on Render as a deploy checklist item before the portal goes live. Same-site sibling subdomains do send `SameSite=Lax` cookies, but only when `Access-Control-Allow-Origin` is the exact origin (not `*`) and `Access-Control-Allow-Credentials: true` is set. The CORS config already sets `credentials: true`; the missing piece will be the origin allowlist.

4. **Campaign Manager double-grant conflict (Pitfall 16)** — `ROLE_CONFLICT_GROUPS` in `roleService.ts` is empty. Whether holding Campaign Manager for two opposing candidates is a prohibited conflict or a permitted consultant arrangement must be decided before the `grant_role` RPC is written. The admin grant UI must show existing grants for the target user before the form is submitted.

5. **feature_scope string drift (Pitfall 17)** — Three definition points now exist: DB CHECK constraint, Zod enum, portal route guards. Create one TypeScript constant array in `backend/src/lib/roles.ts` that generates both the Zod enum and the SQL CHECK string. Add a schema snapshot test asserting DB CHECK matches the TypeScript constant.

---

## Implications for Roadmap

The research suggests eight phases in strict dependency order, with two parallelizable pairs.

### Phase 1: ESSENTIALS-PROV (env var only)

**Rationale:** Independent of all other v1.9 work. Zero code, zero risk. Can be done before the schema migration is reviewed and merged.
**Delivers:** `ESSENTIALS_SERVICE_KEY` added to Render + `.env.example`. Closes a v1.8 loose end.
**Avoids:** Nothing blocked by this. Do it first to get it off the list.

### Phase 2: Schema + RPC Migration

**Rationale:** Hard gate for all downstream phases. The pre-existing gap — `grant_role`, `revoke_role`, `get_user_roles` RPCs called in `roleService.ts` but absent from all 54 migrations — must be closed here or the existing role endpoint errors at runtime.
**Delivers:** Three new columns on `user_roles`, scope-aware unique index (replaces `idx_user_roles_active_unique`), three SECURITY DEFINER functions, `role_audit_log` table with four indexes, five new role slugs seeded in `public.roles`.
**Addresses:** Schema table stakes; pre-existing RPC gap
**Avoids:** Pitfall 16 (define Campaign Manager conflict rules before writing grant_role); Pitfall 20 (two-actor columns on audit table — decide at DDL time, not retrofit); Pitfall 17 (single-source TypeScript constant for feature_scope must exist before migration is written)
**Research flag:** Standard patterns. Full SQL specified in ARCHITECTURE.md. No additional research needed.

### Phase 3: Service Layer + requireRole Middleware

**Rationale:** Service layer (`checkRole()`) and middleware are parallelizable but middleware depends on `checkRole()` being defined — agree on its signature before splitting work. Both must complete before any endpoints are written.
**Delivers:** Updated `roleService.ts` signatures with scope params; `checkRole()` utility (single SQL, two consumers); `roleAuditService.ts` with `logRoleAction()`; `requireRole` middleware in `src/middleware/`.
**Uses:** `pool.query()` with `IS NULL OR IS NOT DISTINCT FROM`; `@upstash/redis` cache at 60–120s TTL (key `roles:uid:{userId}`, invalidate on grant/revoke)
**Avoids:** Pitfall 13 (resource boundary enforcement built into `checkRole()` signature upfront); Pitfall 19 (update architecture test `allowedFiles` in the same PR as any new service file)

### Phase 4: Compass Stance Editor + Campaign Manager Endpoints

**Rationale:** These share the same route structure. Compass Stance Editor is the jurisdiction-scoped case. Campaign Manager is the security-critical resource-scoped case. Build together so two-layer enforcement is established as the canonical pattern, not the exception.
**Delivers:** `GET/PUT /api/contributor/compass/politicians/:id/answers`; `POST /api/contributor/compass/politicians/:id/context`; `GET /api/contributor/compass/politicians` (Stance Editor only — Campaign Manager gets no list endpoint); `GET /api/contributor/me` (portal home, CTC, and Civic Spaces all depend on this).
**Addresses:** Campaign Manager resource_id enforcement; Compass Stance Editor jurisdiction enforcement
**Avoids:** Pitfall 13 (integration test required: two politicians, different jurisdictions, single-jurisdiction grant, assert 403 for out-of-scope politician)

### Phase 5: Essentials Data Editor Endpoint

**Rationale:** Separated from Phase 4 because the Essentials PATCH has a distinct allowed-fields constraint — `district_type`, `district_id`, `is_active`, `is_candidate`, `is_vacant` cannot be changed by contributors. Isolating this reduces the risk of accidentally exposing admin-only fields.
**Delivers:** `GET /api/contributor/essentials/politicians`; `PATCH /api/contributor/essentials/politicians/:id` (restricted field subset); `PUT /api/contributor/essentials/politicians/:id/contacts`; `fields_changed` key list (not values) in audit log details.
**Addresses:** Essentials Data Editor role; field-level boundary enforcement

### Phase 6: Admin UI (Grant/Revoke + Per-User Audit + Global Dashboard)

**Rationale:** Admin tooling depends on backend endpoints being in place. Parallelizable with Phase 7 (contributor portal) once Phase 5 is complete.
**Delivers:** Updated grant/revoke forms with conditional scope fields; per-user Roles tab in account detail; global audit dashboard at `/admin/role-audit`; updated admin routes `POST /api/admin/accounts/:userId/roles/grant|revoke`; `GET /api/admin/accounts/:userId/role-audit` (paginated); `GET /api/admin/role-audit` (filterable).
**Avoids:** Pitfall 16 (admin UI must show existing grants for target user before form submission)
**Research flag:** Standard patterns — follows existing admin component patterns in `admin/src/`.

### Phase 7: Contributor Portal

**Rationale:** Parallelizable with Phase 6 after Phase 5's backend is complete. New Vite app that does not modify any existing code. Blocking dependency is `GET /api/contributor/me` (Phase 4) and the contributor endpoints (Phases 4–5).
**Delivers:** `contributor/` Vite app; Auth flow (ev_token / SSO fallback / hash fragment); `AuthGuard` + `RoleGuard` guard chain; `DashboardPage` routing to role-type views; role-specific pages (CompassEditorPage, CampaignManagerPage, EssentialsEditorPage, CTC tile, Volunteer tile).
**Uses:** React 18 + Vite 5 + Tailwind v4 copied from `app/`; dev port 5176; deploy as Render Static Site at `contributors.empowered.vote`
**Avoids:** Pitfall 15 (CORS_ORIGIN must include `https://contributors.empowered.vote` — deploy checklist item); Pitfall 21 (document local dev cookie domain setup in `.env.example`)

### Phase 8: Civic Spaces Integration

**Rationale:** Last because it depends on `POST /api/roles/check` being live and requires cross-team coordination with Civic Spaces. Must not block any other phase.
**Delivers:** `POST /api/roles/check` endpoint (calls `checkRole()`, returns `{ has_role: boolean }`); Civic Spaces backend integration; smoke test (grant volunteer → write succeeds; revoke → blocked within cache TTL).
**Addresses:** Volunteer role; cross-service role enforcement
**Avoids:** Pitfall 18 (`cache_until` field on roles API response so Civic Spaces uses last-known-state during API unavailability); Pitfall 22 (`Cache-Control: private, no-store` on `/api/roles/me`)
**Research flag:** Requires coordination with Civic Spaces team. The `get_mod_queue` RPC needs a `p_slice_geoid` filter parameter for jurisdiction-scoped Volunteer grants — flag this as a Civic Spaces implementation detail to confirm before scheduling Phase 8.

### Phase Ordering Rationale

- Phase 2 is the hard gate because the SQL functions `roleService.ts` already calls do not exist in any migration — the existing role endpoint is broken at runtime until this migration is applied.
- Phases 4 and 5 are kept separate to isolate the campaign-data security boundary (two-layer auth) from the essentials field-whitelist boundary. Mixing them increases reviewer risk.
- Phases 6 and 7 are parallelizable after Phase 5 because they touch separate directories (`admin/` vs. `contributor/`) with no shared code.
- Phase 8 is last because Civic Spaces integration cannot be smoke-tested until the CORS configuration and `POST /api/roles/check` are both live in production.

### Research Flags

Phases needing closer attention during implementation:
- **Phase 2 (Schema):** Campaign Manager conflict rules must be decided before writing `grant_role`. `ROLE_CONFLICT_GROUPS` is empty — this is a product decision (consultant model vs. conflict-of-interest prohibition) that belongs in Phase 2 requirements, not the implementation.
- **Phase 4 (Campaign Manager):** Two-layer enforcement integration test is a phase completion gate, not an optional add-on. The test (two politicians, different jurisdictions, single grant, assert 403 for out-of-scope politician) is the only reliable signal the resource boundary works.
- **Phase 8 (Civic Spaces):** Requires cross-team coordination. Confirm Civic Spaces team capacity before scheduling.

Phases with standard patterns (research-phase not needed):
- **Phase 3:** SQL and TypeScript signatures fully specified in ARCHITECTURE.md.
- **Phase 6:** Follows existing admin component patterns.
- **Phase 7:** Copy-from-`app/` is fully documented in STACK.md.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings from direct code inspection; no external sources needed |
| Features | HIGH | Role boundaries defined from actual table structures, existing routes, CTC and Civic Spaces source |
| Architecture | HIGH | SQL DDL, TypeScript signatures, and middleware pattern fully specified from codebase inspection |
| Pitfalls | HIGH (security), MEDIUM (operational) | Campaign Manager auth gap and audit completeness verified from source; Civic Spaces lockout risk is architectural inference, not a directly observed failure |

**Overall confidence:** HIGH

### Gaps to Address

- **Campaign Manager conflict rules:** `ROLE_CONFLICT_GROUPS` is empty. Whether one user holding Campaign Manager for two opposing candidates is permitted (consultant model) or prohibited (conflict of interest) is unresolved. Decide before Phase 2 begins — this affects whether the `grant_role` RPC emits a warning or a hard error on the second grant.

- **Contributor portal subdomain:** Research documents `contributors.empowered.vote` as the target. Confirm before DNS is configured. STACK.md notes the portal could alternatively live as a route inside `/app` — confirm the subdomain decision before Phase 7 begins.

- **`get_mod_queue` filter in Civic Spaces:** Jurisdiction-scoped Volunteer grants require a `p_slice_geoid` filter parameter on Civic Spaces's `get_mod_queue` RPC. This is a Civic Spaces implementation detail, not an accounts change, but it gates the full Volunteer scoping feature. Flag to Civic Spaces team during Phase 8 planning.

- **Audit log retention policy:** `role_audit_log` is append-only with no retention policy. Define a retention window (90-day TTL or archive to cold storage) in the Phase 2 migration before the table goes live.

---

## Sources

### Primary — Direct source inspection (HIGH confidence)

- `C:/EV-Accounts/supabase/migrations/20260227000020_phase6_roles_schema.sql` — confirmed current `user_roles` DDL has no scope columns and no grant/revoke/get SQL functions
- `C:/EV-Accounts/backend/src/lib/roleService.ts` — confirmed RPC calls exist but SQL functions are absent; `ROLE_CONFLICT_GROUPS` is empty
- `C:/EV-Accounts/backend/src/middleware/requireAdmin.ts` — middleware guard pattern (pool.query or supabaseAdmin → 403 or next())
- `C:/EV-Accounts/backend/src/middleware/tierGuards.ts` — tier guard pattern
- `C:/EV-Accounts/backend/src/middleware/auth.ts` — AuthenticatedRequest type
- `C:/EV-Accounts/backend/src/routes/admin.ts` — logAdminAction pattern; existing grant/revoke endpoints
- `C:/EV-Accounts/backend/src/routes/roles.ts` — existing `/api/roles/me` (flat list, no scope fields, no Cache-Control)
- `C:/EV-Accounts/backend/src/index.ts` — CORS config (credentials: true, exact-match origin from CORS_ORIGIN)
- `C:/EV-Accounts/backend/src/routes/auth.ts` — `evSessionCookieOptions()`: SameSite=Lax, Secure, COOKIE_DOMAIN
- `C:/EV-Accounts/backend/src/lib/env.ts` — COOKIE_DOMAIN optional, CORS_ORIGIN comma-separated list
- `C:/EV-Accounts/app/src/App.tsx` — SSO init pattern, ev_token, hash fragment fallback
- `C:/EV-Accounts/app/src/store/authStore.ts` — Zustand auth state, ev_token key, User type
- `C:/EV-Accounts/app/src/lib/api.ts` — apiFetch pattern (VITE_API_URL, credentials: include)
- `C:/EV-Accounts/tests/integration/architecture.test.ts` — hardcoded allowedFiles list (lines 50–69)
- `C:/Civic Spaces/src/lib/supabase.ts` — cs_token localStorage key, third-party auth against Civic Spaces Supabase project
- `C:/Civic Spaces/src/hooks/useAuth.ts` — Civic Spaces SSO flow calls accounts-api.empowered.vote session endpoint
- `C:/EV-Accounts/supabase/migrations/20260323000051_phase41_trivia_service_role.sql` — CTC owns trivia schema via `trivia_service` Postgres role
- `C:/Civic Spaces/CIVIC-SPACES-ONBOARDING.md` — Volunteer integration pattern confirmed
- `C:/Civic Spaces/src/components/ModeratorQueue.tsx` — mod queue UI confirmed built

### Secondary — Web standards (HIGH confidence)

- MDN SameSite cookie spec — sibling subdomains are same-site; `SameSite=Lax` cookies sent on same-site cross-origin fetch with `credentials: include`
- WHATWG Fetch spec — `credentials: include` requires explicit `Access-Control-Allow-Origin` (not wildcard) and `Access-Control-Allow-Credentials: true`

---

*Research completed: 2026-04-02*
*Ready for roadmap: yes*
