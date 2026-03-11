# Phase 74: Data Seeding - Research

**Researched:** 2026-03-11
**Domain:** PostgreSQL SQL seeding, GORM idempotent INSERT, government body URL research
**Confidence:** HIGH (all findings from direct codebase inspection + confirmed Phase 73 artifacts + live URL verification)

## Summary

Phase 74 is a pure data seeding phase with no new code constructs. The `essentials.government_bodies` table was created in Phase 73 with a composite unique index on `(state, geo_id, body_key)`. Phase 74 inserts rows into this table with verified `display_name` and `website_url` values for Monroe County and Bloomington government bodies.

The critical complexity in this phase is geo_id fan-out: bodies with per-district chamber records require one row per distinct geo_id that officials use. The JOIN key `body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')` means that after Phase 73's chamber_name_formal migrations, multi-member bodies all share a single body_key — but each distinct `d.geo_id` in the districts table still needs its own government_bodies row for the JOIN to match.

The "Monroe County elected officials" success criterion requires a decision: individual single-office county officials (Sheriff, Assessor, Auditor, etc.) each have their own chamber_name as body_key (no name_formal was set for them in Phase 73). The cleanest approach is to add a Phase 74 name_formal migration for these individual offices to share a common body_key (e.g., 'Monroe County Government'), then seed one row pointing to the county government homepage. This follows the same idempotent UPDATE pattern established in Phase 73's setup.go.

**Primary recommendation:** Two tasks — (1) additional name_formal migrations in setup.go for individual county office chambers + INSERT rows into government_bodies for all required (state, geo_id, body_key) combinations with verified URLs, (2) direct DB verification that all seeded URLs are non-null and that officials return non-empty government_body_url in the API response.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LINK-03 | Monroe County bodies seeded with official website URLs (Commissioners, Council, elected officials) | Three distinct body_key groupings needed: 'Monroe County Commission' (1 geo_id), 'Monroe County Council' (5 geo_ids), 'Monroe County Government' (1 geo_id for individual offices); URLs verified from in.gov official pages |
| LINK-04 | Bloomington bodies seeded with official website URLs (City Council) | body_key = 'Bloomington Common Council'; 7 geo_ids (1 at-large + 6 districts); URL verified from bloomington.in.gov/council |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GORM `db.DB.Exec()` | current | Idempotent INSERT with ON CONFLICT DO NOTHING; name_formal UPDATE | Established pattern in setup.go for Phase 73 chamber migrations |
| PostgreSQL `ON CONFLICT DO NOTHING` | — | Upsert-safe seeding | Composite unique index on (state, geo_id, body_key) makes this the correct idiom |
| Raw SQL INSERT | — | Seed rows with all five columns | GovernmentBody table has no external ID; GORM `.Create()` would work but raw SQL is more explicit for seed data |

### No New Dependencies
No new Go packages, npm modules, or external services required. All work is SQL executed via existing `db.DB.Exec()` calls in `setup.go`.

**Installation:** None required.

## Architecture Patterns

### Recommended Seeding Structure

All seeds go into `setup.go` as additional `db.DB.Exec()` calls immediately after the Phase 73 chamber_name_formal migrations. The idempotent pattern is `INSERT ... ON CONFLICT (state, geo_id, body_key) DO NOTHING` (not DO UPDATE — URLs should not be overwritten if manually changed).

```
EV-Backend/internal/essentials/
└── setup.go   -- ADD name_formal UPDATE for individual county offices
               -- ADD INSERT rows for all (state, geo_id, body_key) combinations
```

### Pattern 1: Idempotent Name_formal UPDATE (new, for individual offices)

Phase 73 only migrated multi-member body chambers. Phase 74 adds migrations for individual county-wide elected offices so they share a common body_key.

