# Phase 73: Backend GovernmentBody Table - Research

**Researched:** 2026-03-11
**Domain:** Go GORM model + SQL migration, classify.js frontend keyword patching, essentials schema enrichment pattern
**Confidence:** HIGH (all findings from direct codebase inspection and completed Phase 72 DB audit)

## Summary

Phase 73 has two distinct jobs that must both complete before Phase 74 (seeding URLs). First, it is a **data migration**: `chamber_name_formal` is empty for every Indiana official in the database, so a SQL UPDATE must populate canonical body names in `essentials.chambers` before any `body_key` logic can work correctly. Second, it is a **feature phase**: a new `essentials.government_bodies` table must be created and the `SearchPoliticians` handler must LEFT JOIN it to annotate each `OfficialOut` record with `government_body_name` and `government_body_url`.

There is also a **frontend classification fix** required: Monroe County Commissioners currently fall through to "County Officials" because the COUNTY branch in `classify.js` checks for "commissioner" (10 chars, ends in 'r') but the actual office title is "Monroe County Commission - District X" (contains "commission", not "commissioner"). Adding "commission" to the COUNTY keyword list fixes this. DATA-03 requires that `LOCAL_ORDER`, `CATEGORY_DISPLAY_NAMES`, and `GROUP_SORT_OPTIONS` in `classify.js` and `sorters.js` are updated atomically in the same commit whenever any new group key is added.

The existing PositionDescription enrichment pattern (LEFT JOIN on position_descriptions, COALESCE fallback) is the direct precedent for how GovernmentBody should be joined. The composite unique constraint pattern `(state, geo_id, body_key)` enables idempotent upserts and is already used for geofence_boundaries `(geo_id, mtfcc)`.

**Primary recommendation:** Plan three sequential tasks — (1) chamber_name_formal data migration SQL, (2) GovernmentBody Go model + GORM AutoMigrate + LEFT JOIN in both fetch functions, (3) classify.js "commission" keyword fix with atomic update to all three consumer structures.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LINK-02 | Website URLs stored in database with graceful absence when URL is null | GovernmentBody table with nullable `website_url` column; LEFT JOIN with COALESCE(..., '') in both fetch queries; OfficialOut gains `government_body_name` and `government_body_url` string fields |
| DATA-02 | classify.js routes "commissioner" title keywords to distinct "County Commissioners" group | Add "commission" to COUNTY branch `hasAny(title, [...])` list in classify.js; confirmed via Phase 72 that office titles are "Monroe County Commission - District X" (not "Commissioner") |
| DATA-03 | All consumer files updated together (LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS) | Three structures in classify.js (LOCAL_ORDER) and sorters.js (CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS) must update atomically; currently "County Legislators" is the target group for Commissioners — adding a new key would require all three |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GORM | current (project) | Model definition + AutoMigrate for government_bodies table | All essentials models use GORM; setup.go calls AutoMigrate on all structs |
| PostgreSQL raw SQL | — | Chamber name_formal UPDATE migration; GovernmentBody JOIN in both fetch functions | Both fetch functions use db.DB.Raw() with hand-written SQL, not GORM query builder |
| classify.js | current | Frontend keyword fix for Commissioners | Direct edit to COUNTY branch keyword array |
| sorters.js | current | GROUP_SORT_OPTIONS atomic update | Companion file to classify.js; both must update in same commit per DATA-03 |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| psql / Supabase SQL editor | — | Verify chamber_name_formal UPDATE results | Post-migration spot check before proceeding to feature work |

**No new npm or Go dependencies required.** Everything runs on existing GORM, Go stdlib, and the existing essentials package.

## Architecture Patterns

### Existing Pattern: PositionDescription Enrichment (direct precedent)

The GovernmentBody JOIN follows the exact same pattern as PositionDescription in both `fetchOfficialsFromDB` and `fetchFederalAndStateFromDBFiltered`:

```sql
-- Source: handlers.go lines 1219-1224 (PositionDescription join — use as template)
LEFT JOIN essentials.position_descriptions pd_specific
  ON pd_specific.normalized_position_name = COALESCE(NULLIF(o.normalized_position_name, ''), o.title)
  AND pd_specific.district_type = d.district_type
LEFT JOIN essentials.position_descriptions pd_generic
  ON pd_generic.normalized_position_name = COALESCE(NULLIF(o.normalized_position_name, ''), o.title)
  AND pd_generic.district_type = ''
```

