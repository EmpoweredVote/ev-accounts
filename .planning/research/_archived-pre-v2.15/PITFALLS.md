# Domain Pitfalls

**Domain:** Delegated authority roles, audit logs, contributor portal — ev-accounts v1.9
**Researched:** 2026-04-02
**Scope:** v1.9 additions only — Campaign Manager roles, politician-scoped permissions, audit log
  infrastructure, contributor portal at `contributors.empowered.vote`

**Prior pitfalls (v1.6 research, still valid, not repeated here):**
- Pitfall 1: NULL geo-scope dropped by naive WHERE clause
- Pitfall 2: Compass compare leaking private responses via supabaseAdmin
- Pitfall 3: is_admin / admin_users drift from scoped role system
- Pitfall 4: pool.query() omitted for non-public schema role writes
- Pitfall 5: Compass compare missing answer-count context
- Pitfall 6: Geo-scope check uses residential location instead of role grant geoid
- Pitfall 7: VR dashboard aggregate query silently truncated by row limit
- Pitfall 8: Compass compare omits deleted_at soft-delete filter
- Pitfall 9: No advisory lock on role grant allows concurrent double-grant race
- Pitfall 10: vq_hold_until raw timestamp exposed in admin dashboard
- Pitfall 11: Feature scope strings not validated against allowlist
- Pitfall 12: GET /api/roles/me returns flat list without scope dimensions

---

## Critical Pitfalls

Mistakes that require schema rewrites, auth model rethinks, or data leaks.

---

### Pitfall 13: Campaign Manager Authorization Stops at Role Presence, Not Resource Boundary

**What goes wrong:** `requireRole('compass_stance_editor')` checks whether the authenticated user
holds the role. It returns 403 if they do not. But if they do hold the role, the request
proceeds to the route handler, which accepts a `politician_id` path parameter with no further
validation. A Campaign Manager for Politician A can call `GET /compass/politicians/B/answers`
with Politician B's ID — the role check passes because they have `compass_stance_editor`, but
they are reading data for an opponent.

**Why it happens:** Role middleware operates at the route level (does the user have this role at
all?). Resource-boundary enforcement — does the user's role grant cover this specific resource —
requires a second check that only the handler or a SECURITY DEFINER RPC can perform, because the
connection between the calling user, their role scope, and the requested resource ID lives in the
grant row, not in the URL pattern.

**Consequences:** Campaign Manager can read opposing candidates' internal compass stances. This is
the exact data they are trying to gain intelligence about. A leaked competitor's planned position
changes is a real campaign liability, not just a privacy bug.

**Prevention:** Two-layer enforcement is required:

Layer 1 — Route middleware: `requireRole('compass_stance_editor')` (role exists, not revoked).

Layer 2 — Handler or RPC: after passing Layer 1, load the user's grant row and compare:
```sql
SELECT jurisdiction_geoid FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
WHERE ur.user_id = $calling_user_id
  AND r.slug = 'compass_stance_editor'
  AND ur.revoked_at IS NULL
```
Then cross-reference that geoid against the requested politician's home jurisdiction. If the
politician is not in any of the caller's granted jurisdictions, return 403 before reading any data.

The geoid linkage (politician → jurisdiction) must be an explicit schema relationship, not
inferred from display strings. Establish it during the schema phase.

**Warning signs:**
- Any route with `requireRole` that uses a path parameter ID without a second DB lookup
- A service function called `getPoliticianAnswers(politicianId)` that accepts no calling-user context

**Detection:** Write a test with two politicians in different jurisdictions. Grant
`compass_stance_editor` for jurisdiction A only. Assert that requesting politician B's data
returns 403.

**Phase:** Role schema phase — establish politician-to-jurisdiction join before writing any
permission-check code. Layer 2 enforcement must be part of the initial route implementation,
not added later.

---

### Pitfall 14: Audit Log Completeness Has No Enforcement Mechanism

**What goes wrong:** Audit logging is implemented as a utility function (e.g.,
`logAuditEvent(userId, action, resourceId)`). Routes that modify role grants or sensitive data
call this function. A new route added later — by a different developer under time pressure — does
not call it. There is no gate, test, or linter rule that detects the omission. The audit trail
has a silent gap.

