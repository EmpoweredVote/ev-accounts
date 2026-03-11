# Architecture Research

**Domain:** Civic tech — local government organization features for existing Essentials app
**Researched:** 2026-03-10
**Confidence:** HIGH (all based on direct codebase inspection)

## Context: Subsequent Milestone

This is an integration-focused architecture document for v2026.3.3. It describes how new local government organization features plug into the existing Go + React system. No new frameworks, schemas, or services are being added — the question is precisely *where* new code lives and *what existing code changes*.

---

## System Overview

The current architecture that this milestone touches:

```
+------------------------------------------------------------------+
|                   React Frontend (essentials)                     |
|                                                                   |
|  Results.jsx --> classifyCategory() --> CategorySection[title]    |
|      |                |                        |                  |
|      |           classify.js              ev-ui component         |
|      |         (pure, stateless)        (just renders title)      |
|      |                                                            |
|  usePoliticianData() --> POST /essentials/politicians/search      |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                  Go Backend (EV-Backend)                          |
|                                                                   |
|  POST /essentials/politicians/search                              |
|       |                                                           |
|       v                                                           |
|  geofence_lookup.go --> FindGeoIDsByPoint                         |
|       |                  FindPoliticiansByGeoMatches              |
|       |                                                           |
|       v                                                           |
|  OfficialOut struct --> JSON response                             |
|  (includes: chamber_name, office_title, district_type,            |
|   government_name, district_id, representing_city/state)          |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                    PostgreSQL (Supabase)                           |
|                                                                   |
|  essentials.chambers      -- name, name_formal                    |
|  essentials.districts     -- district_type, state, city           |
|  essentials.offices       -- title, representing_city/state       |
|  essentials.politicians   -- first_name, last_name                |
|  essentials.geofences     -- PostGIS boundaries                   |
+------------------------------------------------------------------+
```

### What Changes in This Milestone

The milestone adds one new concept: **government body metadata** — specific names and website URLs for each legislative body, keyed so they can be looked up from the frontend classifier output.

The data flow change is minimal. The classifier already groups politicians by body type (e.g., "County Legislators"). The gap is:

1. That group label is generic ("County Legislators"), not specific ("Monroe County Council")
2. There is no website URL attached to the section header

Everything else (geofence lookup, politician cards, profile pages, building photos) is unchanged.

---

## New Data Model: `essentials.government_bodies`

This is the only new backend table. It stores the specific name and website URL for a government body, keyed by the combination of attributes that uniquely identify it.

### Table Design

```sql
CREATE TABLE essentials.government_bodies (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state       TEXT NOT NULL,           -- "IN", "CA"
    geo_id      TEXT NOT NULL,           -- TIGER GEO_ID of the jurisdiction
                                         -- (county FIPS, city FIPS, etc.)
    body_key    TEXT NOT NULL,           -- classifier category key, e.g.
                                         -- "County Legislators", "City Council"
    body_name   TEXT NOT NULL,           -- "Monroe County Council"
    website_url TEXT,                    -- "https://monroecounty.gov/council"
    seat_count  INT,                     -- optional: 7 for council, 3 for commission
    notes       TEXT,                    -- optional: free-form operational notes
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (state, geo_id, body_key)
);
```

**Key design decisions:**

- `geo_id` uses the existing TIGER GEO_ID already stored on `essentials.geofences` and `essentials.districts` — no new geographic key system needed
- `body_key` mirrors the `classifyCategory()` group strings used in classify.js — this is the join point between backend data and frontend classifier output
- The unique constraint `(state, geo_id, body_key)` means one row per body per jurisdiction — upsert-safe
- No FK to `essentials.chambers` or `essentials.districts` — those tables have stale data from BallotReady that does not always match real geography; `geo_id` is the reliable key

### GORM Model (Go)

New struct in `internal/essentials/models.go`:

```go
type GovernmentBody struct {
    ID         uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    State      string     `json:"state" gorm:"uniqueIndex:idx_gov_body_lookup"`
    GeoID      string     `json:"geo_id" gorm:"uniqueIndex:idx_gov_body_lookup"`
    BodyKey    string     `json:"body_key" gorm:"uniqueIndex:idx_gov_body_lookup"`
    BodyName   string     `json:"body_name"`
    WebsiteURL string     `json:"website_url,omitempty"`
    SeatCount  *int       `json:"seat_count,omitempty"`
    Notes      string     `json:"notes,omitempty"`
    CreatedAt  time.Time  `json:"created_at"`
    UpdatedAt  time.Time  `json:"updated_at"`
}

func (GovernmentBody) TableName() string {
    return "essentials.government_bodies"
}
```