```go
// Source: setup.go Phase 73 pattern (lines 78-80) — same pattern
// Add these immediately after the Phase 73 chamber_name_formal UPDATEs in setup.go:

// Individual county-wide elected offices share one body key
db.DB.Exec(`UPDATE essentials.chambers SET name_formal = 'Monroe County Government'
  WHERE name IN (
    'Monroe County Assessor', 'Monroe County Auditor', 'Monroe County Circuit Court Clerk',
    'Monroe County Coroner', 'Monroe County Prosecuting Attorney', 'Monroe County Recorder',
    'Monroe County Sheriff', 'Monroe County Surveyor', 'Monroe County Treasurer'
  ) AND (name_formal = '' OR name_formal IS NULL)`)
```

Note: The JUDICIAL chambers (Indiana Circuit Court Judge - 10th Circuit) are a separate district_type (JUDICIAL) with geo_id=18105. They are optional for Phase 74 — the success criteria do not mention them. They can be left with no government_bodies row (empty body URL in JSON).

### Pattern 2: Idempotent INSERT with ON CONFLICT

```go
// Source: setup.go pattern (db.DB.Exec idiom from existing Phase 73 code)
// Add after the name_formal UPDATE block above:

db.DB.Exec(`
  INSERT INTO essentials.government_bodies (state, geo_id, body_key, display_name, website_url)
  VALUES
    -- Monroe County Commission (all 3 commissioners use geo_id 18105)
    ('18', '18105', 'Monroe County Commission', 'Monroe County Commission',
     'https://www.in.gov/counties/monroe/government/commissioners/'),
    -- Monroe County Council - At Large (3 members, geo_id 18105)
    ('18', '18105', 'Monroe County Council', 'Monroe County Council',
     'https://www.in.gov/counties/monroe/government/council/'),
    -- Monroe County Council - District 1 (1 member, geo_id 1810500001)
    ('18', '1810500001', 'Monroe County Council', 'Monroe County Council',
     'https://www.in.gov/counties/monroe/government/council/'),
    -- Monroe County Council - District 2 (1 member, geo_id 1810500002)
    ('18', '1810500002', 'Monroe County Council', 'Monroe County Council',
     'https://www.in.gov/counties/monroe/government/council/'),
    -- Monroe County Council - District 3 (1 member, geo_id 1810500003)
    ('18', '1810500003', 'Monroe County Council', 'Monroe County Council',
     'https://www.in.gov/counties/monroe/government/council/'),
    -- Monroe County Council - District 4 (1 member, geo_id 1810500004)
    ('18', '1810500004', 'Monroe County Council', 'Monroe County Council',
     'https://www.in.gov/counties/monroe/government/council/'),
    -- Individual county-wide elected officials (geo_id 18105)
    ('18', '18105', 'Monroe County Government', 'Monroe County Government',
     'https://www.in.gov/counties/monroe/'),
    -- Bloomington Common Council - At Large (3 members, geo_id 1805860)
    ('18', '1805860', 'Bloomington Common Council', 'Bloomington Common Council',
     'https://bloomington.in.gov/council'),
    -- Bloomington Common Council - District 1 (geo_id 180586000001)
    ('18', '180586000001', 'Bloomington Common Council', 'Bloomington Common Council',
     'https://bloomington.in.gov/council'),
    -- Bloomington Common Council - District 2 (geo_id 180586000002)
    ('18', '180586000002', 'Bloomington Common Council', 'Bloomington Common Council',
     'https://bloomington.in.gov/council'),
    -- Bloomington Common Council - District 3 (geo_id 180586000003)
    ('18', '180586000003', 'Bloomington Common Council', 'Bloomington Common Council',
     'https://bloomington.in.gov/council'),
    -- Bloomington Common Council - District 4 (geo_id 180586000004)
    ('18', '180586000004', 'Bloomington Common Council', 'Bloomington Common Council',
     'https://bloomington.in.gov/council'),
    -- Bloomington Common Council - District 5 (geo_id 180586000005)
    ('18', '180586000005', 'Bloomington Common Council', 'Bloomington Common Council',
     'https://bloomington.in.gov/council'),
    -- Bloomington Common Council - District 6 (geo_id 180586000006)
    ('18', '180586000006', 'Bloomington Common Council', 'Bloomington Common Council',
     'https://bloomington.in.gov/council')
  ON CONFLICT (state, geo_id, body_key) DO NOTHING
