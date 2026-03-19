# Domain Pitfalls

**Domain:** Scoped roles + compass compare + VR dashboard on existing Express/Supabase app
**Researched:** 2026-03-19
**Scope:** v1.6 features only — ROLES-01, COMP-05, VR-F01

---

## Critical Pitfalls

Mistakes that require schema rewrites, auth model rethinks, or data leaks.

---

### Pitfall 1: NULL Geo-Scope Treated as "No Match" Instead of "Global Match"

**What goes wrong:** The `jurisdiction_geoid` column on the new roles table is nullable, where NULL means "this role applies everywhere." A permission check written as `WHERE jurisdiction_geoid = $user_geoid` will silently drop all global grants when the caller passes any geoid — because NULL != any text. Result: global admin or developer roles appear to have no access at all.

**Why it happens:** SQL NULL inequality is not the same as "unset." `NULL = '18057'` is NULL (falsy), not false — it evaluates to nothing. A naive join or WHERE clause discards the row entirely.

**Consequences:** Admins locked out mid-migration. Feature-scoped roles (CTC Dev, Quest Dev) broken for users who should have global access. Extremely hard to debug because the roles rows exist in the DB — the bug looks like "role not granted" rather than "permission check wrong."

**Prevention:** The WHERE clause for geo-scope must be:
```sql
WHERE (jurisdiction_geoid IS NULL OR jurisdiction_geoid = $user_geoid)
```
This is required in every location that checks role authorization: the SECURITY DEFINER RPC, any service layer query, and any middleware guard. Treat the two-part clause as a mandatory pattern, not optional.

**Detection:** Write a test that grants a role with `jurisdiction_geoid = NULL` and asserts the user has access when passing a real geoid. If the test fails, the query has the bug.

**Phase:** ROLES-01 schema phase — establish the correct query pattern before any permission checks are written. Document it as a project rule in KEY DECISIONS.

---

### Pitfall 2: Compass Compare Leaking Private Responses Via Service Role Client

**What goes wrong:** `inform.compass_responses` already has three SELECT policies that combine via OR: owner select, friends select (visibility='friends'), public select (visibility='public'). A compare endpoint reading another user's responses through `supabaseAdmin` (service role) bypasses RLS entirely — it returns ALL responses for the target user including `visibility='private'`, which must never be exposed to a third party.

**Why it happens:** `supabaseAdmin` is the service role client — it bypasses RLS by design. The existing pattern of using it for admin reads is correct in admin context but wrong for user-facing compare where visibility rules are the entire point. The natural drift is to reach for `supabaseAdmin` because it is already imported in service files.

**Consequences:** Private compass answers exposed to any authenticated caller of the compare endpoint. This is a privacy violation, not just a bug — users explicitly set answers to private to keep them from peers. The `compass_responses: friends select` RLS policy comment (migration 022, line 130) already calls this out: "CRITICAL: the friends policy MUST include visibility='friends' predicate." The same reasoning applies to compare — the policy OR-combination gives access only when visibility is explicitly included.

**Prevention:** The compare endpoint must not use `supabaseAdmin` for target user's responses. The correct approach is a SECURITY DEFINER RPC that takes both user IDs and enforces the three-tier visibility model inside the function:
- If caller and target are accepted peers: return target's answers where `visibility IN ('friends', 'public') AND deleted_at IS NULL`
- If not peers: return target's answers where `visibility = 'public' AND deleted_at IS NULL`
- Always include caller's own answers (all visibility values, owner select)

**Detection:** Write a test that creates two non-peer users, gives target a private answer, and asserts the compare endpoint does NOT return that answer for the caller. This test must be written before implementation and kept in the test suite permanently.

**Phase:** COMP-05 — the service function signature must receive both the calling user's ID and the target user's ID. The visibility enforcement must happen in the RPC, not the route layer.

---

### Pitfall 3: is_admin / admin_users Drift From New Scoped Role System

**What goes wrong:** `requireAdmin` middleware reads from `public.admin_users` (a separate allowlist table). ROLES-01 adds feature-scoped roles. If ROLES-01 introduces its own "admin" role concept and some routes start using the new role check while others still depend on `requireAdmin`, two diverging auth paths emerge. A user revoked from `admin_users` may still hold the new admin role (or vice versa), creating unpredictable access.

**Why it happens:** Incremental migration without a defined cutover point. The natural pattern is "add new role check to new routes, leave old routes untouched." Over time the two systems diverge silently.

**Consequences:** Admin access inconsistency that is hard to audit. The admin audit log may capture actions from one path but not the other.

**Prevention:** The milestone context makes the correct boundary clear: `admin_users` and `requireAdmin` stay as-is for the existing admin panel. ROLES-01 adds five *developer* feature roles (CTC Dev, Quest Dev, Essentials Dev, Compass Dev, and a Compass Admin scope) that are separate from the admin_users allowlist. These two systems do not compete — admin_users gates the internal admin panel; feature roles gate cross-app API access. Document this boundary explicitly before any schema work begins so it cannot drift.

