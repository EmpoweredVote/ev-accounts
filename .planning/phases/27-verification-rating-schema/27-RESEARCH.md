# Phase 27: Verification Rating Schema - Research

**Researched:** 2026-03-15
**Domain:** PostgreSQL schema migration + Express API response update (existing codebase pattern)
**Confidence:** HIGH — all findings sourced directly from codebase inspection

## Summary

Phase 27 is a narrow schema + API update, not a new domain. It adds two columns to `connect.connected_profiles` and exposes three derived booleans plus the raw rating value on `GET /api/account/me`. No new tables, no new RPCs, no new routes — just a migration and an account.ts update.

The codebase has a well-established precedent for exactly this pattern: Phase 9 added `total_xp` and `current_level` to `connected_profiles` via migration 029 (ALTER TABLE ... ADD COLUMN IF NOT EXISTS), then updated `account.ts` to select and expose those columns. Phase 19 added `location_consent` via migration 031 using the same pattern. This phase follows the same track.

The only complexity beyond boilerplate is the derived fields: `vq_hold_active` (derived from `vq_hold_until > now()` in TypeScript), `red_gem_quests_unlocked` (derived from `verification_rating >= 90`), and the fact that `vq_hold_until` is internally significant — it controls whether Phase 28's VQ confirmation endpoint will block a user. The `connected_profiles_public` view must also be updated (DROP + recreate) to expose `verification_rating` to authenticated users who view others' profiles.

**Primary recommendation:** One migration file (037) adds the two columns and rebuilds the public view; one account.ts edit adds the fields to the SELECT clause and exposes derived booleans in `connected_profile`. No RPC needed — derivation is trivial TypeScript.

## Standard Stack

No new libraries. This phase uses what is already in the project.

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Supabase JS `@supabase/ssr` | Existing | `connected_profiles` reads via user-scoped client | Project-wide pattern; RLS enforced |
| PostgreSQL `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` | Postgres | Idempotent column addition | Established in every prior column-add migration |
| Express 4.x route handler | Existing | `GET /api/account/me` update | Project stack |

### No New Installs Required

```bash
# No new packages
```

## Architecture Patterns

### Recommended File Changes

```
supabase/migrations/
└── 20260315000037_phase27_verification_rating.sql   # new migration

backend/src/routes/
└── account.ts                                        # edit: SELECT + response

tests/integration/
└── account.test.ts                                   # edit: ALLOWED_ME_KEYS + new assertions
```

### Pattern 1: ADD COLUMN to connected_profiles (established precedent)

**What:** ALTER TABLE with IF NOT EXISTS guard. No backfill needed — DEFAULT handles existing rows.
**When to use:** Any time a new column is added to an existing table in production.
**Precedent:** Migration 029 (total_xp/current_level), Migration 031 (location_consent)

```sql
-- Source: migrations/20260304000029_phase9_xp_schema.sql (lines 66–68)
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS total_xp      BIGINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS current_level INT    NOT NULL DEFAULT 0;
```

Applied to Phase 27:

```sql
-- Source: established pattern
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS verification_rating INTEGER NOT NULL DEFAULT 60,
  ADD COLUMN IF NOT EXISTS vq_hold_until       TIMESTAMPTZ;
```

Note: `vq_hold_until` is nullable (no DEFAULT, no NOT NULL) — it starts NULL for all users, meaning no hold is active. This is correct.

Note: `verification_rating DEFAULT 60` matches VR-01 exactly. The range is 0–150 (per Phase 28 requirements VQ-03/04), but a CHECK constraint is optional for Phase 27 — Phase 28 enforces the bounds in its RPC. Add the CHECK here for data integrity.

### Pattern 2: DROP + Recreate connected_profiles_public view

**What:** Whenever columns are added to connected_profiles, the public view must be rebuilt. PostgreSQL's CREATE OR REPLACE VIEW cannot change column ordering. Pattern is established in migrations 014, 019, 029.
**Source:** migrations/20260304000029_phase9_xp_schema.sql (Section 4, lines 73–108)

```sql
-- Source: migration 029
DROP VIEW IF EXISTS connect.connected_profiles_public;

CREATE VIEW connect.connected_profiles_public AS
  SELECT
    id, user_id, display_name, account_standing, verification_status,
    verification_method, verified_region, xp, total_xp, current_level,
    gem_balance, gem_balance_red, gem_balance_blue, gem_balance_yellow,
    gem_reserve_cap, veracity_rating,
    -- tolerance_rating intentionally OMITTED (internal field)
    deleted_at, created_at, updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;

GRANT SELECT ON connect.connected_profiles_public TO authenticated;
```

For Phase 27, add `verification_rating` to this view. `vq_hold_until` should NOT be in the public view — it is internal state (same category as `tolerance_rating`). Only the owner's `/me` response needs it.

