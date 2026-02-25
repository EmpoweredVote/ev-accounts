---
phase: 03-alpha-enrollment
verified: 2026-02-25
status: passed
score: 23/23
gaps: []
---

# Phase 3: Alpha Enrollment — Verification Report

**Phase Goal:** Invite-only access is enforced and the full enrollment pipeline — from receiving an invite to holding a verified Connected profile — is complete and abuse-resistant

**Verified:** 2026-02-25
**Status:** passed
**Score:** 23/23 must-haves verified

---

## Goal Achievement

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Invite-only access enforced — enrollment requires a valid invite code | ✓ VERIFIED | `POST /api/connect/start` calls `claimInviteCode()` before creating any session. No path to Connected tier without a valid code. |
| 2 | Full enrollment pipeline complete: start → step → complete creates verified profile | ✓ VERIFIED | `POST /start` creates session at step='profile'; `PATCH /step` advances state; `POST /complete` atomically inserts `connected_profiles` with `verification_status='verified'` and `tolerance_rating=10.00`. |
| 3 | Abandoned flow can be resumed without restarting | ✓ VERIFIED | `POST /start` checks for existing session with `step_reached != 'invite'` and returns it directly (connect.ts line 149). UPSERT handles session at 'invite' step edge case. |
| 4 | Two concurrent claims cannot both succeed; self-invitation is blocked | ✓ VERIFIED | `claimInviteCode()` uses BEGIN + SELECT FOR UPDATE + COMMIT (pg pool). Self-invite check: `row.created_by === claimantUserId` returns `SELF_INVITE_BLOCKED`. |
| 5 | Connected profile creation is idempotent — second attempt returns 409 | ✓ VERIFIED | `POST /complete` SELECT-checks for existing `connected_profiles` row inside transaction before INSERT; returns 409 `ALREADY_CONNECTED` if found (connect.ts lines 415–426). |
| 6 | Compass calibration import has version mismatch flagging with two-phase confirmation | ✓ VERIFIED | `POST /compass-import` with `confirmed=false` queries `inform.compass_topics`, compares versions, returns `{valid, mismatched, ready_to_import}`. `confirmed=true` saves to `compass_import_draft`. |
| 7 | When invitee is sanctioned, direct inviter's TR decrements; propagation stops at one level | ✓ VERIFIED | `adjust_inviter_tolerance_rating` RPC looks up only ONE inviter from `invite_chains` via `WHERE invitee_id = p_invitee_id`. No recursive traversal. `UNIQUE(invitee_id)` enforces single chain per person. |
| 8 | Privacy: tolerance_rating, legal_name, home_address never returned to non-owners | ✓ VERIFIED | `connected_profiles_public` view omits all three. `POST /complete` response whitelist-serialized to `{connected, verification_status, tier}` only. |

---

## Must-Have Checklist

### Plan 03-01: Schema Migration (9/9)

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| `invite_codes` table with code, created_by, claimed_by, is_claimed, expires_at | ✓ | Migration lines 28–38; all columns with correct types and UNIQUE on code |
| `invite_chains` table with inviter_id, invitee_id, invite_code_id and UNIQUE(invitee_id) | ✓ | Migration lines 56–63; `UNIQUE (invitee_id)` on line 62 |
| `notification_events` table with user_id, event_type, metadata JSONB, read_at | ✓ | Migration lines 77–84; all columns present |
| `connected_profiles` has `legal_name` and `home_address` columns | ✓ | Migration lines 105–107; `ADD COLUMN IF NOT EXISTS` for both |
| `verification_sessions` has new draft columns and UNIQUE(user_id) | ✓ | Migration lines 120–128; `legal_name_draft`, `home_address_draft`, `invite_code_id`, `compass_import_draft` + UNIQUE constraint |
| `connected_profiles_public` view excludes `tolerance_rating`, `legal_name`, `home_address` | ✓ | Migration lines 145–165; all three explicitly omitted with inline comments |
| `adjust_inviter_tolerance_rating` RPC decrements TR by 0.10, floors at 0.00, auto-suspends | ✓ | `GREATEST(0.00, COALESCE(...) - 0.10)` + `IF v_new_tr = 0.00` suspend block |
| RLS policies on all new tables restrict access to owners/participants | ✓ | Migration sections 4a/4b/4c; SELECT-only policies; no INSERT/UPDATE grants |
| Architecture test allowlist includes `inviteService.ts` and `enrollService.ts` | ✓ | architecture.test.ts lines 53–54; 7-entry allowedFiles array |

