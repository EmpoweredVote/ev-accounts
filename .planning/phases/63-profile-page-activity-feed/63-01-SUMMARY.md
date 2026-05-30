---
phase: 63-profile-page-activity-feed
plan: 01
subsystem: api
tags: [express, postgres, pool.query, xp_transactions, connect-schema, activity-feed]

# Dependency graph
requires:
  - phase: 62-onboarding-restyle
    provides: no direct dependency — Phase 63 needs design tokens only
  - phase: 59-referral-code-system
    provides: connect.xp_transactions ledger (append-only XP history)
provides:
  - GET /api/account/me/activity endpoint returning last 20 XP transactions for Connected users
  - FIX-01 status: closed — invite label flows end-to-end (Phase 59 already resolved)
affects:
  - phase 63-02 (ProfilePage frontend — consumes /me/activity directly)
  - phase 65-dashboard-redesign (activity feed may surface on dashboard too)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pool.query for connect schema reads — PostgREST does not expose connect schema"
    - "description maps to source — xp_transactions has no description column; API contract hides schema detail"
    - "requireConnected gates tier-specific read endpoints before any DB work"

key-files:
  created: []
  modified:
    - backend/src/routes/account.ts

key-decisions:
  - "description field in activity response maps to source — avoids leaking schema column names and future-proofs the contract"
  - "FIX-01 closed: label round-trip confirmed working via code inspection — DashboardPage sends label, invites.ts reads it from req.body, inviteQuotaService passes it as $2 to generate_invite_code_if_allowed RPC"

patterns-established:
  - "Activity endpoint pattern: pool.query SELECT with LIMIT 20, map rows to API shape with description aliasing"

# Metrics
duration: 1min
completed: 2026-04-26
---

# Phase 63 Plan 01: Profile Page + Activity Feed (API) Summary

**GET /api/account/me/activity added to account.ts — reads connect.xp_transactions via pool.query, gated to Connected tier via requireConnected; FIX-01 (invite label round-trip) confirmed closed by code inspection**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-26T15:17:41Z
- **Completed:** 2026-04-26T15:18:51Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added `GET /me/activity` endpoint to `account.ts` (lines 317–352 after the edit) with `requireAuth, requireConnected` middleware chain — Inform-tier callers receive 403 before any DB work runs
- Endpoint reads `connect.xp_transactions` via `pool.query` (correct pattern — PostgREST does not expose the connect schema), returns `{ activity: [{ source, amount, description, created_at }] }` with `description` aliased from `source`
- Confirmed FIX-01 (invite label round-trip) is already resolved — label flows correctly through all three layers with no code change required

## Task Commits

Each task was committed atomically:

1. **Task 1: Add GET /me/activity endpoint to account.ts** - `34038fe` (feat)
2. **Task 2: Verify FIX-01 (invite label round-trip) — code inspection only** - no commit (no code change)

**Plan metadata:** (see docs commit below)

## Files Created/Modified
- `backend/src/routes/account.ts` — added `GET /me/activity` handler (34 lines) between `GET /me/jurisdiction` and `PATCH /me`

## Endpoint Details

**Path:** `GET /api/account/me/activity`  
**Middleware:** `requireAuth, requireConnected`  
**SQL:**
```sql
SELECT source, amount, created_at
FROM connect.xp_transactions
WHERE user_id = $1
ORDER BY created_at DESC
LIMIT 20
```
**Response shape:**
```json
{ "activity": [{ "source": "compass_calibration", "amount": 50, "description": "compass_calibration", "created_at": "2026-04-20T...Z" }] }
```
Empty history: `{ "activity": [] }` — never 404.

## FIX-01 Status: CLOSED

Code inspection confirmed the label flows end-to-end through all three layers:

| Layer | File | Evidence |
|-------|------|---------|
| Frontend | `app/src/pages/DashboardPage.tsx` line 224 | `body: JSON.stringify({ label: labelInput.trim() \|\| null })` |
| Route handler | `backend/src/routes/invites.ts` line 230 | `const { label } = req.body as { label?: string }` then `generateInviteCodeIfAllowed(userId, label?.trim() \|\| null)` |
| Service/RPC | `backend/src/lib/inviteQuotaService.ts` line 57-58 | `pool.query('SELECT ... FROM connect.generate_invite_code_if_allowed($1, $2)', [userId, label])` |

The field was renamed `optional_name` → `label` in Phase 59 and the entire chain was updated at that time. No gap exists. No code change was made for this task.

## Decisions Made

- **`description` aliases `source`:** `xp_transactions` has no `description` column. Rather than expose `source` twice or change the column name, the API shape maps `source` into `description` so the frontend can render a human-readable label without conditional logic and without coupling to schema column names.
- **FIX-01 closed by inspection, not runtime test:** The running app is not available in this environment. The code chain was verified by reading all three files. The Phase 59 rename (`optional_name` → `label`) updated every layer atomically, and there is no ambiguity in the code.

## Deviations from Plan

None - plan executed exactly as written.

Task 2 was specified as a code inspection (not a runtime test) in the plan's action block. The verification section listed a runtime smoke test as an option, but the plan's action and done criteria both specify documentation of the finding, which was accomplished via inspection.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `GET /api/account/me/activity` is live and compiles cleanly — Plan 63-02 can build the ProfilePage and call this endpoint directly
- FIX-01 is confirmed resolved — no follow-up plan needed for the invite label bug
- No blockers for Phase 63-02

---
*Phase: 63-profile-page-activity-feed*
*Completed: 2026-04-26*
