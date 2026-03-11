# Phase 72: DB Audit - Research

**Researched:** 2026-03-10
**Domain:** PostgreSQL/Supabase schema audit — essentials.chambers, essentials.districts, essentials.geofence_boundaries, classify.js logic verification
**Confidence:** HIGH (all findings from direct codebase inspection)

## Summary

Phase 72 is a pure investigation phase: run SQL queries against the live Supabase database and trace classify.js logic to answer four specific questions before any code is written in Phases 73-76. No code changes are required in this phase — the deliverable is a documented set of facts and a regression mapping table.

The data model is well-understood. Every politician returned by the `/essentials/address` endpoint carries `chamber_name` (ch.name) and `chamber_name_formal` (ch.name_formal) from `essentials.chambers`, plus `office_title` from `essentials.offices`, `district_type` from `essentials.districts`, and `geo_id` from `essentials.districts`. The `classifyCategory()` function in `classify.js` uses `chamber_name_formal || chamber_name` (in that priority order) together with `district_type` and `office_title` to produce a `{tier, group}` pair. The group string becomes the section heading key in Results.jsx.

The critical risk flagged in STATE.md is whether Monroe County Commissioners and Monroe County Council land in distinct groups today. Tracing classify.js against the COUNTY district type: if `office_title` contains "commissioner" they land in "County Legislators"; if `office_title` contains "council" they also land in "County Legislators". This means they currently merge into one section — confirming the need for the data migration in Phase 73. However, whether the Bloomington Common Council is tagged as district_type LOCAL or COUNTY, and what chamber_name_formal values exist, must be verified against the actual database before any body_key logic is designed.

**Primary recommendation:** Execute the five SQL queries defined in this document against the live Supabase database. Document results verbatim. The planner should structure Phase 72 as a single task: connect to DB, run queries, record findings in a FINDINGS.md file.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DATA-01 | Database audit confirms current chamber_name_formal values for Monroe County/Bloomington officials | SQL queries against essentials.chambers + essentials.districts + essentials.geofence_boundaries; classify.js trace for group key collision analysis |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| psql / Supabase SQL editor | — | Run audit queries | Direct DB access; no code deploy needed |
| classify.js | current | Trace group key logic against real data | Source of truth for frontend classification |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| Supabase Table Editor | Cross-check individual rows after SQL | Spot-checking unexpected values |
| Supabase SQL editor | All five audit queries | Primary execution environment |

**No installation required.** This phase executes read-only SQL queries; nothing is installed or deployed.

## Architecture Patterns

### How Data Flows from DB to Frontend Classification

```
essentials.districts (district_type, geo_id)
    + essentials.chambers (name, name_formal)
    + essentials.offices (title)
         |
         v
  Go query in FindPoliticiansByGeoMatches (geofence_lookup.go)
         |
         v
  OfficialOut JSON: {district_type, chamber_name, chamber_name_formal, office_title, geo_id}
         |
         v
  classifyCategory(pol) in classify.js
  → reads: pol.district_type, pol.chamber_name_formal || pol.chamber_name, pol.office_title
  → returns: {tier, group}
         |
         v
  Results.jsx uses group as section heading key
  → CATEGORY_DISPLAY_NAMES[group] → display label
  → GROUP_SORT_OPTIONS[group] → sort options
```

### Pattern 1: classify.js COUNTY + "commissioner" title
**What:** When `district_type === "COUNTY"` and `office_title` contains "commissioner", classify.js returns `{ tier: "Local", group: "County Legislators" }`.
**Collision risk:** When `district_type === "COUNTY"` and `office_title` contains "council" (e.g., Monroe County Council members), classify.js ALSO returns `{ tier: "Local", group: "County Legislators" }` — because the check at line 197 is `hasAny(title, ["commissioner", "supervisor", "council"])`.
**Result:** Both Commissioners and Council members land in the same "County Legislators" section. BODY-02 requires them to be distinct.

**Relevant classify.js code (lines 196-207):**
```javascript
if (dt === "COUNTY") {
  if (hasAny(title, ["commissioner", "supervisor", "council"])) {
    return { tier: "Local", group: "County Legislators" };  // COLLISION
  }
  if (hasAny(title, ROLE_LOCAL_EXEC)) {
    return { tier: "Local", group: "County Executives" };
  }
  if (hasAny(title, ["sheriff", "clerk", "treasurer", "assessor", "auditor", "recorder", "coroner", "surveyor"])) {
    return { tier: "Local", group: "County Officials" };
  }
  return { tier: "Local", group: "County Officials" };
}
```