---

## Backend Integration Points

### Modified: `OfficialOut` struct (handlers.go)

The search response struct needs two new optional fields. These are populated when the backend resolves a `government_bodies` row for the politician's jurisdiction.

```go
// Add to OfficialOut:
GovernmentBodyName string `json:"government_body_name,omitempty"` // "Monroe County Council"
GovernmentBodyURL  string `json:"government_body_url,omitempty"`  // "https://..."
```

These fields are optional. Politicians in jurisdictions without a `government_bodies` entry get empty strings, and the frontend falls back to the existing generic display — zero behavioral change for unsupported areas.

### Modified: Search handler — batch join against `government_bodies`

After fetching the politician list via geofence lookup, join against `essentials.government_bodies` to attach body name and URL. This must be a batch join (not N+1):

1. Derive `(state, geo_id, body_key)` tuples from the result set
2. Query `government_bodies` once for all matching tuples
3. Build an in-memory map: `(geo_id, body_key) -> GovernmentBody`
4. Annotate each `OfficialOut` from the map

The `body_key` for the join is derived by running each politician's `district_type`, `chamber_name`, and `office_title` through the same classification logic as the frontend. This logic is a small set of switch cases — straightforward to replicate in Go.

**Option A (recommended):** Implement a `classifyBodyKey(districtType, chamberName, officeTitle string) string` pure function in a new file `classify.go` within `internal/essentials/`. This mirrors classify.js and produces the body_key for the DB lookup.

**Option B:** Store `body_key` directly on politician records. Fragile — requires data migration and keeps a computed value in the database.

Option A is preferred: the classification function is small, the logic is already well-defined in classify.js, and keeping it in Go means the body lookup requires no extra frontend round-trip.

### New endpoint: `GET /essentials/government-bodies` (optional, low priority)

For admin/tooling use. The OfficialOut embedding is sufficient for the frontend and is the primary delivery mechanism this milestone.

---

## Frontend Integration Points

### No changes to `classify.js` core logic (most likely)

Classification continues to produce group strings like "County Legislators", "City Council". The specific body name comes from the backend data, not frontend logic.

**Possible exception:** If Monroe County commissioners and council members currently map to the same `classifyCategory()` group key (both becoming "County Legislators"), then `classify.js` needs a split to create distinct group keys. Whether this is needed depends on the actual `chamber_name` and `office_title` values in the database — must be verified before writing any code (see Build Order step 1).

If a split is needed, the new group keys follow the same pattern as existing keys:

```js
// In the dt === "COUNTY" block:
if (hasAny(chamber, ["county council"])) return { tier: "Local", group: "County Council" };
if (hasAny(title, ["commissioner"])) return { tier: "Local", group: "County Commissioners" };
```

Then add those keys to `LOCAL_ORDER` and `CATEGORY_DISPLAY_NAMES`.

### Modified: `Results.jsx` — section headers with specific names and links

When rendering a group's politicians, derive the section title and URL from the OfficialOut data rather than only from `getDisplayName(category)`:

```js
// In the orderedEntries(...).map() loop (Local tier rendering):
const bodyName = polList.find(p => p.government_body_name)?.government_body_name;
const bodyURL  = polList.find(p => p.government_body_url)?.government_body_url;
const sectionTitle = bodyName || getDisplayName(category);
```

The `bodyURL` is passed to `CategorySection` as a new optional `titleHref` prop.

This change is purely additive. Jurisdictions without `government_bodies` data display identically to today because `bodyName` will be undefined and the fallback to `getDisplayName(category)` fires.

### Modified: `ev-ui` — `CategorySection` component

Add an optional `titleHref` prop. When present, the section title renders as an anchor tag linking to the government body website.

```jsx
function CategorySection({ title, titleHref, children }) {
  const heading = titleHref
    ? <a href={titleHref} target="_blank" rel="noopener noreferrer">{title}</a>
    : <span>{title}</span>;
  // ...
}
```

This is the only ev-ui change this milestone. It requires a minor version bump and publish to the GitHub npm registry before the essentials frontend can consume it.

---

## Data Flow: Before and After

### Before (current)

```
Search response --> OfficialOut[] --> classifyCategory(pol)
                                            |
                                            v
                               group = "County Legislators"
                                            |
                                            v
                               getDisplayName("County Legislators")
                               = "County Board"  <-- generic label
                                            |
                                            v
                               CategorySection title="County Board"
                               (no link)
```

