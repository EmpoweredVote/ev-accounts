# Phase 21: empowered_profiles Politician Schema - Research

**Researched:** 2026-03-13
**Domain:** PostgreSQL schema migration, Supabase TypeScript types, Express service layer
**Confidence:** HIGH

## Summary

Phase 21 adds 9 new columns to `inform.politicians` and updates the `GET /api/essentials/politicians` endpoint to return them. The work also includes a seed script for Bloomington (IN) and Los Angeles (CA) politicians, and a manual update to `database.types.ts`.

The target table is `inform.politicians`, NOT `empower.empowered_profiles`. The CONTEXT.md clarifies that the roadmap description was wrong: politicians are data records without auth accounts, so they live in `inform.politicians`. `empower.empowered_profiles` already has most of these columns from Phase 8 (migration 025).

The current live schema has `inform.politicians` with: `id`, `first_name`, `last_name`, `preferred_name`, `full_name`, `office_title`, `photo_origin_url`, `is_active`, `is_candidate`, `created_at`. All 9 new columns must be added via a new migration (033). No RLS changes are needed — `inform.politicians` already has a `"politicians: public read"` policy (anon + authenticated, USING true) from migration 016.

**Primary recommendation:** Write migration 033 as a single `ALTER TABLE inform.politicians ADD COLUMN IF NOT EXISTS ...` block for all 9 columns. Update `essentialsService.ts` to select and return the new fields. Update `database.types.ts` manually. Write a TypeScript seed script.

## Standard Stack

Phase 21 uses only existing project dependencies. No new packages required.

### Core (all already installed)
| Tool | Version | Purpose |
|------|---------|---------|
| `pg` | installed | Direct DB connection for migration application |
| `@supabase/supabase-js` | installed | Supabase client for service layer queries |
| TypeScript strict | installed | Type safety across backend + admin |

### Supporting (existing patterns)
| Pattern | File | Purpose |
|---------|------|---------|
| `supabaseAnon` client | `essentialsService.ts` | Read-only public data queries |
| `supabaseAdmin` client | `candidateService.ts` | Service-role queries for `empower.empowered_profiles` |
| `database.types.ts` manual update | `backend/src/types/` | Type sync after schema changes |

No new npm packages required.

## Architecture Patterns

### Migration file location

The project has two migration directories:

1. **`backend/migrations/`** — Numbered plain SQL files (025–032). These are the files that `applyMigrations.ts` actually runs. Migration 033 goes here.
2. **`supabase/migrations/`** — Timestamped Supabase CLI format. Migrations 031 and 032 appear in both directories (same SQL, different filenames). The planner should pick one canonical home; the existing pattern for Phases 19+ uses `supabase/migrations/` as the primary with matching copies in `backend/migrations/`.

**Decision for 033:** Follow Phase 19/20 pattern — create both:
- `backend/migrations/033_politician_schema.sql`
- `supabase/migrations/20260313000033_politician_schema.sql`

(same SQL content in both files)

### Recommended Structure

```
backend/migrations/
└── 033_politician_schema.sql       ← new migration

supabase/migrations/
└── 20260313000033_politician_schema.sql   ← same SQL, timestamped

backend/src/lib/
└── essentialsService.ts            ← update: add new fields to select + PoliticianRecord type

backend/src/types/
└── database.types.ts               ← manual update: inform.politicians Row/Insert/Update

scripts/
└── seedPoliticians.ts              ← new: TypeScript seed script (idempotent)
```

### Pattern 1: ALTER TABLE with ADD COLUMN IF NOT EXISTS

```sql
-- Source: backend/migrations/026_inform_schema_repair_and_candidates.sql (established pattern)
BEGIN;

ALTER TABLE inform.politicians
  ADD COLUMN IF NOT EXISTS representing_city    TEXT,
  ADD COLUMN IF NOT EXISTS representing_state   TEXT,
  ADD COLUMN IF NOT EXISTS district_type        TEXT,
  ADD COLUMN IF NOT EXISTS district_label       TEXT,
  ADD COLUMN IF NOT EXISTS district_id          TEXT,
  ADD COLUMN IF NOT EXISTS chamber_name         TEXT,
  ADD COLUMN IF NOT EXISTS chamber_name_formal  TEXT,
  ADD COLUMN IF NOT EXISTS government_name      TEXT,
  ADD COLUMN IF NOT EXISTS is_vacant            BOOLEAN NOT NULL DEFAULT false;

COMMIT;
```