### Pattern 3: Extend /me SELECT clause and response

**What:** Add new columns to the existing `.select()` call in account.ts, then derive booleans in the response builder. Both GET and PATCH handlers duplicate the connected_profiles read — both must be updated identically.
**Source:** account.ts lines 57–65 (GET) and lines 334–341 (PATCH)

Current SELECT (line 61):
```typescript
// Source: backend/src/routes/account.ts line 61
.select(
  'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, location_consent, created_at'
)
```

After Phase 27:
```typescript
// Add verification_rating, vq_hold_until to the select string
.select(
  'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, location_consent, verification_rating, vq_hold_until, created_at'
)
```

### Pattern 4: Derived boolean fields in response builder

**What:** `vq_hold_active` and `red_gem_quests_unlocked` are derived in TypeScript, not stored. This is established practice — `tier` is also derived from record presence, and `xp.level` is derived from `total_xp` via RPC.

```typescript
// Source: established pattern from account.ts (tier derivation, lines 82–101)
// vq_hold_active: true if vq_hold_until is in the future
const vqHoldActive = connected.vq_hold_until
  ? new Date(connected.vq_hold_until) > new Date()
  : false;

// red_gem_quests_unlocked: true if verification_rating >= 90
const redGemQuestsUnlocked = (connected.verification_rating ?? 60) >= 90;
```

These go inside the `connected_profile` block (owner self-view), alongside `tolerance_rating`. They are NOT at root level. Reasoning: these are Connected-tier features — they only exist when a `connected_profiles` row exists. Placing them inside `connected_profile` is consistent with structural privacy enforcement.

**Important:** `vq_hold_active` and `red_gem_quests_unlocked` should also appear at root level for the same reason `completed_onboarding` and `location_consent` do — they drive routing decisions in consumer apps. Check the Phase 27 success criteria: it says `/me` returns these fields (not specifying nesting). Per the existing pattern for `completed_onboarding` (root AND inside `connected_profile`), expose them at root too.

Looking at account.ts line 119: `completed_onboarding: connected?.completed_onboarding ?? false` — this is at root AND inside `connected_profile` (line 143). Apply the same dual-placement pattern to `verification_rating`, `vq_hold_active`, and `red_gem_quests_unlocked`.

### Pattern 5: ALLOWED_ME_KEYS test update

**What:** The account.test.ts whitelist at line 26–41 gates root-level keys. After adding fields to root, the test set must be updated.
**Source:** tests/integration/account.test.ts lines 26–41