`)
```

### Pattern 3: The Conflict Target Must Match the Index Name

The composite unique index created by GORM from the `uniqueIndex:idx_gov_body_lookup` tag covers all three columns: `(state, geo_id, body_key)`. PostgreSQL `ON CONFLICT` syntax requires naming the columns (not the index), so the clause is `ON CONFLICT (state, geo_id, body_key) DO NOTHING`.

### Anti-Patterns to Avoid

- **ON CONFLICT DO UPDATE SET website_url = ...**: Would overwrite manually-corrected URLs on every server restart. Use DO NOTHING — if a URL changes, fix it directly in the database.
- **Missing the '18105' collision between Commission and Council rows**: Both Commission and Council have At-Large officials using geo_id='18105'. They have DIFFERENT body_key values ('Monroe County Commission' vs 'Monroe County Council'), so they coexist without conflict — each is a separate unique (state, geo_id, body_key) combination.
- **Forgetting the individual office name_formal UPDATE**: Without setting `name_formal = 'Monroe County Government'` for individual office chambers, the body_key for Sheriff etc. is still their individual chamber name (e.g., 'Monroe County Sheriff'), and the INSERT for body_key='Monroe County Government' would be unreachable by the JOIN. The UPDATE must precede or accompany the INSERT.
- **Treating Bloomington City Clerk and Mayor as council members**: geo_id '1805860' is shared by Clerk (LOCAL), At-Large council (LOCAL), and Mayor (LOCAL_EXEC). Only LOCAL district_type officials with chamber_name containing "council" get body_key='Bloomington Common Council'. The Clerk's chamber_name is 'Bloomington City Clerk' (no name_formal migration needed or seeded). The Mayor's chamber is 'Bloomington City Mayor'. Separate body_keys; no collision.
- **Seeding rows for JUDICIAL or LOCAL/LOCAL_EXEC chambers not required by Phase 74**: Township boards, trustees, circuit court judges, Bloomington City Clerk, and Bloomington City Mayor are NOT in the Phase 74 success criteria. Seeding them is optional and can be deferred to Phase 76.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL validation at seed time | Go HTTP client pinging each URL during Init() | Manual pre-verification + DO NOTHING insert | Live URL checks in Init() would slow server startup and fail on network isolation; manual verification is sufficient at this scale (4 URLs) |
| Dynamic body name derivation | SQL CASE WHEN logic to strip district suffix at query time | Pre-seeded display_name column | Already established in Phase 73: GovernmentBody table is a lookup table, not a computed view |
| Script-based seeding | Separate Go binary or psql script file | `db.DB.Exec()` in setup.go | Consistent with existing pattern; runs automatically on server startup; idempotent |

**Key insight:** Phase 74 is entirely SQL data; zero application logic is required beyond what exists.

## Common Pitfalls

### Pitfall 1: geo_id mismatch — '18105' vs '18105' (COUNTY) vs '1810500001' (district)
**What goes wrong:** Developer seeds only one row for Monroe County Council (geo_id='18105') assuming all council members share it. District members (Peter Iversen, Kate Wiltz, Martha Hawk, Jennifer Crossley) use separate district geo_ids (1810500001–1810500004) and get no JOIN match.
**How to avoid:** Seed 5 rows for Monroe County Council (one per distinct geo_id from Phase 72 FINDINGS.md: 18105, 1810500001, 1810500002, 1810500003, 1810500004).
**Warning signs:** GET /essentials/search?zip=47401 shows government_body_name for At-Large council members but not district members.

