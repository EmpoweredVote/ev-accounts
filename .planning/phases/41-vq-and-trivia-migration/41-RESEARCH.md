# Phase 41: VQ and Trivia Migration - Research

**Researched:** 2026-03-22
**Domain:** PostgreSQL schema migration (pg_dump/restore), Postgres role management, Supabase RLS
**Confidence:** HIGH

---

## Summary

Phase 41 migrates two external schemas — `validation_quests` (from the VQ Supabase project) and `trivia` (from the EV-Backend Supabase project, `kxsdzaojfaibhuzmclfq`) — into the ev-accounts Supabase project. The schemas are structurally independent from ev-accounts' native schemas but contain FK references to politician UUIDs that must be reconciled against `essentials.politicians`.

The VQ application already calls the ev-accounts API (`POST /api/vq/confirm-stance`) for its confirmation flow. That flow runs the `connect.confirm_vq_stance` SECURITY DEFINER RPC, which was updated in Phase 35 to reference `essentials.politicians`. VQ's *own* `DATABASE_URL` (used for its internal tables — quests, submissions, consensus) currently points at a separate Supabase project; after this migration it will point at ev-accounts.

The migration is a physical data move (pg_dump + restore) plus three layers of post-restore work: (1) trivia FK reconciliation via `public.politician_id_bridge`, (2) role creation and access grant for VQ's direct connection, and (3) RLS enablement on all migrated tables before any endpoint or connection goes live.

There are no new application endpoints to build in this phase. The `POST /api/vq/confirm-stance` route and `connect.confirm_vq_stance` RPC already work. The only ev-accounts code change is potentially none — just env var updates on the VQ Render service.

**Primary recommendation:** Execute as a single maintenance window: pg_dump both schemas, restore into ev-accounts, run the pre-flight FK reconciliation query, apply the FK fix (insert or null), create the `vq_service` role, apply RLS migrations, update VQ's `DATABASE_URL` env var on Render, restart VQ. Verify row counts and run the confirmation flow smoke test.

---

## Standard Stack

Phase 41 is SQL + CLI tooling — no new npm packages needed.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| pg_dump | Bundled with Postgres | Extract schema + data from source DB | Standard Postgres tool; handles schema isolation with `--schema` flag |
| psql | Bundled with Postgres | Restore dump into target DB | Paired with pg_dump; handles large imports |
| Supabase MCP | Production (`kxsdzaojfaibhuzmclfq` = source; ev-accounts = target) | Verify data post-restore; execute RLS migrations | Already in use for all migrations; `execute_sql` for DDL |
| PostgreSQL RLS | Postgres 17 | Row-level access control | Native DB feature; established pattern across all Phase 34 migrations |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `supabase db query --linked --file` | Supabase CLI | Apply migration SQL files | Used in Phase 34 as alternative to MCP when needed |
| Render dashboard | N/A | Update `DATABASE_URL` env var on VQ service | Post-restore env var swap |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| pg_dump/restore | Supabase migration files (DDL handwritten) | Hand-writing DDL for foreign schemas is error-prone and loses sequence state; pg_dump captures everything including sequences, constraints, and indexes |
| Single combined dump | Separate dump per schema | Separate dumps are easier to debug; if trivia FK reconciliation fails, VQ restore can proceed independently |

**Installation:** No new packages.

---

## Architecture Patterns

### Connection Model: VQ Direct vs. Trivia API

**VQ — Direct Postgres connection (confirmed by context):**

VQ is a persistent Render service that uses `DATABASE_URL` (a direct Postgres connection string, not Supabase REST API) to read/write its own schema. This is the same pattern ev-accounts uses (`pg.Pool` in `backend/src/lib/db.ts`). After migration, VQ's `DATABASE_URL` points at the ev-accounts database, restricted to the `validation_quests` schema via the `vq_service` role.

**Trivia — connection model is Claude's Discretion to investigate:**

