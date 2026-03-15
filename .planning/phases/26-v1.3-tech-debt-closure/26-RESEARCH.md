# Phase 26: v1.3 Tech Debt Closure - Research

**Researched:** 2026-03-15
**Domain:** Surgical codebase fixes — SQL migrations, TypeScript types, Express route parity, docs traceability
**Confidence:** HIGH

## Summary

Phase 26 closes four tech debt items surfaced in the v1.3 audit. This research directly examined the four target files to establish exact current state before recommending fixes.

Two of the four items (migration 031 `CREATE POLICY IF NOT EXISTS`, migration 032 bare `geometry`) were already corrected during Phase 19 execution (commits `b6cbae3` and `7ed0a84`, 2026-03-12) and **are not actionable as written in the audit**. The audit was produced after these commits landed. The planner should note that success criterion 1 is already satisfied — no migration edits are needed for migrations 031 or 032.

The remaining three items are genuinely open: PATCH `/me` is missing `location_consent` from both its SELECT list and its response object; `database.types.ts` still contains `gem_balance` in three shapes; and REQUIREMENTS.md is missing HUB-01 through HUB-04 and has GEM-01/02/03 marked Pending.

**Primary recommendation:** Verify migration idempotency success criterion first (it is already satisfied), then close the three genuine gaps: PATCH `/me` field parity, `database.types.ts` surgical removal, REQUIREMENTS.md doc accuracy.

## Standard Stack

No new libraries. All fixes use existing tools already in the project.

### Core (already in project)
| Tool | Purpose | Notes |
|------|---------|-------|
| TypeScript (strict) | `database.types.ts` edit | Manual edit only — do not run `supabase gen types` |
| Express 4.x | `account.ts` PATCH route edit | Surgical SELECT + response object changes |
| PostgreSQL / Supabase SQL | Migration files | Already fixed — verify only |

### No new installations required.

## Architecture Patterns

### Pattern 1: Exact current state of all four audit items

**Item 1 — Migration 031 idempotency (ALREADY FIXED)**

Current file `supabase/migrations/20260310000031_location_schema.sql` section 4 already uses the correct DO block pattern:

```sql
-- Source: supabase/migrations/20260310000031_location_schema.sql lines 56-71 (current)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'inform'
      AND tablename = 'district_boundaries'
      AND policyname = 'district_boundaries_authenticated_read'
  ) THEN
    CREATE POLICY "district_boundaries_authenticated_read"
      ON inform.district_boundaries
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END;
$$;
```

The original `CREATE POLICY IF NOT EXISTS` was replaced in commit `b6cbae3` (2026-03-12). No edit needed.

**Item 2 — Migration 032 bare `geometry` (ALREADY FIXED)**

Current file `supabase/migrations/20260310000032_location_rpcs.sql` DECLARE block already uses `public.geometry`:

```sql
-- Source: supabase/migrations/20260310000032_location_rpcs.sql line 102 (current)
v_point         public.geometry;
```

This was fixed in commit `b6cbae3` (2026-03-12). No edit needed.

**Item 3 — PATCH /me missing `location_consent` (OPEN)**

Two gaps in `backend/src/routes/account.ts`:

Gap A — Re-fetch SELECT (line 337) does not include `location_consent`:
```typescript
// CURRENT (broken) — line 337
.select(
  'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, created_at'
)
```

Compare with GET /me (line 61) which includes it:
```typescript
// GET /me (line 61) — correct
.select(
  'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, location_consent, created_at'
)
```

Gap B — Root-level `location_consent` is missing from PATCH response object (lines 377-389). GET /me includes it at line 120:
```typescript
// GET /me (line 120) — correct
location_consent: connected?.location_consent ?? false,
```

The PATCH meResponse object at line 377 does not include this field.

Fix: Add `location_consent` to both the SELECT string and the meResponse object in the PATCH handler.

**Item 4 — `gem_balance` in `database.types.ts` (OPEN)**

`backend/src/types/database.types.ts` contains `gem_balance` in:
- `connect.connected_profiles.Row` (line 26): `gem_balance: number`
- `connect.connected_profiles.Insert` (line 54): `gem_balance?: number`
- `connect.connected_profiles.Update` (line 82): `gem_balance?: number`
- `connect.Views.connected_profiles_public.Row` (line 369): `gem_balance: number | null`
- `connect.Views.connected_profiles_public.Insert` (line 390): `gem_balance?: number | null`
- `connect.Views.connected_profiles_public.Update` (line 411): `gem_balance?: number | null`

Total: 6 occurrences across two shapes (Table and View). The `gem_balance_blue/red/yellow` siblings stay; only `gem_balance` is removed.

Constraint: Do NOT run `supabase gen types`. This file has manual additions (e.g. `location_consent` added in Phase 20). A regeneration would overwrite those. Remove only the 6 `gem_balance` lines.

**Item 5 — REQUIREMENTS.md traceability (OPEN)**

