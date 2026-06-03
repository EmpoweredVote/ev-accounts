# Phase 88: Stance Corrections + Party Normalization — Pattern Map

**Mapped:** 2026-06-02
**Files analyzed:** 3 file types (correction migrations, context-update migrations, party normalization migration)
**Analogs found:** 3 / 3

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `supabase/migrations/2026XXXX_116_<politician>_correction.sql` (×8, Wave 1) | migration | CRUD | `supabase/migrations/20260516000011_108_yaroslavsky_full_coverage_sprint.sql` | exact |
| `supabase/migrations/2026XXXX_12X_<politician>_correction.sql` (×21, Wave 2) | migration | CRUD | `supabase/migrations/20260516000018_115_estuardo_mazariegos_full_coverage_sprint.sql` | exact |
| `supabase/migrations/2026XXXX_126_party_normalization.sql` (Wave 5) | migration | batch-transform | `supabase/migrations/20260516000011_108_yaroslavsky_full_coverage_sprint.sql` (UPDATE pattern) | role-match |

---

## Pattern Assignments

### Correction migrations — Wave 1 (confirmed inversions, value change required)

**Analog:** `supabase/migrations/20260516000011_108_yaroslavsky_full_coverage_sprint.sql`

This migration contains the canonical pattern for correcting an existing `politician_answers` value AND updating the corresponding `politician_context` row — exactly what Wave 1 requires.

**Header comment block** (lines 1–10):
```sql
-- Full coverage sprint for [POLITICIAN NAME] (politician_id: [UUID])
-- [Office / role]
-- Group A: update [N] existing rows + fix values on [topic] ([old]→[new])
-- Group B: insert [N] new answer+context rows
-- Skipped: [topics] — [reason]
```

**Core pattern — UPDATE existing value then UPDATE context** (lines 14–20):
```sql
-- [topic]: value [OLD]→[NEW] ([one-line rationale])
UPDATE inform.politician_answers SET value = [NEW_VALUE]
WHERE politician_id = '[UUID]' AND topic_id = '[TOPIC_UUID]';

UPDATE inform.politician_context SET
  reasoning = '[REASONING citing fetched URL]',
  sources = ARRAY['[URL_1]', '[URL_2]']
WHERE politician_id = '[UUID]' AND topic_id = '[TOPIC_UUID]';
```

**Critical:** No `BEGIN`/`COMMIT` wrapping in the analog files — corrections are applied as individual statements. If the planner wants atomic rollback, wrap with `BEGIN;` / `COMMIT;` as shown in RESEARCH.md Pattern 1. Either form is valid; the codebase uses both.

**Important:** `topic_id` values are UUIDs looked up at research time. The RESEARCH.md pattern shows a subquery form:
```sql
AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = '[KEY]')
```
Both forms work. The subquery form is safer if topic UUIDs are not pre-verified.

---

### Correction migrations — Wave 2 (borderline cases, net-new answers + context)

**Analog:** `supabase/migrations/20260516000018_115_estuardo_mazariegos_full_coverage_sprint.sql`

This migration shows the INSERT + ON CONFLICT upsert pattern for adding net-new answer and context rows together — the dominant pattern for Wave 2 politicians who may be missing rows entirely.

**Core pattern — INSERT answer + INSERT context as a pair** (lines 15–22):
```sql
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('[UUID]', '[TOPIC_UUID]', [VALUE])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '[UUID]',
  '[TOPIC_UUID]',
  '[REASONING TEXT citing fetched URL]',
  ARRAY['[URL_1]', '[URL_2]']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;
```

**Note:** Each answer row is immediately followed by its paired context row. Do not batch all answers then all contexts — keep the pairs together so the migration is readable and partially replayable.

---

### Context-only update migrations (when value is correct but reasoning/sources are stale)

**Analog:** `supabase/migrations/20260515000001_096_schiff_context_source_sprint.sql`

Use this pattern when the stance `value` in `politician_answers` is already correct but `politician_context` has no sources or stale reasoning (common for Wave 2 audit cases where the SQL flag turns out to be a sourcing gap, not a value error).