The CONTEXT.md marks Trivia's connection model as requiring investigation. The ev-accounts `serviceKeyAuth.ts` defines `TRIVIA_SERVICE_KEY` → `['civic_trivia_championship_score']`, confirming Trivia already calls the ev-accounts API for XP awards. Whether Trivia also connects directly via DATABASE_URL (for its own `trivia` schema reads) or goes through ev-accounts routes is unknown. Two possible outcomes:
- **If Trivia uses DATABASE_URL:** create a `trivia_service` role (same pattern as `vq_service`)
- **If Trivia uses ev-accounts API only:** no direct DB connection needed; add ev-accounts routes for trivia schema reads

This must be determined during Plan 01 by querying Trivia's Render environment variables (or asking the Trivia repo's configuration).

### Pre-Flight: Row Count Baseline

Pattern established in Phase 34. Before dump: capture counts from source. After restore: compare to target.

```sql
-- Run on EV-Backend DB (source) before dump:
SELECT 'validation_quests' as schema, tablename,
       (SELECT reltuples::bigint FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'validation_quests' AND c.relname = tablename) as approx_count
FROM pg_tables WHERE schemaname = 'validation_quests'
ORDER BY tablename;

-- Same pattern for trivia schema
```

After restore, run count queries on ev-accounts to verify parity.

### Pre-Flight: Trivia FK Reconciliation

The `public.politician_id_bridge` table (created in Phase 35) maps `inform_id → essentials_id` for the 30 politicians from the inform migration. Trivia questions referencing politicians use UUIDs from the source database. These may or may not match `essentials.politicians` in ev-accounts.

```sql
-- Run on EV-Backend DB (source) to count trivia FK gaps:
-- Replace 'politician_id' and 'trivia_table' with actual column/table names after schema inspection
SELECT COUNT(*) as total,
       COUNT(p.id) as matched,
       COUNT(*) - COUNT(p.id) as unmatched
FROM trivia.questions q  -- actual table TBD after schema inspection
LEFT JOIN essentials.politicians p ON p.id = q.politician_id
WHERE q.politician_id IS NOT NULL;
```

**Decision (from CONTEXT.md):**
- Small gaps: add missing politicians to `essentials.politicians` before migration
- Large gaps: null the FK on unmatched rows after restore, log UUIDs for manual review

### Recommended Migration Sequence

```
Plan 01: Pre-flight inspection
  - Enumerate all validation_quests and trivia tables + row counts (source DB)
  - Investigate Trivia connection model
  - Run trivia FK gap analysis against essentials.politicians
  - Document any FK gaps requiring resolution

Plan 02: Restore and Role Creation
  - pg_dump validation_quests schema (source VQ DB)
  - pg_dump trivia schema (source EV-Backend DB)
  - psql restore both into ev-accounts
  - Verify row counts match baseline
  - Resolve trivia FK gaps (insert or null)
  - Create vq_service role with correct grants
  - (If needed) create trivia_service role

Plan 03: RLS Migration
  - Enable RLS on all validation_quests tables
  - Enable RLS on all trivia tables
  - Apply appropriate policies (owner-read for user data, public-read for reference data)
  - GRANT USAGE + SELECT to appropriate roles
  - Smoke test: unauthenticated access blocked

Plan 04: Cutover
  - Update VQ DATABASE_URL env var on Render
  - Restart VQ service
  - Run confirm-stance smoke test end-to-end
  - (If applicable) update Trivia DATABASE_URL
  - Verify PLATFORM-CONSOLIDATION requirements fulfilled
```

### RLS Policy Categories for validation_quests

The `validation_quests` schema holds: quests, submissions, consensus data, veracity profiles. This is user-linked data — users have their own quest progress and veracity profiles. Expected policy categories:

- **Owner-read:** quest submissions, veracity profiles (rows linked to a user_id)
- **Authenticated-read:** consensus data, quest definitions (shared game data that authenticated players need)
- **Public-read:** possibly quest templates or question content if anonymous discovery is needed

