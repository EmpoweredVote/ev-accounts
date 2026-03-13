---
phase: 11-fix-monroe-county-council-data-liz-feitl
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-Backend/internal/essentials/geofence_lookup.go
autonomous: true
requirements: [DATA-01, DATA-02, DATA-03]

must_haves:
  truths:
    - "Monroe County Council members with COUNTY district_type appear in geofence lookup results"
    - "Liz Feitl appears as Monroe County Council At Large member (not linked to Assessor district)"
    - "No duplicate politicians exist for Monroe County Council districts 1-4"
    - "Liz Feitl appears in ZIP-based lookups for all Monroe County ZIP codes"
  artifacts:
    - path: "EV-Backend/internal/essentials/geofence_lookup.go"
      provides: "COUNTY added to X0001 MTFCC mapping"
      contains: '"X0001": {"LOCAL", "COUNTY"}'
  key_links:
    - from: "geofence_lookup.go mtfccToDistrictTypes"
      to: "essentials.districts.district_type"
      via: "X0001 maps to LOCAL and COUNTY"
      pattern: 'X0001.*LOCAL.*COUNTY'
---

<objective>
Fix Monroe County Council data so all council members (districts 1-4 and at-large) appear correctly in address lookups.

Purpose: Monroe County Council members are invisible in search results due to an MTFCC mapping gap and bad migration data.
Output: Code fix to geofence_lookup.go + SQL migration to fix office linkages, remove duplicates, and populate zip_politicians.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@EV-Backend/internal/essentials/geofence_lookup.go
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix MTFCC mapping for COUNTY districts</name>
  <files>EV-Backend/internal/essentials/geofence_lookup.go</files>
  <action>
In `mtfccToDistrictTypes` map (line 34), change:
```go
"X0001": {"LOCAL"},  // City council sub-districts (BallotReady custom MTFCC)
```
to:
```go
"X0001": {"LOCAL", "COUNTY"},  // Sub-district boundaries (city council wards, county council districts)
```

This ensures that geofence matches with MTFCC X0001 can resolve to districts with district_type='COUNTY' (like Monroe County Council districts), not just LOCAL.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build ./...</automated>
  </verify>
  <done>X0001 MTFCC maps to both LOCAL and COUNTY district types. Go project compiles without errors.</done>
</task>

<task type="auto">
  <name>Task 2: Fix Liz Feitl office linkage, remove duplicates, populate zip_politicians</name>
  <files>EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql</files>
  <action>
Create a SQL migration script that performs these operations in order. The script should be idempotent (use IF EXISTS / ON CONFLICT where appropriate).

**Step 1: Reassign Cheryl Munson's vacant at-large office to Liz Feitl**
UPDATE essentials.offices SET politician_id = 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168', is_vacant = false, vacant_since = NULL WHERE id = 'bbb57efc-6b2e-4d95-a749-e6233241a1ce';

**Step 2: Delete Liz Feitl's incorrectly-linked office (pointed to Assessor district)**
DELETE FROM essentials.offices WHERE id = '2e2414f4-3468-4a85-a5ed-60b778b4355e';

**Step 3: Delete duplicate migration offices for districts 1-4**
Find offices linked to politicians with slugs: peter-iversen-monroe-county-council-d1, kate-wiltz-monroe-county-council-d2, marty-hawk-monroe-county-council-d3, jennifer-crossley-monroe-county-council-d4. Delete their offices first, then delete the politician records. Use:
```sql
DELETE FROM essentials.offices WHERE politician_id IN (
  SELECT id FROM essentials.politicians WHERE slug IN (
    'peter-iversen-monroe-county-council-d1',
    'kate-wiltz-monroe-county-council-d2',
    'marty-hawk-monroe-county-council-d3',
    'jennifer-crossley-monroe-county-council-d4'
  )
);
DELETE FROM essentials.politicians WHERE slug IN (
  'peter-iversen-monroe-county-council-d1',
  'kate-wiltz-monroe-county-council-d2',
  'marty-hawk-monroe-county-council-d3',
  'jennifer-crossley-monroe-county-council-d4'
);
```

**Step 4: Populate zip_politicians for Liz Feitl**
Insert Liz Feitl into zip_politicians for all Monroe County ZIPs, using the same ZIP codes as existing at-large county officials (Trent Deckard or David G Henry):
```sql
INSERT INTO essentials.zip_politicians (zip_code, politician_id)
SELECT zp.zip_code, 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168'
FROM essentials.zip_politicians zp
JOIN essentials.politicians p ON zp.politician_id = p.id
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '18105' AND d.district_type = 'COUNTY'
  AND p.id != 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168'
GROUP BY zp.zip_code
ON CONFLICT DO NOTHING;
```

**Step 5: Mark Cheryl Munson as inactive** (no longer holds office)
UPDATE essentials.politicians SET is_active = false WHERE id = '4d893b8e-2134-4177-99d9-ef72d859f0d2';

Print the script contents and instructions to run it manually against the database (user runs via psql or Supabase SQL editor).
  </action>
  <verify>
    <automated>test -f /Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql && echo "Migration file exists"</automated>
  </verify>
  <done>SQL migration script created with all 5 fix steps. Script is idempotent and safe to re-run.</done>
</task>

<task type="checkpoint:human-action" gate="blocking">
  <what-built>Go code fix (MTFCC mapping) and SQL migration script for Monroe County Council data</what-built>
  <how-to-verify>
    1. Run the SQL migration against the database:
       - Open Supabase SQL Editor or connect via psql
       - Paste and execute contents of EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql
    2. Verify Liz Feitl's office: SELECT p.full_name, o.title, d.label, d.district_type FROM essentials.offices o JOIN essentials.politicians p ON o.politician_id = p.id JOIN essentials.districts d ON o.district_id = d.id WHERE p.id = 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168';
       - Expected: Liz Feitl linked to "Monroe County Council - At Large" with district_type COUNTY
    3. Verify no duplicates: SELECT slug FROM essentials.politicians WHERE slug LIKE '%monroe-county-council-d%';
       - Expected: 0 rows
    4. Verify zip_politicians: SELECT COUNT(*) FROM essentials.zip_politicians WHERE politician_id = 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168';
       - Expected: non-zero count matching other at-large council members
    5. Deploy updated backend (go build + restart) and search a Monroe County address (e.g., Bloomington, IN 47401)
       - Expected: All Monroe County Council members appear in Local tier
  </how-to-verify>
  <resume-signal>Type "approved" after running migration and verifying results</resume-signal>
</task>

</tasks>

<verification>
- `go build ./...` passes in EV-Backend
- SQL migration script exists and contains all 5 fix operations
- After migration: Liz Feitl appears in Monroe County Council At Large
- After migration: No duplicate district 1-4 politicians from quick-8 migration
- After code deploy + migration: Monroe County Council members appear in address lookups
</verification>

<success_criteria>
- X0001 MTFCC maps to LOCAL and COUNTY in geofence_lookup.go
- Liz Feitl office correctly linked to at-large district (32eb02a9-a355-4df9-868a-921fdb64ac5b)
- 4 duplicate politician records removed
- Liz Feitl has zip_politicians entries for Monroe County ZIPs
- Monroe County address search returns all council members
</success_criteria>

<output>
After completion, create `.planning/quick/11-fix-monroe-county-council-data-liz-feitl/11-SUMMARY.md`
</output>
