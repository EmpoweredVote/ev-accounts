# Feature Landscape — v1.6 Civic Identity & Roles

**Domain:** Civic identity platform — permission system, compass analytics, admin tooling
**Researched:** 2026-03-19
**Scope:** Three features: scoped roles (ROLES-01), compass compare (COMP-05), VR admin dashboard (VR-F01)

---

## Feature 1: Scoped Roles (ROLES-01)

**Context:** Currently, `is_admin` is a flat boolean on `public.users`. There is a `public.user_roles` lookup table and `public.roles` reference table already in production, but roles have no feature-scoping or geo-scoping. The real use case is: League of Women's Voters in Monroe County needs to edit politician stances for Compass, but only for Monroe County politicians.

### Table Stakes

Features that must exist for scoped roles to work at all — without these, the feature has no value.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Feature dimension on role grants | Without it, you can't distinguish "can edit Compass" from "is admin" | Medium | New column on `public.user_roles`: `feature_scope TEXT` referencing defined features |
| Geographic dimension on role grants | The Monroe County use case is the entire motivation | Medium | New column `jurisdiction_geoid TEXT NULL` (null = national). Text because GEOIDs are numeric strings like `"18105"` |
| `hasPermission(userId, feature, geoid?)` server function | Route middleware needs to call this to check if a request is authorized | Medium | Replaces `requireAdmin`; called by each protected route with the relevant feature + optional geoid |
| Seed the five feature scopes | CTC, Quest, Essentials, Compass, Admin — these are the v1.6 scope | Low | INSERT into a new `feature_scopes` reference or as a defined enum in the grant row |
| Migration: add feature_scope + jurisdiction_geoid to user_roles | Schema change — cannot ship without this | Low | ADD COLUMN on `public.user_roles`, update partial unique index |
| `grant_role` RPC updated to accept feature_scope + jurisdiction_geoid | Atomic grant path must carry the new fields | Medium | Existing SECURITY DEFINER RPC in migration 023; needs signature update |
| Revoke path handles scoped grants | A user may hold compass/national AND compass/Monroe County simultaneously; revoke must target the right row | Medium | Revoke RPC must accept feature_scope + jurisdiction_geoid to identify which grant to revoke |
| Admin UI: grant/revoke form updates | RolesPage.tsx currently uses raw UUID + slug; must add feature_scope + optional geoid fields | Medium | Two new fields in the Grant form; revoke form needs disambiguation if user holds same role with different scopes |
| Architecture test: `is_admin` retired from route files | The entire point of the feature | Low | Update `requireAdmin` middleware or replace usages with `hasPermission('admin')` |

### Differentiators

Features that make this implementation excellent, not just functional.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `is_admin` boolean retired (not just supplemented) | Clean break prevents two permission systems co-existing; eliminates "which one wins?" ambiguity | Medium | Requires updating all callers of `requireAdmin` middleware; `is_admin` column can remain for one milestone then be removed |
| Geo-scope uses raw GEOID string (not PostGIS join) | Comparing a stored GEOID string is O(1); computing the user's jurisdiction from encrypted lat/lng costs a Vault decryption + PostGIS query on every request | Low (once decided) | `jurisdiction_geoid = "18105"` (Monroe County FIPS) is stored directly on the grant row |
| `GET /api/roles/me` returns feature_scope + jurisdiction_geoid | Partners (CTC, VQ, Essentials) need to see their own effective permissions | Low | Extend existing response shape |
| Partial unique index updated: (user_id, role_id, feature_scope, jurisdiction_geoid) | A user should be able to hold Compass Dev nationally AND Compass Dev for Monroe County simultaneously | Low | NULLs are not equal in unique indexes — use `COALESCE(jurisdiction_geoid, '')` or a compound strategy |
| Conflict group: national Admin role implies all feature roles | Admin should not need a stack of per-feature grants; `hasPermission` checks Admin nationally as a fallback | Medium | Implemented in `hasPermission()` logic, not as stored inheritance |
| Feature-scoped middleware factory: `requireFeatureRole(feature, geoidParam?)` | Express middleware that checks the scoped permission cleanly; geoidParam is a URL param name to compare against | Medium | Pattern: `router.post('/compass/stance', requireFeatureRole('compass'))` |