### Pitfall 2: geo_id mismatch — Bloomington district geo_ids
**What goes wrong:** Developer seeds only the At-Large geo_id ('1805860') for Bloomington Common Council. District members (districts 1–6) use geo_ids 180586000001–180586000006 and return empty body URL.
**How to avoid:** Seed 7 rows for Bloomington Common Council (one per distinct geo_id from Phase 72 FINDINGS.md).
**Warning signs:** At-Large council members show body URL; district members do not.

### Pitfall 3: Individual office body_key not matching after name_formal update
**What goes wrong:** Developer inserts a government_bodies row with body_key='Monroe County Government' but forgets to run the name_formal UPDATE for individual office chambers. The chambers still have name_formal='' so body_key = their individual chamber name (e.g., 'Monroe County Sheriff'), and the JOIN finds no match.
**How to avoid:** The name_formal UPDATE must be in setup.go BEFORE (or in the same transaction as) the INSERT. Since setup.go migrations run sequentially and are idempotent, order within the file matters.
**Warning signs:** Monroe County Sheriff/Assessor/Auditor/etc. return empty government_body_name despite the government_bodies row existing.

### Pitfall 4: state value mismatch — 'IN' vs '18'
**What goes wrong:** Developer uses state='IN' (ISO 2-letter code) in the INSERT, but the districts table stores state='18' (FIPS 2-digit code). The JOIN `gb.state = d.state` fails silently.
**How to avoid:** Phase 72 FINDINGS.md confirms: `state = 'IN'` in the Q5 display is the government_name state; the districts table `d.state` is FIPS '18'. Use '18' in all INSERT statements.
**Warning signs:** Rows inserted but government_body_name remains empty for all Indiana officials.

### Pitfall 5: URL trailing slash inconsistency
**What goes wrong:** URL is stored as 'https://www.in.gov/counties/monroe/government/council' (no trailing slash) but the canonical URL has a trailing slash, causing redirect hits.
**How to avoid:** Use the exact canonical URL confirmed via WebFetch: include the trailing slash where the live page uses it (in.gov pages consistently use trailing slashes).
**Warning signs:** Clicking the link in the UI triggers a 301 redirect. While functionally fine, it is cleaner to use the canonical form.

## Code Examples

### Complete setup.go addition (single atomic block)

```go
// Phase 74: Seed individual county office chambers with shared body_key (idempotent)
db.DB.Exec(`UPDATE essentials.chambers SET name_formal = 'Monroe County Government'
  WHERE name IN (
    'Monroe County Assessor', 'Monroe County Auditor', 'Monroe County Circuit Court Clerk',
    'Monroe County Coroner', 'Monroe County Prosecuting Attorney', 'Monroe County Recorder',
    'Monroe County Sheriff', 'Monroe County Surveyor', 'Monroe County Treasurer'
  ) AND (name_formal = '' OR name_formal IS NULL)`)

// Phase 74: Seed government_bodies with verified website URLs (idempotent)
db.DB.Exec(`
  INSERT INTO essentials.government_bodies (state, geo_id, body_key, display_name, website_url)
  VALUES
    ('18', '18105',       'Monroe County Commission',    'Monroe County Commission',    'https://www.in.gov/counties/monroe/government/commissioners/'),
    ('18', '18105',       'Monroe County Council',       'Monroe County Council',       'https://www.in.gov/counties/monroe/government/council/'),
    ('18', '1810500001',  'Monroe County Council',       'Monroe County Council',       'https://www.in.gov/counties/monroe/government/council/'),
    ('18', '1810500002',  'Monroe County Council',       'Monroe County Council',       'https://www.in.gov/counties/monroe/government/council/'),
    ('18', '1810500003',  'Monroe County Council',       'Monroe County Council',       'https://www.in.gov/counties/monroe/government/council/'),
    ('18', '1810500004',  'Monroe County Council',       'Monroe County Council',       'https://www.in.gov/counties/monroe/government/council/'),
    ('18', '18105',       'Monroe County Government',    'Monroe County Government',    'https://www.in.gov/counties/monroe/'),
    ('18', '1805860',     'Bloomington Common Council',  'Bloomington Common Council',  'https://bloomington.in.gov/council'),
    ('18', '180586000001','Bloomington Common Council',  'Bloomington Common Council',  'https://bloomington.in.gov/council'),
    ('18', '180586000002','Bloomington Common Council',  'Bloomington Common Council',  'https://bloomington.in.gov/council'),
    ('18', '180586000003','Bloomington Common Council',  'Bloomington Common Council',  'https://bloomington.in.gov/council'),
    ('18', '180586000004','Bloomington Common Council',  'Bloomington Common Council',  'https://bloomington.in.gov/council'),
    ('18', '180586000005','Bloomington Common Council',  'Bloomington Common Council',  'https://bloomington.in.gov/council'),
    ('18', '180586000006','Bloomington Common Council',  'Bloomington Common Council',  'https://bloomington.in.gov/council')
  ON CONFLICT (state, geo_id, body_key) DO NOTHING
