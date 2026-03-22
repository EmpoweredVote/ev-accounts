# Phase 93: Indiana Data Import - Research

**Researched:** 2026-03-22
**Domain:** Go CSV parsing, Indiana Gateway data format, treasury importer extension
**Confidence:** MEDIUM (column schema for budget-specific download is partially inferred; AFR disbursement columns are documented, budget-specific columns need runtime verification)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Automated fetch — the importer downloads CSV data directly from Indiana Gateway URLs at runtime. No manual file download step.
- **D-02:** Fetch is built into the `import-budgets` CLI command (via a source/format parameter), not a separate download step. One command fetches and imports.
- **D-03:** Validate column headers before processing rows. Fail fast with a clear error if the expected columns are missing or the format has changed.
- **D-04:** Extend the existing `ImportBudgets` function with a source/format parameter. JSON path for Bloomington, Gateway fetch+parse for Indiana entities. Shared municipality lookup and category insertion logic.
- **D-05:** Build hierarchy tree from CSV columns — use the Gateway's fund > department > account columns as hierarchy levels. Each unique combination becomes a BudgetCategory with parent references, matching the existing tree structure.
- **D-06:** Delimiter is configurable per source via `ImportBudgetsConfig`. Gateway defaults to pipe (`|`), but the config supports other delimiters for future sources.
- **D-07:** Entity metadata (name, state, entity_type, Gateway URL, delimiter, hierarchy column mappings) lives in a treasury-specific config file (e.g., `treasury-import-config.json`). Separate from the essentials `pipeline_config.json`.
- **D-08:** Config controls the display name directly — "Monroe County" is stored as the municipality name, not derived from entity_type + "Monroe". What's in the config is what's stored and displayed.
- **D-09:** Import all available dataset types (operating, revenue, and any others the Gateway provides), not just operating. Expand beyond the minimum requirements.
- **D-10:** Fiscal year coverage matches Bloomington: 2021-2025. Skip older data even if available on the Gateway.

### Claude's Discretion

- Pipeline config file structure and field naming
- HTTP client details for Gateway fetch (timeouts, retries, user-agent)
- UTF-8 re-encoding implementation approach

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IND-01 | Ellettsville operating budget imported from Indiana Gateway (pipe-delimited format) | D-01/D-04/D-06: CLI fetch+parse path; pipe delimiter config; municipality find-or-create with entity_type=city |
| IND-02 | Monroe County operating budget imported from Indiana Gateway | D-07/D-08: treasury-import-config.json with name="Monroe County", entity_type=county; same parse path as IND-01 |
| IND-03 | Import script handles pipe-delimited format with explicit delimiter and encoding configuration | D-06: delimiter field in ImportBudgetsConfig; golang.org/x/text/encoding/charmap for Windows-1252→UTF-8 re-encoding already in go.mod |

</phase_requirements>

---

## Summary

Phase 93 extends the existing `ImportBudgets` Go CLI function — which currently reads Bloomington JSON files — to support fetching and parsing Indiana Gateway pipe-delimited CSV exports for Ellettsville (city) and Monroe County (county). The work is entirely backend Go code; no schema changes are needed since Phase 92 already landed the three-column unique index, `entity_type`, and `fiscal_year_start_month`.

The Indiana Gateway serves pipe-delimited files with a Windows-1252 or Latin-1 encoding that must be explicitly re-encoded to UTF-8 before CSV parsing. The `golang.org/x/text` package is already in `go.mod` (v0.25.0), so no new dependencies are required. The importer wraps the raw HTTP response body with `transform.NewReader` using `charmap.Windows1252.NewDecoder()` before handing it to `csv.NewReader` with `Comma` set to `'|'`.

The biggest open risk is the exact column names in the Gateway's budget download file. The file layout documentation (`.xls`) describes Budget Form 1 columns (fund/dept/line-item appropriations) but the exact header strings are not publicly confirmed without downloading a sample file. Column validation (D-03) is the safety net: fail fast with a descriptive error if headers don't match expectations.

