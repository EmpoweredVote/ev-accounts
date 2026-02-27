---
phase: 06-gems-roles-social-graph
plan: 01
subsystem: database
tags: [postgres, supabase, rls, rpc, social-graph, gem-ledger, role-system, advisory-lock, security-definer]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: connected_profiles, gem_transactions, peer_connections, account_follows, user_roles tables + base RLS
  - phase: 04-compass-routes
    provides: inform.compass_responses table with visibility column and owner-only RLS
  - phase: 05-empower-flow
    provides: empower.empowered_profiles with is_active column (used by empowered-follows RLS policy)

provides:
  - gem_type column on gem_transactions + per-type balance columns (red/blue/yellow) on connected_profiles
  - updated connected_profiles_public view with per-type balances
  - public.roles lookup table with 5 active Alpha roles + 6 legacy inactive rows
  - user_roles migrated from role_type ENUM to role_id FK (ENUM and column dropped)
  - connect.social_relationships unified table replacing peer_connections + account_follows
  - RLS policies for social_relationships (4 policies), public.roles, user_roles owner read
  - Friends-visibility and public-visibility RLS policies on inform.compass_responses
  - connect.credit_gems and connect.debit_gems SECURITY DEFINER RPCs with advisory lock + SQL injection prevention
  - connect.create_peer_request SECURITY DEFINER RPC with bidirectional block enforcement

affects:
  - 06-02-service-layer (gem service, role service, social service — calls these RPCs)
  - 06-03-routes (GET /api/gems/balance, GET /api/roles/mine, POST /api/social/peer-requests)
  - 07-admin-tool (admin role grant/revoke endpoints — reads public.roles and user_roles)
  - 08-public-candidate-pages (may need social_relationships for follow counts on candidate pages)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pg_advisory_xact_lock(hashtext(user_id::text)): transaction-level serialization for concurrent gem operations"
    - "EXECUTE format() with pre-validated allowlist: dynamic column name access without SQL injection risk"
    - "Partial unique index on (user_id, role_id) WHERE revoked_at IS NULL: allows re-grant after revocation"
    - "Bidirectional OR lookup in single SELECT: covers both directions of a relationship without UNION"
    - "SECURITY DEFINER + SET search_path = '': Supabase-safe RPC pattern (established in Phase 1, extended here)"
    - "Declined-resend via DELETE+INSERT: stateless re-request without UPDATE (clean audit trail)"

key-files:
  created:
    - supabase/migrations/20260227000019_phase6_gems_schema.sql
    - supabase/migrations/20260227000020_phase6_roles_schema.sql
    - supabase/migrations/20260227000021_phase6_social_schema.sql
    - supabase/migrations/20260227000022_phase6_rls_and_grants.sql
    - supabase/migrations/20260227000023_phase6_rpcs.sql
  modified: []

key-decisions:
  - "gem_type column on single ledger table (not separate tables per type) — simplest schema, supports per-type advisory locks"
  - "Denormalized gem_balance_red/blue/yellow on connected_profiles — O(1) balance reads without ledger sum"
  - "public.roles lookup table replaces ENUM — new roles added by INSERT, no DDL required"
  - "Partial unique index on active roles — re-grant after revocation is INSERT not UPDATE"
  - "social_relationships unified table — one EXISTS join in friends RLS covers all peer contexts"
  - "idx_social_rel_accepted mandatory partial index — friends RLS would cause full table scan without it"
  - "No RLS INSERT/UPDATE/DELETE on social_relationships — all writes via SECURITY DEFINER or pg pool"
  - "Declined peer requests re-sendable via DELETE+INSERT in create_peer_request RPC"
  - "friends RLS MUST include visibility = 'friends' predicate — EXISTS alone would leak private responses via OR policy combination"

patterns-established:
  - "Gem debit pattern: advisory lock → FOR UPDATE balance read → balance check → UPDATE → ledger INSERT"
  - "SQL injection prevention: allowlist check before EXECUTE format() for dynamic column names"
  - "Bidirectional peer lookup: single OR query covers both actor→target and target→actor"

# Metrics
duration: 14min
completed: 2026-02-27
---

# Phase 6 Plan 1: Gems, Roles, and Social Graph — Schema Summary

**Three-type gem ledger with advisory-locked RPCs, ENUM-to-lookup role migration, and unified social_relationships table with friends-visibility RLS enforcement**

## Performance