`)
```

### Verification SQL queries

After server restart against Supabase, run these to confirm:

```sql
-- Q1: All seeded rows present with non-null URLs
SELECT state, geo_id, body_key, display_name, website_url
FROM essentials.government_bodies
WHERE state = '18'
ORDER BY body_key, geo_id;
-- Expected: 14 rows (1 Commission + 5 Council + 1 Monroe County Government + 7 Bloomington)

-- Q2: Individual county office chamber name_formal updated
SELECT name, name_formal
FROM essentials.chambers
WHERE name IN (
  'Monroe County Assessor', 'Monroe County Sheriff', 'Monroe County Auditor',
  'Monroe County Coroner', 'Monroe County Treasurer', 'Monroe County Recorder'
);
-- Expected: name_formal = 'Monroe County Government' for all rows

-- Q3: Council + Commission body_key confirms
SELECT name, name_formal FROM essentials.chambers
WHERE name_formal IN ('Monroe County Council', 'Monroe County Commission', 'Bloomington Common Council')
ORDER BY name_formal, name;
-- Expected: 5 rows Council (At Large + 4 districts), 3 rows Commission, 7 rows Bloomington

-- Q4: JOIN smoke test — verify body_key matches government_bodies
SELECT c.name, c.name_formal,
       COALESCE(NULLIF(c.name_formal, ''), c.name, '') AS body_key,
       gb.website_url
FROM essentials.chambers c
JOIN essentials.offices o ON o.chamber_id = c.id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.government_bodies gb
  ON gb.state = d.state
  AND gb.geo_id = d.geo_id
  AND gb.body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')
WHERE d.geo_id LIKE '18105%' OR d.geo_id LIKE '1805860%'
ORDER BY c.name;
-- Expected: All Monroe County Council/Commission/Government chambers show non-empty website_url
--           All Bloomington Common Council chambers show non-empty website_url
```

## Verified Official URLs

| Body | Canonical URL | Source | Confidence |
|------|--------------|--------|------------|
| Monroe County Commission | https://www.in.gov/counties/monroe/government/commissioners/ | WebFetch in.gov | HIGH |
| Monroe County Council | https://www.in.gov/counties/monroe/government/council/ | WebFetch in.gov | HIGH |
| Monroe County Government (individual offices) | https://www.in.gov/counties/monroe/ | WebFetch in.gov | HIGH |
| Bloomington Common Council | https://bloomington.in.gov/council | WebFetch bloomington.in.gov | HIGH |

All four URLs resolve to official government pages (in.gov = Indiana state government; bloomington.in.gov = City of Bloomington official site). No redirects required. URLs include trailing slashes consistent with canonical form on both domains.

## Geo_ID Seeding Map