**Key notes:**
- `IF NOT EXISTS` on each `ADD COLUMN` makes the migration idempotent (established pattern from 026)
- All string columns: nullable TEXT (no DEFAULT needed — NULL = not yet populated)
- `is_vacant`: NOT NULL DEFAULT false (existing rows are active filled seats per decision)
- No RLS changes needed — existing `"politicians: public read"` policy covers all columns
- No GRANT changes needed — `GRANT SELECT ON ALL TABLES IN SCHEMA inform TO anon, authenticated` (migration 016) covers new columns automatically

### Pattern 2: Explicit column whitelist in service layer

The `essentialsService.ts` must update its Supabase query to include the new fields and its TypeScript types to match.

```typescript
// Source: backend/src/lib/essentialsService.ts (current pattern)
// Current select:
.select('id, full_name, office_title, photo_origin_url, is_candidate')

// Updated select (add all 9 new columns):
.select(`
  id, full_name, office_title, photo_origin_url, is_candidate,
  representing_city, representing_state,
  district_type, district_label, district_id,
  chamber_name, chamber_name_formal, government_name,
  is_vacant
`)
```

DB rows are NEVER spread into responses — explicit whitelist rule applies. Every new field must appear in both the `.select()` call AND the explicit record construction object.

### Pattern 3: manual database.types.ts update

Supabase types are not auto-generated in this project. Manual update is required after every schema migration.

```typescript
// Current inform.politicians Row (database.types.ts line 951):
// Add all 9 new fields to Row, Insert, and Update shapes:

Row: {
  // ... existing fields ...
  chamber_name: string | null
  chamber_name_formal: string | null
  district_id: string | null
  district_label: string | null
  district_type: string | null
  government_name: string | null
  is_vacant: boolean
  representing_city: string | null
  representing_state: string | null
}
Insert: {
  // ... existing fields ...
  chamber_name?: string | null
  chamber_name_formal?: string | null
  district_id?: string | null
  district_label?: string | null
  district_type?: string | null
  government_name?: string | null
  is_vacant?: boolean          // NOT NULL DEFAULT false → optional in Insert
  representing_city?: string | null
  representing_state?: string | null
}
Update: {
  // ... same as Insert ...
}
```

### Pattern 4: TypeScript seed script (idempotent ON CONFLICT)

The seed script should use `supabaseAdmin` and upsert on `id` (or a stable natural key) with `ON CONFLICT DO NOTHING` or `ON CONFLICT DO UPDATE`. TypeScript preferred over raw SQL so it can use shared env loading and Supabase client.

```typescript
// Pattern: use supabaseAdmin.schema('inform').from('politicians').upsert(rows, { onConflict: 'id' })
// or insert with .select() and handle conflict
```

### Anti-Patterns to Avoid

- **Spreading DB rows into API responses:** `essentialsService.ts` must explicitly list each field in the response object, never `{ ...row }`.
- **Using `supabaseAdmin` for essentials reads:** `inform.politicians` has a public-read RLS policy. `supabaseAnon` is the correct client (already established in `essentialsService.ts`).
- **Omitting fields from response when null:** All new fields must always appear in the response, even as `null`. Callers should never need to check for key presence.
- **Running migration via pooler:** `DATABASE_URL` must use `db.<ref>.supabase.co:5432` (direct), not `pooler.supabase.com:6543`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Idempotent column addition | Custom check-and-add logic | `ADD COLUMN IF NOT EXISTS` | PostgreSQL native; established project pattern (migration 026) |
| Null-safe field inclusion | Conditional response building | Always include field, value is `null` | Decided in CONTEXT.md; consistent shape from day one |
| Supabase type updates | Script to regenerate types | Manual update of `database.types.ts` | Established pattern; `supabase gen types` not wired in this project |

## Common Pitfalls

### Pitfall 1: `is_candidate` column gap in migration files

**What goes wrong:** `is_candidate` is NOT in `supabase/migrations/20260226000015_inform_schema.sql`. It was added in `backend/migrations/026_inform_schema_repair_and_candidates.sql` which targets the production DB. The `supabase/migrations/` and `backend/migrations/` directories diverged at migration 025.

**Why it happens:** The project uses two migration systems. `supabase/migrations/` tracks Phases 1–16 schema definitions. `backend/migrations/` contains the production-applied repair migrations (025–032). New migration 033 should appear in BOTH directories.

**How to avoid:** Write 033 SQL once, copy to both directories. The `applyMigrations.ts` script reads from `backend/migrations/`.