**Detection:** Architecture test that asserts `requireAdmin` imports from exactly one location and that `admin_users` is the sole source of truth for the admin panel gate.

**Phase:** ROLES-01 planning phase — define the boundary before schema design begins.

---

### Pitfall 4: `pool.query()` Omitted for Non-Public Schema Role Writes

**What goes wrong:** The existing roles tables (`public.roles`, `public.user_roles`) are in the `public` schema, where PostgREST writes work correctly. If ROLES-01 adds a geo-scope extension table in a non-public schema (e.g., a `connect.user_role_scopes` table), writes via `supabaseAdmin.schema('connect').from(...).insert()` will silently fail — they return success codes but no row is written.

**Why it happens:** The established critical production pattern: PostgREST is unreliable for writes to non-public schemas (documented in MEMORY.md and KEY DECISIONS). The bug was found and fixed across enrollService, auth.ts, connectService, compassService, etc. Adding a new non-public table and forgetting the pattern reintroduces the same failure.

**Consequences:** Role grants appear to succeed (HTTP 200) but no row is written. Users have no access. Hard to debug because the service layer shows no error.

**Prevention:** If any new roles table lands in a non-public schema, ALL writes must use `pool.query()`. The safer option for ROLES-01: extend `public.user_roles` with a `jurisdiction_geoid` column rather than creating a new non-public join table. Keeping the roles data in the public schema avoids the PostgREST write restriction entirely.

**Detection:** Integration test that grants a geo-scoped role and immediately reads it back. If the read returns empty, the write path is using PostgREST instead of pool.

**Phase:** ROLES-01 schema phase — if a new table is needed, put it in `public` schema unless there is a strong reason not to.

---

## Moderate Pitfalls

Mistakes that cause correctness bugs or significant rework.

---

### Pitfall 5: Compass Compare Returns Ambiguous Overlap Without Answer-Count Context

**What goes wrong:** User A has answered 15 topics. User B has answered 8 topics. The compare intersects on 5 shared topics. If the response returns only the 5 shared answers without indicating how many topics each user answered total, the consumer cannot distinguish "they agree on everything they both answered" from "they barely answered anything — 5 topics is their entire compass."

**Why it happens:** The simplest implementation is a SQL INNER JOIN on topic_id — it naturally returns only shared topics. The completeness metadata is discarded because it is not part of the join result.

**Consequences:** Frontend shows misleading "100% alignment" for two users who each answered only 2 topics, one of which matched. Users lose trust in the feature.

**Prevention:** The compare endpoint response must include per-user answer counts alongside the shared-topic comparison:
```json
{
  "shared_topics": [...],
  "user_a_answered": 15,
  "user_b_answered": 8,
  "shared_count": 5
}
```
CompassV2 uses these counts to display confidence context. Define the response shape in the COMP-05 API design plan before implementation.

**Phase:** COMP-05 API design phase.

---

### Pitfall 6: Geo-Scoped Permission Check Uses User's Residential GEOID Instead of Role Grant GEOID

**What goes wrong:** When checking whether a CTC Developer role applies to a given jurisdiction, the check looks up the caller's stored `congressional_district` from `connected_profiles` (set when they last set location). But geographic scope for a role is about what territory the role grant covers — not where the user physically lives.

**Why it happens:** The location infrastructure already stores the user's jurisdiction in `connected_profiles`. It is tempting to reuse those fields as "the user's geographic authority." The variable names look similar. The conceptual confusion is subtle.

**Consequences:** A CTC Developer granted scope for Monroe County is denied access when they are visiting another county (if the check reads their current location). Or a user whose residential jurisdiction coincidentally matches the role's scope gets access without holding the role. Completely wrong semantics.

**Prevention:** Geo-scope for permission checks must come from `user_roles.jurisdiction_geoid` (the grant row), not from `connected_profiles.congressional_district` or any other user location field. The check is: "does this user hold role X where jurisdiction_geoid IS NULL OR jurisdiction_geoid = [target_resource_geoid]?" The user's own residential jurisdiction is irrelevant to this check.

**Phase:** ROLES-01 schema phase — document in migration comments that `jurisdiction_geoid` on `user_roles` is the scope of authority, not the user's residential location.

---

### Pitfall 7: VR Dashboard Aggregate Query Silently Truncated by Supabase Row Limit

**What goes wrong:** A `GET /api/admin/vr-dashboard` implementation that fetches raw `connected_profiles` rows and counts them server-side in JS will silently return incomplete data once the cohort exceeds Supabase PostgREST's default row limit (1,000 rows, configurable but still a ceiling per request). At Alpha scale the bug is invisible.