Current set is missing `is_admin` (a gap in the existing test, but not Phase 27's problem to fix). Phase 27 must add `verification_rating`, `vq_hold_active`, `red_gem_quests_unlocked` to ALLOWED_ME_KEYS and write assertions confirming correct boolean derivation behavior.

### Anti-Patterns to Avoid

- **Nullable with NOT NULL DEFAULT:** `vq_hold_until` must be nullable (`TIMESTAMPTZ` with no NOT NULL) — do not add a DEFAULT. NULL means "no hold" which is the correct initial state.
- **Derivation in SQL vs TypeScript:** Do not create a CHECK constraint that enforces vq_hold_until is in the future — that is temporal and changes at runtime. The TypeScript derivation (`> new Date()`) is correct.
- **Putting vq_hold_until in the public view:** This is internal enforcement state. Non-owning users seeing another user's hold status is a privacy concern. Keep it out of `connected_profiles_public`.
- **Missing PATCH update:** Both GET and PATCH /me handlers read `connected_profiles`. A common mistake is updating only GET. Both handlers at lines 57–65 and 334–341 must be updated identically.
- **No BEGIN/COMMIT in simple migration:** Migration 029 wraps in BEGIN/COMMIT. Migration 036 does not. Convention in this codebase: use BEGIN/COMMIT when the migration has multiple steps that must be atomic. For a two-column ADD COLUMN + view rebuild, wrapping in BEGIN/COMMIT is correct.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| vq_hold_active derivation | SQL generated column | TypeScript `> new Date()` check | The database stores the timestamp; the API derives the boolean at response time. Consistent with how `tier` is derived. |
| Rating range enforcement | App-layer clamp | CHECK constraint in migration | Database-enforced bounds prevent invalid data from Phase 28 RPC bugs |
| Public view column inclusion | API endpoint to fetch profile | View already used by other consumers | Rebuild the view; don't add a separate endpoint |

**Key insight:** This phase is pure plumbing — new columns, updated view, updated select, updated response shape. No new architectural concepts.

## Common Pitfalls

### Pitfall 1: Forgetting PATCH /me handler

**What goes wrong:** Columns added to GET /me but not PATCH /me. PATCH /me re-fetches `connected_profiles` and rebuilds the response (identical logic to GET). The code is duplicated at lines 334–341 and 392–411.
**Why it happens:** GET is what requirements mention; PATCH is a secondary path that mirrors it.
**How to avoid:** Search for `connected_profiles` in account.ts — there are two SELECT calls. Update both.
**Warning signs:** GET /me returns `vq_hold_active` but PATCH /me response doesn't.

### Pitfall 2: vq_hold_until in public view

**What goes wrong:** `vq_hold_until` added to `connected_profiles_public` view, leaking hold state to other authenticated users who look up a profile.
**Why it happens:** Treating all new columns as public by default.
**How to avoid:** Explicitly exclude it from the public view (like `tolerance_rating`). Add a comment: `-- vq_hold_until intentionally OMITTED (internal enforcement state)`.
**Warning signs:** Any query against `connected_profiles_public` can see `vq_hold_until`.

### Pitfall 3: CHECK constraint on rating prevents Phase 28 writes

**What goes wrong:** Adding `CHECK (verification_rating BETWEEN 0 AND 150)` with non-idempotent column definition causes errors when Phase 28 RPC tries to write boundary values.
**Why it happens:** Thinking CHECK constraints are only for DDL time.
**How to avoid:** The CHECK constraint is fine — it should be `CHECK (verification_rating >= 0 AND verification_rating <= 150)`. Phase 28's RPC will use `GREATEST(0, ...)` and `LEAST(150, ...)` to clamp before writing. This is the correct layered defense.
**Warning signs:** Phase 28 RPC gets Postgres CHECK violation errors.

### Pitfall 4: NULL coalesce for vq_hold_until

**What goes wrong:** Using `connected.vq_hold_until ?? null` or not handling the null case, causing TypeScript type errors or incorrect boolean derivation.
**Why it happens:** Nullable timestamptz comes back as null or undefined from Supabase JS client.
**How to avoid:** Always check for null before creating a Date: `connected.vq_hold_until ? new Date(connected.vq_hold_until) > new Date() : false`.

### Pitfall 5: Migration timestamp collision

**What goes wrong:** Using date `20260314` for migration 037 when the last migration is `20260314000036`. Using the same timestamp prefix causes ordering issues if the numbers collide.
**Why it happens:** Copy-pasting migration filename.
**How to avoid:** Use `20260315000037` — today's date (2026-03-15) with seq 000037.

### Pitfall 6: test ALLOWED_ME_KEYS not updated

**What goes wrong:** Tests pass but do not validate the new fields. Or tests fail because the whitelist rejects new keys.
**Why it happens:** The test has a comment saying it's the "privacy contract" but doesn't currently enforce it strictly (line 193–199 only checks for absent bad fields, not strict whitelist membership).
**How to avoid:** Add `verification_rating`, `vq_hold_active`, `red_gem_quests_unlocked` to ALLOWED_ME_KEYS. Add positive assertions that these fields appear in the response with correct types when a connected user exists (Supabase-dependent section of tests).

## Code Examples

### Migration 037: Full structure

```sql
-- Source: established pattern from migrations 029, 031, 035
BEGIN;

-- Section 1: Add verification_rating and vq_hold_until to connected_profiles
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS verification_rating INTEGER NOT NULL DEFAULT 60
    CHECK (verification_rating >= 0 AND verification_rating <= 150),
  ADD COLUMN IF NOT EXISTS vq_hold_until TIMESTAMPTZ;

-- Section 2: Index for hold-state queries (Phase 28 needs to find users in hold)
CREATE INDEX IF NOT EXISTS idx_connected_profiles_vq_hold
  ON connect.connected_profiles(vq_hold_until)
  WHERE vq_hold_until IS NOT NULL;

-- Section 3: DROP + recreate connected_profiles_public view
-- (DROP required — CREATE OR REPLACE cannot add columns to existing view)
DROP VIEW IF EXISTS connect.connected_profiles_public;

CREATE VIEW connect.connected_profiles_public AS
  SELECT
    id, user_id, display_name, account_standing, verification_status,
    verification_method, verified_region, xp, total_xp, current_level,
    gem_balance, gem_balance_red, gem_balance_blue, gem_balance_yellow,
    gem_reserve_cap, veracity_rating,
    verification_rating,
    -- tolerance_rating intentionally OMITTED (internal field, blocked at view layer)
    -- vq_hold_until intentionally OMITTED (internal enforcement state)
    deleted_at, created_at, updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;

GRANT SELECT ON connect.connected_profiles_public TO authenticated;

COMMIT;
```

### account.ts: derived boolean pattern

```typescript
// Source: established derivation pattern (account.ts lines 82–101, tier derivation)
// Place this BEFORE the meResponse builder, inside the `if (connected)` block.

const vqHoldActive: boolean = connected.vq_hold_until
  ? new Date(connected.vq_hold_until) > new Date()
  : false;

const redGemQuestsUnlocked: boolean = (connected.verification_rating ?? 60) >= 90;
```

### account.ts: root-level placement (dual pattern, matching completed_onboarding)

```typescript
// Source: account.ts lines 112–125 (meResponse builder)
// Add to root level (same pattern as completed_onboarding on line 119):
verification_rating: connected?.verification_rating ?? 60,
vq_hold_active: vqHoldActive,
red_gem_quests_unlocked: redGemQuestsUnlocked,
```

### account.ts: connected_profile block

```typescript
// Source: account.ts lines 133–145 (connected_profile nested block)
// Add inside connected_profile:
meResponse.connected_profile = {
  display_name: connected.display_name,
  verification_status: connected.verification_status,
  tolerance_rating: connected.tolerance_rating,
  verification_rating: connected.verification_rating,
  vq_hold_active: vqHoldActive,
  red_gem_quests_unlocked: redGemQuestsUnlocked,
  xp: xpData,
  gems: { ... },
  completed_onboarding: connected.completed_onboarding,
  created_at: connected.created_at,
};
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| N/A — new columns | ADD COLUMN IF NOT EXISTS | Standard from Phase 1 | Idempotent migration, safe to replay |
| Separate view CREATE OR REPLACE | DROP VIEW + CREATE VIEW | Established Phase 3 | Required when column list changes |

**No deprecated patterns** — this phase uses all current codebase conventions.

## Open Questions

1. **Should `vq_hold_active` / `red_gem_quests_unlocked` also appear inside `connected_profile` block, or only at root?**
   - What we know: `completed_onboarding` appears both at root (line 119) AND inside `connected_profile` (line 143). Dual placement is the established pattern.
   - What's unclear: Success criteria says `/me` returns these fields without specifying nesting.
   - Recommendation: Follow the `completed_onboarding` dual-placement pattern. Put them at root AND inside `connected_profile`. Phase 28 needs them accessible at root for quick access; Profile Hub (Phase 30) will read from `connected_profile`.

2. **Should `vq_hold_until` raw value be exposed anywhere in the response?**
   - What we know: Success criteria says the API must communicate hold state "unambiguously." The boolean `vq_hold_active` satisfies this. Exposing the raw timestamp is optional.
   - What's unclear: Would consumer apps (VQ, Profile Hub) benefit from knowing the hold expiry date?
   - Recommendation: Expose `vq_hold_until` inside `connected_profile` alongside `vq_hold_active`. It lets Profile Hub show "Your hold expires on [date]." It does NOT go at root level (same category as `tolerance_rating` — internal enforcement state, owner-only).

3. **Should the CHECK constraint (0–150) be in this migration or Phase 28?**
   - What we know: Phase 28 will enforce bounds via RPC. Phase 27 creates the columns.
   - What's unclear: Whether adding CHECK now could cause issues with seed data or existing rows.
   - Recommendation: Add the CHECK in Phase 27 migration. DEFAULT 60 is within range. Existing rows get DEFAULT 60. No conflict. Fail-fast is better than discovering bad data after Phase 28 ships.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `backend/src/routes/account.ts` — full GET and PATCH /me implementations
- Direct codebase inspection: `supabase/migrations/20260304000029_phase9_xp_schema.sql` — exact ADD COLUMN precedent for `connected_profiles`
- Direct codebase inspection: `supabase/migrations/20260224000004_connect_connected_profiles.sql` — base table schema
- Direct codebase inspection: `supabase/migrations/20260314000035_phase23_tier_promotion.sql` — recent ADD COLUMN precedent for related tables
- Direct codebase inspection: `tests/integration/account.test.ts` — ALLOWED_ME_KEYS whitelist and privacy contract tests
- Direct codebase inspection: `.planning/REQUIREMENTS.md` — VR-01 through VR-04 exact spec
- Direct codebase inspection: `.planning/ROADMAP.md` — Phase 27 success criteria

### No External Sources Required

This phase is entirely within the existing codebase domain. No new libraries, frameworks, or external APIs. All patterns are directly sourced from code already written in this repo.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, all existing patterns
- Architecture (migration pattern): HIGH — direct precedent in migration 029
- Architecture (API response pattern): HIGH — direct precedent in account.ts for completed_onboarding, location_consent
- Pitfalls: HIGH — sourced from direct code inspection (duplicate GET/PATCH handlers are visible in the file)
- Open questions: MEDIUM — derivation placement question requires product judgment, not technical research

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable codebase; only invalidated if account.ts or connected_profiles schema changes before planning starts)