**Why it happens:** Audit logging is cross-cutting. In Express, there is no built-in mechanism
that forces middleware to run for specific route-level operations — only for all routes or none.
Forgetting to call a utility function produces no compiler error, no test failure (unless a test
was written specifically to detect absence), and no runtime error.

**Consequences:** Role grants, revocations, and politician data edits have incomplete audit
trails. Compliance posture degraded. In civic context (campaign data), an unlogged edit to a
politician's stance is indistinguishable from an untracked compromise.

**Prevention strategy — choose one of two approaches:**

Option A (preferred for v1.9 scale): Inline audit writes into SECURITY DEFINER RPCs. The same
atomic transaction that grants a role also writes to `public.audit_log`. Because both happen in
one RPC, it is structurally impossible to grant a role without logging it. The audit write cannot
be omitted by a route author because it never goes through the route layer.

Option B (acceptable if RPC consolidation is too large): Write a route-level wrapper:
```typescript
// auditedRoute(action, handler) — enforces that handler called audit before responding
function auditedRoute(action: AuditAction, handler: RequestHandler): RequestHandler
```
The wrapper asserts `res.locals.auditWritten === true` before calling `next()`. Handlers that
forget the audit write throw an error in test and dev environments. This is a convention
enforcement pattern, not a compiler-level guarantee.

**Warning signs:**
- Audit logging is a standalone `logAuditEvent()` call at the end of a route handler
- No architecture test scanning route files for audit coverage
- Audit log table has fewer rows than `user_roles` grant/revoke events

**Detection:** Architecture test that scans all route files touching `user_roles` or
`politician_answers` writes and asserts they either (a) call only SECURITY DEFINER RPCs (audit
inline) or (b) contain a reference to the audit utility. The existing architecture test in
`tests/integration/architecture.test.ts` is the right place to extend this pattern.

**Phase:** Audit schema phase — establish the enforcement mechanism before any routes call audit
functions. Do not add audit to existing routes after the fact without adding the enforcement test
simultaneously.

---

### Pitfall 15: Contributor Portal CORS + SameSite=Lax Cookie Not Sent Cross-Origin

**What goes wrong:** The `ev_session` cookie is set with `SameSite=Lax`. The contributor portal
at `contributors.empowered.vote` calls `GET /api/auth/session` on `api.empowered.vote` with
`credentials: 'include'`. The cookie is on `.empowered.vote` domain (shared parent domain). But
`SameSite=Lax` has a specific rule: cookies are sent on cross-site navigation (top-level GET) and
same-site requests — but `contributors.empowered.vote` making an XHR/fetch to
`api.empowered.vote` is a cross-origin request, not a top-level navigation. Whether the cookie
is sent depends on how browsers classify same-site vs cross-site for sibling subdomains.

**The actual behavior (verified against MDN and WHATWG):** Two subdomains of the same registrable
domain (e.g., `contributors.empowered.vote` and `api.empowered.vote`) are considered same-site
by browsers. `SameSite=Lax` cookies ARE sent on same-site cross-origin fetch requests with
`credentials: 'include'`. This means the cookie flow works — BUT only if all three conditions
are met simultaneously:
1. `CORS_ORIGIN` env var includes `https://contributors.empowered.vote` (exact match, no trailing
   slash)
2. The CORS response includes `Access-Control-Allow-Credentials: true` (the current `cors()`
   config sets `credentials: true`, which is correct)
3. The CORS response includes `Access-Control-Allow-Origin: https://contributors.empowered.vote`
   (not `*` — credentials mode requires an explicit origin, never wildcard)

**The actual risk:** Condition 1 is the most likely failure point. If `contributors.empowered.vote`
is not added to `CORS_ORIGIN` on Render before the portal goes live, every session call returns
a CORS error. The portal appears broken. Debugging is confusing because the cookie exists and the
domain is correct — the failure is entirely at the CORS header level.

**Secondary risk — HTTP vs HTTPS:** `SameSite=Lax; Secure` cookies are not sent on HTTP
connections regardless of domain relationship. If `contributors.empowered.vote` is served over
HTTP in any environment (staging, local proxy without HTTPS), the cookie will not be sent. The
current `evSessionCookieOptions()` sets `secure: env.NODE_ENV === 'production'` — in non-prod
environments the `Secure` flag is absent, which allows HTTP but also means the `Secure` check
is not the cause of failure in development. This is correct behavior.

