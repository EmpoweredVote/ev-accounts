# Phase 23: Central Profile Page + Admin Tier Promotion - Research

**Researched:** 2026-03-14
**Domain:** Express 4.x / Supabase / React admin — profile aggregation endpoint + audit-logged tier promotion RPC
**Confidence:** HIGH — all findings sourced directly from the live codebase

## Summary

Phase 23 adds two orthogonal features on top of a well-established codebase: a tiered public/owner profile API endpoint, and an admin-triggered promotion pathway (Inform → Connected) with a full audit trail. Both features follow patterns already established in the codebase — no new libraries, no new architectural patterns.

The public profile endpoint (`GET /api/account/profile/:userId`) is purely a read aggregation with tier-conditional field inclusion. The existing `/api/account/me` handler (account.ts) demonstrates the exact whitelist serialization pattern that must be replicated. The key difference is that the profile endpoint uses `supabaseAdmin` for all reads (no user JWT is available for a public unauthenticated request), whereas `/api/account/me` uses `createUserClient`.

The promotion flow (Inform → Connected) requires a new SECURITY DEFINER RPC that atomically creates a `connect.connected_profiles` row and writes a `connect.tier_promotion_log` row. The demotion RPC in `empower.execute_demotion` is the structural analog: it handles a tier transition atomically via a single Postgres function. That pattern applies directly here. The admin route handler, service function, and audit log call pattern all have direct templates in `admin.ts` / `adminService.ts`.

**Primary recommendation:** Model the profile service function on the existing `/api/account/me` read logic, but use `supabaseAdmin` for all queries. Model the promotion RPC on `execute_demotion`. Both are copy-adapt-verify tasks, not design tasks.

## Standard Stack

No new libraries required for this phase. All existing stack components apply.

### Core (already present)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Express 4.x | installed | API routing | Project standard |
| `@supabase/supabase-js` | installed | DB client (admin + anon + user-scoped) | Project standard |
| Zod | installed | Request body validation | Project standard |
| React + Vite | installed | Admin UI | Project standard |
| react-router-dom | installed | Admin SPA routing | Project standard |

### No New Packages Needed
All required capabilities — service-role DB reads, optional auth, RPC calls, admin route guards, Tailwind UI, `apiFetch` — already exist in the codebase.

**Installation:** none required.

## Architecture Patterns

### Recommended Project Structure

New files follow existing conventions:

```
backend/src/routes/
└── profile.ts              # GET /api/account/profile/:userId + /me

backend/src/lib/
└── profileService.ts       # Read aggregation logic (supabaseAdmin reads)
└── adminService.ts         # ADD: promoteToConnected(), getPromotionLog(), getGlobalPromotionLog()

supabase/migrations/
└── 20260314000035_phase23_tier_promotion.sql  # tier_promotion_log table + promote_to_connected RPC

admin/src/pages/admin/
└── AccountDetailPage.tsx   # EXTEND: add Compass, Politician, Promotion History sections + Promote button
└── PromotionsPage.tsx      # NEW: global promotions log at /admin/promotions

admin/src/pages/admin/AdminLayout.tsx  # ADD nav item: "Promotions"
admin/src/App.tsx                      # ADD route: /admin/promotions
```

### Pattern 1: Public Profile Endpoint (unauthenticated, service-role reads)

**What:** `GET /api/account/profile/:userId` — no auth required, reads all data via `supabaseAdmin`, applies tier-conditional field inclusion, serializes via explicit whitelist.

**When to use:** Any endpoint that serves both authenticated and unauthenticated callers and aggregates data from multiple schemas.

The `/api/account/me` handler is the template. Key differences from `/api/account/me`:
- No `requireAuth` middleware
- No `createUserClient` — use `supabaseAdmin` for all reads (service role reads are permissible because no user-sensitive fields are returned)
- No `tolerance_rating`, `legal_name`, `email`, `location_consent`, `gems` in the public shape
- Owner check: `GET /api/account/profile/me` needs `requireAuth` and adds gem balances + `location_consent` + email

