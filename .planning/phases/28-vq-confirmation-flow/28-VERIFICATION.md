---
phase: 28-vq-confirmation-flow
verified: 2026-03-15T21:52:24Z
status: passed
score: 5/5 must-haves verified
gaps: []
---

# Phase 28: VQ Confirmation Flow Verification Report

**Phase Goal:** VQ can call a single authenticated endpoint to resolve a question — awarding Red Gems to correct answerers, adjusting Verification Ratings in both directions, writing the confirmed stance, and doing nothing on replay.
**Verified:** 2026-03-15T21:52:24Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | POST /api/vq/confirm-stance exists, accepts service-key auth, and returns a confirmation result | VERIFIED | backend/src/routes/vq.ts (91 lines), registered at app.use('/api/vq', vqRouter) in index.ts |
| 2 | Correct answerers receive Red Gems; incorrect answerers do not | VERIFIED | Migration Step 5 inserts gem_transactions with gem_type='red', updates gem_balance_red; Step 6 writes no gem transaction |
| 3 | Correct VR +3 (cap 150); incorrect VR -10 (floor 0) with vq_hold_until 30 days on floor | VERIFIED | Migration Step 5: LEAST(v_vr + 3, 150); Step 6: GREATEST(v_vr - 10, 0) + CASE sets vq_hold_until = now() + INTERVAL '30 days' when v_new_rating = 0 |
| 4 | Confirmed stance value is written to inform.politician_answers | VERIFIED | Migration Step 7: INSERT INTO inform.politician_answers ... ON CONFLICT ... DO UPDATE SET value = EXCLUDED.value |
| 5 | Replaying the same idempotency_key returns the original result with no additional gem awards or changes | VERIFIED | Migration Step 2: SELECT from vq_confirmation_results before any writes; FOUND returns cached result with replayed: true |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql | vq_confirmation_results table + RPC | VERIFIED | 287 lines; CREATE TABLE + full SECURITY DEFINER RPC |
| backend/src/lib/vqService.ts | Service wrapping adminRpc call | VERIFIED | 102 lines; typed params/result interfaces, error code mapping |
| backend/src/routes/vq.ts | POST /confirm-stance Express route | VERIFIED | 91 lines; Zod schema, auth middleware, error mapping — no stubs |
| backend/src/index.ts (modified) | vqRouter imported and mounted | VERIFIED | import vqRouter + app.use('/api/vq', vqRouter) confirmed at lines 14 and 53 |
| backend/src/types/database.types.ts (modified) | Type definitions for new table and RPC | VERIFIED | vq_confirmation_results at line 333; confirm_vq_stance Args/Returns at line 576 |
| tests/integration/vq.test.ts | Integration test suite | VERIFIED | 664 lines; 10 non-live + 12 live test cases covering all 5 must-haves |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| vq.ts route | vqService.ts | import { confirmVqStance } | WIRED | Called in POST handler; all parsed body fields forwarded as named params |
| vqService.ts | connect.confirm_vq_stance RPC | adminRpc('confirm_vq_stance', ..., 'connect') | WIRED | Schema arg 'connect' routes to correct schema; all 7 RPC params passed |
| RPC | connect.connected_profiles | SELECT FOR UPDATE + UPDATE | WIRED | Steps 5 and 6 read verification_rating (and gem_balance_red for correct users), write back both |
| RPC | connect.gem_transactions | INSERT with vq_correct transaction_type | WIRED | Per-user idempotency sub-key (p_idempotency_key || ':' || v_uid::text) prevents double-credit |
| RPC | inform.politician_answers | INSERT ON CONFLICT DO UPDATE | WIRED | Step 7 upserts the confirmed stance value |
| RPC | connect.vq_confirmation_results | SELECT (pre-check) + INSERT (cache) | WIRED | Step 2 reads cache before any lock; Step 9 writes result before returning |
| index.ts | vq.ts router | app.use('/api/vq', vqRouter) | WIRED | Mounted after gemsRouter; all sub-routes at /api/vq/* are active |
| requireGemServiceKey middleware | GEMS_SERVICE_KEYS env var | JSON.parse at module load | WIRED | Parses key-to-types map; validates 'red' is a permitted type before forwarding to route |

---

### Requirements Coverage

| Must-Have | Supporting Code | Status |
|-----------|----------------|--------|
| MH-1: Authenticated endpoint accepts payload, returns result | vq.ts route + requireGemServiceKey middleware | SATISFIED |
| MH-2: Correct answerers get Red Gems; incorrect do not | Migration Step 5 (gem INSERT + balance UPDATE); Step 6 (no gem write) | SATISFIED |
| MH-3: VR +3/cap 150; VR -10/floor 0; hold_until on floor | Migration Steps 5 and 6 with LEAST/GREATEST and CASE expression | SATISFIED |
| MH-4: Confirmed stance written to politician_answers | Migration Step 7 upsert | SATISFIED |
| MH-5: Idempotency replay returns original, no side effects | Migration Step 2 pre-check; cached result returned immediately before any lock or write | SATISFIED |

---

### Anti-Patterns Found

None. Scanned vq.ts, vqService.ts, and migration SQL. No TODO/FIXME comments, no placeholder returns, no empty handlers, no console.log-only implementations found.

---

### Human Verification Required

None required for this phase gate. All five must-haves are verifiable at the structural level:

- The authenticated endpoint is wired end-to-end (route to service to RPC to tables).
- Gem award logic is in the SQL RPC body (not a stub), with explicit INSERT and balance UPDATE.
- Rating math (LEAST, GREATEST, CASE) is concrete, not a placeholder.
- Idempotency is structural: the result cache SELECT happens before any lock or write.
- Stance upsert is a real ON CONFLICT DO UPDATE, not an echo of the request input.

Running the integration test suite against a live DB with INTEGRATION_TEST_JWT and fixture env vars would provide functional confirmation, but structural verification is complete for this phase gate.

---

### Gaps Summary

No gaps. All five must-haves are satisfied by substantive, wired implementations.

---

_Verified: 2026-03-15T21:52:24Z_
_Verifier: Claude (gsd-verifier)_
