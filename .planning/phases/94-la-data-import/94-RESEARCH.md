# Phase 94: LA Data Import - Research

**Researched:** 2026-03-23
**Domain:** Open government data ingestion — ArcGIS FeatureServer (LA County) + Socrata CSV (LA City) into Go/GORM treasury pipeline
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Use Socrata CSV export URLs (`/api/views/{id}/rows.csv?accessType=DOWNLOAD`) — simple HTTP GET, returns full CSV, no API key needed for public datasets. Mirrors the Gateway approach of fetching raw CSV.
- **D-02:** Config-driven — add LA entities to `treasury-import-config.json` with `source_type: "socrata"`, `dataset_id`, `base_url`, and column mappings. Consistent with the Gateway entity config pattern.
- **D-03:** Researcher agent must identify the correct Socrata dataset IDs for department-level expenditures (LA County) and operating appropriations (LA City) during research phase. This was flagged as a blocker in STATE.md.
- **D-04:** Config-driven column list via `hierarchy_columns` — same pattern as Gateway. The config lists LA-specific columns in order, and the existing `buildGatewayCategoryTree` logic (or its Socrata equivalent) builds the tree from those columns.
- **D-05:** Full tree depth from config — no artificial cap. If the config lists 4 hierarchy levels, build 4 levels. The frontend already handles arbitrary depth.
- **D-06:** Mirror Bloomington's three dataset types: operating/expenditures, revenue, and salaries. Import all three for each LA entity where available on the portal.
- **D-07:** Transaction-level/checkbook data remains deferred to v2+ per milestone decision (TXNS-01 in REQUIREMENTS.md).
- **D-08:** Fiscal year range: 2021-2025, matching Bloomington and Indiana. California fiscal years run July-June (FY2025 = Jul 2024 – Jun 2025).
- **D-09:** Unified config file (`treasury-import-config.json`) with a `source_type` field per entity — `"gateway"` for Indiana, `"socrata"` for LA. Shared category tree builder and DB insertion logic. Only the HTTP fetch layer differs between sources.
- **D-10:** Extend the existing `import-budgets` CLI with `--source=socrata` alongside `--source=gateway`. One command, source flag routes to the right fetcher.

### Claude's Discretion

- Socrata fetch implementation details (timeouts, error handling, content-type validation)
- Config field naming for Socrata-specific properties (dataset_id, base_url pattern)
- How to refactor shared logic between Gateway and Socrata tree builders (extract common function vs. duplicate with minor differences)

### Deferred Ideas (OUT OF SCOPE)

- Transaction-level/checkbook data for LA entities — deferred to v2+ (TXNS-01)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LA-01 | LA County expenditure data imported from data.lacounty.gov | LA County uses ArcGIS FeatureServer (not Socrata); requires paginated JSON fetch from `services.arcgis.com/RmCCgQtiZLDCtblq/.../Open_Expenditures/FeatureServer/0` |
| LA-02 | LA City appropriations data imported from data.lacity.org Socrata CSV | LA City uses classic Socrata; dataset ID `5242-pnmt`; standard `/api/views/{id}/rows.csv?accessType=DOWNLOAD` URL works |
| LA-03 | Fiscal year start month set to 7 for all California entities | `FiscalYearStartMonth: 7` in config; already supported by Budget model GORM field |
</phase_requirements>

---

## Summary

LA City's budget data uses the standard Socrata platform at data.lacity.org. Dataset `5242-pnmt` ("Open Budget - Appropriations Fiscal Years 2010–2025") is accessible via the standard Socrata CSV URL pattern and covers all fiscal years 2021–2025 with 4,000–7,600 rows per year. The column schema is clean: `Department_Name`, `SubDepartment_Name`, `Program_Name`, `Account_Name`, `Appropriation`, `Fiscal_Year`.