**Why it happens:** At Alpha scale (tens of users), a simple SELECT * works fine. Nobody adds `.range()` or COUNT guards because the data fits easily. The dashboard is built and shipped. The bug emerges when the cohort grows.

**Consequences:** VR distribution charts show incomplete data. Hold counts are understated. Outlier detection misses users beyond the row-limit mark. An admin makes decisions on partial data without knowing it is partial.

**Prevention:** VR dashboard aggregations should be computed in a SECURITY DEFINER RPC that returns aggregated values directly — distribution buckets (e.g., [0-30]: 2 users, [31-60]: 45 users...), hold count, outlier list — rather than raw rows for JS-side aggregation. This is also better security hygiene: `vq_hold_until` is an internal field (excluded from `connected_profiles_public` view); an aggregate RPC can return derived booleans and dates without exposing raw timestamps.

**Detection:** Check whether any `supabaseAdmin.from('connected_profiles').select(...)` in the VR dashboard code has a `.range()` call or is routed through an aggregate RPC. If neither, the implementation is vulnerable to silent truncation.

**Phase:** VR-F01 implementation phase. Build an aggregate RPC rather than shipping raw-row reads.

---

### Pitfall 8: Compass Compare Omits the `deleted_at` Soft-Delete Filter

**What goes wrong:** `inform.compass_responses` uses soft-delete: `deleted_at IS NULL` marks active responses. A compare query written from scratch that does not include this filter returns stale pre-reset answers as if they were current, including responses the user deliberately cleared by resetting their compass.

**Why it happens:** The soft-delete pattern was established in v1.2 and is documented in KEY DECISIONS ("Soft-delete via deleted_at on compass_responses"). A new compare query written in a separate RPC or service file may not carry that context forward, especially if the author references the DB schema directly rather than reading the existing compass route code.

**Consequences:** Compare shows a user's old (reset) answers as if still current. User thinks they matched on topics they no longer hold positions on. Directly undermines the compare feature's value.

**Prevention:** Every query against `inform.compass_responses` must include `AND deleted_at IS NULL` (raw SQL) or `.is('deleted_at', null)` (PostgREST). Add a comment in the compare RPC echoing the project rule. This is the same rule already enforced in `GET /compass/answers` (line 162 of `compass.ts`: `.is('deleted_at', null)`).

**Phase:** COMP-05 implementation phase. If compare uses a SECURITY DEFINER RPC (recommended), add `AND deleted_at IS NULL` to the filter and note it in the migration comment.

---

### Pitfall 9: No Advisory Lock on Role Grant Allows Concurrent Double-Grant Race

**What goes wrong:** The existing `grant_role` RPC enforces "no duplicate active grant" via a partial unique index: `UNIQUE (user_id, role_id) WHERE revoked_at IS NULL`. Two concurrent requests for the same user+role may both pass the pre-INSERT check before either commits, resulting in a raw constraint violation error rather than the clean `ROLE_ALREADY_GRANTED` error.

**Why it happens:** The current grant RPC was sufficient for admin-only single-writer access in Alpha. Any programmatic grant path (e.g., auto-granting a feature role after integration setup) or concurrent admin grants changes the access pattern.

**Consequences:** Unhandled constraint violation bubbles up as a 500 error to the caller during concurrent access.

**Prevention:** If ROLES-01 adds any programmatic (non-admin-only) grant path, wrap the SECURITY DEFINER grant RPC with `pg_advisory_xact_lock(hashtext(p_user_id::text || p_role_id::text))` before the INSERT. This serializes concurrent grants for the same user+role combination. The pattern is already established in `connect.credit_gems` (migration 023) and `connect.confirm_vq_stance` (migration 038). Alternatively, catch the unique constraint violation in the service layer and map it to `ROLE_ALREADY_GRANTED`.

**Phase:** ROLES-01 RPC phase. Evaluate whether any v1.6 grant path is non-admin (if admin-only only, risk is low; if programmatic, add the lock).

---

## Minor Pitfalls

Mistakes that cause friction or fixable inconsistencies.

---

### Pitfall 10: `vq_hold_until` Raw Timestamp Exposed in Admin VR Dashboard

**What goes wrong:** The VR dashboard shows users on hold. The raw `vq_hold_until` timestamp is available via service role. Surfacing it directly creates pressure to display or share exact expiry times, which conflicts with the established privacy pattern (migration 037 comment: "vq_hold_until intentionally OMITTED — internal enforcement state, same as tolerance_rating").

**Prevention:** The VR dashboard response should derive `vq_hold_active: boolean` (same field already on `/api/account/me`) and optionally a `hold_expires_at` date string, not the raw TIMESTAMPTZ. Reserve raw timestamp handling to the aggregate RPC.

**Phase:** VR-F01 API design phase.

---