**Primary recommendation:** Implement Gateway fetch+parse as a new `importGatewaySource()` function in `importer.go`, driven by a `treasury-import-config.json` config file. The existing `importCategories` recursive helper is reused without changes for DB insertion.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `encoding/csv` (stdlib) | Go 1.24+ | CSV parsing with configurable delimiter | Built-in, zero deps; `Comma` field accepts `'|'` directly |
| `net/http` (stdlib) | Go 1.24+ | HTTP fetch of Gateway download URL | Built-in; sufficient for simple GET with timeout |
| `golang.org/x/text/encoding/charmap` | v0.25.0 (already in go.mod) | Windows-1252 → UTF-8 decoding | Required because Gateway files are not guaranteed UTF-8 |
| `golang.org/x/text/transform` | v0.25.0 (already in go.mod) | Wraps `io.Reader` for transparent encoding conversion | Pairs with charmap decoder; zero-copy streaming |
| `encoding/json` (stdlib) | Go 1.24+ | Parse `treasury-import-config.json` | Built-in |

### No New Dependencies

All required packages are already in `go.mod`. No `go get` step needed.

### Installation

No additional installation. All packages already present:
```bash
# Verify — should show current versions
grep -E "golang.org/x/text" EV-Backend/go.mod
```

---

## Architecture Patterns

### Recommended File Structure Changes

```
EV-Backend/
├── internal/treasury/
│   ├── importer.go          # Add importGatewaySource(), GatewayEntityConfig, ImportBudgetsConfig extension
│   ├── models.go            # No changes
│   ├── handlers.go          # No changes
│   └── setup.go             # No changes
├── main.go                  # Add --source=gateway and --config= flags to import-budgets case
└── treasury-import-config.json  # New: entity metadata for Gateway sources
```

### Pattern 1: Config-Driven Gateway Fetch

**What:** A `treasury-import-config.json` file (separate from `scripts/pipeline_config.json`) defines all Gateway entities. Each entity specifies display name, state, entity_type, base URL pattern, and hierarchy column mappings.

**When to use:** Any time a new Indiana Gateway entity is added. No code changes needed to import additional units.

**Example config structure:**
```json
{
  "gateway_entities": [
    {
      "display_name": "Ellettsville",
      "state": "IN",
      "entity_type": "city",
      "unit_code": "5304",
      "base_url": "https://gateway.ifionline.org/public/download.aspx",
      "delimiter": "|",
      "encoding": "windows-1252",
      "fiscal_year_start_month": 1,
      "dataset_types": ["operating", "revenue"],
      "hierarchy_columns": ["fund_name", "dept_name", "line_description"]
    },
    {
      "display_name": "Monroe County",
      "state": "IN",
      "entity_type": "county",
      "unit_code": "5500",
      "base_url": "https://gateway.ifionline.org/public/download.aspx",
      "delimiter": "|",
      "encoding": "windows-1252",
      "fiscal_year_start_month": 1,
      "dataset_types": ["operating", "revenue"],
      "hierarchy_columns": ["fund_name", "dept_name", "line_description"]
    }
  ]
}
```

**Note on unit_code:** The Indiana Gateway identifies units by a numeric code used as a URL/form parameter. The exact codes for Ellettsville and Monroe County must be confirmed by loading the download page and inspecting the unit dropdown. Monroe County is county FIPS 055 in Indiana; Ellettsville is a town within Monroe County. The Gateway download form uses a POST with selections; the actual download URL pattern requires inspection of the form submission.

### Pattern 2: Encoding-Safe CSV Reader

**What:** Wrap the HTTP response body with a Windows-1252 decoder before creating the CSV reader. Set `Comma` to `'|'` on the CSV reader.

**When to use:** All Gateway CSV reads. The encoding wrapper must precede CSV parsing to prevent silent misparse of non-ASCII characters in fund/department names.