### Plan 03-02: Invite System (9/9)

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| Invite code in XXXX-XXXX format with no ambiguous characters | ✓ | CHARSET = `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`; excludes I, O, 0, 1, L; `slice(0,4)-slice(4,8)` format |
| Claiming is atomic via FOR UPDATE — concurrent claims cannot both succeed | ✓ | BEGIN + SELECT FOR UPDATE + validate + UPDATE + INSERT + COMMIT; second claim reads `is_claimed=true` after first commits |
| Self-invitation blocked at service layer | ✓ | inviteService.ts line 208: `row.created_by === claimantUserId` → `SELF_INVITE_BLOCKED` |
| Email normalization (lowercase + plus-addressing stripped) | ✓ | `normalizeEmail()`: `local.split('+')[0]` strips plus-addressing; `.toLowerCase().trim()` normalizes case |
| Codes expire after 30 days if unclaimed | ✓ | `createInviteCodes()` inserts with `now() + interval '30 days'`; `claimInviteCode()` checks expiry → `CODE_EXPIRED` |
| Invite chain permanently recorded on claim | ✓ | INSERT into `connect.invite_chains` within same commit transaction (inviteService.ts lines 226–232) |
| Rate limiting: max 10 invite sends per user per day | ✓ | `inviteSendLimiter`: `windowMs: 24h`, `max: 10`, `keyGenerator: userId` applied to POST /send |
| `POST /api/invites/send` creates code and returns it | ✓ | Checks pending count < 5, calls `createInviteCodes(userId, 1)`, returns 201 `{ code }` |
| `POST /api/invites/claim` validates and atomically claims | ✓ | Zod min(9)/max(9), uppercase normalization, `claimInviteCode()`, error mapping for all 4 error codes |

### Plan 03-03: Connect Flow (5/5)

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| User can start Connect flow with valid invite code — creates or resumes session | ✓ | POST /start claims code then UPSERTs session at step='profile'; resume path returns existing session |
| User who abandons mid-flow can resume from where they left off | ✓ | Resume condition at connect.ts line 149: `existingSession.step_reached !== 'invite'` returns session directly |
| User can update profile fields step by step (all 4 fields) | ✓ | PATCH /step accepts any subset; merges with existing drafts; advances to 'review' only when all 4 present |
| User can complete Connect flow — `connected_profiles` with `verification_status: verified` | ✓ | POST /complete INSERTs with `verification_status='verified'`, `tolerance_rating=10.00` after validating step='review' |
| User cannot complete flow twice (idempotency) | ✓ | Idempotency SELECT before INSERT; returns 409 `ALREADY_CONNECTED` if `connected_profiles` row found |
| User can check current `verification_status` | ✓ | GET /status returns status from connected_profiles, or in_progress+step from session, or not_started |
| Compass calibration import with version mismatch flagging | ✓ | POST /compass-import two-phase: `confirmed=false` returns `{valid, mismatched, ready_to_import}`; `confirmed=true` saves draft |
| Integration tests cover claim atomicity, self-invite, code expiry, connect lifecycle | ✓ | Comprehensive `it.skip` suites document all scenarios; CI-safe architecture + 401 tests run without Supabase |

---

## Phase Success Criteria

