# Phase 35: Politician Deduplication - Research

**Researched:** 2026-03-19
**Domain:** PostgreSQL schema migration, FK reassignment, data deduplication
**Confidence:** HIGH

---

## Summary

Phase 35 unifies two parallel politician ID spaces into one. `inform.politicians` was ev-accounts' hand-rolled table (4 records, created in migration 015 and extended in migration 033). `essentials.politicians` is EV-Backend's authoritative table (1,854 records, already present in the same Supabase project after Phase 34 confirmed both schemas live in `kxsdzaojfaibhuzmclfq`).

The deduplication has a fixed sequence: create the bridge table mapping `inform` UUIDs to `essentials` UUIDs, update the two FK-bearing tables (`inform.politician_answers`, `inform.politician_context`) to reference `essentials.politicians`, update the `confirm_vq_stance` RPC to validate against `essentials.politicians`, drop `inform.politicians`, and update all application code that still queries `inform.politicians`.

The data scale is small: `inform.politicians` has only 4 seed rows (confirmed in Phase 34-01 inventory, which showed 3 in `staging.politicians` — the `inform` count was 4 per the seedPoliticians script). `inform.politician_answers` and `inform.politician_context` have unknown row counts but given 4 politicians and no production users on these answers yet, the data volume is trivially small. The matching algorithm is manual rather than fuzzy-match because there are only 4 records to map.

**Primary recommendation:** Single migration with five steps inside one transaction: create bridge table, update FKs in `politician_answers` and `politician_context`, rebuild `confirm_vq_stance` RPC referencing `essentials.politicians`, verify no orphaned rows remain, then drop `inform.politicians`. Follow with application code updates.

---

## Standard Stack

Phase 35 is pure SQL migration + TypeScript application code updates — no new libraries.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| PostgreSQL DDL | Postgres 17 | FK migration, table drop | Native; established across all 49 existing migrations |
| `pool.query()` (pg) | existing | All non-public schema writes | Established critical production pattern — NEVER PostgREST for non-public schemas |
| Supabase MCP | production | Apply migrations | `mcp__supabase-local__apply_migration` hits prod directly per reference doc |
| `supabase db query --linked` | CLI | Verify migration results | Confirmed working in Phase 34-01 and 34-02 |

### Supporting
No new dependencies. All patterns exist in the current codebase.

**Installation:** No new packages.

---

## Architecture Patterns

### Recommended Migration Structure

```
supabase/migrations/
  20260320000050_phase35_politician_deduplication.sql
```

Single migration file — all steps are causally dependent and must execute atomically. If any step fails, the entire migration rolls back.

### Migration Step Order (within one transaction)

```sql
-- Source: PLATFORM-CONSOLIDATION.md Phase 2 + established project patterns

BEGIN;

-- Step 1: Create bridge table
CREATE TABLE public.politician_id_bridge (
  essentials_id UUID NOT NULL REFERENCES essentials.politicians(id),
  inform_id     UUID NOT NULL REFERENCES inform.politicians(id),
  matched_by    TEXT NOT NULL,  -- 'name_exact', 'manual'
  PRIMARY KEY (essentials_id, inform_id)
);

-- Step 2: Populate bridge table (4 rows, manual matching by name/office)
-- ... INSERT INTO public.politician_id_bridge ...

-- Step 3: Reassign FKs in politician_answers
UPDATE inform.politician_answers pa
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pa.politician_id = bridge.inform_id;

-- Step 4: Reassign FKs in politician_context
UPDATE inform.politician_context pc
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pc.politician_id = bridge.inform_id;

-- Step 5: Drop FK constraint on politician_answers -> inform.politicians
ALTER TABLE inform.politician_answers
  DROP CONSTRAINT IF EXISTS politician_answers_politician_id_fkey;

-- Step 6: Add FK constraint on politician_answers -> essentials.politicians
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_politician_id_fkey
  FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);

-- Step 7: Drop FK constraint on politician_context -> inform.politicians
ALTER TABLE inform.politician_context
  DROP CONSTRAINT IF EXISTS politician_context_politician_id_fkey;

-- Step 8: Add FK constraint on politician_context -> essentials.politicians
ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_politician_id_fkey
  FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);

-- Step 9: Rebuild confirm_vq_stance RPC to reference essentials.politicians
-- (DROP FUNCTION + CREATE OR REPLACE — return type unchanged, only body changes)

-- Step 10: Drop admin_list_politicians (return type changes — must DROP then recreate)
-- Step 11: Recreate admin_list_politicians pointing at essentials.politicians
-- Step 12: Rebuild admin_update_politician_answers to reference essentials.politicians

-- Step 13: Drop inform.politicians
DROP TABLE inform.politicians;

COMMIT;
```