### Anti-Features

Things to deliberately NOT build in v1.6.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Hierarchical permission inheritance stored in DB | Implicit inheritance creates invisible grants that are hard to audit and revoke | Define the Admin-implies-all rule as a runtime check in `hasPermission`, not as stored rows |
| Per-user permission caching in Redis | At Alpha scale (< 1000 users), cache hit rate doesn't justify invalidation complexity | Direct DB check per request; add caching when load testing shows it's needed |
| UI for creating new feature scopes | Feature scopes are platform-defined (CTC, Quest, Essentials, Compass, Admin) — not user-configurable | Seed the five scopes in migration; no UI for creating new ones in v1.6 |
| Role conflict enforcement for all pairs | ROLE_CONFLICT_GROUPS is currently empty; populating exhaustively blocks use cases not yet encountered | Only define the one obvious case: Admin national supersedes per-feature grants |
| Wildcard geo-scope ("all counties in state") | Adds a third GEOID value type creating three-way branching in every permission check | Two tiers only: national (null) or specific GEOID. Multiple counties = multiple grant rows |

### Dependencies on Existing Features

- `public.user_roles` table and partial unique index already exist (migration 020)
- `grant_role` + `revoke_role` RPCs exist (migration 023)
- `requireAdmin` middleware exists and must be updated or replaced
- `is_admin` column exists on `public.users` — must continue to work until fully migrated
- Jurisdiction GEOIDs are computed on demand (not stored on `connected_profiles`) — geo-scoping on grants uses explicitly provided GEOID strings

---

## Feature 2: Compass Compare (COMP-05)

**Context:** `inform.compass_responses` stores user answers with a `visibility` field. `inform.politician_answers` stores politician stances (588 values seeded). The compare endpoint was deferred from Phase 4 because the infrastructure needed to be in place first. Now it is. The primary consumer is Essentials, which will use compass overlap as the primary view when browsing elected officials.

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `GET /api/compass/compare/politician/:politicianId` — requester vs. politician | The Essentials primary use case; replaces profile picture list with compass overlap | Low | Politician answers are always public; only requester's answers have visibility filtering |
| `GET /api/compass/compare/user/:targetId` — requester vs. another Connected user | Core user-to-user compare path | Medium | Requires visibility check: only return target's answers where `visibility = 'public'` (or both are peer connections) |
| Response shape: agreed / disagreed / unanswered_by_requester / unanswered_by_target arrays | Consumers need these four buckets to render overlap | Low | Each item includes `topic_id`, `title`, `short_title`, and `value` for both parties |
| `overlap_count` and `overlap_percent` computed server-side | Clients get a ready-to-display number without computing it themselves | Low | `overlap_percent` = agreed / (agreed + disagreed) × 100, over topics both parties have answered |
| Visibility enforcement on user-to-user compare | "Private" answers must not be visible to non-owners | Low | Filter target's answers to `visibility = 'public'`; peer connection check upgrades visibility |
| Works unauthenticated (optional auth) | Inform-tier and anonymous visitors can browse politician compares in Essentials | Low | When unauthenticated, `agreed`/`disagreed` are empty (no requester answers); return politician answers only with a marker |
| 404 when target politician or user does not exist | Clean error path | Low | |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Optional `?topic_ids=` filter | Essentials can request compare scoped to a user's selected topics | Low | Filter both sides to the provided topic IDs before computing |
| Separate `unanswered_by_requester` bucket with topic titles | Enables "answer these topics to see your full overlap" CTA in Essentials | Low | Trivial set difference |
| Single SQL RPC for the full compare | Avoid N+1 queries; compute agreed/disagreed in Postgres, not application JS | Medium | SECURITY DEFINER RPC takes two entity IDs + entity types, returns bucketed JSONB |
| Peer connection check inline in RPC | Visibility enforcement at DB layer, not route layer | Medium | RPC checks `connect.social_relationships` for accepted connection before returning non-public answers |
| `agree` defined as value within ±0.5 of each other | Exact match is too strict given the 0.5-step scale; near-match reflects genuine alignment | Low | Tunable threshold; start at exact match and relax based on user feedback |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Caching compare results in Redis | Compare result changes every time either party updates an answer; invalidation requires hooking into `upsert_compass_answer`; not worth it at Alpha scale | Compute on every request; add caching post-Alpha if profiling shows it's needed |
| Multi-way compare (3+ users simultaneously) | Exponential complexity; no confirmed use case in v1.6 | Two-party compare only; multi-way is a distinct endpoint if needed later |
| `write_in_text` included in compare response | Write-in text is personal commentary, not a comparable stance value; exposing another user's write-in text raises privacy questions | Exclude `write_in_text` from compare; only `value` is used for agree/disagree |
| `inverted` field used to adjust comparison values | The `inverted` flag changes how a user visualizes a question, not what they believe; comparison should use raw `value` | Ignore `inverted` in compare computation |
| Expose target user's display_name in compare response | Compare endpoint should stay in the compass domain; profile data belongs to `/api/account/profile/:userId` | Return only `target_user_id`; caller fetches display metadata separately if needed |

