---
phase: 67-login-hub-+-inform-signup-flow
plan: 03
subsystem: backend-auth
tags: [postgres, pool.query, signup, display_name, inform-tier]

# Dependency graph
requires:
  - phase: 66-inform-profiles-backend-foundation
    provides: inform.inform_profiles table + trigger (auto-creates on user signup)
provides:
  - POST /api/auth/signup persists display_name to public.users on Inform path (no invite_code)
affects:
  - 67-login-hub-+-inform-signup-flow (ISUP-01 resolved)
  - 68-yellow-inform-profile-page (profile page reads display_name from public.users)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Non-fatal pool.query UPDATE after auth user creation — write best-effort, proceed to 201 on failure"
    - "Inform-path guard: if (!invite_code) — forks write logic between Inform and Connected signup flows"

key-files:
  created: []
  modified:
    - backend/src/routes/auth.ts

key-decisions:
  - "display_name update is non-fatal — if pool.query UPDATE fails, user still gets 201 and can update later from profile page"
  - "UPDATE uses pool.query (not PostgREST) — consistent with project pattern for non-public schema writes; public.users also written this way elsewhere in auth.ts"
  - "Guard is if (!invite_code), not if (tier === inform) — keeps logic tied to the actual branch decision point (invite presence) rather than a derived tier"

patterns-established:
  - "Non-fatal best-effort write after auth user creation: try { await pool.query(...) } catch (e) { console.error(...); } // proceed to 201"

# Metrics
duration: 3min
completed: 2026-04-27
---

# Phase 67 Plan 03: Display Name Inform Path Summary

**Non-fatal `pool.query` UPDATE in POST /api/auth/signup writes `display_name` to `public.users` when no `invite_code` is present (Inform signup path)**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-27T22:16:24Z
- **Completed:** 2026-04-27T22:19:18Z
- **Tasks:** 2 (Task 1: code change + build; Task 2: live curl + SQL verification)
- **Files modified:** 1

## Accomplishments

- Fixed the Inform signup path so `display_name` is persisted to `public.users` after `signUpWithEmail` succeeds
- Connected path (`signup_with_invite` RPC with `p_display_name`) left completely untouched
- Live curl test confirmed HTTP 201, `display_name = "Phase 67 Test User"` in DB, zero `connected_profiles` rows, one `inform_profiles` row

## Task Commits

1. **Task 1: Persist display_name to public.users on Inform signup path** - `ac319b5` (feat)
2. **Task 2: End-to-end verification** - no code change, verified in place

**Plan metadata:** (docs commit follows this summary)

## Files Created/Modified

- `backend/src/routes/auth.ts` — added 21-line non-fatal `if (!invite_code)` pool.query UPDATE block between the `!data.user` guard and the `invite_code && !legal_name` 422 guard

## Code Block Added

Location: inside `router.post('/signup', ...)` handler, after `!data.user` null check, before Phase 24 invite-code guard.

```ts
// Phase 67: Inform signup path persists display_name onto public.users.
if (!invite_code) {
  try {
    await pool.query(
      `UPDATE public.users
         SET display_name = $2,
             updated_at = now()
       WHERE id = $1`,
      [data.user.id, display_name]
    );
  } catch (updateErr) {
    console.error('[auth/signup] Failed to persist display_name for Inform user:', data.user.id, updateErr);
    // Intentionally non-fatal — proceed to 201 below.
  }
}
```

## Decisions Made

- `display_name` update is non-fatal — consistent with the non-fatal posture used for `signup_with_invite` and `migrate_guest_compass_state` in the same handler. User can fix their display name from the profile page.
- Guard on `!invite_code` (not `tier`) — the branch decision point is whether an invite was provided, not a computed tier value. This keeps the guard tight and honest.

## Curl + SQL Verification Results

**Test user:** `phase67-display-name-1777328303@empowered.vote`
**User ID:** `ccf34449-e3b1-4bc8-b4f8-95f99b72a820`

| Check | Expected | Result |
|-------|----------|--------|
| HTTP status | 201 | **201 Created** |
| `public.users.display_name` | "Phase 67 Test User" | **"Phase 67 Test User"** |
| `connect.connected_profiles` rows | 0 (Inform path) | **0 rows** |
| `inform.inform_profiles` rows | 1 (trigger fires on user create) | **1 row** |
| Backend error log | No "Failed to persist" line | **No error logged** |

## Connected Path Confirmation

The Connected path (`invite_code` present) is guarded by `if (!invite_code)` — the new block does NOT execute when `invite_code` is truthy. The `signup_with_invite` RPC call at line 224 continues to pass `p_display_name: display_name` exactly as before. No behavior change for Connected signup.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

Minor: initial SQL query used `public.users.email` column which doesn't exist (email lives on `auth.users`). Switched to querying by UUID (`id`). No code impact — verification-only.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- ISUP-01 (display_name persisted on Inform signup) is resolved
- Phase 68 (Yellow Inform Profile Page) can safely read `display_name` from `public.users` for any Inform user created after this fix
- Users created before this fix have `display_name = NULL`; the profile page should handle NULL gracefully (Phase 68 concern)

---
*Phase: 67-login-hub-+-inform-signup-flow*
*Completed: 2026-04-27*