LA County is a critical divergence from the original plan: data.lacounty.gov runs on ArcGIS Hub (not classic Socrata), and the open expenditure data lives on an ArcGIS FeatureServer at `services.arcgis.com`. The standard Socrata CSV URL pattern (`/api/views/{id}/rows.csv`) returns 404 for all LA County datasets. The correct access method is the ArcGIS FeatureServer query API, which returns JSON and requires pagination (maxRecordCount=2000 per request, `resultOffset` parameter) since FY2024 has 38,519 rows and FY2025 has 37,157 rows.

This means the importer for LA County cannot use simple HTTP GET → CSV reader. It needs a paginated JSON fetcher that reassembles pages and converts to `[]CategoryImport`. The config structure should reflect this with a `source_type: "arcgis"` instead of `"socrata"` for LA County, or a new `source_url` field pointing to the FeatureServer endpoint. Decision D-01 (Socrata CSV URL) applies to LA City only. LA County requires a new fetch strategy.

**Primary recommendation:** Implement two distinct fetch strategies — `socrata` for LA City (CSV), `arcgis` for LA County (paginated JSON FeatureServer). Both share the same category tree builder and DB insertion logic from the Gateway importer.

---

## Standard Stack

### Core (Already in Use)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `encoding/csv` | stdlib | CSV parsing for Socrata response | Already used in Gateway importer |
| `encoding/json` | stdlib | JSON parsing for ArcGIS FeatureServer | Already used throughout |
| `net/http` | stdlib | HTTP client for both fetch strategies | Already used; `http.Client{Timeout: 60s}` pattern established |

### No New Dependencies Required

The Socrata CSV fetch is a simple HTTP GET. The ArcGIS FeatureServer fetch is standard JSON over HTTPS. Both fit entirely within the existing Go stdlib + GORM stack. No new packages needed.

**Installation:** None required.

---

## Confirmed Dataset Inventory

### LA City (Socrata — data.lacity.org)

| Dataset Type | Dataset Name | Dataset ID | CSV Download URL | Rows (2021-2025) | FY Format |
|---|---|---|---|---|---|
| Operating (appropriations) | Open Budget - Appropriations FY 2010-2025 | `5242-pnmt` | `https://data.lacity.org/api/views/5242-pnmt/rows.csv?accessType=DOWNLOAD` | ~4,000-7,700/yr | Integer (2021, 2022, ...) |
| Revenue | Open Budget - Revenue 2010-2025 | `ih6g-qkwz` | `https://data.lacity.org/api/views/ih6g-qkwz/rows.csv?accessType=DOWNLOAD` | ~15/yr | String (2020-2021) |
| Salaries | Not found on data.lacity.org | — | — | — | — |

**Notes on LA City Revenue dataset:** Fiscal year is stored as a range string (`2020-2021`). The `Fiscal_Year_Shorthand` column contains just the end year (integer-like: `2021`). Revenue columns: `Revenue Source`, `Amount`, `Fund Type`, `Fiscal Year`, `Fiscal Year Shorthand`.

**Notes on LA City Salaries:** Searching `api.us.socrata.com/api/catalog/v1?domains=data.lacity.org` found no multi-year employee salary dataset comparable to Bloomington's. The LA City Controller has a separate payroll portal (lacity.spending.socrata.com) but no combined multi-year salary CSV on data.lacity.org was identified. Salary data for LA City is LOW confidence availability — treat as "not available" until confirmed by separate investigation.

### LA County (ArcGIS FeatureServer — services.arcgis.com)

| Dataset Type | Dataset Name | ArcGIS Item ID | FeatureServer URL | Total Rows | FY Range |
|---|---|---|---|---|---|
| Operating (expenditures) | LA County Open Expenditures | `42fc1819497e4ca0bc27be6afd5961e3` | `https://services.arcgis.com/RmCCgQtiZLDCtblq/arcgis/rest/services/Open_Expenditures/FeatureServer/0` | 103,901 | 2007-2026 |
| Budget (appropriations) | LA County Open Budget Appropriation | `4ce1f91f236f4bce85f35c198f3b34ea` | `https://services.arcgis.com/RmCCgQtiZLDCtblq/arcgis/rest/services/Open_Budget_AppropriationI/FeatureServer/0` | 2,774 | 2024-2026 only |
| Revenue | LA County Open Budget Revenue | `a10a164c74044a33ae9982c5884e8341` | `https://services.arcgis.com/RmCCgQtiZLDCtblq/arcgis/rest/services/Open_Budget_Revenue/FeatureServer/0` | not tested | not tested |
| Salaries | LA County Employee Salaries | `1fefbd3af4cf41fda827f2c23a1fe09b` | `https://services.arcgis.com/RmCCgQtiZLDCtblq/arcgis/rest/services/LA_County_Employee_Salaries/FeatureServer/0` | 1,301,144 | 2013-2024 |

