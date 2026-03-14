---
phase: 23-central-profile-page-admin-tier-promotion
plan: 01
subsystem: api
tags: [supabase, postgres, express, typescript, rpc, profile, admin, tier-promotion]

# Dependency graph
requires:
  - phase: 22-multi-currency-gem-system
    provides: gem_balance_yellow/blue/red columns on connected_profiles
  - phase: 21-essentials-politicians-admin-ui
    provides: inform.politicians table with full field set (district, jurisdiction, vacancy columns)
  - phase: 09-xp-ledger-leveling
    provides: total_xp column and calculate_level RPC
provides:
  - Migration 035: tier_promotion_log table, empowered_profiles.politician_id FK, connect.promote_to_connected RPC
  - GET /api/account/profile/:userId — public tier-conditional profile endpoint
  - GET /api/account/profile/me — owner profile with gems, email, location_consent
  - POST /api/admin/accounts/:userId/promote — atomic Inform→Connected promotion
  - GET /api/admin/accounts/:userId/promotion-history — paginated per-user promotion log
  - GET /api/admin/promotions — paginated global promotion log
affects:
  - 23-02 (admin UI profile page — consumes profile endpoints)
  - 23-03 (admin UI tier promotion — consumes promote endpoint and global log)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "profileService.ts pattern: all reads via supabaseAdmin, tier-conditional shape, internal fields stripped before public return"
    - "getAdminEmailById helper: wraps supabaseAdmin.auth.admin.getUserById in lib/ to satisfy architecture test (no supabaseAdmin in routes/)"
    - "tier_promotion_log: denormalized admin_email column avoids auth schema join at read time"

key-files:
  created:
    - supabase/migrations/20260314000035_phase23_tier_promotion.sql
    - backend/src/lib/profileService.ts
    - backend/src/routes/profile.ts
  modified:
    - backend/src/index.ts
    - backend/src/lib/adminService.ts
    - backend/src/routes/admin.ts
    - backend/src/types/database.types.ts
    - tests/integration/architecture.test.ts

key-decisions:
  - "politician_id FK on empowered_profiles is the ONLY join path to inform.politicians — no slug-based join exists"
  - "getAdminEmailById delegates getUserById to lib/adminService.ts — architecture rule prohibits supabaseAdmin in routes/"
  - "tier_promotion_log.admin_email denormalized at write time — avoids auth schema join at read time (same pattern as Supabase admin_audit_log)"
  - "profileService reads gem/location_consent internally but strips them before getPublicProfile return — single fetch, no second round-trip"

patterns-established:
  - "Profile aggregation: fetch all tier tables in parallel, derive tier from child record presence, build shape conditionally"
  - "Tier-conditional public shape: Inform (username/tier only), Connected (adds level/XP/topics), Empowered (adds politician block/compass answers)"
  - "Internal extended type pattern: _-prefixed fields carry owner-only data through fetchInternalProfile, stripped by getPublicProfile, used by getOwnerProfile"

# Metrics
duration: 8min
completed: 2026-03-14
---

# Phase 23 Plan 01: Backend Foundation — Profile Service + Admin Tier Promotion Summary

**Tier-conditional public profile API (inform/connected/empowered shapes) + atomic admin promote-to-connected RPC with audit log, using politician_id FK for empowered profile enrichment**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-14T15:33:26Z
- **Completed:** 2026-03-14T15:41:28Z
- **Tasks:** 2
- **Files modified:** 7 (2 new, 5 modified)

## Accomplishments

