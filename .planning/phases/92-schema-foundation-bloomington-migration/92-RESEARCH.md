# Phase 92: Schema Foundation & Bloomington Migration - Research

**Researched:** 2026-03-22
**Domain:** Go/GORM schema migration, PostgreSQL DDL, TypeScript frontend data layer
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a Go CLI subcommand (`import-budgets`) in EV-Backend, consistent with existing `import-stances` and `import-quotes` patterns. Reads static JSON files, transforms to treasury GORM models, upserts via GORM.
- **D-02:** Migrate all three dataset types (operating, revenue, salaries) together in this phase. Requirements DATA-01 through DATA-03 all land here.
- **D-03:** Validate migration via API round-trip check — after import, hit treasury API endpoints and compare totals/category counts against source JSON to confirm the full stack works.
- **D-04:** Rename `City` model to `Municipality`, table from `treasury.cities` to `treasury.municipalities`, FK from `city_id` to `municipality_id`. User chose "Municipality" as more accurate than "City" for an entity that covers cities, counties, and townships.
- **D-05:** Support three entity_type values: `city`, `county`, `township`. Composite unique constraint on `(name, state, entity_type)`.
- **D-06:** Remove the static JSON fallback from `dataLoader.ts` entirely — no static files, no mock data fallback. Once data is in Supabase, the API is the sole data source.
- **D-07:** When API is unavailable, show an error message with a retry button. No empty dashboard shell.
- **D-08:** Use GORM AutoMigrate for new fields and indexes, consistent with all other EV-Backend modules. The table rename (`cities` → `municipalities`) and FK rename (`city_id` → `municipality_id`) require a manual SQL step run before deploying the updated code.
- **D-09:** Apply table/FK rename via `ALTER TABLE treasury.cities RENAME TO treasury.municipalities` + column rename, then deploy new Go code with updated model that AutoMigrates remaining changes.

### Claude's Discretion
- None — all areas discussed with explicit user decisions.

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHM-01 | Budget unique index includes dataset_type (three-column: city_id, fiscal_year, dataset_type) | Current index `idx_budget_city_year` is two-column only; GORM tag must be updated and old index dropped before new one is created |
| SCHM-02 | City model has entity_type field (city/county/township) with composite unique on (name, state, entity_type) | Current City model has single-column `uniqueIndex` on `Name` only; requires model rename, new field, and index rebuild |
| SCHM-03 | Budget model has fiscal_year_start_month field (default 1, set to 7 for California entities) | New column; AutoMigrate adds it safely; default=1 applies at DB level via GORM default tag |
| DATA-01 | Bloomington operating budget data migrated from static JSON to Supabase via treasury API | 5 years × operating JSON exist in `public/data/budget-*.json`; import-budgets CLI reads them |
| DATA-02 | Bloomington revenue data migrated from static JSON to Supabase | 5 years × revenue JSON exist in `public/data/revenue-*.json` |
| DATA-03 | Bloomington salary data migrated from static JSON to Supabase | 5 years × salary JSON exist in `public/data/salaries-*.json` |
| DATA-04 | Static JSON fallback in dataLoader.ts guarded to Bloomington city only | Per D-06/D-07: remove fallback entirely, replace with error state and retry button |
</phase_requirements>

---

## Summary

Phase 92 is a two-track operation: (1) fix three schema gaps in the treasury backend, and (2) migrate 15 static JSON files of Bloomington budget data into Supabase and switch the frontend to API-only loading.

The schema work has a mandatory ordering constraint. The table and FK rename (`cities` → `municipalities`, `city_id` → `municipality_id`) must be done via raw SQL before deploying the new Go code, because GORM AutoMigrate does not rename tables or columns — it would create a new table and leave the old one intact. Once the rename is applied, AutoMigrate handles the remaining changes: adding `entity_type` and `fiscal_year_start_month`, rebuilding the composite unique indexes.