**Prevention:**
- Add `contributors.empowered.vote` to `CORS_ORIGIN` in Render env vars as part of the portal
  deploy checklist, not as an afterthought
- Write a smoke test in the portal's deploy checklist: `curl -I` with `Origin:
  https://contributors.empowered.vote` and assert `Access-Control-Allow-Origin` is in the
  response
- Document the three-condition requirement (above) in the portal's integration guide so future
  subdomain additions follow the same pattern

**Warning signs:**
- Portal returns "Network Error" or "Failed to fetch" in browser devtools on the session call
- Response headers show `Access-Control-Allow-Origin: *` or the header is absent entirely
- `OPTIONS` preflight returns 204 but the actual request returns CORS error (happens when
  wildcard origin is set without `credentials: true` or when origin is missing from allowlist)

**Phase:** Contributor portal deploy phase — CORS_ORIGIN update is a deploy step, not a code
change. Add it to the Render environment variable checklist before launch.

---

### Pitfall 16: Conflicting Campaign Manager Roles — Intentional Model vs. Accidental Double-Grant

**What goes wrong:** The current `ROLE_CONFLICT_GROUPS` map in `roleService.ts` is empty for
Alpha. The `grant_role` RPC enforces no conflicts today. If Campaign Manager roles are modeled
as one role slug (`campaign_manager`) with `jurisdiction_geoid` differentiating which politician
the manager covers, a user can be granted the same slug for politician A's jurisdiction and
politician B's jurisdiction — this is intentional (one person manages two campaigns). But if
roles are modeled as distinct slugs per politician (e.g., `campaign_manager_politician_a`), two
grants of semantically identical roles creates conflict confusion.

The deeper problem: "Campaign Manager for politician A and B simultaneously" is a legitimate real-
world scenario (consultants manage multiple campaigns). But the system needs to know whether that
is intended or a data entry mistake. Without explicit conflict rules, an admin can accidentally
grant two Campaign Manager roles where only one was intended — especially if the UI does not show
existing grants before offering the new grant form.

**Why it happens:** The grant RPC enforces duplicate-grant prevention (partial unique index on
`user_id, role_id WHERE revoked_at IS NULL`). But "same slug, different jurisdiction_geoid" is
NOT a duplicate — it creates two distinct rows. The constraint intentionally allows this. The
question is whether the UI and admin workflow surface the existing grants clearly enough to
prevent unintended doubles.

**Consequences:** A consultant managing two opposing candidates (e.g., primary opponents) has
access to both candidates' internal data. This is the exact multi-campaign conflict-of-interest
scenario that campaign staff management exists to prevent.

**Prevention:**
- Model Campaign Manager as one role slug (`campaign_manager`) with `jurisdiction_geoid` encoding
  which politician/entity the grant covers — not a separate slug per politician. This keeps the
  role table clean and makes the grant list predictable.
- The admin grant UI must display existing active grants for the target user before presenting
  the grant form. Do not allow the form submission to be the first time the admin sees existing
  grants.
- Populate `ROLE_CONFLICT_GROUPS` for Campaign Manager roles if the platform decides that
  managing opposing candidates is a prohibited conflict. If it is permitted (consultant model),
  document that decision explicitly so it is not treated as a bug later.
- Add a warning (not a hard block) to the grant RPC when a second `campaign_manager` grant
  exists: return `ROLE_MULTI_SCOPE_WARNING` in addition to success, let the admin confirm.

**Warning signs:**
- `ROLE_CONFLICT_GROUPS` is empty and no ticket exists to define Campaign Manager conflict rules
- Grant form does not show existing grants before submission
- Role table has rows with same `user_id + role_slug` but different `jurisdiction_geoid` and no
  documentation on whether that is expected

**Phase:** Role schema design phase — define conflict rules for Campaign Manager before any grant
RPC is written. The empty `ROLE_CONFLICT_GROUPS` is a placeholder that must be filled before
this role type is live.

---

## Moderate Pitfalls

Mistakes that cause correctness bugs, security gaps, or significant rework.

---