**Tier detection logic (matches existing codebase):**
```typescript
// Source: backend/src/routes/account.ts lines 77, 345
const tier = (empowered && empowered.is_active) ? 'empowered' : connected ? 'connected' : 'inform';
```

**Level computation for public endpoint:**
- For Connected/Empowered public profiles, level and XP must be included
- The `calculate_level` RPC is `IMMUTABLE` and safe to call via `adminRpc`
- `connected.total_xp` is the source of truth (NOT the legacy `xp` column — see MEMORY.md CTC fix)

**Public field whitelist (Inform):**
```typescript
// username = candidate_page_slug (Empowered) OR display_name (Connected/Inform)
// tier, level, total_xp
```

**Public field additions for Connected:**
```typescript
// selected_topic_ids (from connect.connected_profiles)
```

**Public field additions for Empowered:**
```typescript
// selected_topic_ids, compass_answers (all non-deleted), empowered_profile (full politician record)
```

**Compass answers read pattern (Empowered public profile):**
```typescript
// Source: backend/src/routes/compass.ts + compassService.ts
// Use supabaseAdmin.schema('inform').from('compass_responses')
//   .select('topic_id, value, write_in_text, inverted, updated_at')
//   .eq('user_id', userId)
//   .is('deleted_at', null)   // CRITICAL: use .is() not .eq() for NULL checks
```

**Empowered profile (politician record join):**
The `inform.politicians` table (as of migration 033) has: `id, first_name, last_name, preferred_name, full_name, office_title, photo_origin_url, is_active, is_candidate, is_vacant, representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, created_at`. The join path: `empower.empowered_profiles.candidate_page_slug` — wait, no. The link is through the user's UUID: `supabaseAdmin.schema('inform').from('politicians').select(...)` where the politician is looked up by matching against `empower.empowered_profiles.user_id`. Need to verify the join column.

**Open question — join between empowered_profiles and politicians:**
The current `account.ts` `/me` endpoint does NOT join `inform.politicians` when returning `empowered_profile`. It only returns `{ legal_name, is_active, candidate_page_slug, empowered_at, demoted_at }`. There is no direct FK from `empower.empowered_profiles` to `inform.politicians.id` visible in the existing code. The `candidates.ts` / `essentialsCandidates.ts` routes may have the join logic. This must be verified before implementing `profileService.ts`.

### Pattern 2: Route File for Profile Endpoint

The profile route is a new Express Router registered in `index.ts`. Follow the pattern of `account.ts`:

```typescript
// backend/src/routes/profile.ts
import { Router } from 'express';
import { optionalAuth, requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { getPublicProfile, getOwnerProfile } from '../lib/profileService.js';

const router = Router();

// GET /api/account/profile/:userId — public, no auth required
router.get('/:userId', async (req, res) => { ... });

// GET /api/account/profile/me — authenticated owner view
// CRITICAL: register /me BEFORE /:userId to prevent Express routing conflict
router.get('/me', requireAuth, async (req, res) => { ... });
```

**Route registration ordering (CRITICAL):** In Express, `router.get('/me', ...)` must be registered BEFORE `router.get('/:userId', ...)`. Otherwise Express treats "me" as a userId param. See the existing comment in `admin.ts` line 248: `// IMPORTANT: /invites/tree must be registered BEFORE /invites/:codeId`.

Mount in `index.ts` at: `app.use('/api/account/profile', profileRouter)` — or add profile routes directly to the existing `accountRouter`. The simpler approach is to add them to `account.ts` since the route prefix is already `/api/account`.

### Pattern 3: Promotion RPC (SECURITY DEFINER, atomic)

**What:** A single Postgres function `connect.promote_to_connected` that:
1. Validates the target user exists in `public.users`
2. Checks they do NOT already have a `connect.connected_profiles` row (idempotency guard)
3. If already Connected or Empowered, raises an exception (caller maps to user-facing error)
4. INSERTs into `connect.connected_profiles` with sensible defaults
5. INSERTs into `connect.tier_promotion_log`
6. Returns the new connected_profiles row