The import work is straightforward: all 15 source files already exist in `treasury-tracker/public/data/` in a format compatible with the existing `ImportBudget` HTTP handler's `CategoryImport`/`LineItemImport` struct shape. The new `import-budgets` CLI subcommand will read those JSON files and call GORM directly (bypassing HTTP), following the exact pattern of `import-stances` and `import-quotes` in `main.go`.

The frontend change is a clean deletion: `dataLoader.ts` currently has three tiers (API → static file → mock `budgetData.ts`). Both fallback tiers get removed. `App.tsx` already has an error state path (`if (!budgetData)`) but currently shows a passive message; it needs a retry button added.

**Primary recommendation:** Apply the SQL rename script first as a manual step, then let AutoMigrate handle the rest, then run `import-budgets`, then simplify `dataLoader.ts`.

---

## Standard Stack

### Core (all already in the project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GORM | v2 (gorm.io/gorm) | ORM + AutoMigrate | Established in all EV-Backend modules |
| Chi | v5 | HTTP router | All EV-Backend routes use Chi |
| PostgreSQL (Supabase) | 15+ | Database | Project database |
| Go | 1.24.3 | Backend runtime | Project standard |
| TypeScript / React | 19 / Vite 7 | Frontend | Project standard for treasury-tracker |

### No New Dependencies
This phase requires zero new package additions to either Go or TypeScript. All functionality exists in the current stack.

---

## Architecture Patterns

### Pattern 1: CLI Subcommand in main.go

All Go CLI import commands follow the same pattern in `main.go`:

```go
// Source: EV-Backend/main.go — existing import-stances case
case "import-budgets":
    jsonDir := "treasury-tracker/public/data"
    dryRun := false
    for _, arg := range os.Args[2:] {
        if arg == "--dry-run" {
            dryRun = true
        }
        if strings.HasPrefix(arg, "--data-dir=") {
            jsonDir = strings.TrimPrefix(arg, "--data-dir=")
        }
    }
    result, err := treasury.ImportBudgets(treasury.ImportBudgetsConfig{
        DataDir: jsonDir,
        DryRun:  dryRun,
    })
    if err != nil {
        log.Fatal("import-budgets failed: ", err)
    }
    fmt.Printf("Import complete: %d files processed, %d budgets inserted, %d skipped\n",
        result.FilesProcessed, result.Inserted, result.Skipped)
    os.Exit(0)
```

The actual import logic lives in a function inside the `treasury` package (e.g., `internal/treasury/importer.go`), keeping `main.go` thin. This matches the shape of `internal/quoteimport/import.go` and `internal/stanceimport/import.go`.

### Pattern 2: Two-Phase Schema Migration (Rename + AutoMigrate)

GORM AutoMigrate only adds columns and indexes — it does not rename tables or columns. The rename requires raw SQL run once manually:

```sql
-- Step 1: Run manually BEFORE deploying new Go code
-- Source: CONTEXT.md D-09
ALTER TABLE treasury.cities RENAME TO municipalities;
ALTER TABLE treasury.municipalities RENAME COLUMN city_id TO municipality_id;
-- Note: FK constraint names may need explicit rename too
```

Then the updated Go model uses the new name and AutoMigrate handles new columns/indexes:

```go
// After rename, models.go Municipality model
type Municipality struct {
    ID         uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
    Name       string    `gorm:"not null" json:"name"`
    State      string    `gorm:"not null" json:"state"`
    EntityType string    `gorm:"not null;default:'city'" json:"entity_type"` // city, county, township
    Population int       `json:"population"`
    CreatedAt  time.Time `json:"created_at"`
    UpdatedAt  time.Time `json:"updated_at"`

    Budgets []Budget `gorm:"foreignKey:MunicipalityID" json:"budgets,omitempty"`
}

func (Municipality) TableName() string {
    return "treasury.municipalities"
}
```

And the composite unique index must be declared explicitly in `setup.go` (GORM multi-column composite unique cannot be expressed reliably in struct tags alone for non-trivial cases):

