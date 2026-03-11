# Stack Research — v2026.3.3 Local Government Organization

**Domain:** Local government organization display — specific body names, website links, state-specific structures
**Researched:** 2026-03-10
**Confidence:** HIGH

---

## Scope

This milestone is a **display and data-modeling** change, not an infrastructure or framework change. The existing validated stack (Go 1.24.3/Chi/GORM/PostgreSQL, React 19/Vite/Tailwind CSS 4, PostGIS, Supabase, ev-ui 0.1.40) is unchanged. Research covers only the new capabilities needed.

**What this milestone needs:**
1. A new database table to store specific body names and website URLs per governing body
2. A JOIN extension in two existing SQL queries
3. Two new fields on the existing `OfficialOut` response struct
4. A `websiteUrl` prop on the existing `CategorySection` ev-ui component
5. Admin CRUD endpoints for curating the new table (following existing pattern)

---

## Recommended Stack

### Core Technologies

All existing. No new frameworks or languages.

| Technology | Current Version | Role in This Milestone |
|------------|----------------|------------------------|
| Go / GORM | 1.24.3 | Add `GovernmentBody` model; AutoMigrate; extend `OfficialOut`; LEFT JOIN in existing queries |
| PostgreSQL / Supabase | existing | Store `essentials.government_bodies` table; no schema changes to existing tables |
| React 19 | existing | Read `body_display_name`/`body_website_url` from API response; pass to `CategorySection` |
| ev-ui | 0.1.40 | Add optional `websiteUrl` prop to `CategorySection`; publish 0.1.41 |

---

### New Data Model: `essentials.government_bodies`

The core gap is that neither `essentials.chambers` nor `essentials.governments` has a `website_url` field or a "specific display name" concept:

- `Chamber` has `name_formal` and `name` but no URL; it is Cicero-synced with an `external_id` — adding fields risks import conflicts
- `Government` has `name`, `type`, `state`, `city` but no URL and no display name concept
- Neither table has a clean per-region curation path

The right approach is a **new lookup table** keyed on `chamber_name_formal` (already present in `OfficialOut`). This is the exact same pattern as the existing `PositionDescription` table, which enriches positions by `normalized_position_name` without touching the import pipeline.

**New Go model:**

```go
// GovernmentBody stores curated display names and website URLs for specific governing bodies.
// Keyed on chamber_name_formal (from essentials.chambers) to avoid touching Cicero-synced tables.
// State-scoped to prevent key collisions across regions (e.g. two states both having "City Council").
type GovernmentBody struct {
    ID          uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    BodyKey     string    `json:"body_key" gorm:"uniqueIndex:idx_govbody_key;not null"` // matches chamber_name_formal
    State       string    `json:"state" gorm:"uniqueIndex:idx_govbody_key;not null"`    // "IN", "CA", "" for national
    DisplayName string    `json:"display_name"`   // e.g. "Monroe County Council"
    WebsiteURL  string    `json:"website_url"`    // e.g. "https://monroecounty.gov/dept/council/"
    Notes       string    `json:"notes,omitempty"` // Internal — not exposed in API
}

func (GovernmentBody) TableName() string { return "essentials.government_bodies" }
```

Why `BodyKey = chamber_name_formal`: This field is already present in `OfficialOut` and populated in the JOIN queries. It is the lowest-friction lookup key — no UUID resolution required when seeding, and it survives Cicero re-imports because chamber names are stable.

Why `State` in the composite unique key: prevents collisions between e.g. Indiana's "Monroe County Council" and any other state that might have a body with the same formal name.

---

### API Change: Extend `OfficialOut`

Add two fields sourced from the new table:

```go
type OfficialOut struct {
    // ... all existing fields unchanged ...
    BodyDisplayName string `json:"body_display_name,omitempty"` // e.g. "Monroe County Council"
    BodyWebsiteURL  string `json:"body_website_url,omitempty"`  // e.g. "https://monroecounty.gov/dept/council/"
}
```

These are populated via a LEFT JOIN added to the raw SQL in `fetchOfficialsFromDB` and `fetchOfficialsByGeofence` (the two paths that serve `OfficialOut`):

```sql
LEFT JOIN essentials.government_bodies gb
    ON gb.body_key = c.name_formal
   AND gb.state = d.state
```

Then in the scan struct:
```go
BodyDisplayName string
BodyWebsiteURL  string
```

This is one additional LEFT JOIN per query — zero measurable latency impact. No new endpoints needed.

---

### Frontend Change: Results.jsx (essentials app)

`Results.jsx` already groups politicians by `classifyCategory()` output and renders each group via `CategorySection`. With `body_display_name` and `body_website_url` available per politician:

**Section header strategy:** All politicians in the same chamber share the same `chamber_name_formal`, so `body_display_name` and `body_website_url` are identical across the group. Take the values from the first politician in each group. This requires no new state or hooks.

```jsx
// In Results.jsx, when rendering a group:
orderedEntries(groups, LOCAL_ORDER).map(([category, polList]) => {
  const firstPol = polList[0];
  const sectionTitle = firstPol?.body_display_name || getDisplayName(category);
  const sectionUrl = firstPol?.body_website_url || null;

  return (
    <CategorySection
      key={category}
      title={sectionTitle}
      websiteUrl={sectionUrl}
    >
      {defaultSort(category, polList).map(renderPoliticianCard)}
    </CategorySection>
  );
});
```

No changes needed to:
- `classifyCategory()` in `classify.js` — classification stays district_type based
- `LOCAL_ORDER`, `STATE_ORDER`, `FEDERAL_ORDER` — ordering unchanged
- `getDisplayName()` — still used as fallback when `body_display_name` is absent
- Any politician card component or profile page

---

### ev-ui Change: CategorySection websiteUrl prop

Add an optional `websiteUrl` prop to the existing `CategorySection` component. When provided, render a small external-link icon after the title pill that opens in a new tab.

```jsx
// CategorySection.jsx — new prop, backward compatible
export default function CategorySection({ title, infoTooltip, websiteUrl, children, style = {} }) {
  // existing logic unchanged
  // add beside titlePill:
  {websiteUrl && (
    <a
      href={websiteUrl}
      target="_blank"
      rel="noopener noreferrer"
      aria-label={`Visit official ${title} website`}
      style={styles.websiteLink}
    >
      {/* small external-link SVG icon */}
    </a>
  )}
}
```

No breaking changes — `websiteUrl` is optional with `undefined` as default (no render effect). Existing callers of `CategorySection` without `websiteUrl` are unaffected.

**Version bump:** ev-ui 0.1.40 → 0.1.41

---

### Admin Endpoints: Government Body CRUD

The `government_bodies` table requires manual curation. Add CRUD endpoints following the exact pattern of the existing `position-descriptions` admin endpoints in `routes.go`:

```go
// In SetupRoutes(), under the existing admin group:
r.Get("/admin/government-bodies",       ListGovernmentBodies)
r.Post("/admin/government-bodies",      UpsertGovernmentBody)   // upsert by body_key + state
r.Delete("/admin/government-bodies/{id}", DeleteGovernmentBody)
```

These handlers follow the identical pattern as `ListPositionDescriptions`, `UpsertPositionDescription`, `DeletePositionDescription`. No new middleware, no new authentication logic.

---

## Supporting Libraries

None new. Everything needed is already in the stack.

| What | Why No New Library |
|------|-------------------|
| External link URL display | Native HTML `<a target="_blank" rel="noopener noreferrer">` |
| External link icon | Inline SVG (3-4 lines) — no icon library needed |
| State-specific body logic | Handled by DB lookup — no frontend branching code |
| Data seeding | SQL INSERT or existing Go admin endpoint |

---

## Installation

No new packages required.

```bash
# Go backend — no new go get needed
cd EV-Backend
go build -o server .   # After adding GovernmentBody model to models.go

# ev-ui — no new npm installs; version bump only
cd ev-ui
npm run build
# Update essentials to consume ^0.1.41

# essentials React app — no new npm installs
```

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| New `essentials.government_bodies` table with string `body_key` | Add `website_url` + `display_name` to `essentials.chambers` | Chambers are Cicero-synced; adding fields risks import conflicts; upsert logic would need updating to preserve manually set values |
| New `essentials.government_bodies` table | Add `website_url` to `essentials.governments` | Government table has no URL or display name concept; a single government can own multiple chambers (commissioners + council both under "Monroe County Government"); no clean per-body targeting |
| LEFT JOIN in existing queries | New `/essentials/government-bodies` endpoint + frontend fetch | Extra network round-trip on every Results page load; adds error state handling; JOIN is simpler and zero-cost |
| `body_key = chamber_name_formal` | `body_key = chamber_id UUID` | UUID key requires resolving chamber UUIDs when seeding (extra DB lookup); string key is human-readable and matches existing `OfficialOut` fields directly |
| `websiteUrl` prop on `CategorySection` | New `CategorySectionWithLink` component | Avoids component proliferation; backward-compatible optional prop is cleaner; `infoTooltip` already established the pattern of optional extras on `CategorySection` |
| Take `body_display_name` from `polList[0]` in Results.jsx | Group-level API shape `{ title, url, politicians[] }` | Group-level shape requires a new API endpoint or response restructuring; all politicians in a chamber already share the same `chamber_name_formal`, so `polList[0]` is deterministic and requires no API changes |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Modifying `essentials.chambers` for `website_url` | Chamber table is Cicero-imported; field would be overwritten on next import unless import upsert logic is updated to preserve it | New `government_bodies` lookup table with manual curation |
| Hardcoding body names/URLs in `classify.js` or `Results.jsx` | Brittle — breaks when expanding to new regions; not editable without code deployment | DB-backed lookup via LEFT JOIN |
| Separate `/government-bodies` API fetch in frontend | Extra network round-trip per page load; adds loading/error state | Embed `body_display_name`/`body_website_url` in existing `OfficialOut` response |
| Adding `websiteUrl` to `PoliticianCard` | The link is per-section (governing body), not per individual politician | Add to `CategorySection` title area only |
| New npm package for external link icon | Inline SVG is 4 lines; importing an icon library for one glyph is disproportionate | Inline SVG `<path>` for external-link arrow icon |

