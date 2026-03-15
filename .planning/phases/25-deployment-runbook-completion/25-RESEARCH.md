# Phase 25: Deployment Runbook Completion - Research

**Researched:** 2026-03-15
**Domain:** Migration file management + deployment runbook documentation
**Confidence:** HIGH

## Summary

Phase 25 is primarily a gap-closure task with a well-defined scope: three migration files are missing from `backend/migrations/` and `applyMigrations.ts` does not know about them. The `supabase/migrations/` source files for 034, 035, and 036 already exist and are correct. The existing pattern in `applyMigrations.ts` (026–033) is the template to extend — pre-verify query, apply, post-verify query.

There are no new libraries, no new architecture patterns, and no unknown technical territory. The entire phase is documentation and file-copy work following an established pattern. The only non-trivial task is writing correct pre/post verification queries for each of the three new migrations.

The audit also identified an open blocker in STATE.md: PostgREST schema config requires a `ALTER ROLE authenticator SET pgrst.db_schemas TO '...'` workaround that is not yet documented in DEPLOY.md. This belongs in the same pass.

**Primary recommendation:** Mirror the three missing migrations from `supabase/migrations/` to `backend/migrations/`, extend `applyMigrations.ts` with correct verification queries, update DEPLOY.md Step 2 to cover all migrations 026–036, and add the PostgREST schema config step.

---

## Standard Stack

No new libraries required. This phase uses only what is already installed.

### Core (already in use)
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| `pg` (node-postgres) | already installed | Pool connection for migration apply | Used by existing `applyMigrations.ts` |
| `tsx` | already installed | Run TypeScript scripts | `npx tsx backend/scripts/applyMigrations.ts` |
| `dotenv` | already installed | Load `.env` for DATABASE_URL | Already imported in script |

No `npm install` needed.

---

## Architecture Patterns

### Existing Pattern: applyMigrations.ts Structure

The script currently handles migrations 026–033. Each migration entry has:
1. A `Migration` object in the `MIGRATIONS` array: `{ file: '034_...sql', label: '034' }`
2. A pre-verify query in `PRE_VERIFY_QUERIES` — returns 0 rows if NOT yet applied (skip detection)
3. A post-verify query in `POST_VERIFY_QUERIES` — returns 1+ rows if successfully applied

The same query is used for both pre and post in all existing cases because the queries are structural checks (column exists, function exists, table exists) — they're false before apply and true after apply.

### Verification Query Patterns by Migration Type

**Migration 034 — gem idempotency + award_gems RPC:**
- What it adds: `idempotency_key` column on `connect.gem_transactions` + `connect.award_gems` function
- Pre-verify (detect if applied): check for `idempotency_key` column OR `award_gems` function — either works; use the function (simpler query)
- Query: `SELECT proname FROM pg_proc WHERE proname = 'award_gems'`
- The `award_gems` function lives in the `connect` schema, not `public`. `pg_proc` stores the bare function name without schema prefix — this query is correct.

**Migration 035 — tier_promotion_log + promote_to_connected RPC:**
- What it adds: `connect.tier_promotion_log` table + `politician_id` column on `empower.empowered_profiles` + `connect.promote_to_connected` function
- Pre-verify: check for `tier_promotion_log` table existence OR `promote_to_connected` function
- Query: `SELECT proname FROM pg_proc WHERE proname = 'promote_to_connected'`
- Alternative: `SELECT table_name FROM information_schema.tables WHERE table_schema='connect' AND table_name='tier_promotion_log'`
- Use the function check (consistent with pattern used for 027/028/029).

**Migration 036 — access_requests + signup_with_invite RPC:**
- What it adds: `public.access_requests` table + `connect.signup_with_invite` function
- Pre-verify: check for `signup_with_invite` function
- Query: `SELECT proname FROM pg_proc WHERE proname = 'signup_with_invite'`

### Migration File Names

Follow the existing `backend/migrations/` naming convention (no timestamp prefix, sequential number + descriptive slug):
- `034_gem_idempotency.sql`
- `035_tier_promotion.sql`
- `036_signup_with_invite.sql`

The success criteria in the phase spec uses these exact names. The supabase counterparts are named with timestamps (`20260314000034_...`) but backend migrations use the short format.

### DEPLOY.md Update Pattern

DEPLOY.md Step 2 currently documents migrations 026–029 only. The update must:
1. Extend "Apply order" section to show 026 → 027 → ... → 036
2. Add post-apply verification queries for 034, 035, and 036
3. Add rollback procedures for 034, 035, 036 (following existing 027/028/029 rollback format)
4. Add the PostgREST schema config step (currently documented only in STATE.md as an open blocker)

### PostgREST Schema Config Step