Current state of `REQUIREMENTS.md` traceability table:
- GEM-01, GEM-02, GEM-03: Phase 22, marked `Pending` — implementation is complete, should be `Complete`
- HUB-01 through HUB-04: Not present at all in the table

Phase 24 (public-auth-hub) implemented four requirements:
- HUB-01: Civic-branded login page
- HUB-02: Post-login tier-based routing
- HUB-03: /signup creates Connected Account
- HUB-04: `?redirect=` with domain whitelist

The REQUIREMENTS.md also has a v1.3 requirements list at the top. The HUB requirements need to be added both to the requirements list (under a new `### HUB — Public Auth Hub` section) and to the traceability table.

Also: GEM-01/02/03 status needs updating to `Complete` in the traceability table at lines 113-115.

### Pattern 2: Field ordering in PATCH /me response (Claude's Discretion)

The CONTEXT.md says field ordering is Claude's discretion. The GET /me response object uses this order:
```typescript
id, email, display_name, avatar_url, tier, is_admin,
completed_onboarding, location_consent, empowerment_status (conditional),
account_standing, created_at, updated_at
```

The PATCH response currently has:
```typescript
id, email, display_name, avatar_url, tier, is_admin,
completed_onboarding, empowerment_status (conditional),
account_standing, created_at, updated_at
```

Recommendation: Insert `location_consent` immediately after `completed_onboarding` in the PATCH response, matching GET /me ordering exactly. This makes them structurally identical.

### Anti-Patterns to Avoid

- **Running `supabase gen types`:** Would overwrite `location_consent` and other manual additions to `database.types.ts`. Manual surgical edit only.
- **Adding corrective migrations:** Do not add a migration 037 to fix 031/032. They are already correct. Adding a corrective migration for already-working code creates confusion in migration history and may produce no-op or error on environments where the original files are already the corrected version.
- **Editing the wrong `connected_profiles` SELECT:** The PATCH handler has two SELECT calls. Only the re-fetch SELECT (line 337, after the update) is missing `location_consent`. The update payload does not select anything — no change needed there.

## Don't Hand-Roll

This phase has no library-level decisions. All fixes are direct text edits.

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Type regeneration | Custom script | Manual edit | `supabase gen types` nukes manual fields |
| Migration idempotency | New migration | Already fixed | Adding corrective migration creates noise |

## Common Pitfalls

### Pitfall 1: Treating audit items as current state without verification

**What goes wrong:** The audit lists all four items as open. Two are already fixed. Blindly "fixing" them again would introduce duplicate DO blocks or syntax changes to already-correct files.

**Why it happens:** Audit was written after the fixes landed; the auditor did not re-examine the files after Phase 19 completion.

**How to avoid:** Verify each item against the actual file before editing. Migration 031 and 032 pass this check — no edit needed.

**Warning signs:** If a PR contains edits to 031 or 032, the reviewer should check that the "fix" is not already in place.

### Pitfall 2: Missing the View shape in database.types.ts

**What goes wrong:** `gem_balance` is removed only from the Table shape (3 occurrences) but left in the View `connected_profiles_public` (3 more occurrences at lines 369-414).

**Why it happens:** The View section is 250+ lines below the Table section; easy to miss.

**How to avoid:** Grep for `gem_balance` after edit — expected result is 0 matches (only `gem_balance_blue`, `gem_balance_red`, `gem_balance_yellow` remain).

### Pitfall 3: PATCH response missing `location_consent` at root vs. inside connected_profile

**What goes wrong:** `location_consent` is added inside `connected_profile` nested object but not at root level (or vice versa).

**Why it happens:** GET /me sets `location_consent` at root (line 120) and does NOT repeat it inside `connected_profile`. This is intentional — it's a root-level field for all tiers (Inform-tier users can have location_consent = false without a connected_profile).

**How to avoid:** Add `location_consent` to PATCH response at root level only — `updatedConnected?.location_consent ?? false`. Do not add it inside the `connected_profile` nested object.

### Pitfall 4: REQUIREMENTS.md HUB requirements counted in coverage

**What goes wrong:** After adding HUB-01 through HUB-04 to the traceability table, the coverage line at the bottom (`v1.3 requirements: 29 total`) becomes stale.

**Why it happens:** The count is hard-coded in the file.

**How to avoid:** Update the count to 33 total (29 original + 4 HUB) after adding the HUB entries. Also update the "Mapped to phases: 29" line to 33.

## Code Examples

### Corrected PATCH /me SELECT (add `location_consent`)

```typescript
// File: backend/src/routes/account.ts — PATCH handler re-fetch, ~line 337
// Change: add location_consent after completed_onboarding
const { data: updatedConnected } = await db
  .schema('connect')
  .from('connected_profiles')
  .select(
    'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, location_consent, created_at'
  )
  .eq('user_id', authReq.userId)
  .maybeSingle();
```

### Corrected PATCH /me response object (add `location_consent`)