### Application Code Update Scope

After the migration, update TypeScript to point at `essentials.politicians`:

| File | Function | Change |
|------|----------|--------|
| `backend/src/lib/compassService.ts` | `getCompassPoliticians()` | `.schema('essentials')` instead of `.schema('inform')` |
| `backend/src/lib/essentialsService.ts` | `getPoliticiansGrouped()` | `.schema('essentials')` instead of `.schema('inform')` |
| `backend/src/lib/adminService.ts` | `adminCreatePolitician()` | `.schema('essentials')` instead of `.schema('inform')` |
| `backend/src/lib/adminService.ts` | `adminUpdatePolitician()` | `.schema('essentials')` instead of `.schema('inform')` |
| `scripts/seedPoliticians.ts` | `main()` | `.schema('essentials')` instead of `.schema('inform')` |

Note: `adminSetPoliticianContext()` in adminService.ts writes to `inform.politician_context` via PostgREST — this is a non-public schema write via PostgREST, which is the forbidden pattern (MEMORY.md critical production pattern). After Phase 35 this should be `pool.query()`. However, the FK migration must happen first so this is a natural cleanup opportunity within this phase.

### Baseline Capture Pattern (Pre-Migration)

Before writing the migration, capture the actual data to populate the bridge table:

```sql
-- Run before migration to get inform.politicians rows for manual matching
SELECT id, first_name, last_name, office_title, district_id, district_type
FROM inform.politicians
ORDER BY last_name;
```

Then match each row against `essentials.politicians`:
```sql
-- Find matching essentials records by name/office
SELECT id, full_name, office_title, district_type, district_id
FROM essentials.politicians
WHERE district_type IS NOT NULL
ORDER BY last_name;
```

### Anti-Patterns to Avoid

- **DO NOT use PostgREST for any non-public schema writes.** All updates to `inform.politician_answers` and `inform.politician_context` in application code must use `pool.query()`. Migration SQL uses direct Postgres (always safe inside migrations).
- **DO NOT drop `inform.politicians` before updating FKs.** Postgres will reject DROP TABLE if there are still FK references pointing at it. The constraint drop + reassignment must happen first.
- **DO NOT use a fuzzy match algorithm.** With only 4 records, manual inspection is safer and produces an auditable mapping. Fuzzy matching on names risks incorrect merges.
- **DO NOT forget to rebuild the RPC.** `confirm_vq_stance` contains `FROM inform.politicians p WHERE p.id = p_politician_id` — this query will fail after `inform.politicians` is dropped if the RPC is not updated.
- **DO NOT forget to rebuild `admin_list_politicians`.** This RPC references `inform.politicians` directly and has a fixed RETURNS TABLE signature. It must be dropped and recreated pointing at `essentials.politicians`.
- **DO NOT forget `admin_update_politician_answers`.** This RPC inserts into `inform.politician_answers` which now has a FK to `essentials.politicians` — the RPC itself is fine (it writes to `inform.politician_answers`, not `inform.politicians`), but the FK constraint on that table changes.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ID mapping audit trail | Ad-hoc comment in migration | `public.politician_id_bridge` table | CONS-05 requires it; bridge table is permanent and queryable by downstream consumers (Essentials integration) |
| Name-matching algorithm | Fuzzy match code | Manual inspection (4 records) | 4 records do not justify code complexity; manual review produces zero false-positive merges |
| FK reassignment logic | Application-layer update loop | Single SQL `UPDATE ... FROM` | Atomic, runs inside the migration transaction; no JS needed |
| Post-migration verification | Test script | SQL query against bridge table + count assertions | Same tools used in Phase 34 verification pattern |

