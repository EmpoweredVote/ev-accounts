---
phase: quick-9
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-Backend/internal/essentials/setup.go
autonomous: true
requirements: [QUICK-9]

must_haves:
  truths:
    - "Ellettsville Town Council shows 'Ellettsville Town Council' (not 'City Council')"
    - "Ellettsville municipal executives show 'Ellettsville Town Officials' (not 'City Officials')"
    - "Richland Township shows 'Richland Township' (not 'Township')"
    - "Richland-Bean Blossom school board shows 'Richland-Bean Blossom Community School Corporation' (not 'School Board')"
    - "Monroe County and Bloomington display names are unchanged"
  artifacts:
    - path: "EV-Backend/internal/essentials/setup.go"
      provides: "government_bodies seed rows for Ellettsville, Richland Township, Richland-Bean Blossom"
      contains: "Ellettsville"
  key_links:
    - from: "essentials.government_bodies"
      to: "Results.jsx splitByBodyName()"
      via: "government_body_name field in OfficialOut"
      pattern: "government_body_name"
---

<objective>
Fix organization display names on the essentials results page for non-Bloomington Monroe County localities.

Purpose: When a user searches an Ellettsville address, section headers show generic labels ("City Council", "City Officials", "Township", "School Board") instead of the actual body names. The fix is seeding missing `government_bodies` rows so the JOIN in `fetchOfficialsFromDB` returns real display names.

Output: Updated setup.go with seed rows for Ellettsville Town Council, Richland Township, and Richland-Bean Blossom Community School Corporation.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

## Root Cause

The `government_bodies` table drives section header names on the results page. The SQL JOIN in `fetchOfficialsFromDB` and `geofence_lookup.go` is:

```sql
LEFT JOIN essentials.government_bodies gb
  ON gb.state = d.state
  AND gb.geo_id = d.geo_id
  AND gb.body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')
```

When no matching row exists, `government_body_name` is `''`. In `Results.jsx`, `splitByBodyName()` puts these politicians in the `unnamed` bucket and falls back to `getDisplayName(category)` — returning generic labels like "City Council", "City Officials", "Township", "School Board".

Monroe County and Bloomington work because their rows ARE seeded in `setup.go`. Ellettsville, Richland Township, and Richland-Bean Blossom are not seeded.

## How body_key Is Derived

`body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')` — the chamber's `name_formal` if non-empty, else `name`. You must look up what actual values exist in the DB for these bodies to seed the correct key.

## Key Files

- `EV-Backend/internal/essentials/setup.go` — contains the `government_bodies` INSERT block (around line 131)
- `EV-Backend/internal/essentials/models.go` — GovernmentBody: (state, geo_id, body_key) unique composite key
- `EV-Backend/internal/essentials/handlers.go` + `geofence_lookup.go` — both JOIN on `government_bodies` the same way
</context>

<tasks>

<task type="auto">
  <name>Task 1: Discover geo_ids and body_keys for missing localities</name>
  <files>EV-Backend/internal/essentials/setup.go</files>
  <action>
Before writing any seed data, run queries against the local Supabase DB to find the exact values needed. The backend must be configured with DATABASE_URL in .env.local.

