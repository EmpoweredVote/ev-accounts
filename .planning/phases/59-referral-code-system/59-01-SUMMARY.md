---
plan: 59-01
phase: 59-referral-code-system
status: complete
commit: ec0bab2
---

# Summary: Schema Columns + Quota RPCs

## What Was Built

Single migration file `supabase/migrations/20260408000059_phase59_invite_quota.sql` applied to production with:

**Schema additions:**
- `connect.connected_profiles.invite_cap_override INTEGER DEFAULT NULL` — admin override (NULL = level-based, -1 = unlimited, positive = floor)
- `connect.invite_chains.slot_locked_until TIMESTAMPTZ DEFAULT NULL` — tracks accountability locks from sanction events

**Functions (all SECURITY DEFINER, SET search_path = ''):**
- `connect.get_invite_cap_for_level(INT) RETURNS INT` — IMMUTABLE helper: 0/3/5/10/15 by level tier
- `connect.generate_invite_code_if_allowed(UUID)` — advisory-locked quota enforcement + XXXX-XXXX code generation, 30-day expiry
- `connect.get_my_invitees(UUID)` — invitee list with computed `active_count` and `effective_cap` on every row (single source of truth)
- `connect.sanction_invitee(UUID, NUMERIC)` — locks slot 60 days, adjusts TR inline, auto-suspends on TR=0, notifies inviter

## Deliverables

- `supabase/migrations/20260408000059_phase59_invite_quota.sql` (commit ec0bab2)

## Key Decisions

- Advisory lock: `pg_advisory_xact_lock(hashtext(user_id::text))` — same pattern as `award_xp`
- Unlimited cap sentinel: `2147483647` (max int) — avoids NULL handling in cap comparisons
- Slot freed condition: `slot_locked_until < now() AND account_standing = 'active'` — both conditions required (expired lock alone doesn't free if still suspended)
- Flat -0.25 TR penalty; severity-scaling deferred until sanctioning system exposes severity field
- `gen_random_bytes` unqualified — same as existing `connect.gen_referral_code`
- No nested SECURITY DEFINER calls (v1.4 pattern) — TR write inline in sanction_invitee, not via nested RPC

## Verification

- All 4 functions confirmed in `pg_proc`
- Cap helper: lvl1=0, lvl3=3, lvl7=5, lvl15=10, lvl25=15 ✓
- Schema columns: both confirmed in `information_schema.columns` ✓