**Rows per year for LA County Expenditures (2021-2025):**

| Fiscal Year | Row Count |
|---|---|
| 2021 | 500 |
| 2022 | 1,407 |
| 2023 | 7,877 |
| 2024 | 38,519 |
| 2025 | 37,157 |

**FY field name:** `Budget_Fiscal_Year` (string, e.g., `"2024"`). A separate `Fiscal_Year` field also exists and matches.

**Critical:** maxRecordCount = 2000 per ArcGIS query. FY2024 and FY2025 require 20+ pages each. The `exceededTransferLimit: true` field in response signals more pages exist. Pagination uses `resultOffset` parameter.

---

## Architecture Patterns

### Recommended Project Structure (New Files)

```
EV-Backend/internal/treasury/
├── importer.go          # Add ImportSocrataBudgets + ImportArcGISBudgets functions
├── socrata_fetcher.go   # (new) fetchSocrataCSV — simple HTTP GET returning io.ReadCloser
├── arcgis_fetcher.go    # (new) fetchArcGISFeatures — paginated JSON, returns []ArcGISFeature
├── arcgis_test.go       # (new) unit tests for ArcGIS tree building with fixture
└── testdata/
    └── la_county_expenditures_sample.json  # (new) fixture for ArcGIS tests
```

Alternatively, put all new fetch logic directly in `importer.go` to mirror Gateway pattern. The Gateway importer keeps `fetchGatewayCSV` and `buildGatewayCategoryTree` in the same file. Consistent style suggests LA County fetch code in `importer.go` too.

### Config Structure Extension

```json
{
  "gateway_entities": [...],
  "socrata_entities": [
    {
      "display_name": "Los Angeles",
      "state": "CA",
      "entity_type": "city",
      "base_url": "https://data.lacity.org",
      "fiscal_year_start_month": 7,
      "fiscal_years": [2021, 2022, 2023, 2024, 2025],
      "datasets": [
        {
          "dataset_type": "operating",
          "dataset_id": "5242-pnmt",
          "hierarchy_columns": ["Department_Name", "SubDepartment_Name", "Program_Name"],
          "amount_column": "Appropriation",
          "fiscal_year_column": "Fiscal_Year"
        }
      ]
    }
  ],
  "arcgis_entities": [
    {
      "display_name": "Los Angeles County",
      "state": "CA",
      "entity_type": "county",
      "fiscal_year_start_month": 7,
      "fiscal_years": [2021, 2022, 2023, 2024, 2025],
      "datasets": [
        {
          "dataset_type": "operating",
          "feature_server_url": "https://services.arcgis.com/RmCCgQtiZLDCtblq/arcgis/rest/services/Open_Expenditures/FeatureServer/0",
          "fiscal_year_field": "Budget_Fiscal_Year",
          "hierarchy_columns": ["Fund_Group", "Department", "Expenditure_Category", "Expenditure_Class"],
          "amount_column": "Amount"
        }
      ]
    }
  ]
}
```

### Pattern 1: Socrata CSV Fetch (LA City)

**What:** Simple HTTP GET to the Socrata CSV export endpoint. Returns full dataset as UTF-8 CSV. Filter by fiscal year in Go after download.

**When to use:** Any entity on data.lacity.org (classic Socrata platform)