**Template:** `empower.execute_demotion` (migration 018) — same SECURITY DEFINER pattern, same two-table atomic write, same SET search_path = '' requirement.

```sql
-- Source: pattern from migration 018 (execute_demotion) and migration 023 (credit_gems)
CREATE OR REPLACE FUNCTION connect.promote_to_connected(
  p_admin_id       UUID,
  p_target_user_id UUID,
  p_note           TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_display_name TEXT;
  v_existing_connected UUID;
BEGIN
  -- 1. Verify target user exists
  SELECT display_name INTO v_display_name
  FROM public.users WHERE id = p_target_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'USER_NOT_FOUND';
  END IF;

  -- 2. Check for existing connected_profiles row (already Connected or Empowered)
  SELECT id INTO v_existing_connected
  FROM connect.connected_profiles WHERE user_id = p_target_user_id;
  IF FOUND THEN
    RAISE EXCEPTION 'ALREADY_CONNECTED_OR_HIGHER';
  END IF;

  -- 3. Create connected_profiles row
  INSERT INTO connect.connected_profiles (user_id, display_name, ...)
  VALUES (p_target_user_id, v_display_name, ...);

  -- 4. Write promotion log row
  INSERT INTO connect.tier_promotion_log (admin_id, target_user_id, previous_tier, new_tier, note)
  VALUES (p_admin_id, p_target_user_id, 'inform', 'connected', p_note);

  RETURN jsonb_build_object('ok', true);
END;
$$;
```

### Pattern 4: Admin Service Function

New functions in `adminService.ts` follow the existing style:

```typescript
// Source: adminService.ts pattern (listAccounts, adminDemote)
export async function promoteToConnected(
  adminId: string,
  targetUserId: string,
  note?: string
): Promise<void> {
  const { error } = await adminRpc('promote_to_connected', {
    p_admin_id: adminId,
    p_target_user_id: targetUserId,
    p_note: note ?? null,
  }, 'connect');

  if (error) {
    if (error.message?.includes('USER_NOT_FOUND')) {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' });
    }
    if (error.message?.includes('ALREADY_CONNECTED_OR_HIGHER')) {
      throw Object.assign(new Error('User is already Connected or Empowered'), { code: 'ALREADY_CONNECTED' });
    }
    throw new Error(error.message);
  }
}
```

Note: `adminRpc` third parameter is the schema. The RPC lives in the `connect` schema, so pass `'connect'`.

### Pattern 5: Admin Route Handler

