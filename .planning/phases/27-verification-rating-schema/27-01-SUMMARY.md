---
phase: 27-verification-rating-schema
plan: 01
subsystem: database, api
tags: [postgres, supabase, typescript, verification-rating, connected-profiles]

# Dependency graph
requires:
  - phase: 09-xp-schema
    provides: connected_profiles_public view definition (used as baseline for updated view)
  - phase: 22-gems-idempotency
    provides: partial index pattern applied to vq_hold index
provides:
  - verification_rating column on connect.connected_profiles (INTEGER NOT NULL DEFAULT 60, CHECK 0-150)
  - vq_hold_until column on connect.connected_profiles (TIMESTAMPTZ nullable)
  - Partial index idx_connected_profiles_vq_hold for hold-state queries
  - Updated connected_profiles_public view with verification_rating (vq_hold_until excluded)
  - GET and PATCH /api/account/me returns verification_rating, vq_hold_active, red_gem_quests_unlocked at root
  - connected_profile nested object exposes verification_rating, vq_hold_active, vq_hold_until for owner self-view
affects:
  - phase-28-vq-confirmation-flow (writes to verification_rating and vq_hold_until via RPCs)
  - phase-30-profile-hub (reads vr data from /me for display)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Derived boolean pattern: server computes vq_hold_active and red_gem_quests_unlocked from raw DB values — callers never do date math"
    - "Privacy layering: internal columns (vq_hold_until) excluded from public view, exposed only in owner self-view nested object"
    - "Default-forward pattern: inform-tier users without connected_profile get safe defaults (verification_rating: 60, vq_hold_active: false, red_gem_quests_unlocked: false) at root"

key-files:
  created:
    - supabase/migrations/20260315000037_phase27_verification_rating.sql
  modified:
    - backend/src/routes/account.ts
    - backend/src/types/database.types.ts
    - tests/integration/account.test.ts

key-decisions:
  - "verification_rating default is 60 — baseline unverified; 90+ unlocks Red Gem quests"
  - "vq_hold_until excluded from connected_profiles_public view — same privacy pattern as tolerance_rating (internal enforcement state)"
  - "red_gem_quests_unlocked is a root convenience field only — NOT added to connected_profile nested object"
  - "vq_hold_active computed as server-side boolean — clients never need to parse vq_hold_until directly"

patterns-established:
  - "Server-side derived booleans: compute vq_hold_active and red_gem_quests_unlocked from raw timestamps/integers before building response"
  - "Inform-tier defaults: root VR fields present with defaults even when connected_profile is null"

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 27 Plan 01: Verification Rating Schema Summary

**verification_rating and vq_hold_until columns on connected_profiles, with derived booleans (vq_hold_active, red_gem_quests_unlocked) on GET and PATCH /api/account/me**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T14:17:52Z
- **Completed:** 2026-03-15T14:20:55Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Migration 037 adds verification_rating (INTEGER NOT NULL DEFAULT 60, CHECK 0-150) and vq_hold_until (TIMESTAMPTZ nullable) to connect.connected_profiles with a partial index for hold-state queries
- Updated connected_profiles_public view includes verification_rating but intentionally excludes vq_hold_until (same privacy pattern as tolerance_rating)
- Both GET and PATCH /me handlers updated to return verification_rating, vq_hold_active, and red_gem_quests_unlocked at root level with inform-tier safe defaults

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration 037 — verification_rating and vq_hold_until columns** - `fd496d9` (feat)
2. **Task 2: Update GET and PATCH /me handlers + test whitelist** - `0972df8` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `supabase/migrations/20260315000037_phase27_verification_rating.sql` - ALTER TABLE, CHECK constraint, partial index, updated public view
- `backend/src/routes/account.ts` - Both GET and PATCH /me handlers updated with new SELECT fields and derived booleans
- `backend/src/types/database.types.ts` - connected_profiles Row/Insert/Update and connected_profiles_public view types updated with new columns
- `tests/integration/account.test.ts` - ALLOWED_ME_KEYS whitelist updated with is_admin, verification_rating, vq_hold_active, red_gem_quests_unlocked

## Decisions Made

- **verification_rating default 60**: "baseline unverified" score — below 90 threshold for Red Gem quests. Phase 28 adjusts upward on confirmed stances.
- **vq_hold_until excluded from public view**: internal enforcement state; publishing hold windows would allow users to predict and game enforcement timing.
- **red_gem_quests_unlocked at root only**: root-level convenience field — callers check this flag directly without needing to inspect the nested object or do threshold math.
- **Server-side boolean derivation**: vq_hold_active computed as `vq_hold_until > now()` on the server — clients receive a clean boolean, never raw timestamps.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated database.types.ts with new columns**

- **Found during:** Task 2 (TypeScript compile after editing account.ts SELECT strings)
- **Issue:** Supabase TypeScript client generates `SelectQueryError` when a SELECT string references columns not present in the type definition. verification_rating and vq_hold_until were not in the Row/Insert/Update types for connected_profiles or the connected_profiles_public view Row type.
- **Fix:** Added verification_rating (number, non-null with default) and vq_hold_until (string | null) to connected_profiles Row/Insert/Update; added verification_rating (number | null) to connected_profiles_public Row/Insert/Update
- **Files modified:** backend/src/types/database.types.ts
- **Verification:** npx tsc --noEmit passes cleanly
- **Committed in:** 0972df8 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary maintenance — database.types.ts must be kept in sync with migrations. No scope creep.

## Issues Encountered

None — plan executed as specified after the type file update.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 28 (VQ Confirmation Flow): connected_profiles now has the columns needed for RPCs that adjust verification_rating and set vq_hold_until
- Phase 30 (Profile Hub UI): /me response now includes all three VR fields at root for display
- Pre-existing test failures (architecture.test.ts, compass.test.ts, env-validation.test.ts) are unrelated to this plan and carry forward as known issues

---
*Phase: 27-verification-rating-schema*
*Completed: 2026-03-15*