The exact category per table cannot be determined until the schema is enumerated in Plan 01. Follow the Phase 34 pattern: run a `user_id` column detection query on both schemas, then assign policy types based on results.

### RLS Policy Categories for trivia

The `trivia` schema holds: topics, collections, questions, player stats, election races. Expected:

- **Public-read:** topics, collections, questions, election races (game content)
- **Owner-read:** player stats (user-linked)

### Role Creation Pattern for vq_service

```sql
-- Source: Postgres docs + ev-accounts db.ts pool pattern
-- Named role with scoped search_path and DML grants

CREATE ROLE vq_service WITH LOGIN PASSWORD '<generated-password>';

-- Grant schema access
GRANT USAGE ON SCHEMA validation_quests TO vq_service;

-- Grant DML on all tables in schema
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA validation_quests TO vq_service;

-- Grant EXECUTE on any RPCs VQ calls (none in this phase — future-proofing)
-- GRANT EXECUTE ON FUNCTION connect.confirm_vq_stance(...) TO vq_service;
-- NOTE: confirm_vq_stance is in connect schema; vq_service scope is validation_quests only.
-- VQ calls confirm_vq_stance via the ev-accounts API (HTTP), NOT direct DB call.

-- Set search_path so VQ's unqualified table references work
ALTER ROLE vq_service SET search_path = validation_quests;
```

**Critical nuance:** `confirm_vq_stance` is called by VQ via HTTP (`POST /api/vq/confirm-stance`), not via direct Postgres connection. The `vq_service` role only needs access to the `validation_quests` schema. No `connect` or `inform` schema access is needed.

### pg_dump/restore Flags

```bash
# Source: PLATFORM-CONSOLIDATION.md Phase 0 + Phase 5 guidance

# Dump validation_quests schema (from VQ Supabase project)
pg_dump \
  --schema=validation_quests \
  --no-owner \
  --no-privileges \
  --no-acl \
  -f vq-export.sql \
  "$VQ_DATABASE_URL"

# Dump trivia schema (from EV-Backend Supabase project)
pg_dump \
  --schema=trivia \
  --no-owner \
  --no-privileges \
  --no-acl \
  -f trivia-export.sql \
  "$EV_BACKEND_DATABASE_URL"

# Restore into ev-accounts
psql "$EV_ACCOUNTS_DATABASE_URL" < vq-export.sql
psql "$EV_ACCOUNTS_DATABASE_URL" < trivia-export.sql
```