```go
// In setup.go, after AutoMigrate:
db.DB.Exec(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_municipality_name_state_type
    ON treasury.municipalities (name, state, entity_type)
`)
db.DB.Exec(`
    DROP INDEX IF EXISTS treasury.idx_budget_city_year
`)
db.DB.Exec(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_budget_municipality_year_type
    ON treasury.budgets (municipality_id, fiscal_year, dataset_type)
`)
```

### Pattern 3: Budget Model Three-Column Index

The current `Budget` model has:
```go
// CURRENT — two-column index only (SCHM-01 gap)
CityID     uuid.UUID `gorm:"type:uuid;not null;index:idx_budget_city_year,unique"`
FiscalYear int       `gorm:"not null;index:idx_budget_city_year,unique"`
DatasetType string   `gorm:"not null;default:'operating'"`
// DatasetType is NOT in the unique index — this is the bug
```

Fixed model (after table/FK rename):
```go
// AFTER fix — three-column index
MunicipalityID uuid.UUID `gorm:"type:uuid;not null;index:idx_budget_muni_year_type,unique" json:"municipality_id"`
FiscalYear     int       `gorm:"not null;index:idx_budget_muni_year_type,unique"            json:"fiscal_year"`
DatasetType    string    `gorm:"not null;default:'operating';index:idx_budget_muni_year_type,unique" json:"dataset_type"`
FiscalYearStartMonth int `gorm:"not null;default:1"                                         json:"fiscal_year_start_month"`
```

### Pattern 4: Frontend API-Only Loading

Current `dataLoader.ts` has three tiers. The simplified version drops tiers 2 and 3 entirely:

```typescript
// Source: treasury-tracker/src/data/dataLoader.ts (current, to be simplified)
export async function loadBudgetData(
  year: number = 2025,
  cityName: string = 'Bloomington',
  dataset: string = 'operating'
): Promise<BudgetData> {
  const cacheKey = `${cityName}-${year}-${dataset}`;
  if (cache.has(cacheKey)) return cache.get(cacheKey)!;

  const apiUrl = `${API_BASE}/treasury/budgets?city=${encodeURIComponent(cityName)}&year=${year}&dataset=${dataset}`;
  const response = await fetch(apiUrl);
  if (!response.ok) throw new Error(`API error: ${response.status}`);

  const apiData = await response.json();
  const budget = Array.isArray(apiData) ? apiData[0] : apiData;
  if (!budget?.id) throw new Error('No budget found');

  const catResponse = await fetch(`${API_BASE}/treasury/budgets/${budget.id}/categories`);
  if (!catResponse.ok) throw new Error(`Categories API error: ${catResponse.status}`);
  const categories = await catResponse.json();

  const data = transformAPIResponse(budget, categories);
  cache.set(cacheKey, data);
  return data;
}
```

`App.tsx` already has an error path but it needs a retry button. The `loadDataset` function in `App.tsx` (which bypasses `dataLoader.ts` entirely and fetches static files directly via `fetch('./data/...')`) also needs to be replaced with calls through the new API-only `loadBudgetData`.

### Anti-Patterns to Avoid

- **Do not use GORM AutoMigrate to rename tables/columns.** AutoMigrate only adds; it creates a new table with the new name and leaves the old one untouched. Use raw SQL `ALTER TABLE ... RENAME TO`.
- **Do not drop the old index before creating the new one in the same AutoMigrate call.** Drop the old index explicitly in `setup.go` using raw SQL, then create the replacement.
- **Do not leave `App.tsx`'s `loadDataset` function pointing at static files.** `App.tsx` has its own `loadDataset` that fetches `./data/${fileName}-${year}.json` directly — this is separate from `dataLoader.ts` and must also be updated.
- **Do not set `entity_type` default in Go code only.** The GORM `default:` tag writes the default into the DB column definition, so existing and future rows get the default at the database level without application intervention.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Recursive category tree insert | Custom DFS walker | Existing `importCategories()` in `handlers.go` | Already handles depth/parent tracking; reuse it |
| Conflict detection on re-import | Custom duplicate check | Three-column unique index + GORM's error on constraint violation | The schema constraint is the gate; detect via error code |
| HTTP transport for CLI import | CLI that calls the API HTTP endpoints | Direct GORM calls inside the `treasury` package | Avoids network latency, auth middleware, and server-must-be-running dependency |

**Key insight:** The `importCategories` recursive function in `handlers.go` is reusable — the CLI importer should extract it to a shared location or call it directly from the same package. No need to rewrite tree insertion logic.

---

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | No budget data yet in Supabase treasury schema (migration target is empty) | Data migration: import-budgets CLI inserts new records |
| Live service config | Render deployment of EV-Backend — currently runs with `treasury.cities` table | Deploy new Go binary after SQL rename completes |
| OS-registered state | None | None |
| Secrets/env vars | `DATABASE_URL` in Render env (points to Supabase) — unchanged by this phase | None |
| Build artifacts | `EV-Backend/server` binary — stale after code changes | Rebuild via `go build -o server .` |

**Rename ripple inventory:**

| Location | Current Reference | Must Change To | How |
|----------|------------------|----------------|-----|
| `treasury/models.go` | `City` struct, `treasury.cities` TableName | `Municipality` struct, `treasury.municipalities` TableName | Code edit |
| `treasury/models.go` | `Budget.CityID` field + GORM FK tag | `Budget.MunicipalityID` | Code edit |
| `treasury/handlers.go` | `var city City`, `City{}`, `CityID`, `city_id` param | `var municipality Municipality`, `Municipality{}`, `MunicipalityID`, `municipality_id` param | Code edit |
| `treasury/handlers.go` | `ListCities`, `GetCity`, `CreateCity`, `UpdateCity`, `DeleteCity` | `ListMunicipalities`, `GetMunicipality`, etc. | Code edit (internal names only; route paths may stay as `/cities/` or change to `/municipalities/`) |
| `treasury/routes.go` | `/cities`, `/cities/{city_id}` | `/municipalities`, `/municipalities/{municipality_id}` (or keep `/cities` for backward compat) | Code edit |
| `treasury/setup.go` | `&City{}` in AutoMigrate call | `&Municipality{}` | Code edit |
| `treasury-tracker/src/data/dataLoader.ts` | `/treasury/cities` API URL | `/treasury/municipalities` (if route changes) | Code edit |
| Supabase DB | `treasury.cities` table | `treasury.municipalities` (SQL rename) | Manual SQL |
| Supabase DB | `city_id` FK column on `treasury.budgets` | `municipality_id` | Manual SQL |
| Supabase DB | `idx_budget_city_year` index | `idx_budget_municipality_year_type` (new three-column) | SQL drop + create |
| Supabase DB | `City.Name` single-column uniqueIndex | Composite `(name, state, entity_type)` unique index | SQL drop + create |

**Route path decision:** The planner should decide whether to rename API routes from `/cities` to `/municipalities` in this phase or keep backward-compatible `/cities` aliases. The frontend only calls `/treasury/cities` in one place (`listCities()` in `dataLoader.ts`, which is not currently called in `App.tsx`). Renaming routes is safe in this phase since the app is single-developer and in development.

---

## Common Pitfalls

### Pitfall 1: GORM AutoMigrate Does Not Rename
**What goes wrong:** Developer updates `TableName()` to return `treasury.municipalities` and runs AutoMigrate. GORM creates a new empty `treasury.municipalities` table and leaves `treasury.cities` untouched. The app now points at an empty table.
**Why it happens:** GORM AutoMigrate only adds columns/tables, never removes or renames them.
**How to avoid:** Run `ALTER TABLE treasury.cities RENAME TO municipalities` via `run-sql` subcommand or Supabase SQL editor before deploying the new Go code.
**Warning signs:** After deploying, API returns empty arrays instead of the expected Bloomington data.

### Pitfall 2: Old Budget Index Persists After GORM Tag Change
**What goes wrong:** Developer changes the GORM index tag on `Budget` to include `DatasetType`, but the old `idx_budget_city_year` (two-column) index still exists in the database. GORM's `CREATE INDEX IF NOT EXISTS` on the new name creates the new index, but the old constraint doesn't block duplicates the same way — both indexes coexist until the old one is explicitly dropped.
**Why it happens:** GORM AutoMigrate adds the new index but does not drop the old one when the tag changes.
**How to avoid:** Explicitly `DROP INDEX treasury.idx_budget_city_year` in `setup.go` before creating the new three-column index.
**Warning signs:** Two indexes on `treasury.budgets` visible in Supabase table inspector.

### Pitfall 3: App.tsx Has Its Own Static File Loader
**What goes wrong:** Developer removes the static fallback from `dataLoader.ts` but `App.tsx` still loads data via its own `loadDataset()` function that calls `fetch('./data/${fileName}-${year}.json')` directly. The app still works with static files.
**Why it happens:** `App.tsx` bypasses `dataLoader.ts` entirely for its primary data loading. `dataLoader.ts` is only used for the `listCities()` helper. The main data path in `App.tsx` is the direct `fetch` in the `loadDataset` function at line 24-53.
**How to avoid:** Replace `App.tsx`'s `loadDataset` with calls to the updated `loadBudgetData` from `dataLoader.ts`. This is the primary location to change, not just `dataLoader.ts`.
**Warning signs:** After removing static files from `public/data/`, the app still loads Bloomington data successfully — meaning it's hitting static files, not the API.

### Pitfall 4: Import CLI Imports Wrong JSON Shape
**What goes wrong:** The static JSON files (`budget-2025.json`) use `camelCase` keys (`cityName`, `fiscalYear`, `totalBudget`) in the `metadata` block, but the `importCategories` function expects `CategoryImport` struct fields. The categories array uses `subcategories` and `line_items` (lowercase in some files) vs `lineItems` (camelCase TypeScript style).
**Why it happens:** The JSON files were generated by a TypeScript script and use TypeScript camelCase conventions, while Go expects snake_case JSON by default.
**How to avoid:** The CLI importer must unmarshal using Go struct tags that match the actual JSON field names. Check a few files: `budget-2025.json` categories use `"subcategories"`, `"line_items"` (verified — see file sample above). `CategoryImport` in `handlers.go` uses `json:"subcategories"` and `json:"line_items"` — these match.
**Warning signs:** Import runs with 0 categories inserted per budget.

### Pitfall 5: Salary JSON Has Different Metadata Fields
**What goes wrong:** Salary JSON files have `totalCompensation` and `totalEmployees` in metadata rather than `totalBudget`. Import script reads `metadata.totalBudget` and gets 0.
**Why it happens:** Each dataset type has slightly different metadata field names in the static JSON files.
**How to avoid:** Import script should read `totalBudget` OR `totalCompensation` OR `totalRevenue`, whichever is non-zero, when populating `Budget.TotalBudget`.
**Warning signs:** Bloomington salaries budget shows $0 total in the API response.

---

## Code Examples

### Full Rename SQL Sequence
```sql
-- Source: CONTEXT.md D-09 — run via Supabase SQL editor or ./server run-sql
-- Step 1: Rename table
ALTER TABLE treasury.cities RENAME TO municipalities;

-- Step 2: Rename FK column on budgets
ALTER TABLE treasury.budgets RENAME COLUMN city_id TO municipality_id;

-- Step 3: Drop old two-column unique index on budgets
DROP INDEX IF EXISTS treasury.idx_budget_city_year;

-- Step 4: Drop old single-column unique index on municipalities (was on cities.name)
-- (AutoMigrate will recreate the composite one after rename)
-- Note: old index name is auto-generated by GORM as "idx_cities_name" or similar
-- Check actual name in Supabase before running
```

### ImportBudgets Config Pattern (mirroring import-quotes)
```go
// Source: EV-Backend/internal/quoteimport/import.go — reference pattern
type ImportBudgetsConfig struct {
    DataDir string // path to directory containing budget JSON files
    DryRun  bool
}

type ImportBudgetsResult struct {
    FilesProcessed int
    Inserted       int
    Skipped        int
    Errors         []string
}
```

### API-Only dataLoader.ts (simplified)
```typescript
// Source: treasury-tracker/src/data/dataLoader.ts (current — to simplify)
export async function loadBudgetData(
  year: number = 2025,
  municipalityName: string = 'Bloomington',
  dataset: string = 'operating'
): Promise<BudgetData> {
  const cacheKey = `${municipalityName}-${year}-${dataset}`;
  if (cache.has(cacheKey)) return cache.get(cacheKey)!;

  // API is the sole source — no fallback
  const budgetsUrl = `${API_BASE}/treasury/budgets?city=${encodeURIComponent(municipalityName)}&year=${year}&dataset=${dataset}`;
  const response = await fetch(budgetsUrl);
  if (!response.ok) throw new Error(`Budget API returned ${response.status}`);

  const apiData = await response.json();
  const budget = Array.isArray(apiData) ? apiData[0] : apiData;
  if (!budget?.id) throw new Error(`No budget found for ${municipalityName} ${year} (${dataset})`);

  const catResponse = await fetch(`${API_BASE}/treasury/budgets/${budget.id}/categories`);
  if (!catResponse.ok) throw new Error(`Categories API returned ${catResponse.status}`);
  const categories = await catResponse.json();

  const data = transformAPIResponse(budget, categories);
  cache.set(cacheKey, data);
  return data;
}
```

### Error State with Retry in App.tsx
```tsx
// Source: treasury-tracker/src/App.tsx (current error state — needs retry button)
if (!budgetData) {
  return (
    <div className="app">
      <div className="main-content" style={{ padding: '4rem', textAlign: 'center' }}>
        <h2>Unable to load budget data</h2>
        <p>The budget API is unavailable. Please try again.</p>
        <button onClick={() => window.location.reload()} style={{ marginTop: '1rem' }}>
          Retry
        </button>
      </div>
    </div>
  );
}
```

---

## State of the Art

| Old Approach | Current Approach | Status |
|--------------|------------------|--------|
| Static JSON files in `public/data/` | Supabase treasury API | This phase migrates to API |
| Two-column budget unique index `(city_id, fiscal_year)` | Three-column `(municipality_id, fiscal_year, dataset_type)` | This phase fixes it |
| `treasury.cities` table | `treasury.municipalities` table | This phase renames it |
| Single-column unique on `cities.name` | Composite unique `(name, state, entity_type)` | This phase adds it |

---

## Open Questions

1. **Route path: `/cities` vs `/municipalities`**
   - What we know: The frontend only calls `/treasury/cities` in one non-critical helper (`listCities()` in `dataLoader.ts`, not wired to `App.tsx`). Main data loading uses `/treasury/budgets?city=...` which does not need to change.
   - What's unclear: Should the handler routes in `routes.go` rename `/cities/{city_id}` to `/municipalities/{municipality_id}` now, or keep backward-compatible `/cities` aliases?
   - Recommendation: Rename the routes to `/municipalities` in this phase. There's only one frontend caller to update, and keeping stale route names invites future confusion.

2. **Exact name of the old auto-generated GORM unique index on `cities.name`**
   - What we know: GORM creates auto-named indexes like `idx_cities_name` when using `gorm:"uniqueIndex"`.
   - What's unclear: The actual index name in Supabase (GORM may use the schema-qualified table name or not).
   - Recommendation: The pre-deployment SQL script should query `pg_indexes WHERE tablename = 'municipalities'` to find the exact name, then drop it. Alternatively, `DROP INDEX IF EXISTS treasury.idx_cities_name` is a safe attempt with fallback.

3. **Years to import: 2021-2025 or 2025 only?**
   - What we know: Static JSON files span 2021-2025 (5 years × 3 dataset types = 15 files) per `ls public/data/`.
   - What's unclear: The requirements say "Bloomington data migrated" without specifying years.
   - Recommendation: Import all 5 years (2021-2025) for completeness, since all files already exist and the importer will process them in a loop. The `YearSelector` in `App.tsx` already shows ['2025', '2024', '2023', '2022', '2021'].

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Go | Backend build | ✓ | 1.24.3 | — |
| PostgreSQL (Supabase) | Schema migration + data import | ✓ | 15+ via Supabase | — |
| `DATABASE_URL` env var | import-budgets CLI | Must be set in `.env.local` | — | None — blocks import |
| Static JSON source files | import-budgets CLI | ✓ | 15 files in `treasury-tracker/public/data/` | — |

**Missing dependencies with no fallback:**
- `DATABASE_URL` must be set in `EV-Backend/.env.local` pointing to the isolated Supabase project before running `import-budgets`

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification (no automated test suite in EV-Backend or treasury-tracker) |
| Config file | None |
| Quick run command | `./server run-sql "SELECT count(*) FROM treasury.budgets"` |
| Full suite command | API round-trip: `curl "http://localhost:5050/treasury/budgets?city=Bloomington&year=2025&dataset=operating"` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCHM-01 | Second import of same city/year/type fails with conflict | manual | `./server import-budgets --dry-run` then repeat import | ❌ Wave 0 |
| SCHM-02 | Municipality with entity_type stores and returns value | manual | `curl .../treasury/municipalities` | ❌ Wave 0 |
| SCHM-03 | fiscal_year_start_month stores correctly | manual | `./server run-sql "SELECT fiscal_year_start_month FROM treasury.budgets LIMIT 5"` | ❌ Wave 0 |
| DATA-01 | Bloomington operating data loads from API | manual | `curl ".../treasury/budgets?city=Bloomington&year=2025&dataset=operating"` | ❌ Wave 0 |
| DATA-02 | Bloomington revenue data loads from API | manual | `curl ".../treasury/budgets?city=Bloomington&year=2025&dataset=revenue"` | ❌ Wave 0 |
| DATA-03 | Bloomington salary data loads from API | manual | `curl ".../treasury/budgets?city=Bloomington&year=2025&dataset=salaries"` | ❌ Wave 0 |
| DATA-04 | Static fallback removed; error state shown on API failure | manual | Stop local server, load frontend — verify error+retry UI | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Build the Go binary: `cd EV-Backend && go build -o server .`
- **Per wave merge:** Run import and verify record counts in DB
- **Phase gate:** All 7 curl checks return populated data before marking phase complete

### Wave 0 Gaps
- No automated test infrastructure exists in this project — all verification is manual curl + SQL queries
- The D-03 API round-trip validation is the phase gate check: compare `totalBudget` from source JSON against `total_budget` returned by the API for each of the 15 datasets

---

## Sources

### Primary (HIGH confidence)
- `EV-Backend/internal/treasury/models.go` — Current schema: exact GORM tags, index names, field names verified by direct read
- `EV-Backend/internal/treasury/handlers.go` — Existing `importCategories` recursive function, `ImportBudget` HTTP handler structure verified
- `EV-Backend/internal/treasury/routes.go` — Current route paths verified
- `EV-Backend/internal/treasury/setup.go` — AutoMigrate call pattern verified
- `EV-Backend/main.go` — CLI subcommand dispatch pattern verified (import-stances, import-quotes, import-federal-bills)
- `treasury-tracker/src/App.tsx` — Confirmed `loadDataset` function is the primary data entry point (not `dataLoader.ts`)
- `treasury-tracker/src/data/dataLoader.ts` — Three-tier fallback structure verified
- `treasury-tracker/public/data/` — All 15 JSON files confirmed present (budget-2021..2025, revenue-2021..2025, salaries-2021..2025)

### Secondary (MEDIUM confidence)
- GORM AutoMigrate behavior (rename limitation) — well-documented behavior from GORM v2 docs; consistent with observed codebase patterns

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use; verified from source files
- Architecture patterns: HIGH — verified from existing CLI subcommand patterns in main.go
- Pitfalls: HIGH — three of five pitfalls discovered by directly reading source code (App.tsx static loader, salary JSON metadata difference, old index persistence)
- Schema migration order: HIGH — confirmed by reading models.go and GORM AutoMigrate documentation behavior

**Research date:** 2026-03-22
**Valid until:** 2026-04-22 (stable domain)