### Dependencies on Existing Features

- `inform.compass_responses` with `visibility` column and `deleted_at` soft-delete (v1.0 + v1.2)
- `inform.politician_answers` (v1.0 + v1.3 — 588 stance values in production)
- `inform.compass_topics` for display metadata (title, short_title)
- `connect.social_relationships` for peer connection visibility check (v1.0)
- `optionalAuth` middleware pattern already established (v1.2)

---

## Feature 3: VR Admin Dashboard (VR-F01)

**Context:** `verification_rating` (INT 0–150, default 60) and `vq_hold_until` (TIMESTAMPTZ) are live on `connect.connected_profiles`. Admin can already manually override a user's VR on AccountDetailPage. What's missing is aggregate visibility: distribution across all users, users currently on hold, outliers. Alpha cohort is small (< 100 users), so this is a low-query-cost page.

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Distribution summary: counts by VR bucket | Without knowing the distribution, admin cannot tell if the system is working or calibrated incorrectly | Low | Buckets: 0 (hold-triggered), 1–59 (below default), 60–89 (default/at-baseline), 90–149 (Red Gem unlocked), 150 (capped at max) |
| Users currently on VQ hold list | Most urgent admin view — hold = user blocked from submitting VQ stances for up to 30 days | Low | `WHERE vq_hold_until IS NOT NULL AND vq_hold_until > now()` — partial index already exists |
| Hold expiry date per user | Admin needs to know when hold lifts without manual date math | Low | Return `vq_hold_until` ISO timestamp + computed `hold_days_remaining` integer |
| Direct link to AccountDetailPage from hold list | Admin needs one click to reach existing override controls | Low | Each row links to `/admin/accounts/:userId` |
| Count of users below unlock threshold (< 90) | Red Gem Quests are locked for these users — admin needs to know the scope | Low | Count of Connected users with `verification_rating < 90` |
| Backend: `GET /api/admin/vr-dashboard` endpoint | New route returning the aggregate view | Low | Single SQL query via raw `pool.query` or SECURITY DEFINER RPC |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Histogram bucket counts alongside per-user hold list | Admin gets the picture at a glance before drilling in; no second round-trip | Low | Return both aggregate and per-user data in the same response object |
| Users sorted by VR ascending (lowest first) | Lowest VR users are most at-risk and deserve first attention | Low | ORDER BY verification_rating ASC |
| VR = 0 users flagged in a separate section | VR = 0 is the extreme case that triggered the 30-day hold; it deserves visual distinction from "just below threshold" | Low | Separate panel in admin UI |
| `hold_days_remaining` integer returned | "Hold expires in 14 days" is more actionable than a raw ISO timestamp | Low | `CEIL(EXTRACT(EPOCH FROM (vq_hold_until - now())) / 86400)::int` computed server-side |
| Integration with existing override controls | Dashboard is read-only; admin drills to AccountDetailPage for overrides — no duplicate UI | Low | Already built in v1.4; no new mutation routes needed |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Real-time auto-refresh or WebSocket | Not necessary at Alpha scale; adds implementation cost for zero user benefit | Manual page refresh; add polling only if admin explicitly reports staleness as a problem |
| Bulk VR adjustment from dashboard | Single-user override already exists; bulk bypasses individual audit log entries and reduces accountability | Keep overrides single-user via AccountDetailPage |
| VR trend chart (historical over time) | Requires a separate VR audit log table not currently tracked; the `vq_confirmation_results` table doesn't have the right shape for trending | Note as a future enhancement in the UI; do not block the dashboard on it |
| Export to CSV | Not needed at Alpha scale (< 100 users) | Post-Alpha if partner orgs need it |
| VR breakdown by source (CTC vs VQ) | VR adjustments don't carry source attribution in the current schema | Document as a future enhancement; add source attribution to the hold/adjust flow in a later milestone |

