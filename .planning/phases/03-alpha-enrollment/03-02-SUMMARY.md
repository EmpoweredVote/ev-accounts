---
phase: 03-alpha-enrollment
plan: 02
subsystem: api
tags: [express, rate-limit, postgresql, invite-system, pg-pool, atomic-transactions]

requires:
  - phase: 03-01
    provides: connect.invite_codes and connect.invite_chains tables, connect.adjust_inviter_tolerance_rating RPC, architecture test allowlist pre-approving inviteService.ts and enrollService.ts

provides:
  - backend/src/lib/inviteService.ts — invite code generation (crypto, 32-char unambiguous charset), batch create with collision retry, atomic pg FOR UPDATE claim, invite chain recording
  - backend/src/lib/enrollService.ts — email plus-addressing normalization, fire-and-forget TR adjustment via supabaseAdmin RPC
  - backend/src/routes/invites.ts — POST /api/invites/send (requireConnected, 5-pending cap, 10/day rate limit), POST /api/invites/claim (requireAuth only, atomic), GET /api/invites/mine (whitelist-serialized)
  - backend/src/index.ts — invitesRouter mounted at /api/invites

affects: [03-03-connect-flow, 05-empower-flow]

tech-stack:
  added: []
  patterns:
    - pg FOR UPDATE row lock for atomic claim (same pool pattern as future empower/demotion transactions)
    - Service layer wrapping all admin writes — routes import named functions, never pool or supabaseAdmin directly
    - Whitelist serialization in GET routes — map to explicit safe fields, never spread full DB row to client
    - User-keyed rate limiting (keyGenerator returns userId) — prevents shared-IP false throttling

key-files:
  created:
    - backend/src/lib/inviteService.ts
    - backend/src/lib/enrollService.ts
    - backend/src/routes/invites.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "ClaimResult.codeId added to success branch — required by POST /api/connect/start (Plan 03) to record invite_code_id on verification_session"
  - "FOR UPDATE blocking lock (not NOWAIT) — second concurrent claim blocks and then reads is_claimed=true, no retry logic needed in service layer"
  - "Admin-created codes (created_by=NULL) succeed without invite_chain insert — no inviter to hold accountable"
  - "Rate limiter keyed on userId not IP — connected users on shared WiFi should not deplete each other's send quota"
  - "POST /claim requires requireAuth only (no requireConnected) — user is in the process of BECOMING Connected"

patterns-established:
  - "inviteService/enrollService: file-level WHY comment explaining service boundary, mirrors authService.ts pattern"
  - "pg pool FOR UPDATE: BEGIN, SELECT FOR UPDATE, validate, mutate, COMMIT — try/catch/finally with client.release() in finally"
  - "Whitelist serialization: GET /mine maps codes to explicit safe fields rather than returning DB row directly"

duration: 20min
completed: 2026-02-25
---

# Phase 3 Plan 02: Invite System Summary

**Atomic invite code generation and claim system with pg FOR UPDATE locking, rate limiting, and invite chain accountability — complete lifecycle from generation through claim.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-02-25
- **Completed:** 2026-02-25
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Invite code generation using `crypto.randomBytes` with 32-char unambiguous charset (no 0, O, 1, I, L), formatted `XXXX-XXXX`
- Atomic invite claim via pg `FOR UPDATE` row lock — two concurrent claims for the same code cannot both succeed
- Invite chain permanently recorded on claim (`inviter_id`, `invitee_id`, `invite_code_id`) — admin-created codes skip chain insert
- Connected users capped at 5 pending codes + 10 sends/day rate limit (user-keyed, not IP-keyed)
- Architecture constraint enforced: zero `supabaseAdmin` references in `routes/` directory

## Manual Commits Required

The Bash tool is non-functional in this environment (EINVAL on temp directory writes). Run these git commands manually:

