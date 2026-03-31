---
phase: quick-010
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: []
autonomous: true

must_haves:
  truths:
    - "76,332 CAL Access committee records are deactivated (is_active = false)"
    - "All 54 CA Cicero politicians with orphaned district_id FKs have their district rows restored"
    - "Geofence queries return these 54 politicians again"
  artifacts: []
  key_links:
    - from: "essentials.offices.district_id"
      to: "essentials.districts.id"
      via: "FK restored by re-inserting district rows"
      pattern: "JOIN essentials.districts d ON d.id = o.district_id"
---

<objective>
Fix BUG-01: Quarantine 76k+ CAL Access committee records polluting essentials.politicians, and restore deleted essentials.districts rows that 54 active CA Cicero politicians reference via their offices.district_id FK.

Purpose: CAL Access discovery import corrupted the essentials schema in two ways — injected PAC/committee records as politicians, and deleted district rows that active politicians depend on. These politicians are invisible to all geofence-based queries (representatives/me, candidates/search).

Output: Production database corrected via Supabase MCP execute_sql. No code changes — data fix only.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@backend/migrations/045_fix_resolve_user_jurisdiction.sql (shows districts table columns: id, geo_id, district_type, label, state, retention — joined via geo_id)
@backend/src/lib/essentialsService.ts (shows how districts are queried — geo_id + district_type)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Quarantine CAL Access committee records</name>
  <files>None — production SQL only via Supabase MCP execute_sql</files>
  <action>
Step 1: Count CAL Access records before quarantine:
```sql
SELECT COUNT(*) AS total,
       COUNT(*) FILTER (WHERE is_active = true) AS active,
       COUNT(*) FILTER (WHERE is_active = false) AS inactive
FROM essentials.politicians
WHERE source = 'cal_access_discovery';
```

Step 2: Quarantine by setting is_active = false:
```sql
UPDATE essentials.politicians
SET is_active = false
WHERE source = 'cal_access_discovery'
  AND is_active = true;
```
Log the rows affected.

Step 3: Verify count after:
```sql
SELECT COUNT(*) FILTER (WHERE is_active = true) AS still_active
FROM essentials.politicians
WHERE source = 'cal_access_discovery';
```
Must be 0.

CRITICAL constraints:
- Filter ONLY on `source = 'cal_access_discovery'` — do NOT use `data_source IS NULL` (1,302 legitimate politicians also have null data_source)
- Use Supabase MCP execute_sql for all queries (essentials schema not in PostgREST exposed list)
  </action>
  <verify>Post-quarantine count query returns 0 active CAL Access records. Total count unchanged (rows still exist, just inactive).</verify>
  <done>All CAL Access committee records have is_active = false. Zero active records with source = 'cal_access_discovery'.</done>
</task>

<task type="auto">
  <name>Task 2: Restore deleted district rows for orphaned CA Cicero politicians</name>
  <files>None — production SQL only via Supabase MCP execute_sql</files>
  <action>
This task is investigative — the executor must run queries and reason about results before writing any data.

Step 1: Inspect districts table schema (need full column list to construct INSERT):
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'essentials' AND table_name = 'districts'
ORDER BY ordinal_position;
```

Step 2: Run the audit query to identify all affected politicians and their orphaned district_id values:
```sql
SELECT p.id, p.full_name, p.source,
       o.id AS office_id, o.title, o.district_id, o.representing_state
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE p.source = 'cicero'
  AND p.is_active = true
  AND o.district_id IS NOT NULL
  AND d.id IS NULL
ORDER BY o.representing_state, p.full_name;
```
Record all unique `district_id` UUIDs — these are the rows that need restoring.

Step 3: Get the distinct set of orphaned district_id values:
```sql
SELECT DISTINCT o.district_id
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE p.source = 'cicero'
  AND p.is_active = true
  AND o.district_id IS NOT NULL
  AND d.id IS NULL;