### Dependencies on Existing Features

- `connect.connected_profiles.verification_rating` (migration 037, v1.4)
- `connect.connected_profiles.vq_hold_until` (migration 037, v1.4)
- `idx_connected_profiles_vq_hold` partial index already exists (migration 037)
- Admin authentication middleware (`requireAuth` + `requireAdmin`) already in place
- AccountDetailPage VR override UI already built (v1.4)

---

## Cross-Feature Dependencies

```
ROLES-01 depends on: existing user_roles table, existing roles reference table
COMP-05 depends on: compass_responses (visibility), politician_answers, social_relationships
VR-F01 depends on: verification_rating + vq_hold_until columns, partial hold index

ROLES-01 is independent of COMP-05 and VR-F01
COMP-05 is independent of ROLES-01 and VR-F01
VR-F01 is independent of COMP-05 and ROLES-01

All three can be built in parallel phases.
```

## MVP Recommendation

All three features are individually self-contained. Recommended delivery order based on risk:

1. **VR-F01 first** — Pure read-only aggregate query. No schema migrations, no new patterns. Lowest risk, high admin value. One endpoint + one admin page.

2. **COMP-05 second** — New endpoint with visibility semantics. Builds on established patterns (optionalAuth, SECURITY DEFINER RPC). Medium risk. Primary unblock for Essentials.

3. **ROLES-01 last** — Schema migrations, RPC signature changes, retiring `is_admin`, updating all admin middleware callers. Highest coordination cost. Must complete before any downstream feature-gating work.

Defer to post-v1.6:
- VR trend history (requires VR audit log table — not currently tracked)
- Multi-way compass compare
- Bulk VR operations
- Role permission caching
- VR source attribution (CTC vs VQ breakdown)

## Sources

- All findings based on direct codebase inspection (HIGH confidence)
- `public.user_roles` + `public.roles` schema: migration 020 (HIGH confidence)
- `grant_role` / `revoke_role` RPCs: migration 023 (HIGH confidence)
- `verification_rating` + `vq_hold_until` + partial index: migration 037 (HIGH confidence)
- `compass_responses.visibility`: compassService.ts + compass.ts routes (HIGH confidence)
- `connect.social_relationships` for peer visibility: social graph phase (HIGH confidence)
- Jurisdiction GEOIDs computed on demand via RPC, not stored on `connected_profiles`: account.ts + location RPC migration 032 (HIGH confidence)
- Alpha cohort size estimate (< 100 users): PROJECT.md context (HIGH confidence)
