---
phase: quick-13
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-Backend/internal/essentials/migrations/normalize_congressional_district_labels.sql
autonomous: true
requirements: [QUICK-13]

must_haves:
  truths:
    - "Erin Houchin and all U.S. House members show a district label of 'District N' (e.g. 'District 9'), not 'Indiana 9th Congress'"
    - "U.S. Senate district labels contain only the state name (e.g. 'Indiana'), not ordinal class suffixes"
    - "district_id numeric field is unchanged — frontend subtitle logic still works"
  artifacts:
    - path: "EV-Backend/internal/essentials/migrations/normalize_congressional_district_labels.sql"
      provides: "Idempotent SQL migration to normalize district labels"
      contains: "UPDATE essentials.districts"
  key_links:
    - from: "essentials.districts.label"
      to: "CompassV2 name.js NATIONAL_UPPER case"
      via: "district_label API field"
      pattern: "distLabel.*NATIONAL_UPPER"
---

<objective>
Normalize the `label` column in `essentials.districts` for congressional districts so all U.S. House rows read "District N" and all U.S. Senate rows read just the state name.

Purpose: Raw Cicero labels like "Indiana 9th Congress" are surfaced in the essentials app sort key and in CompassV2's senator subtitle ("U.S. Senator - Indiana 9th Congress"), making the UI look unprofessional.

Output: A SQL migration file + applied changes in the database.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Key facts:
- `essentials.districts.label` holds the Cicero-sourced label string (e.g., "Indiana 9th Congress", "Indiana - Class 3")
- `essentials.districts.district_id` holds just the numeric string (e.g., "9") — do NOT change this
- `essentials.districts.district_type` = 'NATIONAL_LOWER' for U.S. House, 'NATIONAL_UPPER' for U.S. Senate
- `essentials.districts.state` holds the two-letter state abbreviation (e.g., "IN")

How `district_label` (= `d.label`) is consumed:
- `essentials` app: used only as a sort key in `sorters.js:districtLabelKey` — clean format improves sort quality
- `CompassV2/src/util/name.js` NATIONAL_LOWER: extracts the digit via `distLabel.match(/\d+/)?.[0]` — already robust, clean format is bonus
- `CompassV2/src/util/name.js` NATIONAL_UPPER: returns `"U.S. Senator - " + distLabel` — this is where messy labels are visibly broken

Target formats:
- NATIONAL_LOWER: "District {N}" (e.g., "District 9")
- NATIONAL_UPPER: "{State Full Name}" (e.g., "Indiana") — strip ordinal suffixes and class designations

State abbreviation to full name mapping is needed for NATIONAL_UPPER. Use a CASE expression or a cross-join with a VALUES list.

Prior migration pattern: see `EV-Backend/internal/essentials/migrations/fix_monroe_county_council.sql`
- Wrapped in BEGIN/COMMIT
- Idempotent (safe to re-run)
- Includes verification queries at the bottom as comments
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write and apply normalize_congressional_district_labels.sql</name>
  <files>EV-Backend/internal/essentials/migrations/normalize_congressional_district_labels.sql</files>
  <action>
Create the migration file at `EV-Backend/internal/essentials/migrations/normalize_congressional_district_labels.sql`.

The migration must:

1. For NATIONAL_LOWER — set label to "District {district_id}" for all rows where district_id is a non-empty numeric string:
```sql
UPDATE essentials.districts
SET label = 'District ' || district_id
WHERE district_type = 'NATIONAL_LOWER'
  AND district_id ~ '^\d+$'
  AND district_id != '';
```