**Warning signs:** If you only create a file in `supabase/migrations/`, `applyMigrations.ts` will not find it.

### Pitfall 2: `CREATE POLICY IF NOT EXISTS` not supported

**What goes wrong:** Using `CREATE POLICY IF NOT EXISTS` in migration SQL causes a PostgreSQL error on Supabase Postgres 17.4.

**Why it happens:** Postgres 17.4 does not support the IF NOT EXISTS variant of CREATE POLICY.

**How to avoid:** Migration 033 does NOT need any new RLS policies (the existing `"politicians: public read"` covers all new columns). If any new policy is accidentally added, use the DO block pattern from migrations 031/032:
```sql
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'inform' AND tablename = 'politicians' AND policyname = '...') THEN
    CREATE POLICY "..." ON inform.politicians ...;
  END IF;
END; $$;
```

### Pitfall 3: `is_active` vs `is_vacant` query filter

**What goes wrong:** Confusing the existing `is_active` filter with the new `is_vacant` filter.

**Why it happens:** `is_active = false` means the politician record was soft-deleted or hidden. `is_vacant = false` means the seat is filled (an active office-holder). These are orthogonal.

**How to avoid:** `GET /api/essentials/politicians` must filter `is_active = true AND is_vacant = false`. The current code filters only `is_active = true` — add the `is_vacant = false` filter per the CONTEXT.md decision.

### Pitfall 4: admin_list_politicians RPC must be updated

**What goes wrong:** The `public.admin_list_politicians()` RPC (defined in `backend/migrations/029_compass_admin_rpcs.sql`) has an explicit RETURNS TABLE with a fixed column list. Adding columns to `inform.politicians` does NOT automatically update the RPC return shape.

**Why it happens:** The RPC is a SQL function with a typed return signature. Phase 17 deployment even required dropping and recreating this function when `is_candidate` was added.

**How to avoid:** Migration 033 must include a `CREATE OR REPLACE FUNCTION public.admin_list_politicians()` that updates the RETURNS TABLE signature to include all 9 new columns. The `SET search_path = ''` and `SECURITY DEFINER` constraints must be preserved.

### Pitfall 5: database.types.ts `Row` vs `Insert` nullability

**What goes wrong:** Marking `is_vacant` as `boolean | null` in the Row shape when it is actually `NOT NULL DEFAULT false` in the schema.

**Why it happens:** Pattern confusion with nullable TEXT columns.

**How to avoid:** `is_vacant` Row type is `boolean` (not `boolean | null`). Insert type is `boolean?` (optional, has DEFAULT). All other new columns are `string | null` in Row and `string | null | undefined` (i.e., `string?: string | null`) in Insert/Update.

### Pitfall 6: Seed script LA County coverage gap

**What goes wrong:** Attempting to use `resolve_user_jurisdiction` to derive congressional/state_senate/state_house/school_district GEOIDs for LA-area politicians, and getting null for all of them.

**Why it happens:** Phase 20 confirmed: LA County Alpha coverage is county boundary only. The `inform.district_boundaries` table only contains Indiana TIGER/Line data for those district types. For CA addresses, only `county` returns a non-null GEOID.

**How to avoid:** For LA politicians:
- `district_type` can only be `'county'` (or hard-coded to a known value like `'city_council'` if set manually)
- `district_id` for county may work (LA County GEOID from the county boundary data)
- congressional/state_senate/state_house fields should be left NULL for Alpha
- Document this limitation in the seed script comments

## Code Examples

### Complete migration 033 (SQL)

