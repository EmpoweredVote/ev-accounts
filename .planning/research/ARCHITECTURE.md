# Architecture Research

**Domain:** Treasury Tracker Expansion — Multi-jurisdiction budget visualization
**Researched:** 2026-03-22
**Confidence:** HIGH (based on direct codebase inspection of treasury-tracker, EV-Backend, and ev-ui)

---

## System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                   FRONTEND (Cloudflare Pages)                 │
│         treasury-tracker/  React 19 + Vite + Tailwind        │
├──────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────────┐   │
│  │ EntitySwitcher│  │ BudgetVisuali-│  │  DatasetTabs     │   │
│  │   (NEW)       │  │  zation (D3)  │  │ (revenue/ops/    │   │
│  └──────┬───────┘  └──────┬────────┘  │  salaries)       │   │
│         │                 │           └──────────────────┘   │
│  ┌──────▼─────────────────▼────────────────────────────────┐  │
│  │              App.tsx — State Orchestrator                │  │
│  │  selectedEntity + activeDataset + year + navigationPath  │  │
│  └──────────────────────────┬───────────────────────────────┘  │
│                             │                                  │
│  ┌──────────────────────────▼───────────────────────────────┐  │
│  │  dataLoader.ts — API-first, static JSON fallback         │  │
│  │  cache: Map<"entityType:name-year-dataset", BudgetData>  │  │
│  └──────────────────────────┬───────────────────────────────┘  │
└─────────────────────────────┼──────────────────────────────────┘
                              │ HTTPS REST