**Key insight:** The data volume (4 rows in `inform.politicians`) makes this an administrative migration, not an algorithmic deduplication problem. The entire FK reassignment fits in a single SQL `UPDATE ... FROM` statement.

---

## Common Pitfalls

### Pitfall 1: Orphaned Rows After FK Update

**What goes wrong:** `inform.politician_answers` rows where `politician_id` didn't match any `inform_id` in the bridge table remain pointing at `inform` UUIDs that no longer exist after `inform.politicians` is dropped. The DROP TABLE fails because FKs still reference it (or worse, succeeds with orphaned data if constraints were already dropped).
**Why it happens:** Bridge table is incomplete — a `politician_id` in `politician_answers` has no mapping.
**How to avoid:** Before issuing `DROP TABLE inform.politicians`, assert no orphaned rows exist:
```sql
-- Must return 0 rows before DROP
SELECT pa.politician_id
FROM inform.politician_answers pa
LEFT JOIN essentials.politicians ep ON pa.politician_id = ep.id
WHERE ep.id IS NULL;
```
**Warning signs:** FK violation error on `DROP TABLE inform.politicians`.

### Pitfall 2: confirm_vq_stance Validation Logic Breaks After Drop

**What goes wrong:** `confirm_vq_stance` RPC validates politician existence with `FROM inform.politicians p WHERE p.id = p_politician_id`. After `inform.politicians` is dropped, every VQ confirmation call raises `undefined_table` error.
**Why it happens:** The RPC body is not updated to use `essentials.politicians` before the table drop.
**How to avoid:** The migration must rebuild `confirm_vq_stance` BEFORE issuing `DROP TABLE inform.politicians`. Both operations are in the same transaction — if the RPC rebuild fails, `DROP TABLE` never runs.
**Warning signs:** VQ confirmation calls fail with `relation "inform.politicians" does not exist` after migration.

### Pitfall 3: admin_list_politicians Return Type Change

**What goes wrong:** `admin_list_politicians()` is a SECURITY DEFINER RPC with a `RETURNS TABLE` signature. The essentials.politicians table has many more columns than `inform.politicians`. If the return signature does not change, callers receive fewer fields. If it does change, `CREATE OR REPLACE` raises `cannot change return type of existing function`.
**Why it happens:** This is the same pattern documented in migration 033 (which already dropped and recreated `admin_list_politicians` once to add 9 new columns).
**How to avoid:** Always `DROP FUNCTION IF EXISTS public.admin_list_politicians()` before `CREATE OR REPLACE` — established pattern from migration 033. Update the RETURNS TABLE signature to include whatever fields are needed from `essentials.politicians`.
**Warning signs:** `ERROR: cannot change return type of existing function` during migration.

### Pitfall 4: essentialsService.ts Still Queries inform.politicians

**What goes wrong:** `essentialsService.ts` reads from `inform` schema (`supabaseAnon.schema('inform').from('politicians')`). After the table is dropped, `GET /api/essentials/politicians` returns 500.
**Why it happens:** The code update is separate from the migration and can be missed.
**How to avoid:** Application code updates must land in the same deploy as the migration. The verification step explicitly checks that the endpoint returns a 200 with data.
**Warning signs:** `GET /api/essentials/politicians` returns 500 after migration applied.

### Pitfall 5: seedPoliticians.ts Still Targets inform Schema

