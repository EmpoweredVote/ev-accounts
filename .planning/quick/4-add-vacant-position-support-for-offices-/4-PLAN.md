---
phase: quick-4
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-Backend/internal/essentials/models.go
  - EV-Backend/internal/essentials/handlers.go
  - EV-Backend/internal/essentials/geofence_lookup.go
  - essentials/src/lib/classify.js
  - essentials/src/pages/Results.jsx
autonomous: true
requirements: [VACANT-01, VACANT-02, VACANT-03]

must_haves:
  truths:
    - "Vacant offices appear in search results at their correct classification position"
    - "Vacant offices render with dimmed/muted styling and a Vacant badge"
    - "Kristi Noem no longer appears in results; DHS Secretary shows as Vacant"
    - "Filled offices are unaffected by the changes"
  artifacts:
    - path: "EV-Backend/internal/essentials/models.go"
      provides: "Office model with is_vacant and vacant_since fields"
      contains: "IsVacant"
    - path: "EV-Backend/internal/essentials/handlers.go"
      provides: "API returns vacant offices alongside filled ones"
      contains: "is_vacant"
    - path: "essentials/src/lib/classify.js"
      provides: "Classification handles is_vacant at office level"
    - path: "essentials/src/pages/Results.jsx"
      provides: "Vacant card rendering with dimmed styling"
  key_links:
    - from: "EV-Backend/internal/essentials/handlers.go"
      to: "essentials/src/pages/Results.jsx"
      via: "API JSON response with is_vacant field on OfficialOut"
      pattern: "is_vacant"
    - from: "essentials/src/lib/classify.js"
      to: "essentials/src/pages/Results.jsx"
      via: "classifyCategory returns normal tier/group for vacant offices"
      pattern: "classifyCategory"
---

<objective>
Add vacant position support to the essentials module so that when officials leave office, the seat displays as "Vacant" in search results. Apply this immediately to Kristi Noem's DHS Secretary position.

Purpose: Users should see all seats in their jurisdiction, including currently unfilled ones, so they have complete awareness of their representation.
Output: Backend returns vacant offices in API responses; frontend renders them with dimmed styling and "Vacant" badge.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/quick/4-add-vacant-position-support-for-offices-/4-CONTEXT.md

<interfaces>
<!-- Current Office model (models.go line 61-75) — NO is_vacant/vacant_since fields yet -->
type Office struct {
    ID                    uuid.UUID `json:"id" gorm:"...;primaryKey"`
    PoliticianID          uuid.UUID `json:"politician_id" gorm:"type:uuid;uniqueIndex"`
    ChamberID             uuid.UUID `json:"chamber_id" gorm:"type:uuid"`
    DistrictID            uuid.UUID `json:"district_id" gorm:"type:uuid"`
    Title                 string    `json:"title"`
    RepresentingState     string    `json:"representing_state"`
    RepresentingCity      string    `json:"representing_city"`
    Description           string    `json:"description"`
    Seats                 int       `json:"seats"`
    NormalizedPositionName string   `json:"normalized_position_name"`
    PartisanType          string    `json:"partisan_type"`
    Salary                string    `json:"salary"`
    IsAppointedPosition   bool      `json:"is_appointed_position"`
}

<!-- Politician model already has IsVacant (line 41) — this is the LEGACY field that will be superseded -->
IsVacant bool `json:"is_vacant"`

<!-- OfficialOut (handlers.go lines 161-212) — already has IsVacant field from Politician -->
type OfficialOut struct {
    // ... many fields ...
    IsVacant bool `json:"is_vacant,omitempty"`
    // ...
}

<!-- classify.js line 106 — current VACANT hack filters by first_name -->
if (pol?.first_name === "VACANT") return { tier: "Hidden", group: "Vacant" };

<!-- Results.jsx line 322-325 — current VACANT filter removes them entirely -->
const filteredPols = useMemo(
    () => list.filter((p) => p?.first_name !== 'VACANT'),
    [list]
);

<!-- PoliticianCard (ev-ui) supports badge prop already (e.g., "Candidate") -->
<!-- badge renders as coral pill at top-right of card -->

<!-- All three query paths filter `AND p.is_active = true`:
     - fetchOfficialsFromDB (handlers.go:1231)
     - fetchFederalAndStateFromDBFiltered (handlers.go:1513 — actually MISSING is_active filter!)
     - FindPoliticiansByGeoMatches (geofence_lookup.go:169)