```go
// Source: verified against data.lacity.org live API
func fetchSocrataCSV(client *http.Client, baseURL, datasetID string) (io.ReadCloser, error) {
    csvURL := fmt.Sprintf("%s/api/views/%s/rows.csv?accessType=DOWNLOAD", baseURL, datasetID)
    resp, err := client.Get(csvURL)
    if err != nil {
        return nil, fmt.Errorf("socrata fetch failed: %w", err)
    }
    if resp.StatusCode != http.StatusOK {
        resp.Body.Close()
        return nil, fmt.Errorf("socrata returned HTTP %d", resp.StatusCode)
    }
    contentType := resp.Header.Get("Content-Type")
    if strings.Contains(contentType, "text/html") || strings.Contains(contentType, "application/json") {
        resp.Body.Close()
        return nil, fmt.Errorf("socrata returned %s instead of CSV — dataset ID may be wrong", contentType)
    }
    return resp.Body, nil
}
```

**No encoding conversion needed:** Socrata serves UTF-8 natively. Remove `charmap.Windows1252` decoder used for Gateway (confirmed by live CSV inspection).

### Pattern 2: ArcGIS FeatureServer Paginated Fetch (LA County)

**What:** Paginated GET requests to ArcGIS FeatureServer `/query` endpoint. Each page returns up to 2000 JSON features. Uses `resultOffset` to walk through pages. Stops when `exceededTransferLimit` is absent or false.

**When to use:** Any entity on data.lacounty.gov (ArcGIS Hub platform, NOT Socrata)

```go
// Source: verified against services.arcgis.com live API
type ArcGISFeature struct {
    Attributes map[string]interface{} `json:"attributes"`
}

type ArcGISQueryResponse struct {
    Fields              []ArcGISField   `json:"fields"`
    Features            []ArcGISFeature `json:"features"`
    ExceededTransferLimit bool           `json:"exceededTransferLimit"`
}

func fetchArcGISFeatures(client *http.Client, featureServerURL, fiscalYear string, outFields []string) ([]ArcGISFeature, error) {
    const pageSize = 2000
    var all []ArcGISFeature
    offset := 0

    for {
        params := url.Values{}
        params.Set("where", fmt.Sprintf("Budget_Fiscal_Year='%s'", fiscalYear))
        params.Set("outFields", strings.Join(outFields, ","))
        params.Set("resultRecordCount", strconv.Itoa(pageSize))
        params.Set("resultOffset", strconv.Itoa(offset))
        params.Set("f", "json")

        queryURL := fmt.Sprintf("%s/query?%s", featureServerURL, params.Encode())
        resp, err := client.Get(queryURL)
        if err != nil {
            return nil, fmt.Errorf("arcgis page fetch (offset=%d) failed: %w", offset, err)
        }
        body, err := io.ReadAll(resp.Body)
        resp.Body.Close()
        if err != nil {
            return nil, fmt.Errorf("arcgis read body (offset=%d) failed: %w", offset, err)
        }

        var page ArcGISQueryResponse
        if err := json.Unmarshal(body, &page); err != nil {
            return nil, fmt.Errorf("arcgis JSON parse (offset=%d) failed: %w", offset, err)
        }

        all = append(all, page.Features...)

        if !page.ExceededTransferLimit || len(page.Features) == 0 {
            break
        }
        offset += pageSize
    }

    return all, nil
}
```

### Pattern 3: Socrata CSV Fiscal Year Filtering

The LA City appropriations dataset (`5242-pnmt`) contains all years 2010-2025 in one CSV (58,363 rows total). After download, filter rows by `Fiscal_Year` column value matching the target year.

```go
// Filter after CSV parse — straightforward column comparison
for _, row := range allRows {
    rowYear := strings.TrimSpace(getField(row, headerIdx, "Fiscal_Year"))
    if rowYear != strconv.Itoa(year) {
        continue
    }
    // process row...
}
```

### Pattern 4: Shared buildCategoryTree

`buildGatewayCategoryTree` in `importer.go` already accepts `records [][]string`, `headerIdx map[string]int`, and a config struct with `HierarchyColumns` and `AmountColumn`. The Socrata importer can use an adapter that converts the CSV rows + column names into the same format. The ArcGIS importer similarly converts `[]ArcGISFeature` → `[][]string` + `headerIdx`.