- **Duration:** 14 min
- **Started:** 2026-02-27T19:08:54Z
- **Completed:** 2026-02-27T19:22:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Gem ledger extended with gem_type (red/blue/yellow) and per-type denormalized balance columns; credit_gems/debit_gems RPCs enforce atomic balance operations using pg_advisory_xact_lock + FOR UPDATE
- Role system migrated from rigid ENUM to flexible lookup table (public.roles); 5 active Alpha roles seeded; user_roles.role_id FK backfilled and role_type column + ENUM type dropped in one atomic transaction
- connect.social_relationships unified table replaces two Phase 1 tables (peer_connections, account_follows) with data migration and CASCADE drop; mandatory idx_social_rel_accepted index enables efficient friends-visibility RLS
- Friends-visibility RLS on compass_responses correctly requires BOTH the accepted-peer EXISTS check AND visibility = 'friends' predicate (prevents 'private' response leakage via OR policy combination)
- create_peer_request RPC enforces bidirectional block checks, declined-request re-send via DELETE+INSERT, and SELF_REQUEST guard

## Task Commits

Each task was committed atomically:

1. **Task 1: Gem schema + role schema migrations** - `7d66127` (feat)
2. **Task 2: Social schema + RLS + grants + RPCs migrations** - `fd8d7a2` (feat)

**Plan metadata:** (docs commit follows this summary creation)

## Files Created/Modified

- `supabase/migrations/20260227000019_phase6_gems_schema.sql` - gem_type column on gem_transactions, gem_balance_red/blue/yellow on connected_profiles, updated connected_profiles_public view, composite index
- `supabase/migrations/20260227000020_phase6_roles_schema.sql` - public.roles lookup table, 11 seeded rows, user_roles ENUM-to-FK migration (add role_id, backfill, NOT NULL, drop constraint, partial unique index, drop role_type, drop ENUM)
- `supabase/migrations/20260227000021_phase6_social_schema.sql` - connect.social_relationships unified table, 5 indexes, data migration from peer_connections + account_follows, CASCADE drops
- `supabase/migrations/20260227000022_phase6_rls_and_grants.sql` - 4 social_relationships RLS policies, public.roles authenticated-read, user_roles owner SELECT, compass_responses friends + public SELECT, GRANT statements
- `supabase/migrations/20260227000023_phase6_rpcs.sql` - credit_gems, debit_gems (SECURITY DEFINER, advisory lock, allowlist injection prevention), create_peer_request (bidirectional block enforcement)

## Decisions Made

- **gem_type on single ledger**: One `gem_transactions` table with a `gem_type` discriminator column is simpler than three separate ledger tables and naturally supports the advisory-lock pattern (lock keyed on user_id, not user+type)
- **Denormalized per-type balance columns**: `gem_balance_red/blue/yellow` on `connected_profiles` gives O(1) balance reads without summing the ledger; RPCs maintain these atomically
- **Partial unique index for active roles**: `UNIQUE (user_id, role_id) WHERE revoked_at IS NULL` allows re-granting a revoked role (new INSERT row) while preventing duplicate active grants — cleaner than full UNIQUE which would block re-grants
- **Unified social_relationships table**: One table with `connection_type` column instead of separate tables eliminates the need for UNION queries and simplifies the friends-visibility RLS EXISTS subquery
- **idx_social_rel_accepted is mandatory**: Without this partial index, every SELECT on compass_responses with a friends-visibility policy triggers a sequential scan of all social_relationships rows — documented prominently in migration 021
- **friends RLS requires visibility = 'friends' AND EXISTS**: The EXISTS peer check alone is not sufficient because Postgres combines multiple SELECT RLS policies with OR — a peer could see 'private' responses of an accepted friend without the visibility predicate

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Migrations are SQL files applied via `supabase db push` or Supabase dashboard.

## Next Phase Readiness

- All Phase 6 database infrastructure is in place: gem ledger, role lookup, social graph, RLS, and atomic RPCs
- Phase 6 Plan 2 (service layer) can now implement gemService.ts, roleService.ts, and socialService.ts that call these RPCs via supabase.rpc()
- The Phase 6 route layer can expose GET /api/gems/balance (reads gem_balance_red/blue/yellow), GET /api/roles/mine (reads user_roles with role_id FK), and POST /api/social/peer-requests (calls create_peer_request RPC)
- No blockers. The friends-visibility compass endpoint (user-to-user compare deferred from Phase 4) can now be wired — social_relationships + RLS are in place

---
*Phase: 06-gems-roles-social-graph*
*Completed: 2026-02-27*