### Pitfall 17: feature_scope Drift Between DB and Code When a New Value Is Added

**What goes wrong:** `feature_scope` is validated by a Zod enum in the middleware/service layer.
The DB has a CHECK constraint with the same list. They are defined separately. When a new scope
is added (e.g., `civic_spaces_volunteer`) a developer updates the Zod enum but forgets the DB
migration — or vice versa. One layer accepts the value, the other rejects it.

The worse variant: a scope value exists in the DB (from a manual migration or seed) that the
code does not recognize. `GET /api/roles/me` returns the grant with an unknown `feature_scope`
value. Civic Spaces calls the roles endpoint, receives an unrecognized scope, its conditional
check fails the wrong branch, and the volunteer gate silently denies access.

**Why it happens:** The v1.6 pitfall research (Pitfall 11) identified this and recommended "a
single TypeScript constant array used as both the Zod enum source and the DB CHECK constraint
value list." That recommendation stands — but v1.9 introduces a new surface: the contributor
portal is a separate frontend that may hardcode scope strings in its own gate logic. A third
definition point means three places must agree.

**Prevention:**
- Codify the single-source-of-truth pattern now: one TypeScript constant, used to generate
  both the Zod enum and the DB CHECK constraint SQL string.
- In the contributor portal, import the same constant (via a shared types package or a copied
  constants file with a prominent "DO NOT EDIT — generated from backend/src/lib/roles.ts"
  comment).
- Add a schema snapshot test: read the DB CHECK constraint for `feature_scope` at test time
  and assert it matches the TypeScript constant. This test fails immediately if they diverge.

**Warning signs:**
- Zod enum and DB CHECK constraint are defined in separate files with no automated sync check
- Portal hardcodes scope string literals in gate conditions
- A DB migration adds a new scope value without a paired code change

**Phase:** Role schema phase — establish the single-source pattern as the first artifact, before
any scope values are defined.

---

### Pitfall 18: Civic Spaces Volunteer Gate Fails Closed When Roles API Is Down

**What goes wrong:** Civic Spaces calls `GET /api/roles/me` to determine whether a user has a
volunteer role before granting access to moderation tools. If `api.empowered.vote` is unavailable
(Render sleep, deploy restart, network partition), the fetch fails. Civic Spaces has two options:
fail open (grant access) or fail closed (deny access). The instinct is "fail closed for security."
But for a volunteer who is mid-session, fail closed means immediate lockout with no explanation.

The secondary problem: Civic Spaces has no local cache of the role grant. Every page load or
navigation check triggers a fresh API call. Under Render's free-tier cold start (up to 30 seconds
for the first request), a volunteer opening Civic Spaces for the first time in an hour gets a
30-second delay before their role resolves.

**Why it happens:** Cross-service role checks are synchronous blocking operations in most naive
implementations. The dependency on an external service for gating creates a liveness dependency:
Civic Spaces is only as available as `api.empowered.vote`.

**Prevention:**
- The roles API response for `GET /api/roles/me` must include an explicit `cache_until` or
  `expires_at` field (e.g., 15 minutes). Civic Spaces caches the role list for that duration.
  Mid-session API unavailability does not cause lockout.
- Civic Spaces should treat a failed role fetch as "use last known state" when a cached grant
  exists, and as "deny access with retry prompt" when no cache exists. Never silently grant
  access on failure.
- For the cold start problem: the contributor portal and Civic Spaces should warm the roles call
  immediately on page load rather than gating it on a user action. Role data is cheap to fetch
  and rarely changes.
- Document the cache TTL as a contract in the roles API response, not a Civic Spaces
  implementation detail. If the backend wants to force re-check (e.g., after a role revocation),
  it returns `cache_until` set to the current time.

**Warning signs:**
- `GET /api/roles/me` is called inline in a gating conditional with no error handling
- No client-side cache for roles data
- Civic Spaces treats a network error the same as a "no roles" response

**Phase:** Contributor portal integration design phase — define the caching contract in the roles
API response shape before any consumer implements gating.

---

### Pitfall 19: Audit Log Architecture Test Not Updated When New Service Files Are Added