Complete list of (state, geo_id, body_key) combinations required, derived from Phase 72 FINDINGS.md:

| state | geo_id | body_key | Officials | Rationale |
|-------|--------|----------|-----------|-----------|
| 18 | 18105 | Monroe County Commission | Commissioners D1, D2, D3 (3 officials) | COUNTY district, geo_id=18105 |
| 18 | 18105 | Monroe County Council | At Large x3 | COUNTY at-large, geo_id=18105 |
| 18 | 1810500001 | Monroe County Council | District 1 (Iversen) | COUNTY district geo_id |
| 18 | 1810500002 | Monroe County Council | District 2 (Wiltz) | COUNTY district geo_id |
| 18 | 1810500003 | Monroe County Council | District 3 (Hawk) | COUNTY district geo_id |
| 18 | 1810500004 | Monroe County Council | District 4 (Crossley) | COUNTY district geo_id |
| 18 | 18105 | Monroe County Government | Sheriff, Assessor, Auditor, Coroner, Treasurer, Recorder, Surveyor, Circuit Court Clerk, Prosecuting Attorney | All use geo_id=18105; name_formal='Monroe County Government' after Phase 74 UPDATE |
| 18 | 1805860 | Bloomington Common Council | At Large x3, Clerk (shares geo_id but different chamber_name → different body_key) | LOCAL district, geo_id=1805860 |
| 18 | 180586000001 | Bloomington Common Council | District 1 | Custom geofence |
| 18 | 180586000002 | Bloomington Common Council | District 2 | Custom geofence |
| 18 | 180586000003 | Bloomington Common Council | District 3 | Custom geofence |
| 18 | 180586000004 | Bloomington Common Council | District 4 | Custom geofence |
| 18 | 180586000005 | Bloomington Common Council | District 5 | Custom geofence |
| 18 | 180586000006 | Bloomington Common Council | District 6 | Custom geofence |

**Note on geo_id '18105' with multiple body_keys:** Three different body_keys share geo_id '18105':
- 'Monroe County Commission' — Commissioners
- 'Monroe County Council' — At-Large council members
- 'Monroe County Government' — Individual county offices

These are three distinct rows in government_bodies and three distinct composite keys. No conflict exists because body_key differs.

**Note on geo_id '1805860' with Bloomington City Clerk:** The Clerk's chamber is 'Bloomington City Clerk' with no name_formal migration, so body_key = 'Bloomington City Clerk'. No government_bodies row for this key means the Clerk returns empty body URL — acceptable for Phase 74 (Clerk is not a council member).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No body URL data anywhere in the system | government_bodies table with website_url column | Phase 73 | Table exists and LEFT JOIN is wired; just needs seeded data |
| chamber_name_formal empty for Indiana | Populated for Council, Commission, Bloomington | Phase 73 setup.go | body_key is now stable for multi-member bodies; Phase 74 extends this for individual offices |

## Open Questions

1. **Should Bloomington City Clerk and Mayor also get government_bodies rows?**
   - What we know: LINK-04 says only "City Council." Clerk is a single officer; Mayor is in a separate category.
   - What's unclear: Whether Phase 76's frontend section headings need body URLs for non-council Bloomington officials.
   - Recommendation: Do not seed in Phase 74. Phase 76 can add if needed.

2. **Should circuit court judges (JUDICIAL, geo_id=18105) get a government_bodies row?**
   - What we know: Success criteria mention only Commissioners, Council, elected officials, and Bloomington council.
   - What's unclear: Whether "elected officials" was intended to include JUDICIAL officials.
   - Recommendation: Exclude circuit court judges from Phase 74. They are a distinct district_type and a separate classification group. Seed only COUNTY district_type officials under 'Monroe County Government'.