**What goes wrong:** `scripts/seedPoliticians.ts` inserts into `inform.politicians` (`.schema('inform').from('politicians').insert()`). After the table is dropped, running the seed script causes a PostgREST 404 error.
**Why it happens:** Seed script update is out of scope of the main migration and can be overlooked.
**How to avoid:** Update `seedPoliticians.ts` to target `essentials.politicians` in the same task that updates the other application code. Also note: the seed data column set must be verified against `essentials.politicians` — `full_name` is `GENERATED ALWAYS AS` on `inform.politicians` but may have different generation logic in `essentials.politicians`.
**Warning signs:** `npx tsx scripts/seedPoliticians.ts` errors with PostgREST 404 after migration.

### Pitfall 6: adminSetPoliticianContext Uses PostgREST on Non-Public Schema

**What goes wrong:** `adminService.ts:adminSetPoliticianContext()` uses `supabaseAdmin.schema('inform').from('politician_context').upsert()` — a PostgREST write to a non-public schema, which is the forbidden pattern. Although this happened before Phase 35, the migration is a good opportunity to fix it.
**Why it happens:** Legacy code predating the critical production pattern established in MEMORY.md.
**How to avoid:** Replace with `pool.query()` using a parameterized `INSERT ... ON CONFLICT ... DO UPDATE` statement.
**Warning signs:** Silent write failures on `PUT /api/admin/politicians/:id/context`.

---

## Code Examples

Verified patterns from the existing codebase and PLATFORM-CONSOLIDATION.md:

### Bridge Table Populate (4 rows, manual match)

```sql
-- Source: PLATFORM-CONSOLIDATION.md Phase 2.2 pattern
-- Actual UUIDs from inform.politicians must be captured via SELECT before writing migration

INSERT INTO public.politician_id_bridge (essentials_id, inform_id, matched_by)
VALUES
  ('<essentials-uuid-1>', '<inform-uuid-1>', 'name_exact'),
  ('<essentials-uuid-2>', '<inform-uuid-2>', 'name_exact'),
  ('<essentials-uuid-3>', '<inform-uuid-3>', 'name_exact'),
  ('<essentials-uuid-4>', '<inform-uuid-4>', 'name_exact');
```

### FK Reassignment (PLATFORM-CONSOLIDATION.md pattern)

```sql
-- Source: PLATFORM-CONSOLIDATION.md Phase 2.3
UPDATE inform.politician_answers pa
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pa.politician_id = bridge.inform_id;

UPDATE inform.politician_context pc
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pc.politician_id = bridge.inform_id;
```

### confirm_vq_stance Validation Fix

```sql
-- Source: migration 038 (phase28_vq_confirm_stance.sql) — Step 3 update
-- Before drop: FROM inform.politicians p WHERE p.id = p_politician_id
-- After migration: FROM essentials.politicians p WHERE p.id = p_politician_id

SELECT EXISTS (
  SELECT 1
    FROM essentials.politicians p         -- CHANGED: was inform.politicians
   WHERE p.id = p_politician_id
     AND EXISTS (
       SELECT 1
         FROM inform.compass_topics t    -- UNCHANGED: topic still lives in inform
        WHERE t.id = p_topic_id
     )
) INTO v_politician_exists;
```

### supabaseAnon Schema Switch (compassService.ts pattern)

```typescript
// Before (inform schema):
const { data, error } = await supabaseAnon
  .schema('inform')
  .from('politicians')
  .select('id,first_name,last_name,...')
  .eq('is_active', true);

// After (essentials schema):
const { data, error } = await supabaseAnon
  .schema('essentials')
  .from('politicians')
  .select('id,first_name,last_name,...')
  .eq('is_active', true);
```

Note: `essentials.politicians` has `is_active` — confirmed present in the essentials inventory (1,854 rows). The field set must be verified against the essentials column list since `essentials.politicians` may use normalized related tables (offices, chambers, governments) instead of denormalized columns.

### Orphan Check (Pre-Drop Assertion)