**What goes wrong:** The architecture test in `tests/integration/architecture.test.ts` has a
hardcoded `allowedFiles` list (line 50–69). New service files added for v1.9 — e.g.,
`lib/contributorService.ts`, `lib/auditService.ts` — will cause the "supabaseAdmin exists only
in expected files" test to fail if they import `supabaseAdmin`. This is not a bug in the new
service; it is a gap in the allowed-files list. But it looks like an architecture violation,
creating confusion.

The inverse problem: `auditService.ts` correctly imports `supabaseAdmin` (audit writes go through
the service role client to bypass RLS). If the developer adds it to `allowedFiles` to pass the
test, the test's security guarantee weakens — the list becomes "all service files" rather than
a curated set.

**Why it happens:** The test was designed for a stable set of service files. Every milestone adds
new services. The list drifts.

**Prevention:**
- When adding `lib/auditService.ts` or any other v1.9 service that requires `supabaseAdmin`,
  add it to `allowedFiles` in the architecture test in the same PR as the service file. Never
  let the test fail and fix it separately.
- Consider whether `auditService.ts` should use `pool.query()` instead of `supabaseAdmin` for
  audit writes — raw SQL gives more control and removes the need to add it to the allowed-files
  list. Audit writes are simple INSERTs; PostgREST is not needed.
- Document the rationale for each entry in `allowedFiles`. When the list is well-commented,
  additions require thought rather than reflexive copy-paste.

**Warning signs:**
- Architecture test is failing due to a new service file that was added without updating the list
- `allowedFiles` grows without any accompanying comment explaining why each entry is permitted

**Phase:** Any phase that introduces new service files — update the architecture test allowlist
in the same commit.

---

### Pitfall 20: role_assignments Audit Trail Uses application_user_id for Both Actor and Target

**What goes wrong:** An audit log row should record who did the action (actor = admin or system)
and who was affected (target = the user whose role changed). If the audit table stores only one
`user_id` column — defaulting to the authenticated user's ID — then admin-initiated grants are
logged with the admin's ID, but the target user's ID is lost. Querying "all role changes for
user X" requires scanning the payload JSON instead of a direct WHERE clause.

**Why it happens:** The simplest audit table schema mirrors other event tables:
`(id, user_id, action, created_at, metadata)`. This is sufficient for user-initiated events
(user X did thing to themselves). Role grants are admin-initiated: admin A granted role to
user B. The "user_id" is ambiguous.

**Consequences:** Audit queries for compliance become expensive JSON scans. "Show me all changes
to user B's roles" is not a simple indexed query. The audit log is technically complete but
operationally useless for the most common query pattern.

**Prevention:** The audit log table for role changes must have two explicit actor/target columns:
```sql
CREATE TABLE public.audit_log (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  actor_id      uuid NOT NULL REFERENCES auth.users(id),
  target_id     uuid REFERENCES auth.users(id), -- NULL for non-user-targeted events
  action        text NOT NULL,
  resource_type text NOT NULL,
  resource_id   text,
  metadata      jsonb,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX audit_log_target_id_idx ON public.audit_log (target_id, created_at);
CREATE INDEX audit_log_actor_id_idx ON public.audit_log (actor_id, created_at);
```
The `target_id` index makes "all changes to user B" fast without JSON scanning.

**Phase:** Audit schema phase — define the two-actor-column pattern before writing any RPCs
that call audit writes.

---

## Minor Pitfalls

---

### Pitfall 21: Contributor Portal Cookie Domain Mismatch on Non-Production Environments

**What goes wrong:** In production, `COOKIE_DOMAIN=.empowered.vote` makes `ev_session` available
to `contributors.empowered.vote`. In development, `COOKIE_DOMAIN` is empty, so the cookie is
scoped to `localhost` or the exact API domain. The contributor portal running on
`localhost:5174` (or whichever Vite port) cannot read a cookie set for `localhost:3000` — cookies
are port-agnostic for `localhost` but the domain mismatch still applies in some browsers.

**Prevention:** Document the local dev setup for contributor portal developers: they must either
(a) proxy through the same local Vite dev server that the accounts app uses (so same origin), or
(b) run the backend with a dev-specific `COOKIE_DOMAIN` override. Neither is obvious from reading
`env.ts`. Add a `CONTRIBUTING.md` or `.env.example` note.