**Example:**
```go
// Source: golang.org/x/text/encoding/charmap + golang.org/x/text/transform docs
import (
    "encoding/csv"
    "golang.org/x/text/encoding/charmap"
    "golang.org/x/text/transform"
)

func newGatewayCSVReader(body io.ReadCloser) *csv.Reader {
    // Re-encode Windows-1252 → UTF-8 transparently
    utf8Reader := transform.NewReader(body, charmap.Windows1252.NewDecoder())
    r := csv.NewReader(utf8Reader)
    r.Comma = '|'
    r.LazyQuotes = true   // Gateway data may have unescaped quotes
    r.TrimLeadingSpace = true
    return r
}
```

### Pattern 3: Column Header Validation (D-03)

**What:** Read the first row, build a header-to-index map, then assert required columns exist before processing any data rows.

**Example:**
```go
func validateHeaders(headers []string, required []string) (map[string]int, error) {
    idx := make(map[string]int, len(headers))
    for i, h := range headers {
        idx[strings.TrimSpace(h)] = i
    }
    var missing []string
    for _, col := range required {
        if _, ok := idx[col]; !ok {
            missing = append(missing, col)
        }
    }
    if len(missing) > 0 {
        return nil, fmt.Errorf("gateway CSV missing required columns: %v (got: %v)", missing, headers)
    }
    return idx, nil
}
```

### Pattern 4: Hierarchy Tree Construction from Flat CSV

**What:** The Gateway CSV is flat — each row represents a single line item with fund/department/account columns. Build the three-level BudgetCategory tree by accumulating unique (fund, dept) combinations and tracking parent IDs.

**When to use:** After successfully parsing all rows into an in-memory slice, before calling `importCategories`.

**Approach:**
```
For each CSV row:
  1. Look up or create a fund-level BudgetCategory (depth=0)
  2. Look up or create a dept-level BudgetCategory under that fund (depth=1)
  3. Sum the row's amount into both parent totals
  4. Optionally create line item (depth=2) if line_description is granular

After all rows processed:
  Call importCategories(tx, budgetID, nil, rootCategories, 0) with accumulated tree
```

This matches the existing `importCategories` signature exactly — no changes to that function.

### Anti-Patterns to Avoid

- **Assuming UTF-8:** Never pass the raw Gateway response body directly to `csv.NewReader` without the encoding wrapper. Silent misparse produces garbled department names and potentially zero-amount rows if the amount field crosses a multi-byte boundary.
- **Hardcoding unit IDs in Go code:** All Gateway entity metadata belongs in `treasury-import-config.json`, not as constants in `importer.go`.
- **Skipping header validation:** Reading column by positional index fails silently if the Gateway changes column order. Always use a header map.
- **Importing into a transaction that reads mid-way:** The existing pattern (begin tx → find-or-create municipality → check idempotent → insert budget → insert categories → commit) must be followed exactly. Do not split the municipality and budget inserts into separate transactions.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Character encoding conversion | Custom byte-replacement loop | `golang.org/x/text/encoding/charmap` + `transform.NewReader` | Already in go.mod; handles all Windows-1252 edge cases including extended Latin characters common in Indiana place names |
| CSV parsing with pipe delimiter | Manual `strings.Split(line, "\|")` | `encoding/csv` with `Comma: '|'` | stdlib handles quoted fields, newlines inside quotes, and lazy quote mode correctly |
| HTTP fetch with timeout | Raw `http.Get` with no timeout | `http.Client{Timeout: 30 * time.Second}` | Gateway is a government site; without timeout, import can hang indefinitely |

**Key insight:** No new external libraries are needed. The entire Gateway integration uses stdlib + already-imported packages.

---

## Runtime State Inventory

> Phase 93 is greenfield data import (new records into existing schema). Not a rename/refactor phase.

Not applicable — no runtime state is renamed or migrated. New municipality records ("Ellettsville", "Monroe County") are net-new inserts. The idempotency check (`municipality_id, fiscal_year, dataset_type`) ensures re-runs are safe.

---

## Common Pitfalls

### Pitfall 1: Silent Zero-Amount Rows from Encoding Misparse