Or the existing tree builder can be lightly generalized: extract the core accumulator logic into a function that takes `getField func(col string) string` and `amount float64` per row — allowing both CSV and JSON callers.

### Anti-Patterns to Avoid

- **Using Socrata URL pattern on LA County:** `data.lacounty.gov/api/views/{id}/rows.csv` returns 404. LA County is ArcGIS Hub. Use FeatureServer endpoint.
- **Not paginating ArcGIS results:** maxRecordCount is 2000. FY2024 has 38,519 rows. Without pagination, only the first 2,000 rows are imported silently.
- **Downloading all years in one request:** ArcGIS FeatureServer allows WHERE clause filtering (`Budget_Fiscal_Year='2024'`). Filter per year to keep page counts manageable.
- **Using `f=csv` on FeatureServer `/query`:** Returns "Bad Request". The FeatureServer supports CSV only as an export format (separate endpoint), not as a query format. Use `f=json` for queries.
- **Assuming LA City Revenue fiscal year is an integer:** The `ih6g-qkwz` dataset stores fiscal year as `"2020-2021"` (range string). The `Fiscal Year Shorthand` column has end-year only. Mapping to the treasury `fiscal_year` int column requires parsing the end year from the string.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Paginating ArcGIS results | Custom retry loop with magic numbers | `resultOffset` + `exceededTransferLimit` standard ArcGIS paging pattern | Documented ArcGIS REST API contract |
| CSV parsing | Manual string splits | `encoding/csv` stdlib (already in use) | Handles quoting, escaping, and edge cases |
| Category tree accumulation | New tree builder | Reuse/adapt existing `buildGatewayCategoryTree` | Avoid duplication; same fund→dept→line pattern applies |
| DB insertion | New insert path | Reuse existing `importCategories` + transaction pattern | Already battle-tested in Bloomington/Gateway importers |
| Idempotency check | Timestamp-based | `(municipality_id, fiscal_year, dataset_type)` unique check (already implemented) | Consistent with Phase 92 schema gate |

---

## Key Data Schemas

### LA City Appropriations (dataset `5242-pnmt`)

| Column | Type | Example | Notes |
|---|---|---|---|
| `Dept_Code` | string | `70` | Numeric dept code |
| `Department_Name` | string | `Police` | Human-readable |
| `SubDept_Code` | string | `70LVL5` | Sub-dept code |
| `SubDepartment_Name` | string | `Police` | Often same as Dept |
| `Prog_Code` | string | `` | Frequently empty for 2010-2013 |
| `Program_Name` | string | `` | Frequently empty for older years |
| `Program_Priority` | string | `` | Often empty |
| `Source_Fund_Code` | string | `` | Often empty |
| `Source_Fund_Name` | string | `` | Often empty |
| `Account_Code` | string | `` | Often empty |
| `Account_Name` | string | `` | Often empty |
| `Appropriation` | number | `1166229399` | Dollar amount (no decimals needed, large numbers) |
| `Fiscal_Year` | integer | `2021` | Filter target |
| `Expense_Type` | string | `Salaries` | Optional categorization |

**Recommended hierarchy_columns for operating dataset:** `["Department_Name", "SubDepartment_Name", "Program_Name"]` — these are the columns with consistent data post-2014. Pre-2014 data (2010-2013) only has dept-level aggregates, but 2021-2025 data is detailed.

**Note on `Appropriation` column:** Has a leading space in the header (`" Appropriation "`). `strings.TrimSpace()` on header names is required (already done in `validateHeaders`).

### LA County Expenditures (FeatureServer, FY2021-2025)