**Flag rationale:**
- `--no-owner` — source DB roles don't exist in ev-accounts; skip OWNER TO statements that would fail
- `--no-privileges` — source ACL grants (to EV-Backend's anon/authenticated Supabase roles) are project-specific; phase 41 applies fresh RLS instead
- `--no-acl` — same as above, redundant with `--no-privileges` but explicit

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema export | Manual CREATE TABLE statements | `pg_dump --schema-only` | pg_dump captures sequences, constraints, indexes, triggers in correct order |
| Idempotency key table in ev-accounts | New ev-accounts idempotency table | Preserve `validation_quests` tables via full data migration | Existing idempotency keys are the safety net against double-awards on cutover; they must survive as-is |
| Admin role for VQ | Service role / `supabase_admin` | Dedicated `vq_service` login role | Service role is the ev-accounts server credential; VQ should never share it |
| FK reconciliation via application code | JS loop to fix politician IDs | SQL UPDATE ... FROM public.politician_id_bridge | Atomic single-statement SQL; the bridge table exists exactly for this purpose |
| RLS on validation_quests from scratch | New policy designs | Follow Phase 34 patterns exactly | Phase 34 established the three-category model (public-read / authenticated-read / owner-read); use the same patterns |

---

## Common Pitfalls

### Pitfall 1: pg_dump includes SET search_path statements that break restore

**What goes wrong:** pg_dump outputs `SET search_path TO "$user", public;` at the top, which overrides the schema-qualified table references and can cause objects to land in the wrong schema.
**Why it happens:** pg_dump default behavior; Supabase projects set a specific search_path.
**How to avoid:** Review the dump file header before restoring. If the search_path directive conflicts, either remove it or add `--schema-only` + `--data-only` in separate passes.
**Warning signs:** Tables end up in `public` schema instead of `validation_quests`.

### Pitfall 2: pg_dump captures EV-Backend/VQ-specific extensions or functions

**What goes wrong:** The dump includes CREATE EXTENSION statements (e.g., `pgcrypto`, `uuid-ossp`) that either already exist in ev-accounts or require superuser privileges to create.
**Why it happens:** pg_dump by default includes extension DDL.
**How to avoid:** ev-accounts already has all necessary extensions. If the restore errors on CREATE EXTENSION, add `--exclude-schema=pg_catalog` or manually remove extension statements from the dump before restoring.
**Warning signs:** `ERROR: extension "uuid-ossp" already exists` during restore.

### Pitfall 3: Supabase-specific roles in dump (authenticator, anon) don't exist in target

**What goes wrong:** The dump contains GRANT statements to roles like `anon` or `authenticated` that are project-specific Supabase roles. These fail on restore.
**Why it happens:** `--no-privileges` should suppress these, but `--no-acl` may not suppress all GRANT statements in table definitions.
**How to avoid:** Use `--no-owner --no-privileges --no-acl` consistently. Verify the dump contains no failing GRANT statements in a dry run.
**Warning signs:** `ERROR: role "anon" does not exist` during restore (ev-accounts does have these roles, but timing matters if the dump runs before role creation).

### Pitfall 4: Trivia FK violations block restore

**What goes wrong:** `trivia.questions.politician_id` (or similar) has a FOREIGN KEY constraint referencing a politician table that doesn't exist in ev-accounts under the expected path.
**Why it happens:** The source trivia schema has FK constraints referencing its own project's `public.politicians` or `essentials.politicians` — different UUID space.
**How to avoid:** Inspect the dump for FK constraint definitions before restoring. If FKs reference `essentials.politicians`, they may resolve (ev-accounts has that table). If they reference EV-Backend's `public.politicians` (which doesn't exist in ev-accounts), the constraint must be dropped or deferred.
**Warning signs:** `ERROR: insert or update on table "questions" violates foreign key constraint` during restore.
**Resolution:** Use `--no-owner` plus temporarily disabling FK checks during restore, or restore data-only after creating structure without the problematic FK.

### Pitfall 5: vq_service role search_path doesn't eliminate need for schema-qualified queries in application code

**What goes wrong:** `ALTER ROLE vq_service SET search_path = validation_quests` sets the default for new connections, but doesn't fix queries that are schema-qualified with the wrong prefix.
**Why it happens:** Misunderstanding — the search_path setting is additive; VQ's queries that say `SELECT * FROM validation_quests.quests` still work (fully qualified overrides search_path). Only unqualified queries like `SELECT * FROM quests` benefit from the search_path default.
**How to avoid:** The goal is to make unqualified queries work without code changes. This is the stated design in CONTEXT.md. As long as VQ uses unqualified table names internally, the `search_path` role default achieves the goal.
**Warning signs:** VQ startup errors about missing tables or wrong schema on connect.

### Pitfall 6: Idempotency keys migrate but VQ generates keys based on timestamps that collide with post-migration calls

**What goes wrong:** After cutover, VQ starts generating new idempotency keys. If VQ's key generation uses a counter that resets on restart (rather than UUIDs or timestamp-based keys), new keys could collide with migrated keys.
**Why it happens:** Idempotency key collision would cause post-cutover confirmations to return cached results from pre-migration data.
**How to avoid:** Verify VQ's idempotency key generation strategy. If keys are UUID-based, no collision is possible. If counter-based, the idempotency table migration must be inspected.
**Warning signs:** Post-cutover `confirm-stance` calls return `replayed: true` unexpectedly.

### Pitfall 7: Missing GRANT USAGE on schema blocks vq_service role