```sql
-- Source: established verification pattern from Phase 34-01 and Phase 34-02
-- Run BEFORE DROP TABLE inform.politicians — must return 0 rows

-- Check politician_answers
SELECT COUNT(*) as orphaned_answers
FROM inform.politician_answers pa
LEFT JOIN essentials.politicians ep ON pa.politician_id = ep.id
WHERE ep.id IS NULL;

-- Check politician_context
SELECT COUNT(*) as orphaned_context
FROM inform.politician_context pc
LEFT JOIN essentials.politicians ep ON pc.politician_id = ep.id
WHERE ep.id IS NULL;
```

### adminSetPoliticianContext Fix (pool.query replacement)

```typescript
// Before (PostgREST write to non-public schema — forbidden pattern):
const { data: row, error } = await supabaseAdmin
  .schema('inform')
  .from('politician_context')
  .upsert({ politician_id, topic_id, reasoning, sources })
  .select()
  .single();

// After (pool.query — correct pattern per MEMORY.md):
const { rows } = await pool.query<Record<string, unknown>>(
  `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
   VALUES ($1, $2, $3, $4)
   ON CONFLICT (politician_id, topic_id)
   DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
   RETURNING *`,
  [politicianId, topicId, data.reasoning, data.sources ?? []]
);
return rows[0] ?? {};
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `inform.politicians` as source of truth | `essentials.politicians` as source of truth | Phase 35 | All compass answers, context, and VQ confirmations reference the 1,854-record authoritative table |
| Separate tables for compass vs. essentials politician data | Single `essentials.politicians` table | Phase 35 | No more data divergence; one update path for politician records |
| `inform.politicians` seeded by `scripts/seedPoliticians.ts` | Seed script targets `essentials.politicians` | Phase 35 | Seed script remains functional but targets the right table |

**Deprecated/outdated after Phase 35:**
- `inform.politicians`: dropped
- `admin_list_politicians()`: rebuilt to query `essentials.politicians`
- `admin_update_politician_answers()`: FK constraint change only (function body still writes to `inform.politician_answers`, which is correct)

---

## Open Questions

1. **What are the actual UUIDs in inform.politicians?**
   - What we know: 4 records seeded by `seedPoliticians.ts` (Indiana 9th, Indiana SD-40, Indiana HD-60, LA County); `inform.politicians` uses `gen_random_uuid()` primary key; the actual UUIDs were assigned at seed time and are unknown without querying production
   - What's unclear: The exact UUIDs — needed to populate the bridge table INSERT
   - Recommendation: The first task of the plan should query `SELECT id, first_name, last_name, office_title FROM inform.politicians ORDER BY last_name;` and record the results before writing any migration SQL

2. **Do all 4 inform politicians have matching records in essentials.politicians?**
   - What we know: `essentials.politicians` has 1,854 rows from EV-Backend; the 4 `inform` records are generic/placeholder entries (e.g., "Indiana 9th Congressional District Rep") which may not have exact name matches in essentials
   - What's unclear: Whether essentials contains entries for these exact placeholders, or whether they're more granularly named (e.g., actual legislator names)
   - Recommendation: If no matching essentials row exists for a given `inform` politician, the bridge entry cannot be created — those `politician_answers` rows would have no valid FK target. The plan must handle "unmatched inform politicians" explicitly: either add them to `essentials.politicians` first, or accept that some placeholder compass data is lost (valid given these are seed/placeholder records, not real production data)

3. **Does essentials.politicians have all columns that compassService.ts queries?**
   - What we know: `compassService.ts:getCompassPoliticians()` selects `id, first_name, last_name, preferred_name, full_name, office_title, photo_origin_url, is_active`; `essentialsService.ts` selects a wider set including district columns
   - What's unclear: Whether `essentials.politicians` has `first_name`, `last_name`, `preferred_name` as direct columns, or whether names are denormalized differently in the EV-Backend schema
   - Recommendation: Query `information_schema.columns WHERE table_schema = 'essentials' AND table_name = 'politicians'` to get the exact column list before writing any application code changes

4. **Are there any current rows in inform.politician_answers or inform.politician_context?**
   - What we know: Phase 34-01 inventory did not explicitly count these tables (they were not in the target schemas for that plan)
   - What's unclear: How many rows exist — if zero, the UPDATE ... FROM steps are no-ops (safe either way, but useful to know)
   - Recommendation: Query both tables at plan start: `SELECT COUNT(*) FROM inform.politician_answers; SELECT COUNT(*) FROM inform.politician_context;`

5. **Does vq_confirmation_results.idempotency_key reference politician IDs?**
   - What we know: `confirm_vq_stance` returns `politician_id` in its JSONB result, which is cached in `vq_confirmation_results.result_json`
   - What's unclear: Whether any cached results reference the old `inform` UUIDs — if yes, replayed calls would return old inform UUIDs in the result JSON
   - Recommendation: This is low-risk (cached JSON is for idempotency replay only, not for FK-enforced lookups). Document the known limitation: replayed VQ results will continue returning old inform UUIDs in their cached JSON until the cache expires naturally. No action needed.

---

## Sources

### Primary (HIGH confidence)
- `supabase/migrations/20260226000015_inform_schema.sql` — definitive `inform.politicians`, `inform.politician_answers`, `inform.politician_context` table DDL
- `supabase/migrations/20260313000033_politician_schema.sql` — 9 added columns to `inform.politicians`; `admin_list_politicians()` RPC with full column signature
- `supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql` — `confirm_vq_stance` RPC body with `FROM inform.politicians` validation
- `backend/migrations/025_rpc_pool_migration.sql` — `admin_update_politician_answers` RPC writing to `inform.politician_answers`
- `backend/src/lib/compassService.ts` — `getCompassPoliticians()`, `getPoliticianAnswers()`, `getPoliticianContext()` functions
- `backend/src/lib/essentialsService.ts` — `getPoliticiansGrouped()` function
- `backend/src/lib/adminService.ts` — `adminCreatePolitician()`, `adminUpdatePolitician()`, `adminSetPoliticianContext()`, `adminListPoliticians()`
- `scripts/seedPoliticians.ts` — current seed target and column set
- `.planning/phases/34-database-schema-migration/34-01-SUMMARY.md` — `essentials.politicians` confirmed: 1,854 rows; `inform.politicians` count implicit (4 seed records)
- `PLATFORM-CONSOLIDATION.md` Phase 2 — authoritative bridge table schema and migration SQL pattern

### Secondary (MEDIUM confidence)
- `backend/src/routes/compass.ts` — route handler confirming `GET /api/compass/politicians/:id/answers` path and behavior
- `backend/src/routes/essentialsPoliticians.ts` — `GET /api/essentials/politicians` route
- `.planning/phases/34-database-schema-migration/34-RESEARCH.md` — Phase 34 context: `pool.query()` for all non-public schema writes, `SET search_path = ''` pattern

### Tertiary (LOW confidence)
- Column structure of `essentials.politicians` — inferred from `essentialsService.ts` select list; not directly verified against production `information_schema.columns`. Must be verified before writing migration.

---

## Metadata

**Confidence breakdown:**
- Migration sequence (bridge table → FK update → RPC rebuild → DROP TABLE): HIGH — directly follows PLATFORM-CONSOLIDATION.md Phase 2 and matches the established migration pattern from Phase 34
- Application code change scope: HIGH — all 5 affected files identified by code search
- Bridge table population (actual UUID values): LOW — requires production query before migration can be written; placeholder rows cannot be determined from source alone
- essentials.politicians column compatibility: MEDIUM — `essentialsService.ts` select list implies columns exist; not directly verified against `information_schema.columns`
- inform.politician_answers/context row counts: LOW — not enumerated in Phase 34 inventory; require a pre-migration query

**Research date:** 2026-03-19
**Valid until:** 2026-04-19 (schema migration domain is stable; essentials table structure won't change during this window)