| Field | ArcGIS Type | Example Value | Notes |
|---|---|---|---|
| `Budget_Fiscal_Year` | string | `"2024"` | Primary year filter field |
| `Fiscal_Year` | string | `"2024"` | Matches Budget_Fiscal_Year |
| `Fund_Group_Code` | string | `"001"` | Fund group code |
| `Fund_Group` | string | `"General Fund"` | Top-level hierarchy |
| `Fund_Code` | string | `"1"` | Fund code |
| `Fund` | string | `"GENERAL"` | Fund name |
| `Function_Code` | string | `"10"` | Function code |
| `Function_` | string | `"General"` | Function name (trailing underscore is field name) |
| `Department_Code` | string | `"280"` | Dept code |
| `Department` | string | `"Chief Executive Office"` | Department name |
| `Budget_Unit_Code` | string | `"2801"` | Budget unit code |
| `Budget_Unit` | string | `"CEO Administration"` | Budget unit |
| `Expenditure_Category_Code` | string | `"30"` | Category code |
| `Expenditure_Category` | string | `"Salaries & Employee Benefits"` | Category |
| `Expenditure_Class_Code` | string | `"31"` | Class code |
| `Expenditure_Class` | string | `"Salaries & Wages"` | Class (most granular) |
| `Amount` | double | `2741537.29` | Dollar amount, can be negative |

**Recommended hierarchy_columns for operating dataset:** `["Fund_Group", "Department", "Expenditure_Category", "Expenditure_Class"]` — 4 levels matching the county's natural reporting hierarchy. This gives the frontend rich drill-down capability.

**Note on negative amounts:** The expenditure data includes negative amounts (credits/adjustments). The existing `parseAmount` function handles parenthesized negatives for Gateway data; for ArcGIS JSON the values come as raw floats, no parsing needed. Negative amounts should be passed through as-is — they represent real adjustments.

### LA County Salary (FeatureServer, 1.3M rows)

| Field | Type | Notes |
|---|---|---|
| `Year` | string | `"2024"` |
| `Employee_Last_Name`, `Employee_First_Name` | string | Individual-level PII |
| `Department` | string | Aggregation key |
| `Total_Earnings`, `Total_Benefits`, `Total_Compensation` | double | Financial fields |
| Many more | double | `Base_Earnings`, `Overtime_Earnings`, etc. |

**Scale concern:** 1.3M rows total. For 2021-2025 this is likely 500K+ rows. This is suitable for `BudgetLineItem` records (individual employees), but each page fetch returns only 2,000 records, requiring ~250+ HTTP requests per year. This should work but will be slow. Consider adding a timeout/retry mechanism.

---

## Common Pitfalls

### Pitfall 1: LA County is NOT Socrata

**What goes wrong:** Attempting to use the Socrata CSV URL pattern (`/api/views/{id}/rows.csv`) on data.lacounty.gov returns HTTP 404.
**Why it happens:** data.lacounty.gov uses ArcGIS Hub, not the Socrata platform.
**How to avoid:** Use the ArcGIS FeatureServer query endpoint (`/query?where=...&f=json`).
**Warning signs:** HTTP 404 response when fetching data.lacounty.gov with Socrata-style URL.

### Pitfall 2: ArcGIS Pagination Silent Truncation

**What goes wrong:** The query returns 2,000 rows and the importer assumes that's all the data. FY2024 has 38,519 rows; only 5.2% of the data would be imported.
**Why it happens:** ArcGIS silently caps at `maxRecordCount=2000` without error.
**How to avoid:** Always check `exceededTransferLimit` in the response. Loop with `resultOffset` until `exceededTransferLimit` is absent/false.
**Warning signs:** `totalBudget` is much lower than expected county-level spend (~$38B for LA County).

### Pitfall 3: Appropriation Column Header Has Leading/Trailing Space

**What goes wrong:** `validateHeaders` fails to find the `Appropriation` column because the LA City CSV header is `" Appropriation "` (with spaces).
**Why it happens:** Socrata data quality issue in this specific dataset.
**How to avoid:** The existing `validateHeaders` already calls `strings.TrimSpace(h)` on each header — this pitfall is pre-handled. Verify the config uses `"Appropriation"` (not `" Appropriation "`) as the amount_column value.
**Warning signs:** Header validation error mentioning Appropriation column missing.

### Pitfall 4: LA City Revenue Fiscal Year is a Range String