The GovernmentBody JOIN will be simpler — a single LEFT JOIN on `(state, geo_id, body_key)` where `body_key` is derived from `chamber_name_formal`.

### Pattern: GovernmentBody JOIN in both fetch functions

Both `fetchOfficialsFromDB` (line 1119) and `fetchFederalAndStateFromDBFiltered` (line 1442) contain the same raw SQL query structure. Both must be updated identically — add the LEFT JOIN and the two SELECT columns.

```sql
-- Add to SELECT clause (both fetch functions):
COALESCE(gb.display_name, '') AS government_body_name,
COALESCE(gb.website_url, '') AS government_body_url,

-- Add to FROM/JOIN clause (both fetch functions):
LEFT JOIN essentials.government_bodies gb
  ON gb.state = d.state
  AND gb.geo_id = d.geo_id
  AND gb.body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')
```

Note: `d.state` in districts table stores the 2-digit FIPS code (e.g., '18' for Indiana, '06' for California). The GovernmentBody table's `state` column should match this convention.

### Pattern: GORM Model with composite unique

```go
// Source: models.go pattern (PositionDescription at line 273, geofence unique constraint in setup.go)
type GovernmentBody struct {
    ID          uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    State       string    `json:"state" gorm:"uniqueIndex:idx_gov_body_lookup"`
    GeoID       string    `json:"geo_id" gorm:"uniqueIndex:idx_gov_body_lookup"`
    BodyKey     string    `json:"body_key" gorm:"uniqueIndex:idx_gov_body_lookup"`
    DisplayName string    `json:"display_name"`
    WebsiteURL  string    `json:"website_url"` // nullable-safe: empty string when absent
}

func (GovernmentBody) TableName() string {
    return "essentials.government_bodies"
}
```

Add `&GovernmentBody{}` to the AutoMigrate call in `setup.go` alongside the other models.

### Pattern: chamber_name_formal UPDATE migration

Phase 72 confirmed `chamber_name_formal = ''` (empty string via COALESCE) for all Indiana officials. The UPDATE must target `essentials.chambers` by joining through offices and districts to find Monroe County and Bloomington chambers:

```sql
-- Populate canonical body names for Monroe County Council chambers
-- Target: all chambers whose name matches "Monroe County Council%"
UPDATE essentials.chambers
SET name_formal = 'Monroe County Council'
WHERE name LIKE 'Monroe County Council%'
  AND (name_formal = '' OR name_formal IS NULL);

-- Populate canonical body names for Monroe County Commission chambers
UPDATE essentials.chambers
SET name_formal = 'Monroe County Commission'
WHERE name LIKE 'Monroe County Commission%'
  AND (name_formal = '' OR name_formal IS NULL);

-- Populate for Bloomington Common Council
UPDATE essentials.chambers
SET name_formal = 'Bloomington Common Council'
WHERE name LIKE 'Bloomington City Common Council%'
  AND (name_formal = '' OR name_formal IS NULL);

-- Township boards — keep per-township (already classify correctly)
-- Township trustees — keep per-township (already classify correctly)
-- Individual offices (Sheriff, Assessor, etc.) — no body_key needed; keep name as-is
```

After this migration: the LEFT JOIN `ON gb.body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')` will produce:
- All Monroe County Council members → body_key `'Monroe County Council'`
- All Monroe County Commission members → body_key `'Monroe County Commission'`
- Bloomington council members → body_key `'Bloomington Common Council'`
- Individual county officials (Sheriff etc.) → body_key remains their individual chamber name (no row in government_bodies → NULL → empty string)

### Pattern: Dual geo_id for County Council members

Phase 72 audit finding: Monroe County Council At-Large members use `geo_id = '18105'` while district members use `geo_id = '1810500001'` through `'1810500004'`. The government_bodies JOIN uses `gb.geo_id = d.geo_id`, so separate rows are needed for each geo_id:

```sql
-- After chamber migration and GovernmentBody table creation, seed rows:
-- Row 1: County-level geo_id for At-Large
INSERT INTO essentials.government_bodies (state, geo_id, body_key, display_name, website_url)
VALUES ('18', '18105', 'Monroe County Council', 'Monroe County Council', '');

-- Row 2-5: District-level geo_ids for Council districts
INSERT INTO essentials.government_bodies (state, geo_id, body_key, display_name, website_url)
VALUES ('18', '1810500001', 'Monroe County Council', 'Monroe County Council', '');
-- ... repeat for 1810500002, 1810500003, 1810500004

-- Commission members all use geo_id '18105'
INSERT INTO essentials.government_bodies (state, geo_id, body_key, display_name, website_url)
VALUES ('18', '18105', 'Monroe County Commission', 'Monroe County Commission', '');
```

**Important:** This seeding is minimal — Phase 74 adds the website_url values. Phase 73 only needs display_name populated; website_url can be '' initially.

### Pattern: classify.js COUNTY branch fix (DATA-02)

The current COUNTY branch checks `hasAny(title, ["commissioner", "supervisor", "council"])`. The actual office title is "Monroe County Commission - District X" which contains "commission" (not "commissioner"). Fix:

```javascript
// Source: classify.js line 197 — current:
if (hasAny(title, ["commissioner", "supervisor", "council"])) {
  return { tier: "Local", group: "County Legislators" };
}

// Phase 73 fix — add "commission":
if (hasAny(title, ["commissioner", "commission", "supervisor", "council"])) {
  return { tier: "Local", group: "County Legislators" };
}
```

**Side-effect check:** "commission" appears in `BODY_AGENCY` (line 46) and in LOCAL branch's `hasAny(chamber, ["board of supervisors", "county council", "county commission"])` check. Neither is affected because COUNTY branch runs before LOCAL branch and the `title` check (not chamber) is what's being modified.

**DATA-03 requirement:** Since this fix does NOT introduce a new group key (Commissioners continue to route to "County Legislators"), the three consumer structures do NOT need new entries. They already contain "County Legislators". DATA-03 is satisfied by verifying the existing entries in `LOCAL_ORDER`, `CATEGORY_DISPLAY_NAMES`, and `GROUP_SORT_OPTIONS` are present and consistent.

### Pattern: OfficialOut struct extension

Two new fields must be added to `OfficialOut` in handlers.go and to both raw query `row` structs inside `fetchOfficialsFromDB` and `fetchFederalAndStateFromDBFiltered`:

```go
// Add to OfficialOut struct (handlers.go ~line 162):
GovernmentBodyName string `json:"government_body_name,omitempty"`
GovernmentBodyURL  string `json:"government_body_url,omitempty"`

// Add to both inner `row` structs in fetch functions:
GovernmentBodyName string
GovernmentBodyURL  string

// Add to both OfficialOut construction blocks:
GovernmentBodyName: r.GovernmentBodyName,
GovernmentBodyURL:  r.GovernmentBodyURL,
```

### Recommended Project Structure (no new files needed)

No new Go files are required. All changes fit within existing files:

```
EV-Backend/internal/essentials/
├── models.go          -- ADD GovernmentBody struct + TableName()
├── setup.go           -- ADD &GovernmentBody{} to AutoMigrate list
├── handlers.go        -- ADD 2 fields to OfficialOut, both row structs,
│                         both SELECT clauses, both LEFT JOINs,
│                         both OfficialOut construction blocks
essentials/src/
├── lib/classify.js    -- ADD "commission" to COUNTY keyword list
├── utils/sorters.js   -- VERIFY existing "County Legislators" entries present
```

### Anti-Patterns to Avoid