### After (this milestone)

```
Search response --> OfficialOut[]
(+ government_body_name, government_body_url)
                          |
                          v
                   classifyCategory(pol)
                          |
                          v
                   group = "County Legislators"
                          |
                          v
                   polList.find(p => p.government_body_name)
                          |
              +-----------+----------------------------+
              | found                                   | not found
              v                                         v
     "Monroe County Council"              getDisplayName("County Legislators")
     + website URL                        = "County Board" (unchanged fallback)
              |
              v
     CategorySection
     title="Monroe County Council"
     titleHref="https://monroecounty.gov/council"
```

The change is purely additive. Jurisdictions without `government_bodies` data display identically to today.

---

## State-Specific Configuration: Indiana County Structure

### The Problem

Indiana counties have two distinct bodies that currently map to the same classifier group:

- **County Commissioners** (3 elected, executive/administrative role)
- **County Council** (7 members, budget/fiscal role — mix of at-large and district seats)

The goal is to display them as distinct sections with distinct names and links.

### Solution Path

**Step 1 (data verification):** Query Monroe County politicians' `chamber_name` and `office_title` values to determine if commissioners and council members already produce distinct classifier outputs. If `chamber_name = "Monroe County Council"` for council members and `chamber_name = "Monroe County Board of Commissioners"` for commissioners, the existing string-matching in `classifyCategory()` may already route them to different groups via the chamber name checks. If both map to the same group key, the fix is a targeted addition to the `dt === "COUNTY"` block in classify.js (see Frontend Integration section above).

**Step 2 (database rows):** Add two rows to `essentials.government_bodies` for Monroe County:

```sql
-- geo_id = TIGER FIPS for Monroe County, IN = "18105"
INSERT INTO essentials.government_bodies (state, geo_id, body_key, body_name, website_url, seat_count)
VALUES
  ('IN', '18105', 'County Commissioners', 'Monroe County Commissioners',
   'https://monroecounty.gov/commissioners', 3),
  ('IN', '18105', 'County Council', 'Monroe County Council',
   'https://monroecounty.gov/council', 7);
```

**At-large vs. district seat distinction:** The existing dash-split pattern in `Results.jsx` already handles this:

```js
// "Monroe County Council - At Large" --> title: "Monroe County Council", subtitle: "At Large"
// "Monroe County Council - District 4" --> title: "Monroe County Council", subtitle: "District 4"
```

If Monroe County office_title values follow this convention, no additional code is needed for the at-large/district distinction on cards. Verify actual `office_title` values in the database.

---

## Component Responsibilities (Updated)

| Component | Responsibility | Status |
|-----------|---------------|--------|
| `essentials.government_bodies` table | Body-specific names and URLs | NEW |
| `GovernmentBody` GORM model | DB access layer | NEW in models.go |
| `classify.go` (Go) | Server-side body_key derivation | NEW file |
| `SearchPoliticians` handler | Batch join, annotate OfficialOut | MODIFIED |
| `OfficialOut` struct | Add 2 optional response fields | MODIFIED |
| `classify.js` | May need county council/commissioners split | MODIFIED (conditional) |
| `Results.jsx` | Derive sectionTitle and sectionURL per group | MODIFIED |
| `CategorySection` (ev-ui) | Optional titleHref prop | MODIFIED + version bump |

---

## Build Order (Dependency-Ordered)

**Step 1 — Verify data first.** Query Monroe County politician records for actual `chamber_name` and `office_title` values. Determine whether commissioners and council members produce distinct classify group keys with current data. This finding gates whether classify.js needs changes and what body_key values to use for the government_bodies seed data.

**Step 2 — New DB table and GORM model.** Add `GovernmentBody` struct to `models.go`. Add to `setup.go` AutoMigrate call. Deploy backend to get the table created.

**Step 3 — Seed Monroe County data.** Insert rows via SQL for Monroe County Commissioners and Monroe County Council. Confirm the geo_id (Monroe County IN FIPS = 18105). This is the data the rest of the feature depends on.

**Step 4 — classify.go in Go.** Implement `classifyBodyKey()` pure function. Write a unit test against the district_type/chamber_name/office_title values observed in Step 1.

**Step 5 — SearchPoliticians handler changes.** Batch join against government_bodies post-geofence lookup. Annotate OfficialOut. Return new fields in search response.

**Step 6 — classify.js changes (if needed).** If Step 1 showed both body types hit the same group key, add the split to classify.js. Update LOCAL_ORDER and CATEGORY_DISPLAY_NAMES.