```typescript
// Source: admin.ts promotion route — follows demote pattern (lines 195-210)
router.post('/accounts/:userId/promote', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = PromoteSchema.safeParse(req.body);
    if (!parsed.success) { res.status(400).json(...); return; }

    await promoteToConnected(actorId(req), userId, parsed.data.note);
    await logAdminAction(actorId(req), 'promote_account', userId, {
      previous_tier: 'inform', new_tier: 'connected', note: parsed.data.note
    });
    res.json({ ok: true });
  } catch (err) {
    const e = err as { code?: string };
    if (e.code === 'NOT_FOUND') { res.status(404).json({ error: 'User not found' }); return; }
    if (e.code === 'ALREADY_CONNECTED') { res.status(409).json({ error: 'User is already Connected or Empowered' }); return; }
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

### Pattern 6: Migration Numbering

Next migration is `20260314000035_phase23_tier_promotion.sql`. Contains:
1. `CREATE TABLE connect.tier_promotion_log`
2. `CREATE OR REPLACE FUNCTION connect.promote_to_connected`
3. GRANT statements

### Pattern 7: Admin React UI — Modal Confirmation

The existing `AccountDetailPage.tsx` uses inline confirm state (`showDemoteConfirm`) rather than a true modal component. For the promotion flow, the decision requires a modal with an optional note field. Pattern options:

**Option A (simpler, consistent with existing code):** Inline conditional render — add `showPromoteModal` state, render a modal-looking div with backdrop overlay when true. No new component dependency. Consistent with how demote confirm is handled today.

**Option B (cleaner):** Extract a reusable `ConfirmModal` component. Better for reuse but adds complexity not needed today.

**Recommendation:** Use Option A for consistency with existing AccountDetailPage patterns. The demote confirm inline pattern can be extended to a full modal with backdrop.

### Pattern 8: Search-as-you-type Debounce

The existing `AccountsPage.tsx` already implements a `useDebounce` hook (line 32-38) with 300ms delay. This exact pattern must be reused for the inline search dropdown in the accounts list header. The context decision says "search plugs into the list" so the existing `listAccounts` API call (which already supports `search`) is the backend.

For the inline dropdown, the difference from current behavior: instead of re-rendering the table, show a floating dropdown with results. The 300ms debounce timing is correct for search-as-you-type.

### Pattern 9: Promotion Log Pagination

The `getAdminXpHistory` pattern (adminService.ts) returns `{ transactions, total, page, pages }` with 25 rows/page. Apply the same pagination shape to `getPromotionLog` (per-user) and `getGlobalPromotionLog`. Since Alpha promotion volume will be tiny, pagination is low priority but easy to add using the existing table + pagination component pattern.

### Anti-Patterns to Avoid

- **Do NOT use `createUserClient` for the public profile endpoint.** No user JWT is present for unauthenticated callers. Use `supabaseAdmin` (reads of non-sensitive public data are permitted with service role).
- **Do NOT spread DB row objects.** Explicit whitelist only — the architecture rule from MEMORY.md v1.2: "NEVER spread DB rows."
- **Do NOT use `.eq()` for NULL checks.** Use `.is('deleted_at', null)` for compass_responses soft-delete filter — PostgREST only generates `IS NULL` via `.is()`.
- **Do NOT write to two tables in separate JS awaits for the promotion.** The `connect.connected_profiles` INSERT and `connect.tier_promotion_log` INSERT must be in the same Postgres RPC transaction.
- **Do NOT register /:userId before /me.** Express route matching is first-match; `/me` must precede `/:userId`.
- **Do NOT call `adminRpc` with default schema for connect-schema functions.** Pass `'connect'` as the third argument.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic two-table promotion write | JS-chained awaits | SECURITY DEFINER RPC | Project architecture rule — see MEMORY.md |
| Level + XP computation | Custom arithmetic | `calculate_level` RPC | Already exists, IMMUTABLE, tested |
| Search debounce | Custom implementation | `useDebounce` from AccountsPage.tsx | Already exists in codebase |
| Admin auth guard | Per-route middleware | `router.use(requireAuth, requireAdmin)` | Already established pattern in admin.ts |
| Pagination UI | Custom component | Existing button/page state pattern | Used in AccountDetailPage, AccountsPage |
| Toast notifications | Custom toast | Existing toast pattern (if any) | Check admin/src for existing toast before adding new library |

**Key insight:** All write operations in this codebase go through SECURITY DEFINER RPCs. Never chain two table writes in JS — not for this feature, not for any future feature.

## Common Pitfalls

### Pitfall 1: `supabaseAdmin` vs `createUserClient` for Profile Reads

**What goes wrong:** Using `createUserClient` for the public profile endpoint. This requires a user JWT, which unauthenticated callers don't have. The endpoint returns 401 for public callers.

**Why it happens:** The existing `/api/account/me` handler uses `createUserClient` — copying it without adjusting for the unauthenticated context.

**How to avoid:** The public profile endpoint has no JWT. Use `supabaseAdmin` for all DB reads. The service role bypasses RLS, so the code must enforce field-level privacy by explicit whitelist (which it does anyway).

**Warning signs:** Integration test for unauthenticated caller returning 401.

### Pitfall 2: Route Ordering (Express `/:userId` vs `/me`)

**What goes wrong:** Registering `GET /:userId` before `GET /me`. Express matches `/me` as a userId param — the owner endpoint never fires.

**Why it happens:** Copy-pasting route definitions without attending to order.

**How to avoid:** Always register specific literal paths (`/me`) before parameterized paths (`/:userId`). The codebase has a comment about this in admin.ts line 248.

**Warning signs:** `GET /api/account/profile/me` returns a profile for a user with ID "me" (null/404) rather than the authenticated user's profile.

### Pitfall 3: `connect.connected_profiles` Insert Defaults

**What goes wrong:** Omitting required columns or setting wrong defaults when the promotion RPC inserts a new `connected_profiles` row.

**Why it happens:** The connected_profiles schema (migration 004) has required columns (`display_name`, `account_standing`, `verification_status`) with CHECK constraints. The insert must supply all NOT NULL columns without defaults.

**How to avoid:** Review migration 004. `display_name` must be pulled from `public.users.display_name`. `account_standing` defaults to `'active'`. `verification_status` defaults to `'pending'`.

**Warning signs:** RPC raises `violates not-null constraint` or `violates check constraint` on insert.

### Pitfall 4: Legacy `xp` Column vs `total_xp`

**What goes wrong:** Reading `connected_profiles.xp` for XP display in the public profile. This column is never written to (Phase 9 writes to `total_xp`).

**Why it happens:** The schema has both columns; `xp` is the Phase 6 placeholder. MEMORY.md documents this as the CTC XP fix.

**How to avoid:** Always read `connected_profiles.total_xp`. Never read `connected_profiles.xp`.

**Warning signs:** Public profile shows level 0 / XP 0 for users with visible XP elsewhere.

### Pitfall 5: Empowered Profile → Politician Join

**What goes wrong:** Not finding the correct join column to retrieve a user's politician record from `inform.politicians`.

**Why it happens:** `account.ts /me` does NOT join `inform.politicians` — it returns only the `empowered_profiles` row fields. The join logic, if it exists, is in `candidates.ts` or `essentialsCandidates.ts`.

**How to avoid:** Read `candidates.ts` and `essentialsCandidates.ts` before implementing the Empowered profile section of `profileService.ts`. Determine whether `inform.politicians` has a `user_id` FK or whether the link is through another column.

**Warning signs:** The `empowered_profile` block returns empty or null politician data for Empowered users.

### Pitfall 6: Promotion Button Not Conditionally Hidden

**What goes wrong:** Rendering a disabled "Promote" button for Connected/Empowered users instead of hiding it entirely.

**Why it happens:** Default thinking is to disable rather than hide.

**How to avoid:** The context decision is explicit: "Hidden entirely for Connected and Empowered users. Only visible for Inform-tier accounts. No disabled state — simply absent." Apply `{account.tier === 'inform' && <button>...}`.

### Pitfall 7: `SET search_path = ''` Requirement

**What goes wrong:** Writing the promotion RPC with unqualified table names. Postgres resolves them via search_path, which is empty for SECURITY DEFINER functions — causing "table not found" errors.

**Why it happens:** All existing RPCs in this codebase use `SET search_path = ''` with fully qualified names. Forgetting this on a new RPC.

**How to avoid:** Every table reference in the RPC body must be `schema.table` (e.g., `connect.connected_profiles`, `public.users`, `connect.tier_promotion_log`). Never bare table names.

**Warning signs:** RPC raises `ERROR: relation "connected_profiles" does not exist`.

## Code Examples

### Connected Profiles Insert (Promotion RPC)

The minimum viable insert when promoting Inform → Connected:

```sql
-- Source: migration 004 (connected_profiles schema), migration 023 (RPC patterns)
INSERT INTO connect.connected_profiles (
  user_id,
  display_name,
  account_standing,
  verification_status,
  verification_method,
  total_xp,
  gem_balance_yellow,
  gem_balance_blue,
  gem_balance_red,
  completed_onboarding
)
VALUES (
  p_target_user_id,
  v_display_name,
  'active',
  'pending',
  'admin_promotion',
  0,
  0,
  0,
  0,
  false
);
```

Note: `gem_balance` (legacy column from Phase 6 before Phase 22 decomposed to yellow/blue/red) may also need a default. Check the current schema column list from migration 004 + subsequent ALTERs.

### Tier-Conditional Serialization (Profile Response)

```typescript
// Source: account.ts lines 99-157 — adapt this pattern for profileService
const profileResponse: Record<string, unknown> = {
  username: empowered?.candidate_page_slug ?? connected?.display_name ?? user.display_name,
  tier,
  level: xpData?.level ?? 0,
  total_xp: xpData?.total ?? 0,
};