From STATE.md Open Blockers: PostgREST on Supabase requires a DB-level override to pick up schema changes. The workaround is:
```sql
ALTER ROLE authenticator SET pgrst.db_schemas TO 'public,connect,empower,inform,extensions';
```
This is not in DEPLOY.md. It belongs in a new or expanded Step (between migrations and backend deploy, or as a note in Step 2).

### Anti-Patterns to Avoid
- **Modifying the supabase/migrations/ files:** These are the source of truth for the Supabase CLI. Copy them to `backend/migrations/` but do not change either version.
- **Using proname + nspname in pg_proc queries:** The existing script uses `proname` only (no schema filter). This is consistent and correct since no two functions across all schemas share these names. Do not change the pattern.
- **Wrapping backend migrations in BEGIN/COMMIT:** Check the supabase/migrations source for 034/035/036. Migration 034 and 035 include `BEGIN;`/`COMMIT;` wrapping. Migration 036 does NOT have explicit transaction wrapping. The `pg` Pool.query() call handles single-connection execution either way — do not add or remove transaction wrappers when copying files.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting if migration applied | Custom version table | Pre-verify structural queries against pg_proc / information_schema | Already established pattern; consistent with existing migrations 026–033 |
| Connection management | New connection logic | Existing `pg.Pool` in `applyMigrations.ts` | Already handles pooling, error cleanup in `finally` block |

---

## Common Pitfalls

### Pitfall 1: pg_proc proname conflict across schemas
**What goes wrong:** If two functions with the same name exist in different schemas, the pre-verify query returns >0 rows even before the migration is applied, causing a false SKIP.
**Why it happens:** `pg_proc` has one row per function signature; `proname` alone doesn't filter by schema.
**How to avoid:** The three new functions (`award_gems`, `promote_to_connected`, `signup_with_invite`) have unique names across all schemas. Verify no name collision before confirming query. None of these names appear in existing migrations 026–033.
**Warning signs:** Migration labeled SKIP on first run against a fresh database.

### Pitfall 2: Transaction wrapping inconsistency
**What goes wrong:** Migration 034 and 035 have `BEGIN;`/`COMMIT;` wrappers; migration 036 does not. The `pg` pool executes each as a single query, which is fine either way. But adding `BEGIN`/`COMMIT` to 036 or removing them from 034/035 when copying would make the files diverge from `supabase/migrations/`.
**Why it happens:** Different migrations were written at different times.
**How to avoid:** Copy supabase files verbatim. Do not normalize transaction handling.

### Pitfall 3: DEPLOY.md apply order understates dependency
**What goes wrong:** A reader could apply 034–036 without 026–033.
**Why it happens:** Step 2 currently only shows "026 → 027 → 028 → 029".
**How to avoid:** Update apply order to show full sequence 026 → 036. Note that `applyMigrations.ts` enforces this automatically via sequential loop; psql fallback instructions must also list all files in order.

### Pitfall 4: Forgetting to add psql fallback commands
**What goes wrong:** DEPLOY.md Step 2 has a "Manual apply (fallback)" block listing psql commands for each file. If 034/035/036 are added to the script but not to the fallback block, the runbook is incomplete.
**Why it happens:** Two separate places in DEPLOY.md list migration files.
**How to avoid:** Update BOTH the apply script instructions AND the psql fallback block.

### Pitfall 5: Missing rollback for new migrations
**What goes wrong:** DEPLOY.md Rollback section covers only 026–029. If 034/035/036 fail in production, the operator has no documented rollback.
**How to avoid:** Add rollback SQL for each new migration. For 034: `DROP INDEX IF EXISTS connect.idx_gem_transactions_idempotency_key; ALTER TABLE connect.gem_transactions DROP COLUMN IF EXISTS idempotency_key; DROP FUNCTION IF EXISTS connect.award_gems(...)`. For 035: drop function + table + column. For 036: drop function + table.

---

## Code Examples

### Pattern: Extending MIGRATIONS array

```typescript
// Source: existing backend/scripts/applyMigrations.ts pattern
const MIGRATIONS: Migration[] = [
  // ... existing 026-033 ...
  { file: '034_gem_idempotency.sql',    label: '034' },
  { file: '035_tier_promotion.sql',     label: '035' },
  { file: '036_signup_with_invite.sql', label: '036' },
];
```

### Pattern: Verification queries for new migrations