**What goes wrong:** If the Gateway file is Windows-1252 and the importer reads it as UTF-8, multi-byte characters in amount fields (unlikely but possible in edge rows) or in fund/department name fields can corrupt the column alignment, causing `strconv.ParseFloat` to return 0 or an error that gets silently skipped.

**Why it happens:** `encoding/csv` uses rune-based parsing internally. A raw Windows-1252 byte stream that isn't valid UTF-8 produces replacement characters or parsing errors in rune-based reads.

**How to avoid:** Always wrap with `transform.NewReader(body, charmap.Windows1252.NewDecoder())` before creating the CSV reader. Log and count zero-amount rows explicitly; fail if > 5% of rows have zero amounts.

**Warning signs:** Category tree imports successfully but all amounts are 0. Total budget mismatch between Gateway report UI and imported sum.

### Pitfall 2: Gateway Download Form Requires POST (not GET)

**What goes wrong:** The Indiana Gateway download page uses a form POST with ASP.NET ViewState and selected parameters (unit type, unit code, year, dataset type). A raw `http.Get` to the download URL will return the HTML selection form, not the file.

**Why it happens:** The site is built on ASP.NET WebForms; downloads are triggered by form submission, not direct URL access.

**How to avoid:** Inspect the download form submission in browser DevTools to identify the POST endpoint, required form fields (ViewState, EventTarget, unit selection parameters), and response Content-Type. Alternatively, use direct file download links if the Gateway exposes them (verify during implementation). If POST is required, use `http.PostForm` with the correct parameters.

**Warning signs:** Response Content-Type is `text/html` instead of `text/plain` or `application/octet-stream`. Response body starts with `<!DOCTYPE html>`.

**Investigation required:** Before implementation, the developer must manually download one Gateway budget file for Ellettsville (any year) and inspect: (a) the POST parameters sent, (b) the response Content-Type, (c) the actual column headers in the first row of the file. This is the STATE.md blocker for Phase 93: "Download and inspect Indiana Gateway sample files for Ellettsville and Monroe County before writing transforms."

### Pitfall 3: Hierarchy Column Names May Differ from AFR Column Names

**What goes wrong:** The file layout documentation downloaded is for the Annual Financial Report (AFR disbursements), which has columns like `disburse_class_name`, `department_name`, `fund_code`. The Budget download file (Budget Form 1 data) may use different column names such as `Fund_Name`, `Department`, `Line_Item_Description` or similar.

**Why it happens:** Indiana Gateway has separate download datasets (AFR vs Budget). Each has its own file layout. The budget-specific file layout was not fully decoded from the `.xls` documentation retrieved.

**How to avoid:** The column header validation (D-03) catches this at runtime. Additionally, the `hierarchy_columns` array in `treasury-import-config.json` makes column names configurable without code changes. After downloading the first sample file, update the config with actual column names.

**Warning signs:** Header validation error at startup: "gateway CSV missing required columns: [fund_name dept_name ...]".

### Pitfall 4: Amount Field Format Variations

**What goes wrong:** The Gateway amount field may use comma-formatted numbers (`1,234,567.00`), parentheses for negatives (`(12,345.00)`), or blank strings for zero. `strconv.ParseFloat` fails on all of these.

**Why it happens:** Government financial systems often export amounts in human-readable formats, not machine-parseable floats.

**How to avoid:** Write a `parseAmount(s string) (float64, error)` helper that strips commas, converts parentheses to negative sign, trims whitespace, and treats blank as 0. Log any unparseable values explicitly.

---

## Code Examples

### Extending ImportBudgetsConfig

```go
// Source: existing importer.go pattern, extended per D-04/D-06
type ImportBudgetsConfig struct {
    // Existing Bloomington JSON fields
    DataDir string
    DryRun  bool

    // New Gateway fields
    Source     string // "bloomington" (default) or "gateway"
    ConfigFile string // path to treasury-import-config.json
}
```

### HTTP Fetch with Timeout