if (tier === 'connected' || tier === 'empowered') {
  profileResponse.selected_topic_ids = connected?.selected_topic_ids ?? [];
}

if (tier === 'empowered') {
  profileResponse.compass_answers = compassAnswers; // fetched separately
  profileResponse.empowered_profile = { /* politician fields */ };
}
// DO NOT add: gems, tolerance_rating, legal_name, email, location_consent
```

### Admin Route: Promotion Endpoint

```typescript
// Source: admin.ts lines 195-210 (demote pattern)
const PromoteSchema = z.object({
  note: z.string().max(500).optional(),
});

router.post('/accounts/:userId/promote', async (req, res) => {
  const { userId } = req.params;
  const parsed = PromoteSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body' });
    return;
  }
  await promoteToConnected(actorId(req), userId, parsed.data.note);
  await logAdminAction(actorId(req), 'promote_to_connected', userId, {
    previous_tier: 'inform',
    new_tier: 'connected',
    note: parsed.data.note ?? null,
  });
  res.json({ ok: true });
});
```

### Migration Structure

```sql
-- 20260314000035_phase23_tier_promotion.sql
BEGIN;

-- 1. Create tier_promotion_log table
CREATE TABLE IF NOT EXISTS connect.tier_promotion_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        UUID NOT NULL REFERENCES public.users(id),
  target_user_id  UUID NOT NULL REFERENCES public.users(id),
  previous_tier   TEXT NOT NULL,
  new_tier        TEXT NOT NULL,
  note            TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tier_promotion_log_target
  ON connect.tier_promotion_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_tier_promotion_log_admin
  ON connect.tier_promotion_log(admin_id);