```typescript
// Source: derived from supabase/migrations source files
const PRE_VERIFY_QUERIES: Record<string, string> = {
  // ... existing 026-033 ...
  '034': `SELECT proname FROM pg_proc WHERE proname='award_gems'`,
  '035': `SELECT proname FROM pg_proc WHERE proname='promote_to_connected'`,
  '036': `SELECT proname FROM pg_proc WHERE proname='signup_with_invite'`,
};

const POST_VERIFY_QUERIES: Record<string, string> = {
  // ... existing 026-033 ...
  '034': `SELECT proname FROM pg_proc WHERE proname='award_gems'`,
  '035': `SELECT proname FROM pg_proc WHERE proname='promote_to_connected'`,
  '036': `SELECT proname FROM pg_proc WHERE proname='signup_with_invite'`,
};
```

### Pattern: DEPLOY.md rollback entries for new migrations

```sql
-- 034 rollback
DROP FUNCTION IF EXISTS connect.award_gems(UUID, TEXT, INTEGER, TEXT, TEXT, UUID);
DROP INDEX IF EXISTS connect.idx_gem_transactions_idempotency_key;
ALTER TABLE connect.gem_transactions DROP COLUMN IF EXISTS idempotency_key;

-- 035 rollback
DROP FUNCTION IF EXISTS connect.promote_to_connected(UUID, TEXT, UUID, TEXT);
ALTER TABLE empower.empowered_profiles DROP COLUMN IF EXISTS politician_id;
DROP TABLE IF EXISTS connect.tier_promotion_log;

-- 036 rollback
DROP FUNCTION IF EXISTS connect.signup_with_invite(UUID, TEXT, TEXT);
DROP TABLE IF EXISTS public.access_requests;
```

---

## State of the Art

| What Exists | What's Missing | Fix |
|-------------|---------------|-----|
| `backend/migrations/` 026–033 | 034, 035, 036 | Copy from supabase/migrations/ counterparts |
| `applyMigrations.ts` covers 026–033 | No entries for 034–036 | Extend MIGRATIONS + PRE/POST_VERIFY_QUERIES |
| DEPLOY.md Step 2 covers 026–029 | 030–036 not referenced | Extend to show full 026–036 apply order |
| DEPLOY.md Step 6 types regeneration | PostgREST schema config step | Add ALTER ROLE authenticator step |

---

## Open Questions

1. **Should 030–033 also be added to DEPLOY.md's psql fallback?**
   - What we know: 030–033 exist in `backend/migrations/` and are covered by `applyMigrations.ts`. DEPLOY.md Step 2 currently only shows 026–029 in the psql fallback.
   - What's unclear: Whether 030–033 were omitted from DEPLOY.md intentionally (applied separately) or by oversight.
   - Recommendation: The success criteria only require DEPLOY.md to "reference all migrations 026–036". Include all 11 migrations (026–036) in both the script instructions and psql fallback for completeness. This closes DEPLOY-02 unambiguously.

2. **PostgREST ALTER ROLE step placement in DEPLOY.md**
   - What we know: STATE.md lists this as an open blocker. It requires running `ALTER ROLE authenticator SET pgrst.db_schemas...` after migrations.
   - What's unclear: Whether to add it as a new Step 2.5 or as a note at the end of Step 2.
   - Recommendation: Add as a standalone Step 3 (shift existing steps up) or add a "Step 2, Part 3" subsection. It is operationally distinct from migration application.

---

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `C:/EV-Accounts/backend/scripts/applyMigrations.ts` — complete script source, pattern for extending
- Direct file inspection: `C:/EV-Accounts/DEPLOY.md` — full runbook content, current coverage gaps
- Direct file inspection: `C:/EV-Accounts/supabase/migrations/20260314000034_phase22_gems_idempotency.sql` — migration 034 source
- Direct file inspection: `C:/EV-Accounts/supabase/migrations/20260314000035_phase23_tier_promotion.sql` — migration 035 source
- Direct file inspection: `C:/EV-Accounts/supabase/migrations/20260314000036_phase24_signup_with_invite.sql` — migration 036 source
- Direct file inspection: `C:/EV-Accounts/.planning/v1.3-MILESTONE-AUDIT.md` — audit findings identifying the exact gap
- Direct file inspection: `C:/EV-Accounts/.planning/STATE.md` — PostgREST open blocker documented

### Secondary (MEDIUM confidence)
- `pg_proc` query pattern for function existence checks — verified by reading existing PRE/POST_VERIFY_QUERIES in the script; consistent with PostgreSQL documentation behavior

### Tertiary (LOW confidence)
None. All findings are from direct inspection of the codebase.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all tools already in repo
- Architecture: HIGH — pattern is already implemented for migrations 026–033; extending it is mechanical
- Pitfalls: HIGH — identified from direct reading of migration files and existing script logic

**Research date:** 2026-03-15
**Valid until:** This research covers static files; valid indefinitely unless migrations 034–036 are changed (they are complete and shipped).