```bash
# Task 1: Invite and enrollment service layer
git add backend/src/lib/inviteService.ts backend/src/lib/enrollService.ts
git commit -m "feat(03-02): invite and enrollment service layer

- generateInviteCode: 32-char unambiguous charset via crypto.randomBytes
- createInviteCodes: batch INSERT with collision retry (max 3 per slot)
- claimInviteCode: atomic pg FOR UPDATE with self-invite and expiry checks
- ClaimResult includes codeId field — required by Plan 03 connect/start
- Invite chain recorded on claim (skipped for admin-created codes)
- normalizeEmail: lowercase + plus-addressing strip
- adjustInviterToleranceRating: supabaseAdmin.schema('connect').rpc() call
"

# Task 2: Invite routes with rate limiting
git add backend/src/routes/invites.ts backend/src/index.ts
git commit -m "feat(03-02): invite routes with rate limiting

- POST /api/invites/send: requireConnected, 10/day rate limit, 5 pending cap
- POST /api/invites/claim: requireAuth only, atomic claim with error mapping
- GET /api/invites/mine: requireConnected, whitelist-serialized response
- Mounted at /api/invites in index.ts
"

# Plan metadata (run after STATE.md is updated)
git add .planning/phases/03-alpha-enrollment/03-02-SUMMARY.md .planning/STATE.md
git commit -m "docs(03-02): complete invite system plan"
```

## Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `backend/src/lib/inviteService.ts` | Created | Invite code generation, batch create, atomic claim, invite chain recording |
| `backend/src/lib/enrollService.ts` | Created | Email normalization, TR adjustment RPC caller |
| `backend/src/routes/invites.ts` | Created | POST /send, POST /claim, GET /mine — rate-limited, whitelist-serialized |
| `backend/src/index.ts` | Modified | Added invitesRouter import and mount at /api/invites |

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| `ClaimResult` includes `codeId` on success | Plan 03's `POST /api/connect/start` needs to record `invite_code_id` on `verification_session` — returning it from the claim avoids a separate lookup |
| `FOR UPDATE` blocking (not NOWAIT) | NOWAIT would require application-level retry logic; blocking is simpler and correct — the second request naturally serializes and reads `is_claimed=true` |
| Admin-created codes skip chain insert | `invite_chains.inviter_id` is NOT NULL in schema; NULL-inviter codes have no accountability chain to record |
| Rate limiter keyed on `userId` | Connected users should not deplete each other's daily invite quota when sharing public WiFi or a corporate IP |
| `POST /claim` — `requireAuth` only | The invite claim is the gateway to becoming Connected — requiring Connected here would make enrollment impossible |

## Deviations from Plan

### Auto-fixed Issues

**1. [Objective instructions override] ClaimResult type extended with `codeId`**

- **Found during:** Task 1 (inviteService.ts implementation)
- **Issue:** The plan's original `<action>` section defined `ClaimResult` without a `codeId` field. The execution objective notes explicitly state that `codeId` must be returned on success — required by `POST /api/connect/start` (Plan 03) to record `invite_code_id` on the verification session.
- **Fix:** Added `codeId: string` to the success branch of `ClaimResult`. The `claimInviteCode` function returns `{ success: true, inviterId, codeId: row.id }`.
- **Files modified:** `backend/src/lib/inviteService.ts`
- **Impact:** Non-breaking additive change. Plan 03 integration works without an extra lookup.

---

**Total deviations:** 1 (objective clarification applied — not a scope deviation)
**Impact on plan:** Additive field only. No behavior change to existing contract. Plan 03 integration enabled.

## Issues Encountered

- Bash tool remains non-functional (EINVAL); all file operations performed via Write/Edit tools
- TypeScript compilation check (`npx tsc --noEmit`) must be run manually after committing

## Next Phase Readiness

Ready for `03-03-PLAN.md` (Connect verification flow). Dependencies satisfied:

- `POST /api/invites/claim` returns `codeId` — usable directly by `POST /api/connect/start`
- `enrollService.adjustInviterToleranceRating` is wired and ready to be called on sanction events
- `invitesRouter` is mounted — invite endpoints are live in the application
- Architecture constraint confirmed: zero `supabaseAdmin` in `routes/invites.ts`

---
*Phase: 03-alpha-enrollment*
*Completed: 2026-02-25*