-- 2. Create promote_to_connected RPC
CREATE OR REPLACE FUNCTION connect.promote_to_connected(...)
SECURITY DEFINER SET search_path = '' ...;

-- 3. Grants
GRANT EXECUTE ON FUNCTION connect.promote_to_connected(...) TO service_role;

COMMIT;
```

### Promotion Log Read (per-user)

```typescript
// Source: adminService.ts getAdminXpHistory pattern
export async function getPromotionLog(
  targetUserId: string,
  page: number = 1
): Promise<{ entries: unknown[]; total: number; page: number; pages: number }> {
  const PAGE_SIZE = 25;
  const from = (page - 1) * PAGE_SIZE;

  const { data, error, count } = await supabaseAdmin
    .schema('connect')
    .from('tier_promotion_log')
    .select('*, admin:admin_id(display_name, email:public.users(email))', { count: 'exact' })
    .eq('target_user_id', targetUserId)
    .order('created_at', { ascending: false })
    .range(from, from + PAGE_SIZE - 1);

  // Note: the join for admin email may require a different approach given
  // email is in auth.users not public.users — verify the join path.
  ...
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `xp` column for XP | `total_xp` column | Phase 9 (migration 029) | Always read `total_xp` |
| Per-feature profile views | Central profile endpoint | Phase 23 (this phase) | Admin detail page consolidates all sections |
| No tier promotion tooling | Admin-triggered promote RPC | Phase 23 (this phase) | Enables Alpha invite → promotion workflow |

**Deprecated/outdated:**
- `connected_profiles.xp`: Phase 6 placeholder, never written post-Phase 9. Read `total_xp` only.
- `connected_profiles.gem_balance`: Phase 6 integer. Phase 22 uses `gem_balance_yellow/blue/red`.

## Open Questions

1. **Empowered profile → politician join column**
   - What we know: `empower.empowered_profiles` has `candidate_page_slug`. `inform.politicians` has `id`, and all the politician fields. There is no explicit FK visible in migrations reviewed.
   - What's unclear: Is the join via a `politician_id` FK on `empowered_profiles`, or via `user_id` on `inform.politicians`, or via `candidate_page_slug` matching some politician field?
   - Recommendation: Read `candidates.ts`, `essentialsCandidates.ts`, and migration `20260228000025_phase8_candidate_pages.sql` before writing `profileService.ts`. This is the single most important gap to resolve.

2. **Admin email in promotion log display**
   - What we know: The promotion log table will have `admin_id` (UUID). The admin UI needs to show admin email. Admin email lives in `auth.users`, not `public.users`.
   - What's unclear: Can the log query join to `auth.users` via service role, or should admin email be denormalized into the log row at insert time?
   - Recommendation: Denormalize admin email at insert time (pass `p_admin_email TEXT` to the RPC or look it up in the RPC body). Avoids complex join at read time.

3. **`/me` route in profile vs account router**
   - What we know: The profile routes could live in `account.ts` (existing `/api/account` prefix) or a new `profile.ts` router mounted at `/api/account/profile`.
   - What's unclear: Does adding profile routes to `account.ts` make the file unwieldy?
   - Recommendation: New `profile.ts` file, mounted at `/api/account/profile` in `index.ts`. Keeps `account.ts` focused on `/me` and `/me/jurisdiction`.

4. **Toast notification library**
   - What we know: The context says "success toast" but no toast library is visible in current admin components.
   - What's unclear: Does a toast/notification utility already exist in `admin/src/`?
   - Recommendation: Check `admin/src/` for any existing notification/toast pattern before adding a new library. If none exists, use a simple inline state-driven notification message that auto-clears (avoids new dependency).

## Sources

### Primary (HIGH confidence)
- `backend/src/routes/account.ts` — `/api/account/me` GET/PATCH handler (privacy pattern, tier detection, XP/gem response shape)
- `backend/src/routes/admin.ts` — admin route patterns (middleware chain, service delegation, audit logging)
- `backend/src/lib/adminService.ts` — service function patterns (`listAccounts`, `getAccountDetail`, `adminDemote`)
- `backend/src/lib/supabase.ts` — client types (`supabaseAdmin`, `adminRpc`, `createUserClient`)
- `backend/src/middleware/auth.ts` — `requireAuth`, `optionalAuth` (route guard patterns)
- `backend/src/middleware/requireAdmin.ts` — `requireAdmin` middleware
- `supabase/migrations/20260224000004_connect_connected_profiles.sql` — connected_profiles schema
- `supabase/migrations/20260227000018_empower_phase5.sql` — `execute_demotion` RPC pattern
- `supabase/migrations/20260313000033_politician_schema.sql` — full `inform.politicians` column set
- `supabase/migrations/20260227000023_phase6_rpcs.sql` — `credit_gems` SECURITY DEFINER RPC pattern
- `admin/src/pages/admin/AccountDetailPage.tsx` — existing admin profile page structure
- `admin/src/pages/admin/AccountsPage.tsx` — `useDebounce` hook (300ms), pagination pattern, search UI
- `admin/src/App.tsx` — route registration pattern
- `admin/src/pages/admin/AdminLayout.tsx` — nav item registration pattern

### Secondary (MEDIUM confidence)
- MEMORY.md — `total_xp` vs `xp` column distinction (CTC XP fix, 2026-03-08)
- MEMORY.md — v1.2 key decisions (`SET search_path = ''`, `.is('deleted_at', null)` for soft deletes)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, all existing
- Architecture: HIGH — all patterns derived directly from codebase
- Pitfalls: HIGH — derived from actual migration comments and MEMORY.md documented bugs
- Politician join (empowered profile): LOW — not resolved in files reviewed; requires `candidates.ts` investigation before implementation

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable codebase; only invalidated by schema migrations to `connect` or `empower` schemas)