2. For NATIONAL_UPPER — set label to the full state name derived from the `state` column (2-letter abbreviation). Use a CASE expression mapping all 50 states + DC. Strip any class designation or ordinal suffix currently in the label:
```sql
UPDATE essentials.districts
SET label = CASE state
  WHEN 'AL' THEN 'Alabama'
  WHEN 'AK' THEN 'Alaska'
  WHEN 'AZ' THEN 'Arizona'
  WHEN 'AR' THEN 'Arkansas'
  WHEN 'CA' THEN 'California'
  WHEN 'CO' THEN 'Colorado'
  WHEN 'CT' THEN 'Connecticut'
  WHEN 'DE' THEN 'Delaware'
  WHEN 'FL' THEN 'Florida'
  WHEN 'GA' THEN 'Georgia'
  WHEN 'HI' THEN 'Hawaii'
  WHEN 'ID' THEN 'Idaho'
  WHEN 'IL' THEN 'Illinois'
  WHEN 'IN' THEN 'Indiana'
  WHEN 'IA' THEN 'Iowa'
  WHEN 'KS' THEN 'Kansas'
  WHEN 'KY' THEN 'Kentucky'
  WHEN 'LA' THEN 'Louisiana'
  WHEN 'ME' THEN 'Maine'
  WHEN 'MD' THEN 'Maryland'
  WHEN 'MA' THEN 'Massachusetts'
  WHEN 'MI' THEN 'Michigan'
  WHEN 'MN' THEN 'Minnesota'
  WHEN 'MS' THEN 'Mississippi'
  WHEN 'MO' THEN 'Missouri'
  WHEN 'MT' THEN 'Montana'
  WHEN 'NE' THEN 'Nebraska'
  WHEN 'NV' THEN 'Nevada'
  WHEN 'NH' THEN 'New Hampshire'
  WHEN 'NJ' THEN 'New Jersey'
  WHEN 'NM' THEN 'New Mexico'
  WHEN 'NY' THEN 'New York'
  WHEN 'NC' THEN 'North Carolina'
  WHEN 'ND' THEN 'North Dakota'
  WHEN 'OH' THEN 'Ohio'
  WHEN 'OK' THEN 'Oklahoma'
  WHEN 'OR' THEN 'Oregon'
  WHEN 'PA' THEN 'Pennsylvania'
  WHEN 'RI' THEN 'Rhode Island'
  WHEN 'SC' THEN 'South Carolina'
  WHEN 'SD' THEN 'South Dakota'
  WHEN 'TN' THEN 'Tennessee'
  WHEN 'TX' THEN 'Texas'
  WHEN 'UT' THEN 'Utah'
  WHEN 'VT' THEN 'Vermont'
  WHEN 'VA' THEN 'Virginia'
  WHEN 'WA' THEN 'Washington'
  WHEN 'WV' THEN 'West Virginia'
  WHEN 'WI' THEN 'Wisconsin'
  WHEN 'WY' THEN 'Wyoming'
  WHEN 'DC' THEN 'District of Columbia'
  ELSE label  -- leave unknown states unchanged
END
WHERE district_type = 'NATIONAL_UPPER'
  AND state IS NOT NULL
  AND state != '';
```

Wrap both updates in BEGIN/COMMIT. Add commented verification queries at the bottom per the established pattern.

After writing the file, apply it to the database:
```bash
psql $DATABASE_URL -f EV-Backend/internal/essentials/migrations/normalize_congressional_district_labels.sql
```

If $DATABASE_URL is not set, instruct: "Set DATABASE_URL from .env.local and re-run psql command."
  </action>
  <verify>
    <automated>
      psql $DATABASE_URL -c "SELECT label, district_id, state FROM essentials.districts WHERE district_type = 'NATIONAL_LOWER' AND state = 'IN' LIMIT 5;" 2>/dev/null | grep -E "District [0-9]" || echo "Cannot verify without live DB — check file exists"
      ls EV-Backend/internal/essentials/migrations/normalize_congressional_district_labels.sql
    </automated>
  </verify>
  <done>
    - Migration file exists at the specified path
    - NATIONAL_LOWER rows: label = "District N" (Erin Houchin's IN-9 shows "District 9")
    - NATIONAL_UPPER rows: label = full state name only (no ordinal/class suffix)
    - district_id column unchanged
  </done>
</task>

</tasks>

<verification>
After applying migration, spot-check:

```sql
-- House: should show "District 9" for Erin Houchin's district
SELECT label, district_id, state, district_type
FROM essentials.districts
WHERE district_type = 'NATIONAL_LOWER' AND state = 'IN';

-- Senate: should show "Indiana" (not "Indiana - Class 1" etc.)
SELECT label, district_id, state, district_type
FROM essentials.districts
WHERE district_type = 'NATIONAL_UPPER' AND state = 'IN';

-- Confirm no NATIONAL_LOWER rows still have old format (ordinal words)
SELECT COUNT(*) FROM essentials.districts
WHERE district_type = 'NATIONAL_LOWER'
  AND label ~ '(1st|2nd|3rd|[0-9]th) Congress';
-- Expected: 0
```
</verification>

<success_criteria>
- Migration file committed to repo
- All NATIONAL_LOWER district labels match "District N" format
- All NATIONAL_UPPER district labels are full state names only
- Zero rows still contain ordinal Congress format ("9th Congress", "1st Congress", etc.)
- CompassV2 senator subtitles now read "U.S. Senator - Indiana" instead of "U.S. Senator - Indiana - Class 3"
</success_criteria>

<output>
After completion, create `.planning/quick/13-standardize-congressional-district-names/13-SUMMARY.md` using the summary template.
</output>