**What goes wrong:** `vq_service` role exists with correct DML grants on tables, but all queries fail with "permission denied for schema validation_quests."
**Why it happens:** PostgreSQL requires `GRANT USAGE ON SCHEMA` before any role can access objects in the schema, even if table-level grants exist.
**How to avoid:** Always include `GRANT USAGE ON SCHEMA validation_quests TO vq_service;` before table-level grants.
**Warning signs:** VQ startup connection succeeds but first query fails.

### Pitfall 8: RLS blocks vq_service role's own writes

**What goes wrong:** RLS is enabled, but no policy exists allowing `vq_service` to write. All INSERT/UPDATE/DELETE by VQ fail silently.
**Why it happens:** RLS applies to all roles except those with `BYPASSRLS` privilege or the superuser. The `vq_service` role does not bypass RLS.
**How to avoid:** For `validation_quests`, the `vq_service` role must be explicitly granted by either: (a) adding it to the `TO` clause of existing policies, or (b) creating service-role-specific write policies. Option (b) is consistent with the established ev-accounts pattern.
**Resolution:** Add `GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA validation_quests TO vq_service;` AND ensure RLS policies cover `vq_service` role or use `BYPASSRLS` on the role.

**Note:** The simplest solution is `ALTER ROLE vq_service BYPASSRLS;` — this is what Supabase does for the `service_role` user. Since `vq_service` is scoped to `validation_quests` only, BYPASSRLS for that role is the lowest-friction approach and matches the ev-accounts pattern of service roles bypassing RLS.

---

## Code Examples

### RLS Pattern for Owner-Read (user-linked VQ tables)

```sql
-- Source: migration 20260315000038_phase28_vq_confirm_stance.sql + Phase 34 patterns
-- For tables in validation_quests that have user_id columns

ALTER TABLE validation_quests.submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "submissions: owner select"
  ON validation_quests.submissions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- NOTE: vq_service bypasses RLS via BYPASSRLS privilege (see role creation below)
```

### RLS Pattern for Public-Read (trivia reference data)

```sql
-- Source: migration 20260319000044_phase34_essentials_rls.sql pattern

ALTER TABLE trivia.questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "questions: public read"
  ON trivia.questions
  FOR SELECT
  TO anon, authenticated
  USING (true);
```

### Role Creation (vq_service)

```sql
-- Source: PostgreSQL docs (verified pattern; no Context7 entry for Postgres roles)
-- Confidence: HIGH — standard Postgres DDL

CREATE ROLE vq_service WITH LOGIN PASSWORD '<strong-password>';

GRANT USAGE ON SCHEMA validation_quests TO vq_service;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA validation_quests TO vq_service;
ALTER ROLE vq_service SET search_path = validation_quests;
ALTER ROLE vq_service BYPASSRLS;

-- Verify:
SELECT rolname, rolbypassrls, rolcanlogin FROM pg_roles WHERE rolname = 'vq_service';
```

### Trivia FK Reconciliation (post-restore)

```sql
-- Source: public.politician_id_bridge from Phase 35 migration
-- Run after trivia restore to find unmatched politician references

SELECT q.id, q.politician_id
FROM trivia.<table_with_politician_id> q
LEFT JOIN essentials.politicians ep ON ep.id = q.politician_id
WHERE q.politician_id IS NOT NULL
  AND ep.id IS NULL;
-- Returns rows that need nulling or manual insertion

-- If gaps are small: add to essentials.politicians
-- If gaps are large: null the FK on unmatched rows
UPDATE trivia.<table_with_politician_id>
SET politician_id = NULL
WHERE politician_id NOT IN (SELECT id FROM essentials.politicians)
  AND politician_id IS NOT NULL;
```

### Row Count Verification (post-restore)

```sql
-- Run on source DB to capture baseline, then on ev-accounts to verify
-- Source: Phase 34 pattern (34-01-PLAN.md)

SELECT schemaname, tablename,
       (SELECT COUNT(*) FROM validation_quests.tablename) as row_count
FROM pg_tables
WHERE schemaname = 'validation_quests'
ORDER BY tablename;
```