```go
// Source: net/http stdlib docs
client := &http.Client{Timeout: 30 * time.Second}
req, err := http.NewRequest("POST", gatewayURL, strings.NewReader(formValues.Encode()))
req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
req.Header.Set("User-Agent", "EmpoweredVote-Treasury-Importer/1.0")
resp, err := client.Do(req)
if err != nil {
    return fmt.Errorf("gateway fetch failed: %w", err)
}
defer resp.Body.Close()
if resp.StatusCode != http.StatusOK {
    return fmt.Errorf("gateway returned status %d", resp.StatusCode)
}
```

### main.go CLI Extension Pattern

```go
// Following the existing import-budgets case pattern in main.go
case "import-budgets":
    jsonDir := "treasury-tracker/public/data"
    source := "bloomington"
    configFile := "treasury-import-config.json"
    dryRun := false
    for _, arg := range os.Args[2:] {
        switch {
        case arg == "--dry-run":
            dryRun = true
        case strings.HasPrefix(arg, "--data-dir="):
            jsonDir = strings.TrimPrefix(arg, "--data-dir=")
        case strings.HasPrefix(arg, "--source="):
            source = strings.TrimPrefix(arg, "--source=")
        case strings.HasPrefix(arg, "--config="):
            configFile = strings.TrimPrefix(arg, "--config=")
        }
    }
    result, err := treasury.ImportBudgets(treasury.ImportBudgetsConfig{
        DataDir:    jsonDir,
        Source:     source,
        ConfigFile: configFile,
        DryRun:     dryRun,
    })
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static JSON fallback in dataLoader.ts | API-only loading (Phase 92) | Phase 92 complete | No static files remain; all new entities go through API |
| `treasury.cities` table | `treasury.municipalities` with entity_type | Phase 92 complete | Monroe County uses entity_type="county" without schema changes |

---

## Open Questions

1. **Gateway download POST parameters**
   - What we know: The download page uses ASP.NET WebForms; a POST is likely required with unit selection parameters
   - What's unclear: Exact POST body fields (ViewState, unit code for Ellettsville, dataset type selector). Also unknown: whether the site has rate limiting or requires a session cookie.
   - Recommendation: Manual browser inspection is required before implementation (acknowledged in STATE.md as a pre-implementation step). Capture the POST request in DevTools for both Ellettsville and Monroe County for at least one year/dataset combination.

2. **Exact budget CSV column headers**
   - What we know: AFR disbursement file has `department_name`, `fund_code`, `unit_fund_name`, `amount`. Budget download file (Form 1 data) has entity/fund/department identification and appropriation amounts — column names inferred but not confirmed.
   - What's unclear: Whether the budget file uses `Fund_Name`, `fund_name`, `FUND_NAME`, or something else. Same for department and line item description columns.
   - Recommendation: The config-driven `hierarchy_columns` array (D-07) makes this a config change, not a code change. Column validation (D-03) will surface mismatches immediately on first run.

3. **Available years and dataset types for Ellettsville**
   - What we know: Gateway claims 2012–2025 coverage. D-10 limits to 2021–2025.
   - What's unclear: Whether Ellettsville (a small town) has submitted data for all years in scope, and which dataset types (operating, revenue, salary) are available for each year.
   - Recommendation: The existing `result.Skipped` counter handles missing files gracefully. Import will skip years where data is absent.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Go runtime | importer.go compilation | ✓ | 1.26.1 | — |
| `golang.org/x/text` | UTF-8 re-encoding | ✓ | v0.25.0 (in go.mod) | — |
| `encoding/csv` | CSV parsing | ✓ | stdlib (Go 1.24+) | — |
| Indiana Gateway URL | Runtime data fetch | Unknown | — | Manual download fallback (defeats D-01) |
| Supabase (isolated) | Write imported data | ✓ (per CLAUDE.md setup) | — | — |

**Missing dependencies with no fallback:**
- Indiana Gateway network access at import runtime — if the Gateway is unreachable, the import cannot run. No offline fallback per D-01. The developer must confirm the Gateway is accessible from the machine where the CLI will run.

---

## Validation Architecture

> `workflow.nyquist_validation` is not explicitly set to false in config.json — treating as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Go testing (`go test ./...`) |
| Config file | none (standard Go test discovery) |
| Quick run command | `cd EV-Backend && go test ./internal/treasury/... -v -run TestGateway` |
| Full suite command | `cd EV-Backend && go test ./...` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| IND-01 | Ellettsville CSV parses and inserts without errors | integration (needs DB) | `go test ./internal/treasury/... -run TestImportGatewayEllettsville` | ❌ Wave 0 |
| IND-02 | Monroe County inserts with entity_type=county, name="Monroe County" | integration (needs DB) | `go test ./internal/treasury/... -run TestImportGatewayMonroeCounty` | ❌ Wave 0 |
| IND-03 | Pipe delimiter and Windows-1252 re-encoding visible in code; zero-amount detection | unit | `go test ./internal/treasury/... -run TestParseGatewayCSV` | ❌ Wave 0 |

**Note:** Integration tests for IND-01 and IND-02 require a live Supabase connection. They may be implemented as dry-run tests (parse only, no DB writes) with manual verification for the full DB round-trip, per the established Phase 92 validation pattern (API round-trip check).

### Sampling Rate

- **Per task commit:** `cd EV-Backend && go build ./...` (compilation check)
- **Per wave merge:** `cd EV-Backend && go test ./internal/treasury/... -v`
- **Phase gate:** API round-trip verification — after import, `curl https://api.empowered.vote/treasury/municipalities` shows Ellettsville and Monroe County, and category totals match Gateway report UI