```

Step 4: For each orphaned district_id, infer district_type and geo_id:

a) **Infer district_type** from the office title. The mapping is:
   - "U.S. Senator" / "Senator" (federal) → NATIONAL_UPPER
   - "U.S. Representative" / "Representative" (federal) / "Congressmember" → NATIONAL_LOWER
   - "State Senator" → STATE_UPPER
   - "State Representative" / "Assembly Member" / "Assemblymember" → STATE_LOWER
   - County-level offices → COUNTY
   - School board → SCHOOL

b) **Infer geo_id** by cross-referencing existing districts for the same state + district_type:
   - For NATIONAL_UPPER (e.g., Alex Padilla, CA): look up Adam Schiff's or any other CA senator's district — there is only one NATIONAL_UPPER district per state
   ```sql
   SELECT id, geo_id, label, state, district_type
   FROM essentials.districts
   WHERE state = 'CA' AND district_type = 'NATIONAL_UPPER'
   LIMIT 5;
   ```
   - For NATIONAL_LOWER: extract district number from office title, find matching geo_id
   - For STATE_UPPER/STATE_LOWER: extract district number, find matching geo_id

c) **For each distinct district_type + state combination**, query existing districts to find the geo_id pattern:
   ```sql
   SELECT geo_id, label, district_type
   FROM essentials.districts
   WHERE state = '{STATE}' AND district_type = '{TYPE}'
   ORDER BY geo_id
   LIMIT 10;
   ```

Step 5: Construct and execute INSERT statements for each missing district row. Use the id values from the orphaned district_id set (these are the UUIDs the offices already reference). Fill columns from the reference districts:
```sql
INSERT INTO essentials.districts (id, geo_id, district_type, label, state, ...)
VALUES
  ('{orphaned_uuid}', '{inferred_geo_id}', '{inferred_type}', '{inferred_label}', '{state}', ...)
ON CONFLICT (id) DO NOTHING;
```

Step 6: If any district's geo_id CANNOT be reliably inferred (ambiguous office title, no reference district for that state+type), do NOT guess. Log those politicians and their office details for manual resolution. Report them clearly in the summary.

Step 7: Verify the fix — rerun the audit query from Step 2. It should return 0 rows:
```sql
SELECT COUNT(*) AS still_orphaned
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE p.source = 'cicero'
  AND p.is_active = true
  AND o.district_id IS NOT NULL
  AND d.id IS NULL;
```

Step 8: Spot-check a few restored politicians appear in geofence queries:
```sql
SELECT p.full_name, d.geo_id, d.district_type, d.label
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
WHERE p.source = 'cicero' AND p.is_active = true
  AND o.representing_state = 'CA'
ORDER BY p.full_name
LIMIT 10;
```

CRITICAL constraints:
- Use Supabase MCP execute_sql for ALL queries
- The orphaned district_id UUIDs ARE the primary keys to insert — offices already reference them
- Do not modify offices table — only restore districts rows
- Flag (don't guess) any unresolvable geo_ids
  </action>
  <verify>Audit query returns 0 orphaned rows. Spot-check shows restored districts joined correctly to offices.</verify>
  <done>All 54 CA Cicero politicians have their district rows restored. Orphaned district_id count = 0. Any unresolvable cases documented.</done>
</task>

</tasks>

<verification>
1. `SELECT COUNT(*) FROM essentials.politicians WHERE source = 'cal_access_discovery' AND is_active = true` returns 0
2. Audit query (orphaned district_id) returns 0 rows
3. CA Cicero politicians appear in district JOINs again
</verification>

<success_criteria>
- Zero active CAL Access committee records in essentials.politicians
- Zero orphaned district_id references from active Cicero politicians
- Any unresolvable districts explicitly documented (not silently skipped)
</success_criteria>

<output>
After completion, create `.planning/quick/010-fix-bug-01-restore-cicero-districts-quarant/010-SUMMARY.md`
</output>