### Pattern 2: LOCAL district_type + "council" chamber_name
**What:** When `district_type === "LOCAL"` and `chamber_name` contains "council", classify.js returns `{ tier: "Local", group: "City Council" }`.
**Bloomington implication:** If Bloomington Common Council members are stored with `district_type = LOCAL` and `chamber_name` or `chamber_name_formal` contains "council", they correctly land in "City Council" — distinct from County Legislators.

### Pattern 3: Geofence GeoID format for Indiana counties
**What:** TIGER county geofences use a 5-digit FIPS GeoID: `{state_fips}{county_fips}`. For Monroe County, Indiana: state_fips = "18", county_fips = "105", so GeoID = "18105". MTFCC for counties is "G4020".
**Verification needed:** Confirm `SELECT geo_id FROM essentials.geofence_boundaries WHERE geo_id = '18105' AND mtfcc = 'G4020'` returns a row.

### Anti-Patterns to Avoid
- **Running UPDATE queries in this phase:** Phase 72 is read-only. No schema or data changes.
- **Assuming chamber_name_formal is populated:** BallotReady-sourced data often has name_formal = '' (empty string). The Go query uses `COALESCE(ch.name_formal, '')` — an empty string is returned, not NULL. classify.js checks `pol.chamber_name_formal || pol.chamber_name`, so an empty string falls through to `chamber_name`.
- **Assuming district_type is always COUNTY for county bodies:** Some Indiana county officials may be stored as LOCAL. The audit must check `district_type` for all Monroe County officials, not just those assumed to be COUNTY.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema exploration | Custom introspection scripts | Direct SQL queries to information_schema or specific tables | Faster and less error-prone |
| classify.js simulation | A separate JS test harness | Manual trace with known values from DB | Phase 72 is an investigation; the planner will build tests in Phase 73 |

## Common Pitfalls

### Pitfall 1: COALESCE makes empty strings invisible
**What goes wrong:** The Go query uses `COALESCE(ch.name_formal, '')` — if `name_formal` is NULL in DB, the API returns an empty string `""`, not null. classify.js then evaluates `"" || chamber_name` which is falsy and falls through to `chamber_name`. An audit querying for `name_formal IS NULL` would miss rows where name_formal = ''.
**How to avoid:** Query `WHERE name_formal = '' OR name_formal IS NULL` (or `WHERE COALESCE(name_formal, '') = ''`) to catch both cases.

### Pitfall 2: Monroe County data source is BallotReady, not scraped
**What goes wrong:** The LA County gap-fill was manual/scraped, but Monroe County/Bloomington politicians were originally imported from BallotReady (the `ballotready/` provider, now dead code). BallotReady chamber data may have different naming conventions than what's expected. Chamber names from BallotReady often include the full state + body name (e.g., "Monroe County Council, Indiana").
**How to avoid:** Query for actual `chamber_name` and `chamber_name_formal` values — don't assume they match plain strings like "Monroe County Council".

### Pitfall 3: Bloomington officials may be in LOCAL or COUNTY district_type
**What goes wrong:** Bloomington Common Council members serve a city (incorporated place), so their district_type could be LOCAL. Monroe County officials could be COUNTY. But the historical BallotReady import may have put some in unexpected district_types.
**How to avoid:** Query with no district_type filter first; then inspect what district_types actually appear for Monroe County / Bloomington officials.

### Pitfall 4: geofence_boundaries uses numeric state FIPS, not abbreviation
**What goes wrong:** Looking for Indiana geofences using `state = 'IN'` will find nothing. The `stateAbbrevToFIPS` map in `geofence_lookup.go` shows `"IN": "18"` — the geofence_boundaries table stores state as the 2-digit FIPS code.
**How to avoid:** Use `WHERE state = '18'` for Indiana queries.

### Pitfall 5: Monroe County geo_id may not use the canonical 5-digit FIPS
**What goes wrong:** The TIGER 2024 import may have stored the geo_id with or without leading zeros, or may use a different format (e.g., "18105" vs "18105000000").
**How to avoid:** Query `WHERE geo_id LIKE '18105%'` to catch variants, not just exact match.

## Code Examples

### Query 1: Distinct chamber values for Monroe County and Bloomington officials

```sql
-- Source: direct schema inspection of essentials.chambers + essentials.districts
SELECT DISTINCT
  ch.name AS chamber_name,
  ch.name_formal AS chamber_name_formal,
  d.district_type,
  d.geo_id,
  COUNT(p.id) AS politician_count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
WHERE p.is_active = true
  AND (
    -- Monroe County by FIPS geo_id
    d.geo_id LIKE '18105%'
    -- OR Bloomington city geo_id (look up separately)
    OR (d.state = '18' AND (d.city ILIKE '%bloomington%' OR ch.name ILIKE '%bloomington%' OR ch.name ILIKE '%common council%'))
  )
GROUP BY ch.name, ch.name_formal, d.district_type, d.geo_id
ORDER BY d.district_type, ch.name;
```