```typescript
// File: backend/src/routes/account.ts — PATCH meResponse object, ~line 377
// Change: add location_consent after completed_onboarding
const meResponse: Record<string, unknown> = {
  id: updatedUser.id,
  email: authUserData?.user?.email,
  display_name: updatedUser.display_name,
  avatar_url: updatedUser.avatar_url,
  tier,
  is_admin: isAdmin,
  completed_onboarding: updatedConnected?.completed_onboarding ?? false,
  location_consent: updatedConnected?.location_consent ?? false,  // ADD THIS LINE
  ...(updatedEmpowermentStatus !== undefined && { empowerment_status: updatedEmpowermentStatus }),
  account_standing: updatedConnected?.account_standing ?? 'active',
  created_at: updatedUser.created_at,
  updated_at: updatedUser.updated_at,
};
```

### REQUIREMENTS.md HUB section (add to requirements list)

```markdown
### HUB — Public Auth Hub

- [x] **HUB-01**: Civic-branded login page — tier-neutral "Sign in to Empowered Vote" with logo/wordmark; no feature callouts; "Create account" link below sign-in
- [x] **HUB-02**: Post-login tier-based routing — `?redirect=` first; then `completed_onboarding = false` → profile page; Connected/Empowered → profile page; Admin flag → profile page with Admin Panel link
- [x] **HUB-03**: `/signup` creates Connected Account — invite code required, legal name collected, one-account covenant callout, `?redirect=` supported post-signup
- [x] **HUB-04**: `?redirect=` with `*.empowered.vote` wildcard domain allowlist — untrusted domains silently ignored; callout shown to user when redirect is active
```

### REQUIREMENTS.md traceability entries (add to table)

```markdown
| HUB-01 | Phase 24 | Complete |
| HUB-02 | Phase 24 | Complete |
| HUB-03 | Phase 24 | Complete |
| HUB-04 | Phase 24 | Complete |
```

And update existing GEM rows:
```markdown
| GEM-01 | Phase 22 | Complete |
| GEM-02 | Phase 22 | Complete |
| GEM-03 | Phase 22 | Complete |
```

## State of the Art

| Audit Item | Audit Status | Actual Current Status | Action Needed |
|------------|-------------|----------------------|---------------|
| Migration 031 `CREATE POLICY IF NOT EXISTS` | Open | Fixed (commit b6cbae3, 2026-03-12) | Verify only — no edit |
| Migration 032 bare `geometry` | Open | Fixed (commit b6cbae3, 2026-03-12) | Verify only — no edit |
| PATCH `/me` missing `location_consent` | Open | Still open | Edit account.ts |
| `gem_balance` in database.types.ts | Open | Still open | Surgical edit types file |
| REQUIREMENTS.md GEM-01/02/03 Pending | Open | Still open | Update status to Complete |
| REQUIREMENTS.md HUB-01–04 missing | Open | Still open | Add section + table rows |

## Open Questions

1. **Does the backend/migrations/ mirror also need the 031/032 fixes?**
   - What we know: The project has both `supabase/migrations/` (Supabase CLI) and `backend/migrations/` (applyMigrations.ts). The Phase 19 fix commits show changes to both directories.
   - What's unclear: Whether `backend/migrations/032_location_rpcs.sql` has `public.geometry` already applied (the diff shows it was fixed in the same commit).
   - Recommendation: Grep `backend/migrations/032_location_rpcs.sql` for `v_point` type at plan-time. If it shows `public.geometry`, both mirrors are clean.

2. **Should HUB requirements also appear in the requirements list body (not just the traceability table)?**
   - What we know: The CONTEXT.md says "minimum targeted update: mark GEM-01/02/03 complete, add HUB-01 through HUB-04 with Phase 24 reference and Complete status."
   - What's unclear: Whether "add HUB-01 through HUB-04" means just the traceability table rows or also a new `### HUB` section in the requirements list body.
   - Recommendation: Add both — the requirements section body for completeness, and the traceability table rows. The phase success criteria only specifies the traceability table, so if scope is strict, table only is acceptable.

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `supabase/migrations/20260310000031_location_schema.sql` — current state confirmed via Read tool
- Direct file inspection: `supabase/migrations/20260310000032_location_rpcs.sql` — current state confirmed via Read tool
- Direct file inspection: `backend/src/routes/account.ts` — GET and PATCH /me both read in full
- Direct file inspection: `backend/src/types/database.types.ts` — lines 1-100 and 350-430 read
- Direct file inspection: `.planning/REQUIREMENTS.md` — full file read
- Git log: `git show b6cbae3` and `7ed0a84` confirmed migration fix commit contents
- Direct file inspection: `.planning/v1.3-MILESTONE-AUDIT.md` — audit tech_debt section read

### Secondary (MEDIUM confidence)
- None needed — all findings from direct code inspection

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Current state of 4 audit items: HIGH — directly verified from file contents and git history
- Exact lines to edit: HIGH — line numbers confirmed from Read tool output
- Migration items already fixed: HIGH — git diff confirmed both fixes landed in b6cbae3
- REQUIREMENTS.md HUB content: HIGH — Phase 24 CONTEXT.md read for exact scope

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable — no external dependencies)