- **Adding GovernmentBody JOIN to only one fetch function:** Both `fetchOfficialsFromDB` and `fetchFederalAndStateFromDBFiltered` must be updated. Missed updates mean ZIP-code searches return body data but address searches (SearchPoliticians) do not, or vice versa.
- **Using GORM query builder for the enrichment JOIN:** The existing fetch functions use raw SQL. Mixing GORM ORM `.Find()` with raw SQL `db.DB.Raw()` would require refactoring. Follow the existing raw SQL pattern.
- **Seeding government_bodies rows only for geo_id '18105':** Monroe County Council district members use geo_id '1810500001' through '1810500004'. All must have matching government_bodies rows or those officials will return empty body name/URL.
- **Updating classify.js without verifying sorters.js:** DATA-03 requires atomic update. Even if no new group key is added, the PR must touch both files or explicitly verify both files contain "County Legislators" consistently.
- **Setting website_url to NULL instead of empty string:** The COALESCE in the SELECT uses `COALESCE(gb.website_url, '')`. If the column is NOT NULL with default '', this is fine. If the column is nullable, COALESCE handles it. Either way, the OfficialOut field should be empty string (not null) when absent — the `omitempty` tag on the JSON field drops it from response when empty.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Body name derivation at query time | CASE WHEN logic in SELECT to derive display name from chamber_name | GovernmentBody table with explicit display_name column | PositionDescription precedent; display names need overrides (e.g., "Bloomington Common Council" not "Bloomington City Common Council") |
| body_key computed in Go code | A Go function that strips district suffix from chamber_name at runtime | SQL UPDATE to populate chamber_name_formal canonical values | Ensures body_key is stable, testable, and visible in DB; avoids per-request string manipulation |
| Multi-geo_id fan-out in Go | Go-side loop to look up government body for all geo_ids of a council | Multiple database rows (one per geo_id + body_key combination) | Simpler; LEFT JOIN naturally handles it; consistent with TIGER geofence structure |

**Key insight:** The GovernmentBody table is a lookup table, not a computed view. Display names should be editable by hand, which requires a real row rather than derived data.

## Common Pitfalls

### Pitfall 1: Forgetting the fetchFederalAndStateFromDBFiltered duplicate
**What goes wrong:** Developer updates `fetchOfficialsFromDB` (the ZIP/address search path) but misses `fetchFederalAndStateFromDBFiltered` (the federal+state fallback path). Federal officials — and any state/national officials returned via the fallback — won't have government_body_name populated.
**How to avoid:** Search handlers.go for `type row struct` — there are exactly two occurrences. Both must receive the same field additions.
**Warning signs:** government_body_name is present in ZIP search results but absent in address search fallback results.

### Pitfall 2: chamber_name_formal UPDATE affecting wrong chambers
**What goes wrong:** A broad UPDATE pattern like `WHERE name LIKE '%Commission%'` might match federal or state "commission" chambers that should not receive an Indiana-specific canonical name.
**How to avoid:** Scope the UPDATE with `WHERE name LIKE 'Monroe County Commission%'` (precise prefix) or join through districts to `WHERE d.state = '18'`. Verify row count before committing.
**Warning signs:** Non-Indiana chambers suddenly have incorrect name_formal values.

### Pitfall 3: geo_id type mismatch in JOIN
**What goes wrong:** `government_bodies.geo_id` stored as TEXT and `districts.geo_id` stored as TEXT — these should JOIN cleanly. But if government_bodies uses a different type (e.g., VARCHAR(20) with GORM size tag), a cast mismatch could silently prevent matches.
**How to avoid:** Define `GeoID string` in the GORM struct (maps to TEXT); avoid size annotations. The existing District model uses `GeoID string` without size tag.

### Pitfall 4: "commission" keyword matching unintended federal entries
**What goes wrong:** Adding "commission" to the COUNTY branch `hasAny(title, [...])` list — but the COUNTY branch only runs when `dt === "COUNTY"`, so federal agencies (NATIONAL_EXEC, STATE_EXEC) are unaffected. However, testing locally on a broader dataset should verify no unexpected COUNTY officials are now reclassified.
**How to avoid:** After the fix, run `classifyCategory()` against all Monroe County + Bloomington officials from the Phase 72 regression table and verify all 82 expected groups remain correct.

### Pitfall 5: DATA-03 partial update (classify.js updated, sorters.js not verified)
**What goes wrong:** Developer updates classify.js COUNTY branch but assumes sorters.js needs no change since "County Legislators" already exists. The commit goes through without verifying GROUP_SORT_OPTIONS has a "County Legislators" entry.
**How to avoid:** Confirm `GROUP_SORT_OPTIONS["County Legislators"]` exists in sorters.js (it does — lines 322-338). The verification task should include a grep check to confirm all three structures contain the key.