### Wave 0 Gaps

- [ ] `EV-Backend/internal/treasury/importer_gateway_test.go` — covers IND-01, IND-02, IND-03 with sample CSV fixture
- [ ] `EV-Backend/internal/treasury/testdata/gateway_sample_ellettsville.txt` — sample pipe-delimited fixture (manually captured from Gateway)

---

## Sources

### Primary (HIGH confidence)
- `EV-Backend/internal/treasury/importer.go` — existing ImportBudgets function structure, ImportBudgetsConfig, importCategories reuse pattern
- `EV-Backend/internal/treasury/models.go` — Municipality, Budget, BudgetCategory, BudgetLineItem GORM models
- `EV-Backend/go.mod` — confirmed `golang.org/x/text v0.25.0` already in dependencies
- `pkg.go.dev/encoding/csv` — Comma field for pipe delimiter, LazyQuotes
- `pkg.go.dev/golang.org/x/text/encoding` — charmap.Windows1252 decoder + transform.NewReader pattern

### Secondary (MEDIUM confidence)
- [Indiana Gateway Download Page](https://gateway.ifionline.org/public/download.aspx) — confirmed pipe-delimited format, confirmed form-based download (not direct URL), file layout documentation links
- [Budget File Layout Documentation XLS](https://gateway.ifionline.org/guides/downloads/FileLayoutDocumentation_budgets.xls) — partial column recovery (fund/dept/year/unit identification columns confirmed; exact budget appropriation column names inferred)
- [AFR File Layout Documentation XLS](https://gateway.ifionline.org/guides/downloads/FileLayoutDocumentation_AFR.xls) — disbursement column names (department_name, fund_code, amount) as reference; may differ from Budget dataset columns

### Tertiary (LOW confidence)
- WebSearch finding: Gateway files are pipe-delimited with no confirmed encoding specification — Windows-1252 is the standard for ASP.NET WebForms government systems of this era, but has not been confirmed by downloading an actual file

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages confirmed in go.mod; patterns are standard Go
- Architecture: HIGH — importer.go extension pattern is well-established; config-driven approach mirrors existing pipeline_config.json
- Gateway column schema: LOW — file layout XLS was partially decoded; exact budget column names require runtime confirmation via first download + header validation error
- Pitfalls: MEDIUM — POST requirement inferred from ASP.NET WebForms pattern; encoding assumption (Windows-1252) is standard for this class of government system but unconfirmed

**Research date:** 2026-03-22
**Valid until:** 2026-04-22 (Gateway format is stable government infrastructure; low churn risk)