┌─────────────────────────────▼──────────────────────────────────┐
│               BACKEND (Render — api.empowered.vote)            │
│              EV-Backend Go 1.24 + Chi router + GORM            │
│                                                                │
│  /treasury/*  routes.go (public GET + admin POST)              │
│  ┌──────────────────┐  ┌───────────────┐  ┌────────────────┐  │
│  │   handlers.go    │  │   models.go   │  │   setup.go     │  │
│  │  CRUD + import   │  │  City/Budget/ │  │  AutoMigrate + │  │
│  │  + tree builder  │  │  Category/    │  │  manual SQL    │  │
│  └──────────────────┘  │  LineItem     │  └────────────────┘  │
│                        └───────────────┘                      │
└──────────────────────────────┬─────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────┐
│                  DATABASE (Supabase PostgreSQL)                 │
│                        schema: treasury                        │
│                                                                │
│  treasury.cities → treasury.budgets → treasury.budget_         │
│   (+ entity_type)    (city_id FK)      categories →           │
│                                        treasury.budget_        │
│                                        line_items              │
└────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Status for this Milestone |
|-----------|---------------|--------------------------|
| `App.tsx` | Top-level state: selected entity, dataset, year, nav path | MODIFY |
| `dataLoader.ts` | Fetch from API with static JSON fallback; in-memory cache | MODIFY |
| `EntitySwitcher.tsx` | Dropdown/pill to select city or county | NEW |
| `DatasetTabs.tsx` | Switch between Money In / Money Out / People | UNCHANGED |
| `YearSelector.tsx` | Fiscal year picker | UNCHANGED |
| `BudgetVisualization.tsx` | D3 sunburst / icicle / tree rendering | UNCHANGED |
| `CategoryList.tsx` | Drilldown list of budget categories | UNCHANGED |
| `LineItemsTable.tsx` | Leaf-level line items display | UNCHANGED |
| `SiteHeader` (ev-ui) | Shared header with auth-aware nav | UNCHANGED |

---

## Schema Changes Required

### Current Schema Constraint Issue

The `treasury.cities` table has a simple `uniqueIndex` on `name`. This works for a single-entity system but breaks when "Monroe County" (county entity) needs to coexist with "Monroe City" if one were ever added. More importantly, the table conflates conceptually different entity types — the frontend needs to know whether to label the hero card "City Finances" or "County Finances."

### Required: Add `entity_type` to `treasury.cities`

```sql
-- Step 1: Add column with default so existing rows don't break
ALTER TABLE treasury.cities
  ADD COLUMN entity_type TEXT NOT NULL DEFAULT 'city'
  CHECK (entity_type IN ('city', 'county', 'township', 'special_district'));

-- Step 2: Drop old single-field unique constraint
ALTER TABLE treasury.cities
  DROP CONSTRAINT IF EXISTS cities_name_key;

-- Step 3: Replace with composite unique on (name, state, entity_type)
ALTER TABLE treasury.cities
  ADD CONSTRAINT cities_name_state_type_unique UNIQUE (name, state, entity_type);
```

In `models.go`, update the `City` struct:

```go
type City struct {
    ID         uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
    Name       string    `gorm:"not null" json:"name"`
    State      string    `gorm:"not null" json:"state"`
    EntityType string    `gorm:"not null;default:'city'" json:"entity_type"`
    Population int       `json:"population"`
    CreatedAt  time.Time `json:"created_at"`
    UpdatedAt  time.Time `json:"updated_at"`

    Budgets []Budget `gorm:"foreignKey:CityID" json:"budgets,omitempty"`
}
```

**Note on AutoMigrate:** GORM AutoMigrate will add the `entity_type` column automatically. However, it will NOT drop the old `cities_name_key` unique constraint or add the new composite constraint. Those two SQL statements must be placed in `setup.go` as explicit `db.DB.Exec()` calls that run before AutoMigrate.

### Optional: Entity Metadata Fields

For data-driven hero cards (city hall photo, official website link):

```sql
ALTER TABLE treasury.cities
  ADD COLUMN website_url TEXT,
  ADD COLUMN hero_image_url TEXT;
```

These are low-priority. For the initial milestone, hero images can remain hardcoded per entity in App.tsx and be migrated to DB fields in a follow-on.

---

## Recommended Project Structure Changes

### Frontend (treasury-tracker/src/)

```
src/
├── components/
│   ├── entity/                    (NEW folder)
│   │   └── EntitySwitcher.tsx     (NEW — city/county picker dropdown)
│   ├── datasets/
│   │   └── DatasetTabs.tsx        (UNCHANGED)
│   ├── BudgetVisualization.tsx    (UNCHANGED)
│   ├── CategoryList.tsx           (UNCHANGED)
│   ├── YearSelector.tsx           (UNCHANGED)
│   └── ...all other components    (UNCHANGED)
├── styles/
│   └── tokens.ts                  (NEW — re-export ev-ui tokens for D3 usage)
├── data/
│   └── dataLoader.ts              (MODIFY — entity_type param, updated cache key)
├── types/
│   └── budget.ts                  (MODIFY — add entity_type to metadata interface)
└── App.tsx                        (MODIFY — selectedEntity state, EntitySwitcher, dynamic hero)
```

### Backend (EV-Backend/internal/treasury/)

```
internal/treasury/
├── models.go     (MODIFY — add EntityType field to City struct)
├── setup.go      (MODIFY — manual constraint SQL + AutoMigrate)
├── handlers.go   (MODIFY — entity_type in ImportBudget find-or-create; ListCities filter)
├── routes.go     (UNCHANGED)
└── fetcher.go    (UNCHANGED)
```

### Import Scripts (new)

```
scrapers/treasury/                     (NEW folder alongside existing scrapers/)
├── import_utils.py                    (shared: auth, POST helper, data transformer)
├── bloomington_migrate.py             (POST existing static JSON to API)
├── ellettsville_import.py             (transform source data + POST)
├── monroe_county_import.py            (transform source data + POST)
├── la_county_import.py                (transform source data + POST)
└── la_cities_import.py                (per LA city, likely loop over city list)
```

---

## Architectural Patterns

### Pattern 1: API-First with Static JSON Fallback (Existing — Keep)

**What:** `dataLoader.ts` calls `GET /treasury/budgets?city=X&year=Y&dataset=Z` first, falls back to `./data/{type}-{year}.json` in the public directory, then falls back to hardcoded mock data in `budgetData.ts`.

**Change needed for entity switcher:** The `loadBudgetData()` signature currently accepts `cityName: string`. Add `entityType: string` so the API call can include `?entity_type=county` for disambiguation. Update the cache key from `"${cityName}-${year}-${dataset}"` to `"${entityType}:${entityName}-${year}-${dataset}"` to prevent cache collisions.

The static JSON fallback only applies to Bloomington (city), since no other entities have static JSON files. When an API call for Monroe County fails, the static fallback lookup for `./data/operating-2025.json` will succeed (it's Bloomington data) — this could confuse users. Best mitigation: check `entityType === 'city' && entityName === 'Bloomington'` before attempting static JSON fallback.

**Trade-offs:** The fallback system is a safety net, not a migration path. Keep static JSON files in `public/data/` throughout this milestone.

### Pattern 2: POST /treasury/budgets/import for All Data Ingestion (Existing — Extend)

**What:** Admin-protected `POST /treasury/budgets/import` accepts a full JSON payload with nested categories and line items. Wraps insert in a transaction. Find-or-creates the city record on first import.

**Change needed:** The `ImportBudget` handler finds-or-creates city by `name + state` only. After adding `entity_type`, update the find-or-create query to include `entity_type`:

```go
// In handlers.go ImportBudget
if err := tx.Where("name = ? AND state = ? AND entity_type = ?",
    importRequest.CityName, importRequest.CityState, importRequest.EntityType).
    First(&city).Error; err != nil {
    city = City{
        Name:       importRequest.CityName,
        State:      importRequest.CityState,
        EntityType: importRequest.EntityType,
        Population: importRequest.Population,
    }
    // ...
}
```

The import request struct also needs `EntityType string` added.

**All import scripts** should POST to this endpoint rather than using direct SQL. The handler handles recursive category insertion, transaction safety, and city upsert.

### Pattern 3: EntitySwitcher as Controlled Stateless Component

**What:** `EntitySwitcher` receives the entity list from `GET /treasury/cities` (via `listEntities()` in dataLoader.ts) and the currently selected entity, and calls back with the selected entity on change. App.tsx owns all state.

**Design:** A single dropdown pill. Group entities by `entity_type` in the option list (Cities section, Counties section). Label the active entity prominently. Style with EV design tokens: teal-600 (`#005366`) for active border, `--light-gray` background, Manrope font, rounded pill shape.

**When to place:** Top of page, above DatasetTabs. The hero card city name, image, and per-resident stats update when the entity changes.

**API surface:** `GET /treasury/cities` already exists and returns all cities. It needs to include `entity_type` in its response (the field will be present after the model change). No new endpoint needed.

### Pattern 4: Design Token Integration via ev-ui tokens.js

**What:** ev-ui v0.1.53 exports `tokens.js` from `@chrisandrewsedu/ev-ui/tokens`. The treasury tracker currently hardcodes hex colors inline in component files (e.g., `#585937` in DatasetTabs, `#00657c` in index.css).

**Gap to close:**
- `treasury-tracker/src/index.css` defines CSS variables like `--muted-blue: #00657c` and `--coral: #ff5740`. These are close but not identical to ev-ui tokens (ev-ui teal is `#005366`, not `#00657c`).
- D3 chart colors in BudgetVisualization and BudgetSunburst are hardcoded category hex strings from the source JSON.
- DatasetTabs colors (`#585937`, `#00657c`, `#9d3c89`) are hardcoded inline.

**Recommended approach:**

1. Create `src/styles/tokens.ts` as a thin re-export:
   ```typescript
   export { dataVizPalette, colors, semanticTokens } from '@chrisandrewsedu/ev-ui/tokens';
   ```

2. Replace DatasetTabs color definitions with ev-ui palette references. Map the three datasets to palette entries from `dataVizPalette`:
   - Money In (revenue): Sage (`#5A9A6E`) or Olive palette shades from index.css
   - Money Out (operating): Teal (`#00647A`) — matches ev-ui teal base
   - People (salaries): Dusk (`#7C6B9E`) — replaces purple

3. Update `index.css` CSS variable values to exactly match ev-ui token values (`--muted-blue` → `#005366`, not `#00657c`). The diff is small (1 hex digit) but alignment prevents subtle color inconsistency.

4. For D3 category colors: keep them as JSON-driven hex strings in the budget data, but use `dataVizPalette` shades as the palette source when generating import data.

**Do not** try to replace D3 inline hex colors with CSS variables — D3 requires resolved hex values at render time, not CSS variable strings.

---

## Data Flow

### Current Data Flow (Single Entity — Bloomington)

```
Page Load
    ↓
App.tsx useEffect([selectedYear, activeDataset])
    ↓
loadDataset(type, year)  →  fetch ./data/{type}-{year}.json (static fallback)
    ↓
setBudgetData(data)
    ↓
BudgetVisualization + CategoryList render
```

### Target Data Flow (Multi-Entity, API-First)

```
Page Load
    ↓
listEntities()  →  GET /treasury/cities
    ↓
EntitySwitcher rendered with grouped entity list (Cities / Counties)
User selects entity (default: Bloomington, city)
    ↓
App.tsx useEffect([selectedEntity, activeDataset, selectedYear])
    ↓
loadBudgetData(year, entityName, entityType, dataset)
    ↓
  1. Check in-memory cache: key = "city:Bloomington-2025-operating"
  2. GET /treasury/budgets?city=Bloomington&year=2025&dataset=operating&entity_type=city
  3. If budget found: GET /treasury/budgets/{id}/categories
  4. Transform response → BudgetData shape
  5. Cache and return
  (Fallback only for Bloomington city: fetch ./data/operating-2025.json)
    ↓
setBudgetData(data)  →  BudgetVisualization + CategoryList render
Hero card updates: entity name, population, per-resident stat
```

### Import Pipeline Data Flow

```
Source document (PDF / Excel / CSV from city or county website)
    ↓
scrapers/treasury/{entity}_import.py
  - Download / scrape raw data
  - Transform to CategoryImport JSON structure (same shape as existing static JSON categories)
  - Authenticate: POST /auth/login → set cookie
  - POST /treasury/budgets/import  {city_name, city_state, entity_type, fiscal_year, dataset_type, categories}
    ↓
Go ImportBudget handler
  BEGIN tx
  → UPSERT treasury.cities (find-or-create by name + state + entity_type)
  → INSERT treasury.budgets
  → importCategories() recursive insert → treasury.budget_categories + treasury.budget_line_items
  COMMIT
```

### Bloomington Migration Data Flow

```
for each file in public/data/{operating,revenue,salaries}-{2021..2025}.json:
    load JSON
    extract metadata (fiscalYear, datasetType, totalBudget, hierarchy, categories)
    POST /treasury/budgets/import {
        city_name: "Bloomington", city_state: "IN", entity_type: "city",
        fiscal_year, dataset_type, total_budget, categories
    }
    verify 201 response
```

The existing `processedBudget.json` and transaction JSON files are supplementary — they can be kept as-is in `public/data/` and continue to serve the static fallback path.

---

## Integration Points: New vs Modified

| Item | New or Modified | Integration Notes |
|------|----------------|-------------------|
| `EntitySwitcher.tsx` | NEW | Calls `listEntities()` from dataLoader; controlled by App.tsx `selectedEntity` state |
| `App.tsx` state | MODIFIED | Add `selectedEntity: {id, name, state, entityType}` replacing hardcoded "Bloomington" references |
| `App.tsx` hero section | MODIFIED | Title, image, and context card driven by `selectedEntity` fields rather than hardcoded strings |
| `App.tsx` breadcrumbs | MODIFIED | First breadcrumb label uses `selectedEntity.name` instead of static "City" |
| `dataLoader.ts` `loadBudgetData()` | MODIFIED | Add `entityType` param; update cache key; pass `entity_type` to API query string |
| `dataLoader.ts` `listEntities()` | MODIFIED | Rename from `listCities()`; return `entity_type` in result shape |
| `budget.ts` `BudgetMetadata` | MODIFIED | Add `entityType?: string` field |
| `src/styles/tokens.ts` | NEW | Re-export ev-ui tokens for use in component files and D3 config |
| `DatasetTabs.tsx` colors | MODIFIED | Replace hardcoded hex with ev-ui `dataVizPalette` references |
| `index.css` CSS variables | MODIFIED | Align `--muted-blue` and `--coral` values to exact ev-ui token values |
| `treasury/models.go` `City` | MODIFIED | Add `EntityType string` field |
| `treasury/setup.go` | MODIFIED | Add manual SQL to drop old constraint and add composite unique before AutoMigrate |
| `treasury/handlers.go` `ImportBudget` | MODIFIED | Add `EntityType` to import request struct; include in find-or-create WHERE clause |
| `treasury/handlers.go` `ListCities` | MODIFIED | Returns `entity_type` field automatically after model change; optionally add `?type=` filter |
| `scrapers/treasury/` | NEW (folder) | 5 Python scripts + shared utils for data import pipeline |

---

## Build Order Rationale

The schema + backend work is the critical-path dependency. Everything downstream (frontend entity switcher, data import, design polish) unblocks after the backend changes are deployed.

**Step 1 — Backend schema + model changes (blocks all frontend work)**

Add `entity_type` to `City` model. Update `setup.go` with manual constraint SQL. Update `ImportBudget` handler. Deploy to Render. This is the only step with a deploy dependency — all other steps can run locally until final deploy.

**Step 2 — Bloomington data migration (independent, run after step 1)**

Write `bloomington_migrate.py` to POST all existing static JSON files (5 years × 3 datasets = 15 requests) to the backend. Verify API responses match the static JSON shape. After migration, all Bloomington data is in Supabase and the API-first path returns real data.

**Step 3 — Frontend entity switcher (depends on step 1 for entity_type field)**

Implement `EntitySwitcher.tsx`. Update `App.tsx` state (`selectedEntity`). Update `dataLoader.ts` cache key and API query. Update hero card to be data-driven. At this point the app works with multiple jurisdictions — but only Bloomington has data until step 4.

**Step 4 — New jurisdiction imports (independent of step 3, depends on step 1)**

Each new jurisdiction requires its own research phase: find the source data file, understand its column structure, write the transform logic. Recommended order: Ellettsville (small, simple), Monroe County (county entity_type test), LA County, LA Cities (largest, most complex). Importable in any order since they are independent entities.

**Step 5 — Design token integration (fully independent)**

Import ev-ui tokens in `src/styles/tokens.ts`. Update `DatasetTabs.tsx` color definitions. Align `index.css` CSS variable values. This is pure visual polish and has no dependencies on steps 1-4. Can be done first, last, or in parallel.

---

## Anti-Patterns

### Anti-Pattern 1: Direct SQL Inserts from Import Scripts

**What people do:** Use `psycopg2` to INSERT directly into Supabase from Python import scripts.

**Why it's wrong:** Bypasses the `importCategories()` recursive tree builder in the Go handler, bypasses transaction safety, and bypasses the find-or-create city logic. Direct inserts are hard to replay and don't benefit from the existing validation logic in the handler.

**Do this instead:** POST to `POST /treasury/budgets/import` from import scripts. The handler handles all complexity. The only extra cost is HTTP overhead — negligible for a one-time import.

### Anti-Pattern 2: Creating a Separate `treasury.counties` Table

**What people do:** Add a new `treasury.counties` table for county entities to avoid touching the existing `treasury.cities` table.

**Why it's wrong:** Forces frontend and backend to maintain two separate data paths. The entity switcher would need to list from two separate endpoints. The Budget and BudgetCategory tables are entity-type-agnostic and work identically for cities and counties.

**Do this instead:** Add `entity_type` column to `treasury.cities`. "Cities" in this context means "municipal entities." The table name is historical.

### Anti-Pattern 3: Jurisdiction-Specific Branching in App.tsx

**What people do:** Add `if (selectedEntity.name === 'Monroe County') { showCountyLayout() }` branching in App.tsx.

**Why it's wrong:** Every new jurisdiction requires a code change. Brittle and doesn't scale.

**Do this instead:** Drive display text and layout variations from `selectedEntity.entityType`. For hero images: derive from entity_type as a fallback (`city` → courthouse photo, `county` → courthouse or default), or drive from `entity.hero_image_url` once that field is added to the model.

### Anti-Pattern 4: Deleting Static JSON After Migration

**What people do:** Remove `public/data/*.json` after successfully migrating Bloomington to Supabase.

**Why it's wrong:** The static JSON fallback is a safety net. If Render has a cold start or brief downtime, the treasury tracker degrades to Bloomington data rather than showing an error state. This is valuable for a nonprofit with no SLA on the backend.

**Do this instead:** Keep the static JSON files indefinitely. The cache key change (`"city:Bloomington-..."`) ensures API-loaded data for other entities never gets confused with Bloomington static data.

### Anti-Pattern 5: Using ev-ui CSS Variable Names as D3 Color Inputs

**What people do:** Pass CSS variable references like `var(--muted-blue)` to D3 color scales or as `fill` attributes on SVG elements.

**Why it's wrong:** D3 and SVG `fill` attributes require resolved hex values. CSS variable strings fail silently — the element renders with no fill or uses the browser default.

**Do this instead:** Import from `@chrisandrewsedu/ev-ui/tokens` as JavaScript constants. Use the resolved hex values from `dataVizPalette` or `colors` directly in D3 color scale definitions.

---

## Scaling Considerations

At the current scale (5-10 jurisdictions, hundreds of budget categories per jurisdiction), no architectural changes are needed.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 5-10 jurisdictions | Current monolith + single API per entity is fine |
| 50+ jurisdictions | Add search/filter to `GET /treasury/cities`; consider lazy-loading subcategories on drill-down instead of fetching full category tree upfront |
| 500+ jurisdictions | Paginate entity list; separate treasury microservice; Redis cache for category trees |

**First bottleneck:** `GET /treasury/budgets/{id}/categories` fetches the entire category tree in one query and builds it in Go memory. For LA County's budget (potentially 300-500 categories + thousands of line items), this single query could slow the initial page load. Mitigation for this milestone: ensure the query uses the existing `idx_category_tree` index. Longer-term: lazy-load line items only on leaf-node drill-down.

---

## Sources

All findings from direct source inspection (HIGH confidence):

- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/models.go`
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/handlers.go`
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/routes.go`
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/setup.go`
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/App.tsx`
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/data/dataLoader.ts`
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/types/budget.ts`
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/components/datasets/DatasetTabs.tsx`
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/index.css`
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/tokens.js` (v0.1.53)
- `/Users/chrisandrews/Documents/GitHub/.planning/PROJECT.md` — v2026.3.7 milestone goals

---

*Architecture research for: Treasury Tracker multi-jurisdiction expansion (v2026.3.7)*
*Researched: 2026-03-22*