### Query 2: classify.js group simulation for Monroe County/Bloomington officials

```sql
-- Source: classify.js logic trace — shows what group each official would land in
SELECT
  p.full_name,
  o.title AS office_title,
  d.district_type,
  COALESCE(ch.name_formal, '') AS chamber_name_formal,
  COALESCE(ch.name, '') AS chamber_name,
  d.geo_id,
  -- Simulate classify.js COUNTY branch
  CASE
    WHEN d.district_type = 'COUNTY' THEN
      CASE
        WHEN LOWER(o.title) LIKE '%commissioner%' OR LOWER(o.title) LIKE '%supervisor%' OR LOWER(o.title) LIKE '%council%'
          THEN 'County Legislators'
        WHEN LOWER(o.title) IN ('mayor', 'county executive', 'county board president', 'city manager')
          THEN 'County Executives'
        ELSE 'County Officials'
      END
    WHEN d.district_type = 'LOCAL' THEN
      CASE
        WHEN LOWER(o.title) LIKE '%township%' OR LOWER(COALESCE(ch.name,'')) LIKE '%township%'
          THEN 'Township Officials'
        WHEN LOWER(COALESCE(ch.name_formal,'')) LIKE '%board of supervisors%'
          OR LOWER(COALESCE(ch.name_formal,'')) LIKE '%county council%'
          OR LOWER(COALESCE(ch.name_formal,'')) LIKE '%county commission%'
          THEN 'County Legislators'
        WHEN LOWER(COALESCE(ch.name,'')) LIKE '%council%'
          OR LOWER(COALESCE(ch.name_formal,'')) LIKE '%council%'
          OR LOWER(o.title) IN ('commissioner','councilmember','councilor','alder','alderman','alderperson')
          THEN 'City Council'
        ELSE 'Local (Other)'
      END
    ELSE d.district_type
  END AS simulated_group
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
WHERE p.is_active = true
  AND (d.geo_id LIKE '18105%' OR d.state = '18')
ORDER BY d.district_type, simulated_group, p.last_name;
```

### Query 3: Verify Monroe County TIGER geofence exists

```sql
-- Source: geofence_models.go (GeofenceBoundary), geofence_lookup.go (mtfccToDistrictTypes)
SELECT geo_id, mtfcc, name, state, source, imported_at
FROM essentials.geofence_boundaries
WHERE geo_id LIKE '18105%'
ORDER BY mtfcc;
```

### Query 4: Indiana geofences coverage check

```sql
-- Shows all Indiana geofences to understand what boundaries exist
SELECT mtfcc, COUNT(*) as count, MIN(geo_id) as sample_geo_id
FROM essentials.geofence_boundaries
WHERE state = '18'
GROUP BY mtfcc
ORDER BY mtfcc;
```

### Query 5: All active Indiana officials — district and chamber data

