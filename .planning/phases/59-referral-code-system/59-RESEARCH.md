# Phase 59: Referral Code System - Research

**Researched:** 2026-04-08
**Domain:** Level-gated invite quota system — PostgreSQL RPC, Express 4.x, React admin + app UI
**Confidence:** HIGH — all findings sourced directly from codebase inspection

## Summary

This phase replaces the existing single-slot referral code card (which only unlocks at level 2 and refreshes when one invitee reaches level 2) with a full level-gated quota system. The existing `connect.invite_codes` and `connect.invite_chains` tables, the `inviteService`, `referralService`, and the Dashboard referral card are the direct foundation — they are not being removed, they are being extended and superseded.

The core schema additions needed are: (1) a quota enforcement layer on `connect.connected_profiles` (or a separate table) to track the admin invite cap override, and (2) a slot-locking mechanism for suspended invitees. The existing `insert_notification` RPC (`adminRpc('insert_notification', {...})`) is the confirmed notification delivery path — it writes to `public.notifications`. The existing `connect.adjust_inviter_tolerance_rating` RPC handles the TR penalty and notification together. The accountability surface needs to be extended to handle slot-locking (not just TR adjustment) when an invitee is sanctioned.

The Profile Hub Referrals section lives in `app/src/pages/DashboardPage.tsx` today as a card — the decision for Phase 59 is to expand it into a dedicated Referrals section (tab or standalone card with a list). The admin override UI lives in `admin/src/pages/admin/AccountDetailPage.tsx` (user profile page) plus a new "Invite Overrides" list view.

**Primary recommendation:** Build quota logic entirely in PostgreSQL SECURITY DEFINER RPCs (following the `award_xp` advisory lock pattern). The Express layer calls RPCs; no multi-step JS logic for quota enforcement. Use `pool.query()` for all `connect` schema reads and writes — never PostgREST for non-public schema.

## Standard Stack

This phase adds no new npm dependencies. Everything is built on the existing stack.

### Core (already installed)
| Library | Purpose | Why Standard |
|---------|---------|--------------|
| `pg` (pool.query) | All non-public schema reads/writes | Enforced project pattern |
| `supabaseAdmin` + `adminRpc` | Public schema RPC calls | Existing pattern for `insert_notification`, `adjust_inviter_tolerance_rating` |
| `express-rate-limit` | Rate limiting code generation | Already used on `/api/invites/send` |
| `zod` | Request body validation | Existing pattern across all routes |
| `crypto` (Node built-in) | Code generation | Already used in `inviteService.generateInviteCode()` |

### No New Dependencies
All functionality is achievable with the existing stack. The invite code generation (`generateInviteCode()` in `inviteService.ts`), claim flow, notification delivery, and TR adjustment RPCs are all already present.

**Installation:** None needed.

## Architecture Patterns

### Recommended File Layout

New files to create:
```
backend/src/lib/
├── inviteQuotaService.ts        # Quota cap computation, slot counting, admin override reads
backend/src/routes/
├── invites.ts                   # Extend: replace /send with quota-aware version
├── inviteOverrides.ts           # New: admin override endpoints (separate router)
supabase/migrations/
├── 20260408NNNNNN_phase59_invite_quota.sql  # Schema + all RPCs
admin/src/pages/admin/
├── AccountDetailPage.tsx        # Extend: add invite override field
├── InviteOverridesPage.tsx      # New: list view of all active overrides
app/src/pages/
├── DashboardPage.tsx            # Extend: replace referral card with full Referrals section
```

### Pattern 1: Quota Enforcement via PostgreSQL RPC (advisory lock pattern)

The existing `award_xp` pattern is the model for the code generation endpoint.

**What:** When a user requests a new invite code, the RPC:
1. Acquires an advisory lock on the user's ID hash (prevents concurrent double-generation)
2. Reads user's `current_level` from `connected_profiles`
3. Computes their level-based cap using the quota schedule
4. Reads their admin override cap if present
5. Counts their active invitees (claimed + not yet graduated + not slot-locked-expired)
6. If under cap → generates a new code and inserts into `invite_codes`
7. Returns `{ code, active_count, cap }` or `{ error: 'CAP_REACHED' }`