```sql
-- Source: established pattern from backend/migrations/026 and 031
BEGIN;

-- =============================================================================
-- Migration 033: Politician schema expansion
-- Adds jurisdiction and district fields to inform.politicians so that
-- GET /api/essentials/politicians can return full representative context.
-- =============================================================================

ALTER TABLE inform.politicians
  ADD COLUMN IF NOT EXISTS representing_city    TEXT,
  ADD COLUMN IF NOT EXISTS representing_state   TEXT,
  ADD COLUMN IF NOT EXISTS district_type        TEXT,
  ADD COLUMN IF NOT EXISTS district_label       TEXT,
  ADD COLUMN IF NOT EXISTS district_id          TEXT,
  ADD COLUMN IF NOT EXISTS chamber_name         TEXT,
  ADD COLUMN IF NOT EXISTS chamber_name_formal  TEXT,
  ADD COLUMN IF NOT EXISTS government_name      TEXT,
  ADD COLUMN IF NOT EXISTS is_vacant            BOOLEAN NOT NULL DEFAULT false;

-- =============================================================================
-- Update admin_list_politicians RPC to include new columns
-- DROP + CREATE OR REPLACE is required when the RETURNS TABLE changes.
-- (CREATE OR REPLACE alone fails if the return type changes.)
-- =============================================================================

DROP FUNCTION IF EXISTS public.admin_list_politicians();

CREATE OR REPLACE FUNCTION public.admin_list_politicians()
RETURNS TABLE(
  id                   uuid,
  first_name           text,
  last_name            text,
  preferred_name       text,
  full_name            text,
  office_title         text,
  photo_origin_url     text,
  is_active            boolean,
  is_candidate         boolean,
  is_vacant            boolean,
  representing_city    text,
  representing_state   text,
  district_type        text,
  district_label       text,
  district_id          text,
  chamber_name         text,
  chamber_name_formal  text,
  government_name      text,
  created_at           timestamptz,
  answer_count         bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    p.id, p.first_name, p.last_name, p.preferred_name, p.full_name,
    p.office_title, p.photo_origin_url, p.is_active, p.is_candidate,
    p.is_vacant, p.representing_city, p.representing_state,
    p.district_type, p.district_label, p.district_id,
    p.chamber_name, p.chamber_name_formal, p.government_name,
    p.created_at,
    (SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id) AS answer_count
  FROM inform.politicians p
  ORDER BY p.last_name, p.first_name;
$$;

GRANT EXECUTE ON FUNCTION public.admin_list_politicians() TO service_role, authenticated;

COMMIT;
```

**Critical note on DROP + CREATE OR REPLACE:** PostgreSQL requires DROP when a function's RETURNS TABLE signature changes. `CREATE OR REPLACE` alone fails with "cannot change return type of existing function" when the column list differs. Phase 17 deployment already hit this exact issue with the `is_candidate` column addition.

### Updated PoliticianRecord type (essentialsService.ts)

```typescript
// Source: established pattern — explicit type, all fields listed
export interface PoliticianRecord {
  id: string;
  full_name: string | null;
  office_title: string | null;
  photo_origin_url: string | null;
  is_candidate: boolean;
  is_vacant: boolean;
  representing_city: string | null;
  representing_state: string | null;
  district_type: string | null;
  district_label: string | null;
  district_id: string | null;
  chamber_name: string | null;
  chamber_name_formal: string | null;
  government_name: string | null;
}
```

### Seed script pattern (TypeScript)

```typescript
// Pattern: supabaseAdmin upsert with onConflict: 'id'
// Idempotent — safe to re-run as data grows
const bloomingtonPoliticians = [
  {
    id: '<stable-uuid>',  // stable UUID so re-runs are idempotent
    first_name: 'John',
    last_name: 'Smith',
    full_name: 'John Smith',
    office_title: 'Indiana 9th Congressional District Representative',
    representing_city: 'Bloomington',
    representing_state: 'Indiana',
    district_type: 'congressional',
    district_label: 'Indiana 9th Congressional District',
    district_id: '1809',  // GEOID from TIGER/Line data
    chamber_name: 'House of Representatives',
    chamber_name_formal: 'United States House of Representatives',
    government_name: 'U.S. Federal Government',
    is_candidate: false,
    is_vacant: false,
  },
  // ...
];

await supabaseAdmin
  .schema('inform')
  .from('politicians')
  .upsert(rows, { onConflict: 'id' });
```

### district_label format recommendation

Based on the CONTEXT.md guidance that `district_label` should be human-readable for display:

| district_type | district_label format | Example |
|--------------|----------------------|---------|
| `congressional` | `[State] [N]th Congressional District` | `Indiana 9th Congressional District` |
| `state_senate` | `[State] Senate District [N]` | `Indiana Senate District 40` |
| `state_house` | `[State] House District [N]` | `Indiana House District 60` |
| `county` | `[Name] County` | `Monroe County` |
| `school_district` | `[Name] School District` | `Monroe County Community School District` |
| `city_council` | `[City] City Council, District [N]` | `Los Angeles City Council, District 4` |

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `inform.politicians` had 9 columns (id, names, office_title, photo_origin_url, is_active, is_candidate, created_at) | After migration 033: 18 columns (adds 9 jurisdiction fields) | Essentials/VQ can display full representative context without additional lookups |
| `admin_list_politicians()` RETURNS TABLE with 11 columns | After migration 033: 20 columns | Admin can see district context inline |
| `PoliticianRecord` type: 5 fields | After migration 033: 14 fields | TypeScript strict compilation tracks the full shape |