## Code Examples

### GovernmentBody Model (new struct in models.go)
```go
// models.go — add after PositionDescription (line ~273)
// GovernmentBody stores display names and website URLs for government bodies,
// keyed by (state, geo_id, body_key). The body_key matches COALESCE(chamber.name_formal, chamber.name).
// Seeded manually; website_url may be empty until Phase 74.
type GovernmentBody struct {
    ID          uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    State       string    `json:"state" gorm:"uniqueIndex:idx_gov_body_lookup;not null"`
    GeoID       string    `json:"geo_id" gorm:"uniqueIndex:idx_gov_body_lookup;not null"`
    BodyKey     string    `json:"body_key" gorm:"uniqueIndex:idx_gov_body_lookup;not null"`
    DisplayName string    `json:"display_name" gorm:"not null"`
    WebsiteURL  string    `json:"website_url"` // empty string when URL not yet seeded
}

func (GovernmentBody) TableName() string {
    return "essentials.government_bodies"
}
```

### setup.go addition
```go
// setup.go AutoMigrate list — add after PositionDescription:
&GovernmentBody{},
```

### LEFT JOIN addition (same pattern in both fetch functions)
```sql
-- Add to both SELECT clauses (after existing COALESCE lines):
COALESCE(gb.display_name, '') AS government_body_name,
COALESCE(gb.website_url, '') AS government_body_url,

-- Add to both FROM/JOIN blocks (after government LEFT JOIN):
LEFT JOIN essentials.government_bodies gb
  ON gb.state = d.state
  AND gb.geo_id = d.geo_id
  AND gb.body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')
```

### classify.js COUNTY branch fix
```javascript
// classify.js line ~197 — change:
if (hasAny(title, ["commissioner", "supervisor", "council"])) {

// to:
if (hasAny(title, ["commissioner", "commission", "supervisor", "council"])) {
```

### Regression verification (manual test after classify.js fix)
Expected outcomes for all 82 Monroe County + Bloomington officials (from Phase 72 FINDINGS.md):
- Monroe County Commission - District 1/2/3: NOW "County Legislators" (was "County Officials")
- Monroe County Council - At Large / District 1-4: "County Legislators" (unchanged)
- Monroe County Sheriff/Assessor/Auditor/etc.: "County Officials" (unchanged)
- Bloomington City Common Council members: "City Council" (unchanged)
- Township boards/trustees: "Township Officials" (unchanged)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| governments table for body names | New government_bodies table keyed by (state, geo_id, body_key) | Phase 73 | governments table is empty for Indiana (confirmed Phase 72); new table is purpose-built for lookup |
| chamber_name_formal empty for BallotReady data | Populated via UPDATE migration | Phase 73 | Enables body_key grouping across per-district chambers |
| Monroe County Commissioners in "County Officials" | Moved to "County Legislators" via classify.js fix | Phase 73 | Semantically correct: Commissioners are the county legislative body |

**Deprecated/outdated:**
- Using `essentials.governments` for Indiana body names: confirmed empty for Indiana in Phase 72; not a viable source for body display names at this time.

## Open Questions

1. **Should government_bodies rows be seeded for single-official offices (Sheriff, Assessor)?**
   - What we know: These offices currently return empty government_body_name (no matching row). The LEFT JOIN returns NULL → COALESCE → ''.
   - What's unclear: Whether Phase 76 (section headings) needs a government_body_name for individual COUNTY offices or just for multi-member bodies.
   - Recommendation: Do not seed them in Phase 73. Phase 76 can seed individual offices if needed. Keep Phase 73 minimal.

2. **Should the classify.js fix introduce a new "County Commissioners" group distinct from "County Legislators"?**
   - What we know: DATA-02 says "routes commissioner title keywords to distinct County Commissioners group." But Phase 72 confirmed Commissioners already land in different group from Council (County Officials vs County Legislators). The fix routes them to "County Legislators" not a new group.
   - What's unclear: Whether DATA-02 means a brand-new group key "County Commissioners" or just "correctly separated from County Officials."
   - Recommendation: Route to existing "County Legislators" key — no new group key. BODY-02 (distinct sections) is a Phase 76 concern using government_body_name for sub-grouping, not a classify.js group key concern. If DATA-02 requires a genuinely new group key, DATA-03 demands all three consumer structures (LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS) be updated atomically in the same commit.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — no automated test suite exists for this codebase |