**What goes wrong:** Trying to filter LA City revenue by integer year fails because `Fiscal Year` contains `"2020-2021"`, not `"2021"`.
**Why it happens:** The revenue dataset uses a different FY naming convention than the appropriations dataset.
**How to avoid:** For revenue dataset, match using `Fiscal Year Shorthand` column (end year as integer-like string) or extract the last 4 characters of `Fiscal Year`. Document in config which column to use for year filtering.
**Warning signs:** 0 rows imported for revenue data despite the year being in range.

### Pitfall 5: ArcGIS FeatureServer WHERE Clause Quoting

**What goes wrong:** SQL-style WHERE clause with unquoted string fails. `Budget_Fiscal_Year=2024` returns Bad Request.
**Why it happens:** `Budget_Fiscal_Year` is an `esriFieldTypeString` field, not integer. Must use `'2024'` (single-quoted string).
**How to avoid:** Always quote the fiscal year value in the WHERE clause: `Budget_Fiscal_Year='2024'`.
**Warning signs:** ArcGIS returns `{"error": {...}}` JSON with "Bad Request" or "Invalid query" message instead of features.

### Pitfall 6: LA County Appropriation Dataset Has Very Few Historical Years

**What goes wrong:** The budget appropriation dataset (`4ce1f91f236f4bce85f35c198f3b34ea`) only covers FY2024-2026 (2,774 rows total). It will produce zero results for 2021-2023.
**Why it happens:** LA County started publishing appropriation detail data more recently than expenditure actuals.
**How to avoid:** For LA County operating data, use the **expenditures** dataset (not appropriations). Document in config: LA County operating = expenditures dataset, not budget appropriation.
**Warning signs:** Empty import result for LA County 2021-2023.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Socrata assumed for all CA portals | LA County uses ArcGIS Hub; LA City uses Socrata | Need two distinct fetch strategies |
| Single CSV download | ArcGIS requires paginated JSON queries | More complex fetch loop, but well-documented API |
| Gateway: Windows-1252 encoding | Socrata/ArcGIS: UTF-8 native | No charset conversion needed for CA data |

---

## Open Questions

1. **LA County Revenue Dataset Coverage**
   - What we know: Revenue FeatureServer URL identified (`Open_Budget_Revenue`), but row count and fiscal year range not verified.
   - What's unclear: Whether 2021-2025 data is available.
   - Recommendation: Plan a "discover and skip if empty" approach — attempt import, log warning if no rows found for target years.

2. **LA City Salary Data**
   - What we know: No multi-year employee salary dataset was found on data.lacity.org via Socrata catalog search.
   - What's unclear: Whether LA City publishes individual-level salary data at all, or only at the account-level (which is already in the appropriations dataset under `Expense_Type: "Salaries"`).
   - Recommendation: Mark LA City salary as not available in this phase. The appropriations dataset already includes salary appropriations rolled up by department. This satisfies D-06's intent at a different granularity.

3. **ArcGIS FeatureServer Request Rate Limits**
   - What we know: Public dataset, no API key required. Standard ArcGIS Online public service.
   - What's unclear: Whether rate limiting applies for 20+ consecutive requests per year × 5 years = 100+ requests for LA County operating data.
   - Recommendation: Add a small delay (100ms) between ArcGIS pages or implement retry with backoff. Use 60-second timeout per request (same as Gateway).

4. **LA County Salary — Import Feasibility**
   - What we know: 1.3 million total rows; 2,000-row page size; 2021-2024 coverage.
   - What's unclear: How many pages per year (likely 30,000-80,000 rows per year = 15-40 pages).
   - Recommendation: Include salary import in the plan but flag as "may be slow" (5-10 minutes). The existing idempotency check protects against partial re-runs.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Go | Build/run importer | Yes | 1.24.3 | — |
| PostgreSQL (Supabase) | DB insertion | Yes (via DATABASE_URL) | Supabase-managed | — |
| data.lacity.org | LA City CSV fetch | Yes (public) | Live, verified | — |
| services.arcgis.com | LA County FeatureServer | Yes (public) | Live, verified | — |
| Internet access on build machine | Fetch at import time | Yes | — | — |