### Post-Cutover Smoke Test

```bash
# Verify VQ connects on startup (check Render logs for connection success)
# Then test the confirmation flow:
curl -X POST https://ev-accounts-api.onrender.com/api/vq/confirm-stance \
  -H "X-Gems-Service-Key: $VQ_GEMS_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "politician_id": "<valid-essentials-uuid>",
    "topic_id": "<valid-compass-topic-uuid>",
    "confirmed_value": 3,
    "correct_user_ids": [],
    "incorrect_user_ids": [],
    "idempotency_key": "smoke-test-phase41-001",
    "gems_amount": 1
  }'
# Expected: 200 with politician_id, topic_id, confirmed_value in response
# If replayed: true, use a fresh idempotency_key
```

---

## Key Dependency: confirm_vq_stance is Already in ev-accounts

**This is the most important architectural point for planning:**

The `POST /api/vq/confirm-stance` endpoint and `connect.confirm_vq_stance` RPC already exist in ev-accounts (shipped in Phase 28, updated in Phase 35 to use `essentials.politicians`). VQ already calls this endpoint over HTTP — it does NOT access the `connect` schema via DATABASE_URL.

Phase 41's `DATABASE_URL` change affects only VQ's access to its **own** `validation_quests` schema (quests, submissions, veracity profiles). The confirm-stance flow is unaffected by the DATABASE_URL swap — it continues going through the ev-accounts HTTP API.

This means:
- No ev-accounts code changes are required for the confirm-stance flow
- The `vq_service` Postgres role needs zero access to `connect`, `inform`, or `essentials` schemas
- The smoke test for CONS-18 (VQ confirmation flow works end-to-end after migration) is already passing on the current ev-accounts API; the test verifies the full path (HTTP → RPC → connect schema writes)

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| inform.politicians as politician FK target | essentials.politicians | Phase 35 (migration 050) | confirm_vq_stance RPC updated; trivia FK reconciliation targets essentials.politicians |
| No RLS on migrated schemas | RLS on all tables before endpoints go live | Phase 34 | Pattern established; validation_quests and trivia follow the same pattern |
| EV-Backend compass schema (Go) | inform.* (ev-accounts) | Phase 34 | compass schema is legacy; validation_quests references inform.compass_topics via the RPC |

**Deprecated:**
- `inform.politicians` table: dropped in Phase 35; any trivia/VQ FK to this table must target `essentials.politicians` instead
- EV-Backend `public.politicians` (integer PK): the source Supabase project used integer IDs in early phases; these were migrated to UUID. Trivia questions created before UUID migration may have integer politician references — this is a potential FK gap to discover in Plan 01.

---

## Open Questions

1. **What tables exist in validation_quests and trivia, and what are their exact row counts?**
   - What we know: PLATFORM-CONSOLIDATION.md says `validation_quests` has 14 tables, `trivia` has 9 tables
   - What's unclear: exact table names, which tables have user_id columns, current row counts
   - Recommendation: Plan 01's first task is `SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('validation_quests', 'trivia') ORDER BY schemaname, tablename` against the source databases

2. **Does Trivia connect via DATABASE_URL or ev-accounts API?**
   - What we know: Trivia uses `TRIVIA_SERVICE_KEY` to call ev-accounts for XP awards (confirmed in `serviceKeyAuth.ts`)
   - What's unclear: whether Trivia also reads/writes its own `trivia` schema via a direct DATABASE_URL
   - Recommendation: Inspect Trivia's Render environment variables. If `DATABASE_URL` is set and points to a Supabase project, it uses direct DB. If not, all Trivia DB access goes through the ev-accounts API.
   - Impact: determines whether a `trivia_service` role is needed