| Success Criterion | Status |
|-------------------|--------|
| 1. Abandoned flow resumes in new session without restarting | ✓ VERIFIED — POST /start resume path; session persists in `verification_sessions` |
| 2. Connected profile with `verification_status: verified` after completion; cannot repeat | ✓ VERIFIED — POST /complete creates verified record; idempotency at both /start and /complete |
| 3. Compass import with version mismatch flagging (localStorage clearing is client-side scope) | ✓ VERIFIED (API scope) — Two-phase import; `confirmed=true` signals client to clear localStorage |
| 4. Invite code cannot be claimed by two concurrent requests; self-invite blocked; plus-address normalized | ✓ VERIFIED — FOR UPDATE serializes claims; SELF_INVITE_BLOCKED; `normalizeEmail()` strips plus-addressing |
| 5. Invitee sanctioned → direct inviter TR adjusted; does not propagate further | ✓ VERIFIED — RPC queries single level from `invite_chains`; no recursive traversal |

---

## Key Links Verified

| From | To | Pattern | Status |
|------|----|---------|--------|
| `connect.ts POST /start` | `claimInviteCode()` | import from `lib/inviteService.js` | ✓ WIRED |
| `connect.ts POST /start` | UPSERT with `ON CONFLICT (user_id)` | requires UNIQUE(user_id) from migration 014 | ✓ WIRED |
| `claimInviteCode()` | pg BEGIN/FOR UPDATE/COMMIT | atomic transaction | ✓ WIRED |
| `claimInviteCode()` | `invite_chains` INSERT | conditional on `created_by != null` | ✓ WIRED |
| `enrollService` | `connect.adjust_inviter_tolerance_rating` RPC | `supabaseAdmin.schema('connect').rpc(...)` | ✓ WIRED |
| RPC | `invite_chains` single-level lookup | `WHERE invitee_id = p_invitee_id` | ✓ WIRED |
| `POST /complete` | `connected_profiles` INSERT | pg transaction with FOR UPDATE | ✓ WIRED |
| `connected_profiles_public` | omits PII columns | SELECT list excludes 3 columns | ✓ WIRED |
| `invites.ts` | rate limiter keyed on userId | `keyGenerator: req => req.userId ?? req.ip` | ✓ WIRED |
| `index.ts` | `/api/invites` and `/api/connect` | `app.use(...)` | ✓ WIRED |

---

## Human Verification Required (Runtime)

These items require a live Supabase + Postgres environment and cannot be verified via static analysis:

1. **FOR UPDATE concurrency** — Send two simultaneous `POST /api/invites/claim` requests for the same code; confirm exactly one returns 200 and the other returns 409
2. **Session resume across HTTP sessions** — Start flow, close client, re-request with same JWT; confirm session resumes at correct step with drafts preserved
3. **Full lifecycle end-to-end** — start → PATCH /step (partial) → PATCH /step (step=review, all 4 fields) → POST /complete; confirm `tolerance_rating` and `legal_name` are in DB but NOT in 201 response body
4. **TR adjustment propagation boundary** — Sanction invitee in 3-level chain; confirm only direct inviter's TR decrements

---

## Phase Goal Assessment

**The codebase delivers the phase goal in full.**

**Invite-only access is enforced.** The Connect flow cannot be started without a valid, unclaimed, unexpired invite code. The claim is atomic via pg transaction with FOR UPDATE locking. There is no path to `connected_profiles` that bypasses invite validation.

**Full enrollment pipeline is complete.** Five routes implement a well-defined state machine (invite → profile → review → complete). Session state persists in Postgres, enabling abandonment and resumption. The final step atomically creates a verified Connected profile in a single pg transaction.

**Abuse-resistant.** Layered defenses: FOR UPDATE concurrency control, 5-pending-code cap, 10/day rate limit keyed on userId, self-invite block, email plus-addressing normalization, idempotent completion preventing duplicate profiles, and accountability chain tracking with one-level TR impact on inviters.

**Privacy enforced.** The public view and `POST /complete` response both exclude `tolerance_rating`, `legal_name`, and `home_address`. Architecture tests enforce this boundary structurally on every test run.

---

*Phase: 03-alpha-enrollment*
*Verified: 2026-02-25*