-->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Backend — Add vacancy fields to Office model and update all query paths</name>
  <files>
    EV-Backend/internal/essentials/models.go,
    EV-Backend/internal/essentials/handlers.go,
    EV-Backend/internal/essentials/geofence_lookup.go
  </files>
  <action>
**1. Add vacancy fields to Office model (models.go):**

Add two fields to the `Office` struct (after `IsAppointedPosition`):
```go
IsVacant    bool       `json:"is_vacant" gorm:"default:false"`
VacantSince *time.Time `json:"vacant_since,omitempty"`
```

The `PoliticianID` field must change from `uuid.UUID` to `*uuid.UUID` (nullable pointer) so that vacant offices can exist without a linked politician:
```go
PoliticianID *uuid.UUID `json:"politician_id" gorm:"type:uuid;uniqueIndex"`
```

GORM AutoMigrate will add the new columns on next server start.

**2. Update OfficialOut and query assembly (handlers.go):**

Add `VacantSince` to `OfficialOut`:
```go
VacantSince *time.Time `json:"vacant_since,omitempty"`
```

The `IsVacant` field already exists on `OfficialOut` (line 188) — change it to source from `o.is_vacant` (Office) instead of `p.is_vacant` (Politician) in all SQL queries.

**3. Modify all three query functions to include vacant offices:**

The core change: vacant offices have `o.is_vacant = true` and may have `politician_id IS NULL` or link to an inactive politician. The queries currently `JOIN essentials.offices o ON o.politician_id = p.id` and `AND p.is_active = true`, which excludes vacant offices entirely.

For each query function, apply these changes:

**a) `fetchOfficialsFromDB` (handlers.go ~line 1117):**
- Change the SQL JOIN from `JOIN essentials.offices o ON o.politician_id = p.id` to `LEFT JOIN essentials.politicians p ON o.politician_id = p.id` with `FROM essentials.offices o` as the base table
- Move the `JOIN essentials.districts d ON d.id = o.district_id` to join from `o` (already does)
- Change the `WHERE` clause: instead of `AND p.is_active = true`, use `AND (p.is_active = true OR o.is_vacant = true)`
- Add `o.is_vacant` and `o.vacant_since` to the SELECT list
- Use COALESCE for all `p.*` fields to handle NULL politician: `COALESCE(p.first_name, '') AS first_name`, etc.
- In the `row` struct, add `IsVacantOffice bool` and `VacantSince *time.Time`
- In the DTO assembly, set `IsVacant: r.IsVacantOffice` and `VacantSince: r.VacantSince`
- For the `is_contained` LEFT JOIN on zip_politicians, this still works with vacant offices since vacant offices without politicians won't match zip_politicians — that's fine, they'll get `is_contained = NULL`

**b) `fetchFederalAndStateFromDBFiltered` (handlers.go ~line 1421):**
- Apply the same pattern: base table = offices, LEFT JOIN politicians
- Add `AND (p.is_active = true OR o.is_vacant = true)` — note this function currently has NO is_active filter at all, so add it as `WHERE (...) AND (p.is_active = true OR o.is_vacant = true)`
- Add `o.is_vacant` and `o.vacant_since` to SELECT
- COALESCE all p.* fields

**c) `FindPoliticiansByGeoMatches` (geofence_lookup.go ~line 72):**
- Change `FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id` to `FROM essentials.offices o LEFT JOIN essentials.politicians p ON o.politician_id = p.id`
- Change `AND p.is_active = true` to `AND (p.is_active = true OR o.is_vacant = true)`
- Add `o.is_vacant` and `o.vacant_since` to SELECT, update the Scan() call
- COALESCE all p.* fields
- Update `DISTINCT ON (p.id)` to `DISTINCT ON (o.id)` since o is now the base table, and `ORDER BY p.id` to `ORDER BY o.id`