3. **What politician UUID format does Trivia use?**
   - What we know: essentials.politicians uses UUIDs; Trivia is on the EV-Backend Supabase project which originally used integer politician IDs
   - What's unclear: whether Trivia's politician references are UUID or integer
   - Recommendation: Run `SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'trivia' AND column_name ILIKE '%politician%'` against EV-Backend to determine FK type

4. **Are there any Supabase Auth triggers or functions in validation_quests that reference auth.users?**
   - What we know: VQ uses Supabase JWT auth (already ev-accounts auth)
   - What's unclear: whether the VQ schema has triggers or FK constraints referencing `auth.users` that need to survive migration
   - Recommendation: `SELECT trigger_name, event_manipulation, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'validation_quests'` against source DB

5. **What is VQ's idempotency key format?**
   - What we know: VQ calls `confirm_vq_stance` with an idempotency_key; the result is cached in `connect.vq_confirmation_results` (not in `validation_quests`)
   - What's unclear: whether VQ maintains its own idempotency tracking in the `validation_quests` schema for its internal operations
   - Recommendation: Verify in Plan 01 whether any `validation_quests` table is named `*idempotency*` or `*cache*`

---

## Sources

### Primary (HIGH confidence)
- `supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql` — confirms confirm_vq_stance RPC is in `connect` schema; VQ calls it via HTTP, not direct DB
- `supabase/migrations/20260320000050_phase35_politician_deduplication.sql` — confirms RPC updated to use `essentials.politicians`; bridge table structure
- `backend/src/lib/db.ts` — ev-accounts Pool config pattern (ssl: rejectUnauthorized false, direct port 5432)
- `backend/src/lib/vqService.ts` — VQ uses HTTP API for confirm-stance; `DATABASE_URL` is separate concern
- `backend/src/middleware/serviceKeyAuth.ts` — Trivia uses `TRIVIA_SERVICE_KEY` for ev-accounts API; confirms Trivia already calls ev-accounts
- `.planning/phases/34-database-schema-migration/34-01-SUMMARY.md` — row count baseline pattern; RLS policy categories; clean-slate pattern
- `.planning/phases/34-database-schema-migration/34-RESEARCH.md` — established RLS patterns; GRANT USAGE requirement; policy naming conventions
- `supabase/migrations/20260319000044_phase34_essentials_rls.sql` — exact migration file pattern to follow
- `supabase/migrations/20260319000049_phase34_staging_rls.sql` — authenticated-only read pattern

### Secondary (MEDIUM confidence)
- `PLATFORM-CONSOLIDATION.md` — Phase 5 (VQ/Trivia migration steps); pg_dump flags; table count estimates
- `PLATFORM-CONSOLIDATION.md` — Appendix A confirms EV-Backend and Trivia share the same Supabase project (`kxsdzaojfaibhuzmclfq`)
- `PLATFORM-CONSOLIDATION.md` — `validation_quests: 14 tables` and `trivia: 9 tables` (unverified against production)

### Tertiary (LOW confidence)
- Trivia connection model (DATABASE_URL vs API only) — inferred from `TRIVIA_SERVICE_KEY` existence but not confirmed
- Exact trivia politician FK type (UUID vs integer) — inferred from platform history but requires production inspection

---

## Metadata

**Confidence breakdown:**
- pg_dump/restore tooling and flags: HIGH — standard Postgres tooling; PLATFORM-CONSOLIDATION.md guidance verified
- RLS policy patterns: HIGH — verified across 6 Phase 34 migration files
- vq_service role creation SQL: HIGH — standard Postgres DDL; consistent with ev-accounts db.ts pattern
- confirm_vq_stance is in ev-accounts (not affected by DATABASE_URL swap): HIGH — confirmed in Phase 28 migration and vqService.ts
- Trivia connection model: LOW — requires investigation in Plan 01
- Exact validation_quests and trivia table inventory: LOW — PLATFORM-CONSOLIDATION.md estimates; must verify against production

**Research date:** 2026-03-22
**Valid until:** 2026-04-22 (stable domain — Postgres migration patterns don't change frequently)