All this logic lives in a single `SECURITY DEFINER` RPC. The Express route calls it and does no multi-step logic itself.

```typescript
// Pattern: call quota-aware code generation via pool.query RPC
// Source: inviteService.ts + award_xp pattern in xpService.ts

export async function generateInviteCodeIfAllowed(userId: string): Promise<GenerateResult> {
  const result = await pool.query<{ ok: boolean; code: string | null; error: string | null; active_count: number; cap: number }>(
    'SELECT * FROM connect.generate_invite_code_if_allowed($1)',
    [userId]
  );
  const row = result.rows[0];
  if (!row) throw new Error('generate_invite_code_if_allowed returned no rows');
  return row;
}
```

### Pattern 2: Schema Columns for Quota State

Add to `connect.connected_profiles`:
- `invite_cap_override INTEGER` — NULL = use level-based default; -1 = unlimited; positive = floor override
- (Active invitee slot locking is derived at query time from `invite_chains` + invitee `account_standing` + a new `slot_locked_until` column on `invite_chains`)

Add to `connect.invite_chains`:
- `slot_locked_until TIMESTAMPTZ` — NULL = slot is free after graduation; non-null = locked until this time (or until invitee is unsuspended)

**Why `invite_chains` not `connected_profiles`:** The slot lock is per-invitee relationship, not per-inviter. One inviter could have multiple invitees; each invitee's suspension locks one slot independently. A column on `invite_chains` is the correct cardinality.

### Pattern 3: Admin Override Storage

`invite_cap_override INTEGER` on `connect.connected_profiles`:
- `NULL` = default (level-based cap applies)
- `-1` = unlimited
- Any positive integer = this value is used as a floor (effective cap = `MAX(level_based_cap, override_cap)`)

**Recommend `-1` for unlimited** (not a boolean flag) — this allows the query `GREATEST(level_cap, COALESCE(invite_cap_override, level_cap))` to work cleanly with a special-case for `-1`.

**Audit log:** Use `pool.query()` to insert into `public.admin_audit_log` (same as `logAdminAction()` in `adminService.ts`). Do NOT create a new audit table — the existing `admin_audit_log` with `action = 'set_invite_cap_override'` is sufficient.

### Pattern 4: Notification Delivery

Use the existing `insert_notification` RPC — this is the confirmed pattern:
```typescript
// Source: cronService.ts lines 82, 104, 123
await adminRpc('insert_notification', {
  p_user_id: inviterId,
  p_type: 'invitee_sanctioned_slot_locked',
  p_payload: {
    invitee_id: inviteeId,
    slot_locked_until: lockedUntil,
    tr_delta: -0.10,
    message: 'An invitee you vouched for has been sanctioned. One invite slot is locked for 60 days or until they are reinstated.'
  }
});
```