Run these SQL queries (use psql or a Go one-off, or run via the backend's existing db connection):

```sql
-- Find Ellettsville Town Council body_key and geo_id
SELECT d.geo_id, d.state, d.district_type, d.label,
       COALESCE(NULLIF(c.name_formal, ''), c.name, '') AS body_key,
       c.name, c.name_formal, g.name AS gov_name
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN essentials.governments g ON g.id = c.government_id
WHERE g.name ILIKE '%Ellettsville%'
   OR c.name ILIKE '%Ellettsville%'
   OR d.label ILIKE '%Ellettsville%'
ORDER BY d.geo_id, body_key;

-- Find Richland Township body_key and geo_id
SELECT d.geo_id, d.state, d.district_type,
       COALESCE(NULLIF(c.name_formal, ''), c.name, '') AS body_key,
       c.name, c.name_formal, g.name AS gov_name
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN essentials.governments g ON g.id = c.government_id
WHERE g.name ILIKE '%Richland%'
   OR c.name ILIKE '%Richland%'
   OR d.label ILIKE '%Richland%'
ORDER BY d.geo_id, body_key;

-- Find Richland-Bean Blossom School Corporation body_key and geo_id
SELECT d.geo_id, d.state, d.district_type,
       COALESCE(NULLIF(c.name_formal, ''), c.name, '') AS body_key,
       c.name, c.name_formal, g.name AS gov_name
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN essentials.governments g ON g.id = c.government_id
WHERE g.name ILIKE '%Bean Blossom%'
   OR c.name ILIKE '%Bean Blossom%'
   OR g.name ILIKE '%Richland%Bean%'
   OR d.label ILIKE '%Bean Blossom%'
ORDER BY d.geo_id, body_key;
```

Capture the results. You need `geo_id`, `state`, and `body_key` for each distinct body.

Also confirm that no existing `government_bodies` rows exist for these geo_ids:
```sql
SELECT * FROM essentials.government_bodies WHERE state = 'IN' ORDER BY geo_id;
```

Then add the new seed rows to `setup.go` inside the existing `INSERT INTO essentials.government_bodies` block (around line 131, before the `ON CONFLICT` clause). Follow the exact same pattern as existing rows.

For each distinct (geo_id, body_key) pair found:
- `state`: use the state abbreviation from districts (likely 'IN')
- `geo_id`: exact value from the query
- `body_key`: exact value from the COALESCE expression
- `display_name`: use the proper display name:
  - Ellettsville council body → "Ellettsville Town Council"
  - Ellettsville executive body (mayor/officials) → "Ellettsville Town Officials" (or the correct govt body name)
  - Richland Township → "Richland Township"
  - Richland-Bean Blossom school body → "Richland-Bean Blossom Community School Corporation"
- `website_url`: use '' for now (can be filled in later)

If multiple geo_ids exist for the same body (e.g., district seats), add one row per (state, geo_id, body_key).

Do NOT change any existing rows. Use `ON CONFLICT (state, geo_id, body_key) DO NOTHING` (already present in the block) so it is idempotent.

After editing setup.go, rebuild the backend:
```bash
cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build -o server . 2>&1
```

Then restart the server and verify with a test query for an Ellettsville address ZIP (47429):
```bash
curl -s "http://localhost:5050/essentials/politicians/47429" | python3 -m json.tool | grep -A2 "government_body_name"
```

Confirm `government_body_name` is non-empty for local Ellettsville/Richland politicians.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build -o server . 2>&1 | grep -c "^" || echo "build_ok"</automated>
  </verify>
  <done>
- go build succeeds with no errors
- Curl to /essentials/politicians/47429 returns politicians where government_body_name is "Ellettsville Town Council", "Richland Township", and "Richland-Bean Blossom Community School Corporation" (not empty strings)
- Existing Monroe County and Bloomington government_body_name values are unchanged
  </done>
</task>

</tasks>

<verification>
After the backend is rebuilt and restarted, test with an Ellettsville address in the essentials frontend (`npm run dev` in `/Users/chrisandrews/Documents/GitHub/essentials`). Search for an Ellettsville, IN address and confirm the Local section shows:
- "Ellettsville Town Council" (not "City Council")
- "Richland Township" (not "Township")
- "Richland-Bean Blossom Community School Corporation" (not "School Board")

Also search a Bloomington address to confirm no regression.
</verification>

<success_criteria>
- Ellettsville results page shows locality-specific names in all section headers
- go build passes
- No existing government_bodies rows were modified (Monroe County and Bloomington unaffected)
</success_criteria>

<output>
After completion, create `.planning/quick/9-fix-organization-display-names-on-essent/9-SUMMARY.md`
</output>