---

## Stack Patterns by Variant

**Indiana county with distinct commissioners + council bodies:**
- Two `GovernmentBody` rows: one for commissioners (`chamber_name_formal` of commissioner records), one for council (`chamber_name_formal` of council records)
- `classifyCategory()` already creates distinct groups ("County Executives" vs "County Legislators") because these bodies have different titles
- Each group renders with its own specific `body_display_name` and `body_website_url`
- No frontend code changes needed for this structural distinction

**Body with no DB entry yet (new regions, unsupported areas):**
- LEFT JOIN returns NULL for `body_display_name` and `body_website_url`
- Frontend fallback: `firstPol?.body_display_name || getDisplayName(category)` — existing generic names
- `websiteUrl` is `null` — `CategorySection` renders without link icon
- Zero visual regression for unsupported regions

**Expanding to new states/regions:**
- Insert rows into `essentials.government_bodies` via admin endpoint
- No frontend code changes
- No backend code changes
- The JOIN picks them up automatically on next query

**City council vs county council same page:**
- Different `chamber_name_formal` values → different `body_key` rows → each section gets correct name/URL
- Already deduped correctly by existing `byTier` logic in `Results.jsx`

---

## Version Compatibility

| Package | Current | Target | Notes |
|---------|---------|--------|-------|
| ev-ui | 0.1.40 | 0.1.41 | Add optional `websiteUrl` to `CategorySection`; backward-compatible |
| essentials (React app) | — | — | Consume ev-ui `^0.1.41`; update `Results.jsx` to pass new props |
| EV-Backend | Go 1.24.3 | unchanged | Add `GovernmentBody` model; extend `OfficialOut`; extend JOIN in queries |
| Supabase PostgreSQL | existing | unchanged | AutoMigrate creates `essentials.government_bodies`; no manual migration |

---

## Data Seeding Plan

The `government_bodies` table is populated manually (not via import pipelines). For the Indiana v2026.3.3 launch:

**Seeding method:** SQL INSERT during development, or via admin API endpoint after deploy.

**Critical step before seeding:** Verify exact `chamber_name_formal` values from the DB for Monroe County and Bloomington records:

```sql
SELECT DISTINCT c.name_formal, g.name, d.state
FROM essentials.chambers c
JOIN essentials.governments g ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.state = 'IN'
ORDER BY g.name, c.name_formal;
```

Use the exact `name_formal` strings from that query as `body_key` values. Do not guess the strings — a mismatch means the JOIN silently returns NULL.

---

## Sources

- `GovernmentBody` pattern modeled on existing `PositionDescription` — HIGH confidence (read directly from EV-Backend/internal/essentials/models.go)
- `OfficialOut` struct and SQL query structure — HIGH confidence (read directly from EV-Backend/internal/essentials/handlers.go lines 162-214)
- `CategorySection` component API — HIGH confidence (read directly from ev-ui/src/CategorySection.jsx)
- ev-ui current version 0.1.40 — HIGH confidence (read from ev-ui/package.json)
- essentials consumes `@chrisandrewsedu/ev-ui ^0.1.40` — HIGH confidence (read from essentials/package.json)
- Indiana county dual-body structure (commissioners + council) — MEDIUM confidence ([NACo Indiana County Overview PDF](https://www.naco.org/sites/default/files/event_attachments/DRAFT_Indiana_012022.pdf), [Indiana County Commissioners Association](https://www.indianacountycommissioners.com/what-is-a-county-commissioner))
- No `website_url` on `Chamber` or `Government` tables — HIGH confidence (read from models.go; confirmed absence)

---
*Stack research for: v2026.3.3 Local Government Organization — specific body names and website links*
*Researched: 2026-03-10*