**Core pattern — UPDATE context only** (lines 5–14):
```sql
UPDATE inform.politician_context
SET
  reasoning = '[DETAILED REASONING with specific bill/vote citations]',
  sources = ARRAY[
    '[URL_1]',
    '[URL_2]',
    '[URL_3]'
  ]
WHERE politician_id = '[UUID]'
  AND topic_id = '[TOPIC_UUID]';
```

**Note:** This migration uses `UPDATE` (not upsert). If the context row might not exist yet, use the INSERT … ON CONFLICT pattern from the Wave 2 analog instead.

---

### Party normalization migration (Wave 4)

**Analog:** No existing party normalization migration in the codebase — this is a first. Use the UPDATE pattern from `yaroslavsky` for structure reference; the SQL itself comes from RESEARCH.md Pattern 4.

**Full migration content:**
```sql
-- Normalize party strings: 496 "Democrat" rows → "Democratic"
-- "Democratic" is the canonical form (official party name: Democratic Party)
-- Affected: essentials.politicians — no FK dependencies, no PostgREST impact
-- Verified: no hardcoded 'Democrat' string comparisons in backend/src TS files

BEGIN;

UPDATE essentials.politicians
SET party = 'Democratic'
WHERE party = 'Democrat';

-- Verify: should return 0 rows after normalization
-- SELECT COUNT(*) FROM essentials.politicians WHERE party = 'Democrat';

COMMIT;
```

**Note on schema access:** `essentials.politicians` is NOT in PostgREST's exposed schema list. This migration runs via `psql` / `DATABASE_URL` (direct Postgres), same as all other migration files. Do NOT attempt via `supabaseAdmin.schema('essentials')`.

**No hardcoded party strings in backend:** Grep confirmed zero occurrences of `'Democrat'` or `"Democrat"` as exact string literals in `backend/src/**/*.ts`. Party normalization has no downstream code impact.

---

## Shared Patterns

### inform.* Write Constraint
**Source:** MEMORY.md + RESEARCH.md Anti-Patterns section
**Apply to:** All Wave 1, 2, 3 correction migrations

All writes to `inform.politician_answers` and `inform.politician_context` must use direct SQL via `psql` / `DATABASE_URL`. Never `supabaseAdmin.schema('inform').from(...)` — the `inform` schema is not in PostgREST's exposed schema list and writes will fail silently or throw.

### Source URL Requirement
**Source:** RESEARCH.md SACC-02 requirement + Pitfall 1
**Apply to:** Every correction migration

Every corrected stance must have at least one real fetched URL in `sources`. Reject any researcher output where reasoning contains "likely", "as a [party] politician", or "generally speaking" — these indicate party inference, not sourced research.

### Migration Numbering
**Source:** RESEARCH.md Environment Availability section
**Apply to:** First migration file written

Next sequential migration number is **116**. Verify before writing:
```bash
ls C:/EV-Accounts/supabase/migrations/ | sort | tail -1
```
Last confirmed: `20260516000018_115_estuardo_mazariegos_full_coverage_sprint.sql`

Timestamp prefix convention: `20260602000000_116_[politician_slug]_correction.sql`, incrementing the `000000` suffix for same-day migrations.

### topic_id Lookup
**Source:** All analog migrations
**Apply to:** All correction migrations

Topic UUIDs used in analogs come from the live DB. The subquery form is safest when writing corrections without pre-verified UUIDs:
```sql
AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion')
```

Alternatively, look up all topic UUIDs once before writing Wave 1 migrations:
```sql
SELECT id, topic_key FROM inform.compass_topics ORDER BY topic_key;
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `data/stance-research/*.csv` | data artifact | — | CSV output from research-stances skill invocations; no existing correction-mode CSV in `data/stance-research/` to copy from. Use the skill's standard output format — column headers match what the skill produces |
| Party normalization migration | migration | batch-transform | No prior party-field UPDATE migration exists. Full SQL provided above; no analog needed |

---

## Metadata

**Analog search scope:** `supabase/migrations/` (88 files), `backend/src/` (party string grep)
**Files scanned:** 6 migration files read in full; 4 grepped
**Pattern extraction date:** 2026-06-02