## Open Questions

1. **Seed script politician data**
   - What we know: Bloomington, IN district GEOIDs from TIGER/Line — congressional `1809` (Indiana 9th), county is Monroe County
   - What's unclear: exact real politician names, terms, and office titles to seed; whether real names are desired vs. placeholder records
   - Recommendation: Seed with real incumbent names (a quick research pass at plan time) — this is for Alpha usage, not test data. If planner doesn't have real names, use clearly-labeled placeholder records.

2. **LA politician district coverage**
   - What we know: `resolve_user_jurisdiction` returns null for congressional/state/house/school_district for CA addresses; only `county` returns a value (LA County GEOID)
   - What's unclear: Whether LA city council-level data is useful to seed given no city boundary data is loaded
   - Recommendation: LA seed records set `district_type = 'county'`, `district_label = 'Los Angeles County'`, `district_id = <LA County GEOID>`, and leave congressional/state fields null. Document this limitation in seed script comments.

3. **LA County GEOID from TIGER/Line**
   - What we know: LA County FIPS code is `06037`; the national county TIGER/Line file was NOT loaded for CA (only Indiana FIPS 18 was filtered)
   - What's unclear: whether LA County boundary data is actually present in `inform.district_boundaries`
   - Recommendation: Check `SELECT geoid FROM inform.district_boundaries WHERE name ILIKE '%Los Angeles%'` before assuming GEOID. If not present, `district_id` for LA politicians will need to be hard-coded as the FIPS string `'06037'` without PostGIS validation.

4. **`admin_list_politicians` return type change requires DROP**
   - What we know: Phase 17 hit this exact issue; `DROP FUNCTION IF EXISTS` then `CREATE OR REPLACE` is required when RETURNS TABLE changes
   - What's unclear: nothing — the approach is confirmed by prior incident
   - Recommendation: Migration 033 must include the DROP explicitly before CREATE OR REPLACE.

## Sources

### Primary (HIGH confidence)

- **Codebase inspection** — `backend/migrations/026_inform_schema_repair_and_candidates.sql`: confirms `is_candidate` addition pattern and `ALTER TABLE inform.politicians ADD COLUMN IF NOT EXISTS` idiom
- **Codebase inspection** — `backend/migrations/029_compass_admin_rpcs.sql`: confirms `admin_list_politicians()` RETURNS TABLE shape and GRANT pattern
- **Codebase inspection** — `backend/src/lib/essentialsService.ts`: confirms current `PoliticianRecord` shape, `supabaseAnon` client usage, explicit whitelist pattern
- **Codebase inspection** — `backend/src/types/database.types.ts` (lines 951–989): confirms current `inform.politicians` Row/Insert/Update shapes — missing all 9 new columns
- **Codebase inspection** — `.planning/phases/17-live-alpha-deployment/17-03-SUMMARY.md`: confirms DROP + recreate is required when RPC return type changes (Phase 17 Issue 4)
- **Codebase inspection** — `.planning/STATE.md`: confirms `CREATE POLICY IF NOT EXISTS` not supported in Supabase Postgres 17.4; use DO block checking pg_policies
- **Codebase inspection** — `supabase/migrations/20260310000031_location_schema.sql`: confirms DO block pattern for idempotent RLS policy creation

### Secondary (MEDIUM confidence)

- **Phase 20 STATE.md note** (project documentation): LA County Alpha coverage is county boundary only — congressional/state_senate/state_house/school_district return null for CA addresses

## Metadata

**Confidence breakdown:**
- Migration SQL pattern: HIGH — established in migrations 026, 031, 032; copy pattern directly
- admin_list_politicians DROP + recreate: HIGH — Phase 17 encountered this exact scenario (Issue 4 in 17-03-SUMMARY.md)
- essentialsService.ts update pattern: HIGH — current file is the direct template to extend
- database.types.ts manual update: HIGH — established project pattern, multiple prior examples
- Seed script: MEDIUM — TypeScript upsert pattern is clear; specific politician data TBD
- LA County district_id: LOW — GEOID availability in live DB unconfirmed; operator should verify

**Research date:** 2026-03-13
**Valid until:** 2026-04-13 (stable domain — schema migration and service layer patterns don't shift)