**No missing dependencies with no fallback.**

---

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Go testing stdlib (table-driven tests) |
| Config file | none (Go test discovery by convention) |
| Quick run command | `cd EV-Backend && go test ./internal/treasury/... -run TestSocrata -v` |
| Full suite command | `cd EV-Backend && go test ./internal/treasury/... -v` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| LA-01 | LA County ArcGIS feature-to-tree conversion | unit | `go test ./internal/treasury/... -run TestBuildArcGISCategoryTree -v` | No — Wave 0 |
| LA-01 | LA County pagination stops at last page | unit | `go test ./internal/treasury/... -run TestArcGISPagination -v` | No — Wave 0 |
| LA-02 | LA City CSV row-to-tree conversion | unit | `go test ./internal/treasury/... -run TestBuildSocrataCategoryTree -v` | No — Wave 0 |
| LA-02 | LA City CSV fiscal year filtering | unit | `go test ./internal/treasury/... -run TestSocrataFiscalYearFilter -v` | No — Wave 0 |
| LA-03 | fiscal_year_start_month=7 set on CA Budget records | unit (integration) | `go test ./internal/treasury/... -run TestCAFiscalYearStartMonth -v` | No — Wave 0 |

### Sampling Rate

- **Per task commit:** `cd EV-Backend && go test ./internal/treasury/... -v`
- **Per wave merge:** `cd EV-Backend && go test ./... -v`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `EV-Backend/internal/treasury/arcgis_test.go` — covers LA-01 (ArcGIS tree build, pagination logic)
- [ ] `EV-Backend/internal/treasury/testdata/la_county_expenditures_sample.json` — fixture for ArcGIS tests
- [ ] `EV-Backend/internal/treasury/testdata/la_city_appropriations_sample.csv` — fixture for Socrata tests

---

## Project Constraints (from CLAUDE.md)

- Git remote: `git@github.com:chrisandrewsedu/<repo>.git`
- NEVER commit `.env` or `.env.local` files
- NEVER publish API keys, tokens, passwords
- Go backend at `EV-Backend/` — no Express port this milestone
- New treasury fetch code goes in `EV-Backend/internal/treasury/`
- `FiscalYearStartMonth` field already exists in Budget GORM model — no schema migration needed for LA-03

---

## Sources

### Primary (HIGH confidence)

- Live API: `https://services.arcgis.com/RmCCgQtiZLDCtblq/arcgis/rest/services/Open_Expenditures/FeatureServer/0?f=json` — field schema verified
- Live API: `https://data.lacity.org/api/views/5242-pnmt/rows.csv?accessType=DOWNLOAD` — column headers and row counts verified
- Live API: `https://data.lacity.org/api/views/ih6g-qkwz/rows.csv?accessType=DOWNLOAD` — revenue dataset column schema verified
- Live API: ArcGIS item metadata for all 4 LA County datasets via `arcgis.com/sharing/rest/content/items/{id}?f=json`

### Secondary (MEDIUM confidence)

- Socrata discovery API `api.us.socrata.com/api/catalog/v1?domains=data.lacity.org` — confirmed dataset inventory for lacity.org
- `/tmp/lacounty_catalog.json` (DCAT-US catalog from data.lacounty.gov) — identified all 4 LA County budget datasets and their ArcGIS item IDs

### Tertiary (LOW confidence)

- LA City salary dataset availability: Socrata catalog search found no multi-year employee salary dataset on data.lacity.org. Absence confirmed by catalog query but not by official documentation.

---

## Metadata

**Confidence breakdown:**

- LA City dataset ID and schema: HIGH — verified by live CSV download
- LA County FeatureServer URL and schema: HIGH — verified by live API call
- LA County pagination requirement: HIGH — confirmed by `exceededTransferLimit: true` on FY2024 query
- LA City salary data unavailability: MEDIUM — catalog search found nothing, but not verified with official documentation
- LA County revenue dataset year coverage: LOW — URL identified but rows not tested

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (ArcGIS FeatureServer URLs are stable; Socrata dataset ID `5242-pnmt` is stable with annual updates)
