---
plan: 24-01
phase: 24-public-auth-hub
subsystem: auth
status: complete
completed: 2026-03-14
tags: [auth, signup, invite, rpc, access-requests, is-admin]

dependency-graph:
  requires: [23-01, 23-02, 23-03]
  provides: [signup-with-invite-rpc, access-requests-table, request-access-endpoint, is-admin-on-me]
  affects: [24-02]

tech-stack:
  added: []
  patterns: [atomic-signup-via-rpc, service-helper-pattern, fail-closed-admin-check]

key-files:
  created:
    - supabase/migrations/20260314000036_phase24_signup_with_invite.sql
  modified:
    - backend/src/routes/auth.ts
    - backend/src/routes/account.ts
    - backend/src/lib/adminService.ts
    - backend/src/types/database.types.ts

decisions:
  - key: signup-with-invite-non-fatal-unknown-errors
    value: Unknown RPC errors from signup_with_invite are non-fatal — auth user already created
  - key: invite-code-validation-order
    value: invite_code without legal_name returns 422 before auth user creation; invite code validation happens after auth user creation
  - key: is-admin-fails-closed
    value: isUserAdmin() returns false on error (fail closed); a DB error doesn't promote a user to admin

metrics:
  duration: 9 minutes
  tasks-completed: 2
  commits: 2
---

# Phase 24 Plan 01: Public Auth Hub Backend Summary

**One-liner:** Atomic signup-with-invite RPC, access_requests waitlist table, request-access endpoint, and is_admin boolean on GET /me.

## What Was Built

Migration 036 creates `public.access_requests` (waitlist email capture) and `connect.signup_with_invite` — a `SECURITY DEFINER` RPC that atomically validates an invite code, claims it, creates a `connected_profiles` row, and records the invite chain in one transaction. The Express signup route is extended to call this RPC when `legal_name` + `invite_code` are provided, while remaining backward-compatible for callers that provide neither. A new `POST /api/auth/request-access` endpoint captures emails from users without invite codes. `GET /api/account/me` now returns `is_admin: boolean` for all authenticated users.

## Deliverables

| Artifact | Description |
|---|---|
| `supabase/migrations/20260314000036_phase24_signup_with_invite.sql` | `public.access_requests` table + `connect.signup_with_invite` SECURITY DEFINER RPC |
| `backend/src/routes/auth.ts` | Extended signup with invite logic; new `POST /request-access` endpoint |
| `backend/src/routes/account.ts` | `is_admin: boolean` added to GET and PATCH /me responses |
| `backend/src/lib/adminService.ts` | `isUserAdmin()` and `insertAccessRequest()` helpers |
| `backend/src/types/database.types.ts` | `access_requests` table type + `signup_with_invite` function type |

## Key Decisions

**invite_code without legal_name returns 422 before auth user creation**
The validation check is placed before the Supabase auth call so the user is not created at all for this invalid combination. This is cleaner than creating an orphaned auth user.

**Unknown RPC errors are non-fatal for signup**
When `signup_with_invite` fails with an unrecognized error, the signup still returns 201 (auth user was created). The user can claim a Connected profile later through the Connect flow. Specific errors (`INVALID_OR_CLAIMED_CODE`, `SELF_INVITE_BLOCKED`) surface to the client as 422s.

**`insertAccessRequest` and `isUserAdmin` in adminService.ts, not in routes**
Architecture test enforces that `supabaseAdmin` cannot appear in any file under `src/routes/`. Both new functions that require service role are placed in `adminService.ts` following the established service-helper pattern.

**`is_admin` fails closed**
`isUserAdmin()` returns `false` on error. A DB connectivity issue can never accidentally promote a user to admin.

## Deviations from Plan

### Auto-fixed Issues

**[Rule 1 - Bug] Comment in auth.ts contained "supabaseAdmin" string**

- **Found during:** Task 2 verification
- **Issue:** The JSDoc comment added to `POST /request-access` contained the string `supabaseAdmin` (explaining that it is NOT imported here). The architecture test does a raw string scan — it does not distinguish comments from imports.
- **Fix:** Rewrote the comment to describe the pattern without using the word `supabaseAdmin`.
- **Files modified:** `backend/src/routes/auth.ts`
- **Commit:** Included in e4a9c71 (same Task 2 commit)

## Architecture Notes

The `access_requests` table has RLS enabled with no user-facing read policy. `GRANT SELECT TO authenticated` prevents PostgREST from hiding the table entirely, but the absence of any policy means all reads by non-admin users are blocked. Admin reads use `supabaseAdmin` via `adminService.ts`.

The `signup_with_invite` RPC uses `FOR UPDATE` on the `invite_codes` row to prevent concurrent claims on the same code — the same pattern as the existing `claim_invite_code` RPC in migration 025.

## Authentication Gates

None encountered during execution.

## Commits

| Hash | Message |
|---|---|
| dc4048e | feat(24-01): migration 036 — signup_with_invite RPC + access_requests table |
| e4a9c71 | feat(24-01): signup with invite_code, request-access endpoint, is_admin on /me |

## Next Phase Readiness

**Phase 24-02** (frontend) can now wire:
- Signup form with `legal_name` + `invite_code` fields → `POST /api/auth/signup`
- "Request access" form → `POST /api/auth/request-access`
- Post-login routing based on `is_admin` and `completed_onboarding` from `GET /api/account/me`