| Config file | none |
| Quick run command | `cd EV-Backend && go build -o server . && echo "build OK"` |
| Full suite command | Manual: psql queries to verify migration + curl against running server |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LINK-02 | government_bodies table exists with correct columns | manual-smoke | `psql $DATABASE_URL -c "\d essentials.government_bodies"` | N/A — runs post-migration |
| LINK-02 | SearchPoliticians returns government_body_name + government_body_url fields | manual-smoke | `curl -s -X POST https://api.empowered.vote/essentials/address -d '{"query":"Monroe County IN"}' | jq '.[0].government_body_name'` | N/A |
| LINK-02 | NULL-safe: officials without a matching government_body row return empty string not null | manual-smoke | Check an individual county official (Sheriff) in response — field should be `""` or absent | N/A |
| DATA-02 | Monroe County Commissioners land in "County Legislators" | manual-smoke | Confirm via classify.js trace with title "Monroe County Commission - District 1" | N/A |
| DATA-03 | All three structures contain "County Legislators" consistently | manual-code-review | `grep -n "County Legislators" essentials/src/lib/classify.js essentials/src/utils/sorters.js` | ❌ — run after fix |

### Sampling Rate
- **Per task commit:** `go build -o server .` in EV-Backend directory (catches Go compilation errors)
- **Phase gate:** Manual curl test against running server confirming government_body_name in response before proceeding to Phase 74

### Wave 0 Gaps
None — no test infrastructure is needed. All validation is manual SQL queries and curl. The build command `go build` provides sufficient Go compilation verification.

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/72-db-audit/72-FINDINGS.md` — Phase 72 DB audit: all Monroe County/Bloomington chamber names, district types, group classifications, regression mapping table
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — GovernmentBody model pattern (PositionDescription at line 273, Chamber at line 80); TableName() convention
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — AutoMigrate call structure; where to add new model
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — OfficialOut struct (line 162), fetchOfficialsFromDB raw SQL (line 1119), fetchFederalAndStateFromDBFiltered raw SQL (line 1442), PositionDescription LEFT JOIN pattern (lines 1219-1224)
- `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/classify.js` — COUNTY branch (lines 196-207), existing group keys, LOCAL_ORDER, CATEGORY_DISPLAY_NAMES
- `/Users/chrisandrews/Documents/GitHub/essentials/src/utils/sorters.js` — GROUP_SORT_OPTIONS (lines 112-387); "County Legislators" entry confirmed at lines 322-338
- `/Users/chrisandrews/Documents/GitHub/.planning/REQUIREMENTS.md` — LINK-02, DATA-02, DATA-03 definitions
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — Key decisions: GovernmentBody composite unique (state, geo_id, body_key); body_key from classify.go; LOCAL_ORDER/CATEGORY_DISPLAY_NAMES/GROUP_SORT_OPTIONS atomic update rule

### Secondary (MEDIUM confidence)
- STATE.md decision: "body_key derived by classify.go (Go mirror of classify.js)" — no classify.go file exists yet; this means Phase 73 creates the body_key via SQL UPDATE to chamber_name_formal rather than a separate Go file (simpler and consistent with findings)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools already in use in the project
- Architecture patterns (GovernmentBody model, JOIN structure): HIGH — direct precedent from PositionDescription pattern in existing code
- chamber_name_formal migration SQL: HIGH — exact chamber names from Phase 72 FINDINGS.md
- classify.js fix: HIGH — "commission" vs "commissioner" confirmed by Node.js trace in Phase 72
- geo_id multi-row requirement for Council districts: HIGH — Phase 72 confirmed geo_ids 1810500001-1810500004

**Research date:** 2026-03-11
**Valid until:** Until Phase 73 plan is created (immediately consumed); underlying data is stable until Phase 74 seeding