- Migration 035 creates `connect.tier_promotion_log`, adds `empowered_profiles.politician_id` FK, and creates atomic `connect.promote_to_connected` SECURITY DEFINER RPC
- Public profile endpoint serves tier-conditional shapes: Inform (username/tier), Connected (adds level/XP/selected_topics), Empowered (adds politician fields from inform.politicians + compass answers)
- Owner profile endpoint adds gem balances, location_consent, and email on top of the public shape — single internal fetch, no extra round-trips
- Admin promote endpoint resolves admin email server-side via `getAdminEmailById` helper, returns 409 for already-Connected users, logs via `logAdminAction`
- Paginated promotion log endpoints (per-user and global) with `target_display_name` batch-attached on global log

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration + Profile Service + Profile Routes** - `543e66f` (feat)
2. **Task 2: Admin Promotion Endpoint + Promotion Log Endpoints** - `c830c1b` (feat)

## Files Created/Modified

- `supabase/migrations/20260314000035_phase23_tier_promotion.sql` — tier_promotion_log table, politician_id FK, promote_to_connected RPC
- `backend/src/lib/profileService.ts` — getPublicProfile, getOwnerProfile (all reads via supabaseAdmin)
- `backend/src/routes/profile.ts` — GET /me (auth) before GET /:userId (public)
- `backend/src/index.ts` — mount /api/account/profile before /api/account
- `backend/src/lib/adminService.ts` — getAdminEmailById, promoteToConnected, getPromotionHistory, getGlobalPromotionLog
- `backend/src/routes/admin.ts` — POST promote, GET promotion-history, GET promotions
- `backend/src/types/database.types.ts` — politician_id added to empower.empowered_profiles, tier_promotion_log added to connect schema
- `tests/integration/architecture.test.ts` — profileService.ts added to supabaseAdmin allowlist

## Decisions Made

- **politician_id FK is the ONLY join path** — inform.politicians has no slug column; plan note confirmed no join exists via candidates.ts. politician_id on empowered_profiles is the sole join path added in migration 035.
- **getAdminEmailById in lib/adminService.ts, not in routes** — Architecture test prohibits `supabaseAdmin` in route files. Plan spec says `supabaseAdmin.auth.admin.getUserById` is the only acceptable method. Resolved by wrapping in a lib helper, which satisfies both constraints.
- **database.types.ts manually updated** — Added `politician_id` to empower.empowered_profiles Row/Insert/Update shapes and added `tier_promotion_log` table to connect schema. Matches the established pattern from Phase 20-03 (location_consent was similarly missing).
- **profileService.ts on architecture allowlist** — profileService uses supabaseAdmin for all reads (public endpoint has no JWT). Added to tests/integration/architecture.test.ts allowlist alongside other lib/*Service.ts files.

## Deviations from Plan

None — plan executed exactly as written.

The one architectural constraint (supabaseAdmin in routes) was anticipated by creating `getAdminEmailById` in adminService.ts, which the plan implicitly required (plan said "resolve via supabaseAdmin.auth.admin.getUserById" but architecture rule prohibits supabaseAdmin in routes; the helper pattern is the established solution in this codebase).

## Issues Encountered

- TypeScript: `empowered_profiles.politician_id` not in database.types.ts (new migration column). Manually added per established pattern from Phase 20-03. Also added `tier_promotion_log` to connect schema types.
- TypeScript: `username` derived via nullish coalescing chain could be `string | null`. Fixed with explicit `string` annotation and `|| ''` fallback.
- TypeScript: `displayNameMap` typed as `Record<string, string>` but `user.display_name` is `string | null`. Fixed to `Record<string, string | null>`.

## User Setup Required

None — no external service configuration required. Migration 035 applies at next deploy.

## Next Phase Readiness

- All backend APIs for Phase 23 Plans 02 and 03 are ready
- GET /api/account/profile/:userId — tested by Plans 02/03 admin UI profile page
- POST /api/admin/accounts/:userId/promote — consumed by Plan 02 admin tier promotion UI
- GET /api/admin/accounts/:userId/promotion-history and GET /api/admin/promotions — consumed by Plan 03 promotion log views
- Migration 035 must be applied to live DB before Phase 23 features go live

---
*Phase: 23-central-profile-page-admin-tier-promotion*
*Completed: 2026-03-14*