### Pitfall 11: Feature Scope Strings Not Validated Against Allowlist at API and DB Layers

**What goes wrong:** The role grant API accepts `feature_scope` as a string. Without a server-side allowlist (Zod enum) AND a DB-layer CHECK constraint, a caller can grant `feature_scope: 'ctc_dev '` (trailing space) or `feature_scope: 'CTCDev'` — values that look valid but never match any downstream permission check. The grant succeeds but the role is permanently inert.

**Prevention:** Define the feature scope allowlist in one TypeScript constant array used as both the Zod enum source and the DB CHECK constraint value list. Single source of truth prevents drift between layers.

**Phase:** ROLES-01 API design phase.

---

### Pitfall 12: `GET /api/roles/me` Returns Flat List Without Scope Dimensions

**What goes wrong:** The existing `GET /api/roles/me` returns `[{ role_id, slug, name, granted_at }]`. After ROLES-01, each grant has `feature_scope` and `jurisdiction_geoid`. Without updating the response shape, consumers cannot determine what scope a granted role covers — they cannot gate features correctly.

**Prevention:** Update `getUserRoles` return type and `GET /api/roles/me` response to include `feature_scope` and `jurisdiction_geoid` in each role object. Include this in the ROLES-01 API design plan explicitly as a breaking-change note to any consumers of this endpoint.

**Phase:** ROLES-01 API design phase — extend the response shape in the same phase as the schema, never after.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| ROLES-01 schema | NULL geo-scope dropped by naive WHERE clause | Mandatory `(jurisdiction_geoid IS NULL OR jurisdiction_geoid = $x)` pattern |
| ROLES-01 schema | Non-public schema writes via PostgREST silently fail | Extend `public.user_roles` with new column rather than a new non-public table |
| ROLES-01 boundary | admin_users and new role system diverge | Define scope boundary first: admin_users gates admin panel; ROLES-01 gates feature API access |
| ROLES-01 RPC | Concurrent grant race without advisory lock | Add `pg_advisory_xact_lock` if any programmatic grant path exists |
| ROLES-01 API | Feature scope strings not validated | Single allowlist constant drives both Zod enum and DB CHECK constraint |
| ROLES-01 API | `GET /roles/me` missing scope dimensions | Update response shape in same phase as schema |
| COMP-05 design | Geo-scope check uses residential location instead of role grant | Scope comes from `user_roles.jurisdiction_geoid`, not `connected_profiles` location fields |
| COMP-05 design | Compare response lacks answer-count context | Include `user_a_answered`, `user_b_answered`, `shared_count` in response shape |
| COMP-05 implementation | Private answers exposed via supabaseAdmin | SECURITY DEFINER RPC enforces visibility; service role client never used for compare reads |
| COMP-05 implementation | Soft-delete filter omitted from compare query | Every `compass_responses` query requires `AND deleted_at IS NULL` |
| VR-F01 design | `vq_hold_until` raw timestamp surfaced in UI | Derive `vq_hold_active` boolean + `hold_expires_at` date; never expose raw TIMESTAMPTZ |
| VR-F01 implementation | Raw row scan silently truncated at row limit | Aggregate RPC returns computed buckets and counts, not raw rows |

---

## Sources

**Codebase analysis (HIGH confidence):**
- `backend/src/lib/roleService.ts` — existing grant/revoke pattern and error codes
- `backend/src/routes/compass.ts` — optionalAuth pattern, `.is('deleted_at', null)` filter usage
- `backend/src/middleware/requireAdmin.ts` — current admin_users lookup, `admin_users` as sole source
- `backend/src/middleware/tierGuards.ts` — supabaseAdmin used in middleware by design
- `supabase/migrations/20260227000020_phase6_roles_schema.sql` — existing roles schema structure
- `supabase/migrations/20260227000022_phase6_rls_and_grants.sql` — line 130 CRITICAL comment on OR-policy visibility
- `supabase/migrations/20260315000037_phase27_verification_rating.sql` — vq_hold_until internal-field privacy pattern
- `supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql` — advisory lock pattern for concurrent writes
- `MEMORY.md` — "pool.query() for ALL non-public schema writes" production rule (Critical Production Pattern section)

**External research (MEDIUM confidence):**
- [Common Postgres RLS Footguns](https://www.bytebase.com/blog/postgres-row-level-security-footguns/) — OR-policy combination leaks (Pitfall 2)
- [Postgres RLS Implementation Guide](https://www.permit.io/blog/postgres-rls-implementation-guide) — restrictive vs permissive policy behavior
- [10 RBAC Best Practices 2025](https://www.osohq.com/learn/rbac-best-practices) — scoped roles vs global roles design (Pitfall 6)
- [Supabase PostgREST Aggregate Functions](https://supabase.com/blog/postgrest-aggregate-functions) — row limit context for VR dashboard (Pitfall 7)