The `public.notifications` table (not `public.notification_events` — that's a legacy table from Phase 3) is what `insert_notification` writes to.

### Pattern 5: Level-Based Cap Computation (pure SQL)

The quota schedule translates to a SQL `CASE` expression — model after `calculate_level`:

```sql
-- Compute level-based active invitee cap from current_level
CASE
  WHEN p_level <= 1  THEN 0
  WHEN p_level <= 5  THEN 3
  WHEN p_level <= 10 THEN 5
  WHEN p_level <= 20 THEN 10
  ELSE 15
END
```

This is IMMUTABLE logic and can live as a separate `connect.get_invite_cap_for_level(p_level INT)` helper function, called by the main quota RPC.

### Anti-Patterns to Avoid

- **PostgREST for connect schema writes:** Never `supabaseAdmin.schema('connect').from(...).update()`. Always `pool.query()`.
- **JS-chained awaits for quota check + code insert:** The check-then-insert is a TOCTOU race. This MUST be atomic inside a single RPC with an advisory lock.
- **Reading `connect.connected_profiles` via PostgREST:** Use `pool.query()` for all connect schema reads in new service functions.
- **Storing active invitee count as a denormalized column:** Compute it at query time from `invite_chains`. Denormalized counts get out of sync. The cap check RPC does the count atomically inside the lock.
- **Using `notification_events` (Phase 3 legacy table) for new notifications:** Use `public.notifications` via `insert_notification` RPC — that is the active notification table.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Invite code generation | Custom token generator | `generateInviteCode()` in `inviteService.ts` | Already implemented with correct charset, no modulo bias |
| Collision retry | Application retry loop | Existing `create_invite_codes` RPC or the pattern in `unlock_referral_code` | DB-level retry, handles concurrent collisions |
| Advisory locks | Application-level mutex | `pg_advisory_xact_lock(hashtext(p_user_id::text))` — exact pattern from `award_xp` | Transaction-scoped, auto-released, correct concurrency semantics |
| Claim flow | New claim logic | Existing `claim_invite_code` RPC + `claimInviteCode()` in `inviteService.ts` | Already handles FOR UPDATE locking, all error paths |
| Notification delivery | New notification table/system | `adminRpc('insert_notification', {...})` writing to `public.notifications` | Existing infrastructure, RLS policy already in place |
| TR adjustment | Custom TR decrement logic | `adjustInviterToleranceRating()` → `connect.adjust_inviter_tolerance_rating` RPC | Already handles floor, auto-suspend, and notification |

**Key insight:** The invite code generation, claiming, and TR accountability infrastructure is complete. Phase 59 adds quota enforcement and slot management as a layer on top — not a replacement.

## Common Pitfalls

### Pitfall 1: TOCTOU Race in Cap Check
**What goes wrong:** Two concurrent "generate code" requests for the same user both see 0 active invitees, both pass the cap check, both generate codes — user gets two codes when they only had one slot.
**Why it happens:** Cap check and code insert are two separate operations.
**How to avoid:** The `generate_invite_code_if_allowed` RPC must acquire `pg_advisory_xact_lock(hashtext(p_user_id::text))` before counting active invitees and before inserting the new code. Same pattern as `award_xp`.
**Warning signs:** Integration test shows double-code generation under concurrent load.

### Pitfall 2: Incorrect Active Invitee Count
**What goes wrong:** Counting all `invite_chains` rows for the inviter, including graduated invitees (invitee reached level 2) or expired unclaimed codes.
**Why it happens:** "Active invitee" has a specific definition: claimed + invitee not yet at level 2 + slot not lock-expired.
**How to avoid:** The active count query must:
1. Join `invite_chains` → `invite_codes` (to filter unclaimed/expired codes) → `connected_profiles` (invitee's `current_level`)
2. Exclude rows where invitee `current_level >= 2` (graduated — slot freed)
3. Exclude rows where `slot_locked_until IS NOT NULL AND slot_locked_until < now()` (lock expired — slot freed)
4. Include rows where invitee is suspended with `slot_locked_until >= now()` (locked slot counts against cap)

### Pitfall 3: Unclaimed Code Slot Confusion
**What goes wrong:** A generated-but-unclaimed code consumes an invitee slot.
**Why it happens:** Naively counting all `invite_codes` created by the user.
**How to avoid:** Only count codes where `is_claimed = true` (an invitee has joined). Unclaimed codes expire after 30 days and free the slot with no penalty — the slot was never consumed. The quota check is on active invitees, not outstanding unclaimed codes.

### Pitfall 4: Effective Cap Computation with -1 Unlimited
**What goes wrong:** `GREATEST(level_cap, -1)` returns `level_cap` — the unlimited override is silently ignored.
**Why it happens:** -1 is mathematically less than any level cap.
**How to avoid:** The RPC must special-case `-1` before the GREATEST computation:
```sql
IF v_override = -1 THEN
  -- unlimited: skip cap check, generate code
  ...
END IF;
v_effective_cap := GREATEST(v_level_cap, COALESCE(v_override, 0));
```

### Pitfall 5: Slot-Lock Expiry vs. Invitee Reinstatement Race
**What goes wrong:** Two triggers can free a slot — time expiry (60 days) and admin reinstatement. If only one path updates `slot_locked_until`, the other path may not clean up correctly.
**Why it happens:** The lock-freeing logic is split between a time-based check (at quota query time) and a status change event (admin unsuspends invitee).
**How to avoid:** Design the system to check BOTH conditions: `slot_locked_until IS NULL OR slot_locked_until < now() OR invitee.account_standing = 'active'`. Do not rely on a separate cleanup job to null out `slot_locked_until` — check it at cap-evaluation time.

### Pitfall 6: TR Adjustment RPC Already Notifies — Don't Double-Notify
**What goes wrong:** The existing `connect.adjust_inviter_tolerance_rating` RPC already inserts a `notification_events` row. If Phase 59 also calls `insert_notification` for the same event, the inviter gets two notifications.
**Why it happens:** `adjust_inviter_tolerance_rating` writes to `public.notification_events` (the Phase 3 legacy table). Phase 59 notifications should go to `public.notifications` (the Phase 7 active table). These are different tables — both notifications could fire for different channels.
**How to avoid:** Either (a) extend the existing `adjust_inviter_tolerance_rating` RPC to also write the slot_locked_until on invite_chains, or (b) create a new RPC `connect.sanction_invitee` that handles TR adjustment + slot lock + notification atomically. Option (b) is cleaner.

### Pitfall 7: Existing /api/invites/send Has Hardcoded 5-Code Limit
**What goes wrong:** The existing route checks `unclaimedCount >= 5` — a flat cap on unclaimed codes. This is incompatible with the new quota system where the cap is on active invitees, not unclaimed codes.
**Why it happens:** `/api/invites/send` was built before the quota system was designed.
**How to avoid:** Replace the `/send` route logic entirely. The new route calls `generate_invite_code_if_allowed` RPC which enforces the correct quota semantics. Remove the `unclaimedCount >= 5` check.

### Pitfall 8: The referral_code / referral_invite_id Columns vs. New Multi-Invitee System
**What goes wrong:** The existing `referral_code` and `referral_invite_id` columns on `connected_profiles` assume exactly one active invite at a time. Phase 59 allows up to 15 simultaneous active invitees.
**Why it happens:** The v1.5 referral system was a simplified one-slot-at-a-time design.
**How to avoid:** Do NOT use `referral_code` / `referral_invite_id` columns for Phase 59. These columns represent the old one-code model. New codes are tracked entirely through `invite_codes` (with `created_by = user_id`) and `invite_chains`. The quota RPC queries `invite_codes` directly. The existing referral card UI and `GET /api/referral` endpoint can be deprecated in favor of the new `GET /api/invites/my-invitees` endpoint.

## Code Examples

### Effective Cap Logic (SQL)

```sql
-- Source: codebase analysis + quota schedule from CONTEXT.md
-- Inside connect.generate_invite_code_if_allowed(p_user_id UUID)

-- Step 1: Get user's current level and admin override
SELECT cp.current_level, cp.invite_cap_override
INTO v_level, v_override
FROM connect.connected_profiles cp
WHERE cp.user_id = p_user_id
FOR UPDATE;

-- Step 2: Handle unlimited override
IF v_override = -1 THEN
  v_effective_cap := 2147483647; -- INT max as proxy for unlimited
ELSE
  -- Level-based cap
  v_level_cap := CASE
    WHEN v_level <= 1  THEN 0
    WHEN v_level <= 5  THEN 3
    WHEN v_level <= 10 THEN 5
    WHEN v_level <= 20 THEN 10
    ELSE 15
  END;
  -- Override is a floor, not a ceiling
  v_effective_cap := GREATEST(v_level_cap, COALESCE(v_override, 0));
END IF;

-- Step 3: Count active invitees
SELECT COUNT(*)::int INTO v_active_count
FROM connect.invite_chains ic
JOIN connect.invite_codes code ON code.id = ic.invite_code_id
JOIN connect.connected_profiles invitee ON invitee.user_id = ic.invitee_id
WHERE ic.inviter_id = p_user_id
  AND invitee.current_level < 2          -- not yet graduated
  AND (
    ic.slot_locked_until IS NULL          -- not locked (OR)
    OR ic.slot_locked_until >= now()      -- lock still active counts against cap
  )
  AND (
    invitee.account_standing = 'active'   -- active invitees OR
    OR (ic.slot_locked_until IS NOT NULL  -- suspended invitees with active lock
        AND ic.slot_locked_until >= now())
  );
```

### Sanction + Slot Lock + Notification (one atomic RPC)

```sql
-- Source: codebase analysis — new RPC pattern for Phase 59
-- connect.sanction_invitee(p_invitee_id UUID, p_severity TEXT)
-- Replaces direct calls to adjust_inviter_tolerance_rating for the quota system

-- 1. Adjust TR (inline, not via nested SECURITY DEFINER call per v1.4 pattern)
-- 2. Lock invitee slot for 60 days
UPDATE connect.invite_chains
SET slot_locked_until = LEAST(now() + interval '60 days',
                               -- freed when invitee is unsuspended:
                               -- checked at query time, not stored here
                               now() + interval '60 days')
WHERE invitee_id = p_invitee_id;

-- 3. Notify inviter via insert_notification
INSERT INTO public.notifications (user_id, type, payload)
VALUES (v_inviter_id, 'invitee_sanctioned', jsonb_build_object(
  'invitee_id', p_invitee_id,
  'slot_locked_until', (now() + interval '60 days')::text,
  'tr_impact', v_tr_delta
));
```

### Admin Override Route Pattern

```typescript
// Source: admin.ts role grant pattern + adminService.logAdminAction pattern
// POST /api/admin/accounts/:userId/invite-cap-override

router.post('/accounts/:userId/invite-cap-override',
  requireAdmin,
  async (req, res) => {
    const { cap } = req.body; // null | -1 | positive integer
    await pool.query(
      `UPDATE connect.connected_profiles
       SET invite_cap_override = $2, updated_at = now()
       WHERE user_id = $1`,
      [req.params.userId, cap ?? null]
    );
    await logAdminAction(actorId(req), 'set_invite_cap_override', req.params.userId, { cap });
    res.json({ ok: true });
  }
);
```

### My Invitees Response Shape (for Profile Hub UI)

```typescript
// GET /api/invites/my-invitees
// Returns the data needed for the Referrals section
interface InviteeEntry {
  invitee_id: string;
  display_name: string;
  account_standing: 'active' | 'suspended';
  current_level: number;          // for "level X / 2" graduation progress
  graduated: boolean;             // current_level >= 2
  slot_locked_until: string | null;
}

interface MyInviteesResponse {
  active_count: number;           // active invitees (not graduated, not lock-expired)
  cap: number;                    // effective cap (level-based or override)
  can_generate: boolean;          // active_count < cap
  invitees: InviteeEntry[];       // compact list, all time (not just active)
}
```

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Single referral slot (referral_code column) | Multi-slot quota system (invite_codes + cap RPC) | Old `GET /api/referral` endpoint deprecated in favor of `GET /api/invites/my-invitees` |
| Flat 5-code unclaimed limit on `/api/invites/send` | Level-gated active invitee cap | Replace entire `/send` route logic |
| `unlock_referral_code` called from `xp.ts` | Still called from `xp.ts` for level-2 graduation detection | Keep — it's now one of the slot-freeing triggers |
| `adjust_inviter_tolerance_rating` handles TR + notification | New `sanction_invitee` RPC handles TR + slot lock + notification | Old RPC still called for existing sanction flow; new RPC extends it |

**Deprecated patterns for Phase 59:**
- `referral_code` / `referral_invite_id` columns on `connected_profiles`: not removed (backward compat), but not used for new quota system
- `GET /api/referral` route: not removed, but UI migrates to new endpoint
- The `unclaimedCount >= 5` check in `POST /api/invites/send`: replaced by RPC quota check

## Open Questions

1. **Does Phase 59 include CTC XP path triggering quota checks?**
   - What we know: XP award via `POST /api/xp/award` already calls `unlockReferralCode` (which fires on level 2). Level changes via CTC would trigger slot graduation detection.
   - What's unclear: Should `maybeRefreshReferralForInvitee` still run, or is it replaced by the new quota system's graduation detection?
   - Recommendation: Keep `maybeRefreshReferralForInvitee` for the old single-slot referral_code refresh. The new quota system tracks graduation via a query at cap-check time, not via the refresh path. These are parallel systems for now.

2. **Sanction severity field — dependency on sanctioning system**
   - What we know: The CONTEXT.md notes: "Scales with sanction severity — requires a severity field/category on the sanction record. This is a dependency: the sanctioning system must expose severity when TR adjustments are applied."
   - What's unclear: Does a sanctioning system with severity exist in the codebase?
   - Finding: The admin route `POST /api/admin/accounts/:userId/suspend` sets `account_standing = 'suspended'` with no severity field. There is no severity/category concept in `admin_audit_log` for sanctions.
   - Recommendation: For Phase 59, use a flat TR penalty (e.g., -0.25 for any sanction) rather than severity-scaled. Add severity as a deferred extension. This avoids a cross-repo dependency.

3. **Existing Dashboard referral card vs. new Referrals section**
   - What we know: The referral card in `DashboardPage.tsx` is a simple card in the Connected section. Phase 59 adds a dedicated Referrals section with a compact invitee list.
   - Recommendation: Add a new route `/referrals` or use a dedicated section within the dashboard. Given the app's flat routing (single-page dashboard), a new card/section below the existing referral card is the least disruptive approach. The existing card stays for users who haven't generated any codes yet; the new section shows the invitee list once codes exist.

4. **Admin "Invite Overrides" list view**
   - What we know: Decision calls for a new dedicated list page in admin showing all users with active overrides.
   - What's unclear: Pagination requirements, whether to integrate into AccountsPage filters or create a separate page.
   - Recommendation: Create `InviteOverridesPage.tsx` as a separate admin page (like `RolesPage.tsx` pattern) with a simple table: user display name, level, level-based cap, override value, effective cap, "Edit" link to AccountDetailPage.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection — `backend/src/lib/inviteService.ts` — existing code generation, claim, list functions
- Direct codebase inspection — `backend/src/lib/referralService.ts` — existing single-slot referral RPCs
- Direct codebase inspection — `backend/src/routes/invites.ts` — existing route with hardcoded 5-code limit
- Direct codebase inspection — `backend/src/routes/xp.ts` — level-up hook calling `unlockReferralCode`
- Direct codebase inspection — `supabase/migrations/20260304000030_phase9_xp_rpcs.sql` — advisory lock + idempotency pattern
- Direct codebase inspection — `supabase/migrations/20260318000001_referral_codes.sql` — existing referral_code columns + RPCs
- Direct codebase inspection — `supabase/migrations/20260225000014_phase3_invite_connect_schema.sql` — invite_codes, invite_chains, notification_events tables
- Direct codebase inspection — `supabase/migrations/20260227000024_phase7_admin_schema.sql` — public.notifications table + insert_notification
- Direct codebase inspection — `backend/src/lib/enrollService.ts` — `adjustInviterToleranceRating` pattern
- Direct codebase inspection — `backend/src/lib/adminService.ts` — `logAdminAction`, `writeRoleAuditLog` patterns
- Direct codebase inspection — `app/src/pages/DashboardPage.tsx` — existing referral card UI
- Direct codebase inspection — `admin/src/pages/admin/AccountDetailPage.tsx` — user profile page pattern for admin override UI

### Secondary (MEDIUM confidence)
- None — all findings are from direct codebase inspection

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, all existing libraries
- Architecture: HIGH — patterns sourced directly from working codebase code
- Pitfalls: HIGH — identified from reading existing code logic + known project patterns
- Schema design: HIGH — follows established conventions in existing migrations

**Research date:** 2026-04-08
**Valid until:** Stable — internal codebase research, valid until schema or patterns change