```sql
-- Full picture of all Indiana officials currently in DB
SELECT
  p.full_name,
  p.is_active,
  o.title AS office_title,
  d.district_type,
  d.geo_id,
  d.label AS district_label,
  d.state,
  d.city,
  COALESCE(ch.name, '') AS chamber_name,
  COALESCE(ch.name_formal, '') AS chamber_name_formal,
  g.name AS government_name
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
LEFT JOIN essentials.governments g ON g.id = ch.government_id
WHERE p.is_active = true
  AND (d.state = '18' OR d.geo_id LIKE '18%')
ORDER BY d.district_type, d.geo_id, p.last_name;
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| BallotReady API for politician data | PostGIS geofence + manual/scraped data | v1.5 (Phase 26-31) | chamber_name/name_formal values reflect what BallotReady stored; may be stale or incomplete |
| Cicero API for district data | TIGER 2024 shapefiles in geofence_boundaries | v1.6 (Phase 32-38) | geo_id values follow TIGER format |

**Known gaps:**
- Monroe County politicians: imported via BallotReady historically; chamber_name_formal may be empty or contain full state-qualified names
- Bloomington Common Council: imported via OnBoard scraper (Phase 58); chamber data set during import — the import script does not set chamber_name_formal explicitly

## Open Questions

1. **Are Monroe County Commissioners stored as `district_type = COUNTY` or `LOCAL`?**
   - What we know: MTFCC G4020 maps to `["COUNTY", "JUDICIAL"]` in geofence_lookup.go
   - What's unclear: Whether the BallotReady import used COUNTY or LOCAL for commissioner district records
   - Recommendation: Query 5 resolves this definitively

2. **What is the actual chamber_name_formal for Bloomington Common Council?**
   - What we know: The OnBoard import script does not set chamber records — it only creates legislative sessions, committees, and memberships
   - What's unclear: Whether a Chamber record for the Bloomington Common Council exists in essentials.chambers, and if so, what name_formal value was set by the BallotReady import
   - Recommendation: Query 1 resolves this

3. **Does a geofence boundary exist for Monroe County (18105)?**
   - What we know: TIGER 2024 congressional, state senate, state house, and county boundaries were imported in v1.6. The stateAbbrevToFIPS map includes Indiana ("IN" → "18")
   - What's unclear: Whether the Monroe County G4020 (county boundary) geofence was included in the Indiana import batch
   - Recommendation: Query 3 resolves this; if absent, Phase 73 may need a geofence import step

4. **Do Monroe County Council members have `office_title` containing "council" or "councilor"?**
   - What we know: classify.js COUNTY branch checks `hasAny(title, ["commissioner", "supervisor", "council"])` — both "Commissioner" and "Council Member" would land in "County Legislators"
   - What's unclear: Exact title strings stored in essentials.offices for Monroe County Council members
   - Recommendation: Query 2 simulated_group output will show the collision explicitly

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — Phase 72 is SQL-only investigation |
| Config file | none |
| Quick run command | `psql $DATABASE_URL -c "<query>"` or Supabase SQL editor |
| Full suite command | Execute all 5 queries in order |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Distinct chamber_name + chamber_name_formal values for Monroe County/Bloomington documented | manual-only | Execute Query 1, record output | N/A — output is documentation |
| DATA-01 | classify.js group collision between Commissioners and Council confirmed or denied | manual-only | Execute Query 2, inspect simulated_group column | N/A — output is documentation |
| DATA-01 | TIGER GeoID 18105 verified present in geofence_boundaries | manual-only | Execute Query 3, check row count > 0 | N/A — output is documentation |
| DATA-01 | Regression mapping table (politician → expected group) created | manual-only | Execute Query 5, manually assign expected groups | N/A — output is FINDINGS.md |

### Sampling Rate
- **Per task commit:** Not applicable — Phase 72 produces documentation, not code
- **Phase gate:** All 4 DATA-01 sub-questions answered in FINDINGS.md before Phase 73 starts

### Wave 0 Gaps
None — no test infrastructure needed for a SQL audit phase.

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/classify.js` — direct source inspection, all classify logic traced
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — mtfccToDistrictTypes map, FindPoliticiansByGeoMatches query (confirms which fields are returned in OfficialOut)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — Chamber model confirms name/name_formal fields
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — OfficialOut struct, COALESCE behavior in SQL query
- `/Users/chrisandrews/Documents/GitHub/.planning/REQUIREMENTS.md` — DATA-01 definition
- `/Users/chrisandrews/Documents/GitHub/.planning/ROADMAP.md` — Phase 72 success criteria and Phase 73 dependency
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — Key decision: "Phase 72 critical branch: if chamber_name_formal is unpopulated for Indiana chambers, Phase 73 becomes a data migration before a feature phase"
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_local_bloomington.py` — confirms Bloomington data source is OnBoard scraping; the importer does NOT set chamber_name/name_formal

### Secondary (MEDIUM confidence)
- Indiana state FIPS "18", Monroe County FIPS "105" → expected geo_id "18105" (standard TIGER convention, consistent with LA County FIPS pattern observed in pipeline_config.json)

## Metadata

**Confidence breakdown:**
- classify.js collision analysis: HIGH — traced directly from source code
- DB schema structure: HIGH — read directly from models.go and handlers.go
- Actual DB values (chamber names, geo_ids): UNKNOWN until queries run — that is the entire point of this phase
- TIGER geo_id format for Indiana counties: MEDIUM — inferred from FIPS standards and LA County precedent

**Research date:** 2026-03-10
**Valid until:** Until Phase 73 is planned (immediately consumed)

---

## Appendix: Expected FINDINGS.md Structure

The deliverable of Phase 72 is a `FINDINGS.md` file committed alongside the plan. It should capture:

```markdown
# Phase 72: DB Audit Findings

## Q1: Distinct chamber_name / chamber_name_formal values
[Paste Query 1 output verbatim]

## Q2: classify.js group simulation results
[Paste Query 2 output — focus on simulated_group column]
Collision confirmed: YES/NO
  - Commissioners group: [value]
  - Council group: [value]
  → Both landing in "County Legislators": YES/NO

## Q3: Monroe County (18105) geofence presence
[Paste Query 3 output]
Geofence present: YES/NO
  - If NO: Phase 73 must add Indiana county geofence import step

## Q4: Regression mapping table
| Full Name | office_title | district_type | Expected Group |
|-----------|-------------|---------------|----------------|
[Populated from Query 5 output with manual expected-group annotation]
```