**Phase:** Contributor portal setup phase — add to developer onboarding docs.

---

### Pitfall 22: GET /api/roles/me Cached by CDN or Proxy Strips Scope Dimensions for Other Users

**What goes wrong:** If any intermediate layer (Render's edge, a future CDN, or browser HTTP
cache) caches `GET /api/roles/me`, it will serve the same response to multiple users. This is
less likely on Render's current config (no CDN in front of the Express app), but the endpoint
has no `Cache-Control: private, no-store` header. If a caching layer is added later, the bug
appears silently.

**Prevention:** Add `Cache-Control: private, no-store` to `/api/roles/me` and any other
per-user endpoint that returns authorization state. This is a one-line addition per route but
prevents an entire class of authorization cache poisoning bugs.

**Phase:** Role API implementation phase — add Cache-Control headers as part of the initial
implementation.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Campaign Manager role schema | Politician-scope boundary not enforced at resource level | Layer 2 enforcement: role check + politician-jurisdiction join before any data is returned |
| Campaign Manager grant flow | Unintended double-grant for opposing candidates | Admin UI must show existing grants; define conflict rules before first grant RPC is written |
| Audit log schema | Two-actor pattern (actor + target) not established | audit_log must have `actor_id` and `target_id`; index both; define pattern in migration 0 |
| Audit log routes | New route added without audit call | Inline audit in SECURITY DEFINER RPC (preferred) OR architecture test enforcement |
| Contributor portal CORS | `contributors.empowered.vote` missing from CORS_ORIGIN | Deploy checklist item: add to Render env var before portal goes live |
| Contributor portal session | SameSite=Lax behavior on sibling subdomains misunderstood | Same-site subdomains work; root cause is always CORS config or missing credentials mode |
| feature_scope strings | Zod enum and DB CHECK constraint diverge | Single TypeScript constant → both Zod and SQL CHECK; schema snapshot test |
| Civic Spaces role gate | API unavailability = immediate volunteer lockout | roles response includes `cache_until`; clients cache and use last-known-state on failure |
| Architecture tests | New v1.9 service files not in allowedFiles list | Update allowlist in same PR as service file; consider pool.query() for audit writes |
| Audit log table growth | Unbounded INSERT-only table with no retention policy | Define retention policy in schema phase (90-day TTL or archive to cold storage) |

---

## Sources

**Codebase analysis (HIGH confidence):**
- `backend/src/index.ts` — CORS config: `credentials: true`, exact-match origin from `CORS_ORIGIN`
  env var, no wildcard in production
- `backend/src/routes/auth.ts` lines 17–25 — `evSessionCookieOptions()`: `SameSite=Lax`,
  `Secure: NODE_ENV === production`, `domain: COOKIE_DOMAIN`
- `backend/src/lib/env.ts` — `COOKIE_DOMAIN` optional, defaults to empty string; `CORS_ORIGIN`
  optional (comma-separated list)
- `backend/src/lib/roleService.ts` — `ROLE_CONFLICT_GROUPS` is empty for Alpha; grant_role RPC
  enforces duplicate prevention via partial unique index
- `backend/src/routes/roles.ts` — `GET /roles/me` returns flat list (`role_id, slug, name,
  granted_at`) with no resource scope or `Cache-Control` header
- `tests/integration/architecture.test.ts` — hardcoded `allowedFiles` list (lines 50–69);
  scans `src/routes/` for supabaseAdmin violations

**Web standards (HIGH confidence):**
- MDN — SameSite cookie attribute: subdomains of the same registrable domain are same-site;
  `SameSite=Lax` cookies are sent on same-site cross-origin fetch with `credentials: include`
- WHATWG Fetch spec — `credentials: include` requires `Access-Control-Allow-Origin` to be an
  explicit origin (not `*`) and `Access-Control-Allow-Credentials: true`

**Domain reasoning from codebase patterns (MEDIUM confidence):**
- Audit log two-actor pattern: derived from MEMORY.md `tolerance_rating` internal-field
  privacy conventions and the established advisory lock / idempotency key patterns in
  migrations 023 and 038. Not from external research.
- Civic Spaces lockout risk: derived from cross-service architecture established in v1.7
  (`GET /api/auth/session` pattern). Same availability dependency applies to role checks.