**Step 7 — ev-ui CategorySection update.** Add `titleHref` prop. Publish new minor version to GitHub npm registry.

**Step 8 — Results.jsx changes.** Add body name + URL derivation per group. Consume updated ev-ui version.

**Step 9 — Seed additional jurisdictions.** Add rows for Bloomington city bodies and LA County bodies. Each body is one INSERT.

Steps 2-4 can run in parallel. Step 5 depends on Step 4. Steps 7-8 can run in parallel with Steps 4-5. Step 9 can run anytime after Step 2.

---

## Scaling Considerations

This feature is data-light. The `government_bodies` table will have at most a few thousand rows at statewide coverage (92 Indiana counties times ~4 bodies plus LA County cities times ~3 bodies).

| Scale | Approach |
|-------|----------|
| Current (Monroe County + LA County) | Direct GORM join in search handler; no caching needed |
| Indiana statewide (92 counties) | Same approach; ~460 rows; no architectural change |
| Multi-state expansion | Load government_bodies into a warm in-memory map at startup to skip the join entirely; premature for now |

---

## Anti-Patterns

### Anti-Pattern 1: Frontend-only text substitution

**What people do:** Add a hardcoded `BODY_NAME_OVERRIDES` map in classify.js or Results.jsx keyed by city/county name.

**Why it's wrong:** Brittle as coverage expands; cannot carry website URLs; duplicates data that belongs in the database; impossible to maintain across 92 Indiana counties without a massive frontend config object.

**Do this instead:** Store specific names and URLs in `essentials.government_bodies`, join server-side, embed in OfficialOut response.

### Anti-Pattern 2: Separate endpoint per body type

**What people do:** Add `GET /essentials/county-council/{geo_id}` and `GET /essentials/county-commissioners/{geo_id}` as separate endpoints.

**Why it's wrong:** Multiplies endpoints without benefit; frontend must make extra requests per section; the search response already has everything needed to annotate.

**Do this instead:** Embed body name and URL in the existing search response OfficialOut fields. One request, no extra round trips.

### Anti-Pattern 3: classify.js changes without verifying existing data

**What people do:** Split commissioners from council members in classifyCategory(), then discover both have identical chamber_name values in the database, making the split impossible without a data migration.

**Why it's wrong:** Code change is wasted if the underlying data does not support the distinction.

**Do this instead:** Query actual Monroe County politician records first. Write the classify.js change to match what the data actually contains.

### Anti-Pattern 4: ev-ui scope creep on CategorySection

**What people do:** Use this milestone to redesign CategorySection with icons, collapsible sections, member counts, and other new features.

**Why it's wrong:** Delays the milestone; ev-ui publish cycle is a real dependency that blocks frontend deployment; the section link is the only new user-visible change needed.

**Do this instead:** Single minimal prop addition (titleHref). Ship the minimal ev-ui change. Defer visual redesign.

---

## Integration Points Summary

| Boundary | Communication | Notes |
|----------|---------------|-------|
| SearchPoliticians handler -> government_bodies | Batch GORM query | Happens after geofence lookup, before JSON serialization |
| OfficialOut -> Results.jsx | JSON fields government_body_name, government_body_url | Optional; empty string triggers fallback to generic label |
| Results.jsx -> CategorySection | New titleHref prop | Requires ev-ui minor version bump and publish |
| classify.js -> classify.go | Mirrored classification logic | Go version used server-side for body_key derivation; keep in sync |
| government_bodies.geo_id -> geofences.geo_id | Shared TIGER GEO_ID | Same identifier already on geofences and districts tables |

---

## Sources

- Direct inspection of `essentials/src/lib/classify.js` — full classification logic, existing group keys, LOCAL_ORDER, CATEGORY_DISPLAY_NAMES
- Direct inspection of `essentials/src/pages/Results.jsx` — rendering pipeline, CategorySection usage, dash-split title pattern, qualifyLocalTitle function
- Direct inspection of `EV-Backend/internal/essentials/models.go` — all existing GORM models, table naming conventions
- Direct inspection of `EV-Backend/internal/essentials/routes.go` — existing endpoint surface, admin middleware pattern
- Direct inspection of `EV-Backend/internal/essentials/geofence_lookup.go` — geo_id / MTFCC structure, district type mapping, OfficialOut composition
- Direct inspection of `.planning/PROJECT.md` — milestone scope, active feature requirements, out-of-scope boundaries

---

*Architecture research for: v2026.3.3 Local Government Organization*
*Researched: 2026-03-10*