3. **Is 'Monroe County Government' the right display_name for individual elected county offices?**
   - What we know: The group in classify.js is "County Officials" and the county homepage is at in.gov/counties/monroe/.
   - What's unclear: Whether the display_name should match what Phase 76 uses as a section heading.
   - Recommendation: Use 'Monroe County Government' as a neutral, accurate label. Phase 76 can override the displayed heading independently using the display_name from the government_bodies row.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — no automated test suite exists for this codebase |
| Config file | none |
| Quick run command | `cd EV-Backend && go build -o server . && echo "build OK"` |
| Full suite command | Manual: psql queries to verify seeded rows + curl against running server |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LINK-03 | Monroe County bodies seeded with non-null URLs | manual-smoke | `psql $DATABASE_URL -c "SELECT body_key, geo_id, website_url FROM essentials.government_bodies WHERE state='18' ORDER BY body_key, geo_id"` | N/A |
| LINK-03 | Monroe County Commission officials return non-empty government_body_url | manual-smoke | Curl ZIP 47401 search, check Commissioner JSON objects | N/A |
| LINK-03 | Monroe County Council officials (all geo_ids) return non-empty government_body_url | manual-smoke | Curl ZIP 47401, verify district council members have body URL | N/A |
| LINK-03 | Monroe County individual offices return non-empty government_body_url | manual-smoke | Curl ZIP 47401, check Sheriff/Assessor/Auditor JSON | N/A |
| LINK-04 | Bloomington council officials return non-empty government_body_url | manual-smoke | Curl ZIP 47408 or address search for Bloomington, check council member JSON | N/A |
| LINK-04 | All 7 Bloomington geo_ids have seeded rows | manual-smoke | psql query: `SELECT geo_id FROM essentials.government_bodies WHERE body_key='Bloomington Common Council'` — expect 7 rows | N/A |

### Sampling Rate
- **Per task commit:** `go build -o server .` in EV-Backend directory (catches Go compilation errors)
- **Phase gate:** Manual psql query confirming 14 seeded rows with non-empty website_url before proceeding to Phase 75

### Wave 0 Gaps
None — no test infrastructure required. All validation is manual SQL and curl checks. The build command provides Go compilation verification.

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/72-db-audit/72-FINDINGS.md` — All geo_ids for Monroe County and Bloomington officials (confirmed from live DB query)
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/73-backend-governmentbody-table/73-01-SUMMARY.md` — Phase 73 completed: government_bodies table exists, chamber_name_formal migrations complete, LEFT JOIN wired in both fetch functions
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/73-backend-governmentbody-table/73-VERIFICATION.md` — All 7 Phase 73 truths verified, including composite unique index (state, geo_id, body_key)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — Idempotent UPDATE pattern (lines 78-80); AutoMigrate structure
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — GovernmentBody struct (lines 284-291): state, geo_id, body_key, display_name, website_url
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — JOIN confirmed at lines 1231-1234 and 1560-1563; OfficialOut fields at 214-215

### Secondary (HIGH confidence — verified via WebFetch)
- https://www.in.gov/counties/monroe/government/commissioners/ — Official Monroe County Board of Commissioners page (in.gov = Indiana state government)
- https://www.in.gov/counties/monroe/government/council/ — Official Monroe County Council page
- https://www.in.gov/counties/monroe/ — Monroe County government homepage
- https://bloomington.in.gov/council — Official Bloomington Common Council page

### Tertiary (not applicable)
No tertiary sources required — all critical findings sourced from codebase or official government pages.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools already in use; no new patterns introduced
- Geo_id seeding map: HIGH — exact geo_ids from Phase 72 live DB query
- Official URLs: HIGH — all four URLs verified via WebFetch against live official government sites
- Individual office body_key approach: MEDIUM — "Monroe County Government" as the shared body_key is a design decision; the Phase 74 success criteria say "Monroe County elected officials" without specifying the exact body_key value; this interpretation is reasonable and consistent with the JOIN pattern

**Research date:** 2026-03-11
**Valid until:** 90 days (stable data — government URLs rarely change; geo_ids are permanent TIGER identifiers)