**4. Important: Keep backward compatibility:**
- The `IsVacant` field on the `Politician` model (line 41) stays as-is — it's a legacy BallotReady field. The new source of truth is `Office.IsVacant`.
- The `OfficialOut.IsVacant` field now reflects the Office-level vacancy, not the Politician-level one.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build -o /dev/null .</automated>
  </verify>
  <done>
    - Office model has `is_vacant` (bool) and `vacant_since` (*time.Time) fields
    - PoliticianID on Office is nullable (*uuid.UUID)
    - All three query functions return vacant offices (is_vacant=true) even without active politicians
    - OfficialOut.IsVacant sourced from Office, not Politician
    - Go build succeeds with no errors
  </done>
</task>

<task type="auto">
  <name>Task 2: Frontend — Render vacant offices with dimmed styling and Vacant badge</name>
  <files>
    essentials/src/lib/classify.js,
    essentials/src/pages/Results.jsx
  </files>
  <action>
**1. Update classify.js:**

Remove the `first_name === 'VACANT'` hidden-tier hack (line 106):
```js
// DELETE THIS LINE:
if (pol?.first_name === "VACANT") return { tier: "Hidden", group: "Vacant" };
```

Vacant offices now come from the API with `is_vacant: true` on the OfficialOut. The `district_type`, `chamber_name`, and `office_title` fields are still populated (from the Office/District/Chamber tables), so `classifyCategory` will correctly classify them into the right tier and group (e.g., a vacant DHS Secretary will classify as Federal > Cabinet).

No other changes needed in classify.js — the existing classification logic works on office/district metadata, not politician name.

**2. Update Results.jsx:**

**a) Remove the VACANT name filter** (lines 322-325):
Change the `filteredPols` memo from:
```js
const filteredPols = useMemo(
    () => list.filter((p) => p?.first_name !== 'VACANT'),
    [list]
);
```
to:
```js
const filteredPols = useMemo(() => list, [list]);
```
(Or just use `list` directly — but keep the memo for consistency with the rest of the code.)

**b) Update `renderPoliticianCard` function** (~line 94) to handle vacant offices:

At the top of `renderPoliticianCard`, detect vacancy:
```js
const isVacant = pol.is_vacant;
```

For vacant offices:
- Pass `name="Vacant"` to PoliticianCard (not the politician's name since there may be no politician)
- Pass `badge="Vacant"` to show the pill badge (reusing the existing badge prop that already works for "Candidate")
- Pass `imageSrc={undefined}` (no photo — the initials placeholder will show "V")
- Pass `onClick={undefined}` (no click handler — there's no profile to navigate to)
- Add an inline `style` override on the wrapping div to apply dimmed/muted appearance:
  - `opacity: 0.6` on the wrapping div
  - Alternatively, use a CSS filter or reduced opacity approach

The card title (position name) should still render normally — e.g., "Secretary of Homeland Security" for the DHS seat. The subtitle (district info) renders as before.

Here's the updated render logic for the vacant case (add before the existing return in `renderPoliticianCard`):

```jsx
if (isVacant) {
  return (
    <div key={pol.id || `vacant-${pol.office_title}`} style={{ opacity: 0.55 }}>
      <PoliticianCard
        id={pol.id}
        imageSrc={undefined}
        name="Vacant"
        title={cardTitle}
        subtitle={subtitle}
        badge="Vacant"
        onClick={undefined}
        variant="horizontal"
      />
    </div>
  );
}
```

**c) Update the deduplication key** in `byTier` memo (~line 389):
The current dedup key is `${pol.first_name}-${pol.last_name}-${pol.office_title}-${cat.group}`. For vacant offices, `first_name` and `last_name` will be empty strings, so multiple vacant offices with different titles will still deduplicate correctly. But add `pol.is_vacant` to the key to prevent vacant/filled collisions:
```js
const key = `${pol.first_name}-${pol.last_name}-${pol.office_title}-${cat.group}-${pol.is_vacant || false}`;
```
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build</automated>
  </verify>
  <done>
    - classify.js no longer hides VACANT-named politicians (legacy hack removed)
    - Vacant offices render inline in their correct classification tier/group
    - Vacant cards show "Vacant" as name, dimmed opacity (0.55), "Vacant" badge pill, no photo, no click handler
    - Filled office cards are completely unaffected
    - Frontend builds successfully
  </done>
</task>

<task type="auto">
  <name>Task 3: Apply Noem vacancy — set is_active=false and mark DHS office vacant</name>
  <files>
    EV-Backend/scripts/apply_noem_vacancy.sql
  </files>
  <action>
Create a SQL script at `EV-Backend/scripts/apply_noem_vacancy.sql` that:

1. Finds Kristi Noem's politician record (search by `last_name = 'Noem'` AND `first_name = 'Kristi'` in `essentials.politicians`)
2. Sets `is_active = false` on her politician record (preserves all data for potential future reassignment)
3. Updates her office record in `essentials.offices`: set `is_vacant = true`, `vacant_since = '2025-01-20'` (use a plausible date for when she was removed/confirmed fired — if the exact date is unknown, use a reasonable approximation)
4. Optionally sets `politician_id = NULL` on the office to fully detach her — but per the user decision, the vacancy flag is sufficient to skip rendering her, so leaving politician_id linked is fine. The query logic `(p.is_active = true OR o.is_vacant = true)` will return the office regardless.

The script should be wrapped in a transaction and include safety checks (verify exactly 1 row affected per UPDATE). Include a SELECT at the end to verify the result.

```sql
BEGIN;

-- 1. Find Noem's politician ID
DO $$
DECLARE
  noem_id UUID;
  affected INT;
BEGIN
  SELECT id INTO noem_id FROM essentials.politicians
  WHERE last_name = 'Noem' AND first_name = 'Kristi';

  IF noem_id IS NULL THEN
    RAISE EXCEPTION 'Kristi Noem not found in essentials.politicians';
  END IF;

  -- 2. Deactivate politician record
  UPDATE essentials.politicians SET is_active = false WHERE id = noem_id;
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected != 1 THEN
    RAISE EXCEPTION 'Expected 1 row updated for politician, got %', affected;
  END IF;

  -- 3. Mark her office as vacant
  UPDATE essentials.offices
  SET is_vacant = true, vacant_since = '2025-01-20'
  WHERE politician_id = noem_id;
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected != 1 THEN
    RAISE EXCEPTION 'Expected 1 row updated for office, got %', affected;
  END IF;

  RAISE NOTICE 'Successfully marked Kristi Noem (%) as inactive and her office as vacant', noem_id;
END $$;

COMMIT;

-- Verify
SELECT p.id, p.full_name, p.is_active, o.title, o.is_vacant, o.vacant_since
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
WHERE p.last_name = 'Noem';
```

Add a comment at the top of the file explaining when and why to run this script:
```sql
-- apply_noem_vacancy.sql
-- Marks Kristi Noem as inactive and her DHS Secretary office as vacant.
-- Run against the production database after deploying the is_vacant/vacant_since migration.
-- Usage: psql $DATABASE_URL -f scripts/apply_noem_vacancy.sql
```

NOTE: Do NOT run this script automatically. It is a manual migration script the user runs against their database after deploying the backend changes from Task 1.
  </action>
  <verify>
    <automated>test -f /Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/apply_noem_vacancy.sql && echo "SQL script exists"</automated>
  </verify>
  <done>
    - SQL migration script exists at EV-Backend/scripts/apply_noem_vacancy.sql
    - Script deactivates Noem's politician record (is_active=false)
    - Script marks her office as vacant (is_vacant=true, vacant_since set)
    - Script is transactional with safety checks
    - Script includes verification SELECT
  </done>
</task>

</tasks>

<verification>
1. Backend compiles: `cd EV-Backend && go build -o /dev/null .`
2. Frontend builds: `cd essentials && npm run build`
3. SQL script exists and is syntactically reasonable
4. After running the server with AutoMigrate and applying the SQL script:
   - Search for a DC-area address should show "Secretary of Homeland Security" as a vacant card with dimmed styling
   - Kristi Noem should NOT appear as a filled card
   - All other officials should appear normally
</verification>

<success_criteria>
- Office model has is_vacant and vacant_since columns (GORM AutoMigrate adds them)
- All three backend query paths (fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, FindPoliticiansByGeoMatches) return vacant offices
- Frontend renders vacant offices with dimmed styling, "Vacant" badge, no clickable profile
- Frontend no longer filters out results by first_name === 'VACANT' hack
- SQL script ready to apply the Kristi Noem vacancy
- Both Go backend and React frontend build without errors
</success_criteria>

<output>
After completion, create `.planning/quick/4-add-vacant-position-support-for-offices-/4-SUMMARY.md`
</output>
