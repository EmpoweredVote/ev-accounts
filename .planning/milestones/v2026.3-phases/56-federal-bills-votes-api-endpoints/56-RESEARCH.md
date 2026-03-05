# Phase 56: Federal Bills, Votes & API Endpoints - Research

**Researched:** 2026-03-02
**Domain:** Congress.gov API v3 client, LegiScan batch import, Go CLI subcommands, GORM upsert, Chi route handlers
**Confidence:** HIGH

---

## Summary

Phase 56 completes the federal legislative data pipeline by importing bills and votes via batch CLI, and wires all 5 legislative API endpoints that Phase 59 (frontend) will consume. The phase builds directly on the infrastructure from Phase 55: the LegiScan client (`legiscan_client.go`) already exists with rate limiting, the schema (`LegislativeBill`, `LegislativeBillCosponsor`, `LegislativeVote`) already exists and is AutoMigrated, and the handler/route pattern is established.

The four planned work units map cleanly to the phase's technical requirements: (1) a Congress.gov API v3 client file (`congress_client.go`) with token bucket at 4,500 req/hr and exhaustive pagination via `len(items) < limit`; (2) `import_federal_bills.go` CLI that fetches sponsored/cosponsored bills per bioguide and CRS summaries per bill; (3) `import_federal_votes.go` CLI that fetches House votes via Congress.gov `house-vote` endpoints and Senate votes via LegiScan `getMasterList` + `getRollCall`; (4) three new handlers (`GetPoliticianBills`, `GetPoliticianVotes`, `GetPoliticianLegislativeSummary`) added to `handlers.go` with routes registered in `routes.go`.

The highest-risk finding is Congress.gov API reliability: confirmed outages in August 2025 and January 2026 mean the import CLI must log failures gracefully and must NOT block during outages. A critical design constraint is that Senate vote data is NOT available from Congress.gov API v3 — the house-vote endpoint is House-only (confirmed via official documentation as of March 2026). Senate votes must come from LegiScan. The LegiScan workflow for Senate votes requires `getSessionList` (state="US") → `getMasterList` (by session_id) → `getBill` per bill (to find roll_call_ids) → `getRollCall` per call; this is budget-intensive (~8-10K LegiScan queries for a full Congress) and requires the existing monthly counter to be checked before starting.

**Primary recommendation:** Build the Congress.gov client and bills import first (56-01 + 56-02), then the votes import (56-03), then the API handlers (56-04). The client and bills work can proceed independently; the votes work depends on the client. API handlers can be built in parallel with the import work since the schema is already in place.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FED-03 | Congress.gov API client with rate limiting (5K req/hr) and exhaustive pagination (250-item page cap handling) | Build `congress_client.go` with `rate.NewLimiter(rate.Every(800*time.Millisecond), 10)` for ~4,500 req/hr headroom; pagination stop: `len(items) < limit`; max page size = 250; `pagination.next` field exists but `len(items) < limit` is the canonical stop condition per STATE.md decision |
| FED-04 | Sponsored and cosponsored legislation imported for federal politicians via Congress.gov API (current + previous Congress) | Endpoints: `GET /v3/member/{bioguideId}/sponsored-legislation` and `/cosponsored-legislation`; response has `sponsoredLegislation[]` array with `congress`, `type`, `number`, `latestTitle`, `introducedDate`, `latestAction`, `url`; fetch CRS summary via `GET /v3/bill/{congress}/{billType}/{billNumber}/summaries`; upsert into `legislative_bills` + `legislative_bill_cosponsors` |
| FED-05 | Voting records batch-imported for federal politicians — House via Congress.gov API, Senate via LegiScan (current + previous Congress) | House: `GET /v3/house-vote/{congress}/{sessionNumber}` (list) → `GET /v3/house-vote/{congress}/{sessionNumber}/{rollCallNumber}/votes` (member votes, bioguideId + voteCast); Senate: LegiScan `getMasterList(state="US", session_id)` → `getBill(bill_id)` → `getRollCall(roll_call_id)` for each bill's roll calls → match `people_id` to `legislative_politician_id_map` |
| FED-06 | CRS plain-language bill summaries fetched from Congress.gov and stored alongside bill records | Endpoint: `GET /v3/bill/{congress}/{type}/{number}/summaries`; response has `summaries[]` array; store the text from the most recent summary (sort by `actionDate` desc, use first); store in `legislative_bills.summary` column; use `latestTitle` as fallback when summary is empty |
| API-01 | GET /politician/{id}/committees returns committee assignments with roles for any government level | Already implemented in Phase 55 (`GetPoliticianCommittees`). No new work needed. |
| API-02 | GET /politician/{id}/leadership returns leadership positions with date ranges | Already implemented in Phase 55 (`GetPoliticianLeadership`). No new work needed. |
| API-03 | GET /politician/{id}/bills returns sponsored and cosponsored legislation with status | New handler `GetPoliticianBills`; raw SQL join on `legislative_bills` + `legislative_bill_cosponsors`; query param `?advanced=true` to filter `status_label != 'Introduced'`; default returns only advanced bills; order by `introduced_at DESC`; include `number`, `title`, `status_label`, `introduced_at`, `url`, `is_sponsor` boolean |
| API-04 | GET /politician/{id}/votes returns voting record with bill info and position | New handler `GetPoliticianVotes`; raw SQL join on `legislative_votes LEFT JOIN legislative_bills`; returns `vote_question`, `position`, `vote_date`, `result`, `bill_title`, `bill_number`, `bill_url`; order by `vote_date DESC`; query param `?limit=N` with default 50 |
| API-05 | GET /politician/{id}/legislative-summary returns bounded overview for initial profile render | New handler `GetPoliticianLegislativeSummary`; single response combining: top 5 recent bills (advanced only), top 10 recent votes; structure: `{ bills: [...], votes: [...] }`; uses same underlying queries as /bills and /votes but with hardcoded limits |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `net/http` stdlib | Go 1.24 | Congress.gov API HTTP calls | Already used throughout EV-Backend; no additional dependency |
| `encoding/json` stdlib | Go 1.24 | Parse Congress.gov JSON responses (bills, votes, summaries) | Standard Go JSON; no external library needed |
| `golang.org/x/time/rate` | v0.14.0 | Token bucket rate limiter for Congress.gov API client | Already in `go.mod` as direct dependency (added in Phase 55 for LegiScan client) |
| GORM | 1.30.0 | Upsert into `legislative_bills`, `legislative_bill_cosponsors`, `legislative_votes` | All Phase 54 tables already AutoMigrated; pattern established in Phase 55 import files |
| `gorm.io/gorm/clause` | (same) | `clause.OnConflict` for upserts | Pattern established in `import_committees.go` |
| `github.com/go-chi/chi/v5` | v5.2.1 | Route registration for new endpoints | Already used in `routes.go` |
| `github.com/google/uuid` | v1.6.0 | UUID parsing in handlers | Established pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `context` stdlib | Go 1.24 | Context propagation for API call timeouts | Pass context to all HTTP requests; use `context.WithTimeout` for each API batch |
| `strconv`, `strings`, `fmt` stdlib | Go 1.24 | URL construction, flag parsing, logging | Standard; no extras needed |
| `time` stdlib | Go 1.24 | Rate limiter calculations, date formatting for bill responses | Standard |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom Congress.gov client | ProPublica Congress API | ProPublica API is not updated for 119th Congress data; Congress.gov API v3 is authoritative |
| LegiScan `getMasterList` workflow for Senate | LegiScan `getDataset` bulk download | Bulk dataset would be more efficient (~1 query vs 8-10K) but dataset format is ZIP+JSON requiring different parsing; getMasterList is simpler to implement and matches existing client design |
| `pagination.next` field for stop condition | `len(items) < limit` | STATE.md locked decision: always use `len(items) < limit` — the `total` field was removed and `next` is unreliable during outages |

**Installation (no new dependencies needed):**
```bash
# All required packages already in go.mod:
# golang.org/x/time v0.14.0 — direct
# gorm.io/gorm v1.30.0 — direct
# github.com/google/uuid v1.6.0 — direct
# github.com/go-chi/chi/v5 v5.2.1 — direct
```

---

## Architecture Patterns

### Recommended Project Structure

All new code goes in `internal/essentials/`. No new packages:

```
EV-Backend/
├── internal/essentials/
│   ├── congress_client.go       ← NEW: CongressClient struct with rate limiting (FED-03)
│   ├── import_federal_bills.go  ← NEW: ImportFederalBills function (FED-04, FED-06)
│   ├── import_federal_votes.go  ← NEW: ImportFederalVotes function (FED-05)
│   ├── handlers.go              ← MODIFY: Add GetPoliticianBills, GetPoliticianVotes, GetPoliticianLegislativeSummary (API-03, API-04, API-05)
│   └── routes.go                ← MODIFY: Register three new routes
├── main.go                      ← MODIFY: Add import-federal-bills, import-federal-votes cases
└── legiscan_client.go           ← EXISTING: Already has GetBudgetStatus, RemainingBudget
```

### Pattern 1: Congress.gov API Client (new, modeled on LegiScan client)

**What:** A struct wrapping `net/http.Client` with a `rate.Limiter` enforcing 4,500 requests/hr (1 token every ~800ms, burst of 10). Uses `context.WithTimeout` for each request to avoid hanging during Congress.gov outages.

**Rate limit math:**
- Congress.gov limit = 5,000 req/hr
- Operating at 4,500 req/hr = 90% of limit = 1 req per 800ms
- `rate.NewLimiter(rate.Every(800*time.Millisecond), 10)` gives ~4,500/hr with burst 10

**Client struct:**
```go
// Source: modeled on legiscan_client.go in same package
type CongressClient struct {
    apiKey     string
    httpClient *http.Client
    limiter    *rate.Limiter
    baseURL    string // "https://api.congress.gov/v3"
}

func NewCongressClient(apiKey string) *CongressClient {
    return &CongressClient{
        apiKey:     apiKey,
        httpClient: &http.Client{Timeout: 30 * time.Second},
        limiter:    rate.NewLimiter(rate.Every(800*time.Millisecond), 10),
        baseURL:    "https://api.congress.gov/v3",
    }
}
```

**Generic paginated fetch (core method):**
```go
// Source: pagination rules from api.congress.gov README and STATE.md decisions
func (c *CongressClient) fetchPaginated(ctx context.Context, path string, params url.Values, dest func([]byte) (int, error)) error {
    limit := 250
    offset := 0
    params.Set("limit", "250")
    params.Set("api_key", c.apiKey)
    params.Set("format", "json")

    for {
        if err := c.limiter.Wait(ctx); err != nil {
            return fmt.Errorf("rate limiter: %w", err)
        }

        params.Set("offset", strconv.Itoa(offset))
        fullURL := c.baseURL + path + "?" + params.Encode()

        req, _ := http.NewRequestWithContext(ctx, "GET", fullURL, nil)
        resp, err := c.httpClient.Do(req)
        if err != nil {
            return fmt.Errorf("Congress.gov request failed: %w", err)
        }
        body, _ := io.ReadAll(resp.Body)
        resp.Body.Close()

        if resp.StatusCode != http.StatusOK {
            return fmt.Errorf("Congress.gov returned %d: %s", resp.StatusCode, string(body))
        }

        // dest parses the body and returns len(items) received
        n, err := dest(body)
        if err != nil {
            return err
        }

        // CRITICAL: Stop condition — never assume round number means complete
        // len(items) < limit signals last page (STATE.md locked decision)
        if n < limit {
            break
        }
        offset += limit
    }
    return nil
}
```

### Pattern 2: Import Federal Bills Workflow

**What:** For each politician with a bioguide bridge row, fetch sponsored and cosponsored bills from Congress.gov for the current and previous Congress. Then fetch CRS summaries for each bill that has them.

**Bill import workflow:**
```go
// Source: pattern from import_committees.go (same package)
type ImportFederalBillsConfig struct {
    DryRun           bool
    CongressNumbers  []int // default [119, 118]
    SkipSummaries    bool  // for faster dry runs
    LegiScanAPIKey   string // needed for LegiScan budget check (not used in bills, but passed for logging)
}

type ImportFederalBillsResult struct {
    BillsUpserted       int
    CosponsorsUpserted  int
    SummariesFetched    int
    Skipped             int
    Errors              []string
}

func ImportFederalBills(cfg ImportFederalBillsConfig) (ImportFederalBillsResult, error) {
    // 1. Load all politicians with bioguide bridge rows
    // 2. For each politician, for each congress number:
    //    a. Fetch /v3/member/{bioguideId}/sponsored-legislation (paginated)
    //    b. Upsert each bill into legislative_bills (SponsorID = politician.ID)
    //    c. Fetch /v3/member/{bioguideId}/cosponsored-legislation (paginated)
    //    d. Upsert each bill into legislative_bills (SponsorID = nil)
    //    e. Upsert each cosponsored bill into legislative_bill_cosponsors
    // 3. For each unique bill that has no summary, fetch /v3/bill/{congress}/{type}/{number}/summaries
    // 4. Return result counts
}
```

**Bill upsert pattern (unique on external_id + jurisdiction):**
```go
// external_id = "{congress}-{billType}-{billNumber}" e.g. "119-HR-1044"
// jurisdiction = "federal"
bill := LegislativeBill{
    SessionID:    sessionID,  // from getOrCreateFederalSession(congressNum)
    ExternalID:   fmt.Sprintf("%d-%s-%s", congress, billType, billNumber),
    Jurisdiction: "federal",
    Number:       fmt.Sprintf("%s %s", billType, billNumber), // "HR 1044"
    Title:        latestTitle,
    RawStatus:    latestAction.Text,
    StatusLabel:  normalizeBillStatus(latestAction.Text),
    SponsorID:    &politicianID,  // nil for cosponsored
    IntroducedAt: &introducedDate,
    URL:          congressBillURL,
    Source:       "congress",
}
db.DB.Clauses(clause.OnConflict{
    Columns:   []clause.Column{{Name: "external_id"}, {Name: "jurisdiction"}},
    DoUpdates: clause.AssignmentColumns([]string{"title", "raw_status", "status_label", "summary", "url"}),
}).Create(&bill)
```

**Bill status normalization:**
```go
// Source: derived from Congress.gov latestAction.text values
func normalizeBillStatus(latestActionText string) string {
    t := strings.ToLower(latestActionText)
    switch {
    case strings.Contains(t, "became public law") || strings.Contains(t, "signed by president"):
        return "Signed"
    case strings.Contains(t, "passed senate") || strings.Contains(t, "passed house"):
        return "Passed"
    case strings.Contains(t, "reported by"):
        return "Reported"
    case strings.Contains(t, "referred to"):
        return "In Committee"
    default:
        return "Introduced"
    }
}
```

**CRS summary fetch:**
```go
// Endpoint: GET /v3/bill/{congress}/{billType}/{billNumber}/summaries
// Response: {"summaries": [{"text": "...", "actionDate": "2024-01-15", ...}]}
// Strategy: Sort by actionDate DESC, use first (most recent summary)
// Fallback: if no summaries, leave summary="" (handled by omitempty in API response)
```

### Pattern 3: Import Federal Votes Workflow

**What:** House votes from Congress.gov `house-vote` endpoints (beta, covers 118th+119th Congress). Senate votes from LegiScan via getMasterList → getBill → getRollCall workflow.

**House votes workflow (Congress.gov):**
```go
// For each congress number, for each session (1, 2):
// 1. GET /v3/house-vote/{congress}/{sessionNumber} (paginated list)
//    Response has houseRollCallVotes[].rollCallNumber
// 2. For each rollCallNumber:
//    GET /v3/house-vote/{congress}/{sessionNumber}/{rollCallNumber}/votes
//    Response has houseRollCallVoteMemberVotes[].{bioguideId, voteCast}
// 3. Match bioguideId → legislative_politician_id_map → politician UUID
// 4. Map voteCast: "Aye"→"yea", "Nay"→"nay", "Present"→"present", "Not Voting"→"not_voting"
// 5. Upsert LegislativeVote (unique on politician_id, external_vote_id, session_id)
```

**external_vote_id for House:** `"house-{congress}-{session}-{rollCallNumber}"` e.g. `"house-119-1-42"`

**Senate votes workflow (LegiScan):**
```go
// IMPORTANT: Budget check first — Senate full Congress import uses ~8-10K LegiScan queries
// Step 1: getSessionList(state="US") → find current and previous Congress session IDs
// Step 2: getMasterList(session_id) → all bills for session (1 query per session)
//         MasterList response: {masterlist: {1: {bill_id, number, title, ...}, 2: {...}, ...}}
//         Note: getMasterList returns a map object keyed by index, NOT an array
// Step 3: for each bill_id, getBill(bill_id) → bill.votes[] array with roll_call_ids
//         bill.votes = [{roll_call_id, date, desc, yea, nay, nv, absent, passed, chamber}]
// Step 4: for each roll_call_id where chamber="S", getRollCall(roll_call_id)
//         Returns votes[] with {people_id, vote_id, vote_text}
// Step 5: Match people_id → legislative_politician_id_map WHERE id_type='legiscan'
//         Note: legiscan ID bridge rows added here if not present (new id_type)
// Step 6: Upsert LegislativeVote
```

**external_vote_id for Senate (LegiScan):** `"legiscan-{roll_call_id}"` e.g. `"legiscan-1234567"`

**Critical: LegiScan session_id for US Congress:**
```go
// LegiScan uses state="US" for US Congress
// getSessionList(state="US") returns sessions like:
// {session_id: 2116, session_name: "2025-2026 Regular Session", year_start: 2025, year_end: 2026}  // 119th Congress
// {session_id: 1916, session_name: "2023-2024 Regular Session", year_start: 2023, year_end: 2024}  // 118th Congress
// Select by year_start to identify the right session
```

**LegiScan getMasterList response structure (important — it's a map, not array):**
```go
// Response: {"status":"OK", "session":{...}, "masterlist": {"0":{session: metadata}, "1":{bill_id,number,title,...}, "2":{...}, ...}}
// Key "0" is session metadata, keys "1"+ are bills
// Parse as: map[string]json.RawMessage then filter out non-bill entries
type masterListBill struct {
    BillID  int    `json:"bill_id"`
    Number  string `json:"number"`
    Title   string `json:"title"`
    Status  int    `json:"status"` // 1=Introduced, 4=Passed, 5=Vetoed, etc.
    // change_hash for future incremental updates
}
```

**LegiScan getBill response with votes:**
```go
// Response: {"status":"OK", "bill": {"bill_id":..., "votes": [{"roll_call_id":..., "date":..., "desc":..., "yea":..., "nay":..., "passed":..., "chamber":"S"}]}}
type legiscanBillVoteSummary struct {
    RollCallID int    `json:"roll_call_id"`
    Date       string `json:"date"`
    Desc       string `json:"desc"`
    Yea        int    `json:"yea"`
    Nay        int    `json:"nay"`
    NV         int    `json:"nv"`
    Absent     int    `json:"absent"`
    Passed     int    `json:"passed"`
    Chamber    string `json:"chamber"` // "S" for Senate, "H" for House (skip H, using Congress.gov for House)
}
```

**LegiScan people_id → senator bridge:**
```go
// Phase 56 adds a new id_type "legiscan" to legislative_politician_id_map.
// The bridge table already has "bioguide" rows (from Phase 54 backfill).
// For Senate matching: use getSessionPeople(session_id="US Congress session") to get
// all LegiScan people_id values for senators, then match by name to existing bioguide
// bridge rows (exact last_name + first_name match or name fuzzy match).
// Insert new rows: id_type="legiscan", id_value=strconv.Itoa(people_id)
// This requires ONE getSessionPeople call per session (~2 queries for current+previous).
```

### Pattern 4: API Handlers (new, established pattern from Phase 55)

**What:** Three new handlers in `handlers.go` following the exact same pattern as `GetPoliticianEndorsements` and `GetPoliticianCommittees` from Phase 55.

**GetPoliticianBills:**
```go
type LegislativeBillOut struct {
    ExternalID    string `json:"external_id"`
    Number        string `json:"number"`
    Title         string `json:"title"`
    Summary       string `json:"summary,omitempty"`
    StatusLabel   string `json:"status_label"`
    IntroducedAt  string `json:"introduced_at,omitempty"`
    IsSponsor     bool   `json:"is_sponsor"` // true if primary sponsor, false if cosponsor
    URL           string `json:"url,omitempty"`
    Source        string `json:"source"`
}

// Query logic:
// - JOIN legislative_bills LEFT JOIN legislative_bill_cosponsors
// - WHERE sponsor_id = ? OR bill_id IN (SELECT bill_id FROM cosponsors WHERE politician_id = ?)
// - Default filter: status_label != 'Introduced' (significance filter)
// - Query param ?all=true to include introduced bills
// - Order by introduced_at DESC
```

**GetPoliticianVotes:**
```go
type LegislativeVoteOut struct {
    VoteQuestion string `json:"vote_question"`
    Position     string `json:"position"`   // "yea", "nay", "not_voting", "absent", "present"
    VoteDate     string `json:"vote_date"`
    Result       string `json:"result"`     // "passed", "failed"
    BillTitle    string `json:"bill_title,omitempty"`
    BillNumber   string `json:"bill_number,omitempty"`
    BillURL      string `json:"bill_url,omitempty"`
    Source       string `json:"source"`
}

// Query:
// SELECT v.vote_question, v.position, v.vote_date, v.result, v.source,
//        COALESCE(b.title, '') AS bill_title,
//        COALESCE(b.number, '') AS bill_number,
//        COALESCE(b.url, '') AS bill_url
// FROM essentials.legislative_votes v
// LEFT JOIN essentials.legislative_bills b ON b.id = v.bill_id
// WHERE v.politician_id = ?
// ORDER BY v.vote_date DESC
// LIMIT ?  (default 50, max 250)
```

**GetPoliticianLegislativeSummary:**
```go
type LegislativeSummaryOut struct {
    RecentBills []LegislativeBillOut  `json:"recent_bills"` // 5 items max, advanced only
    RecentVotes []LegislativeVoteOut  `json:"recent_votes"` // 10 items max
}

// Implementation: call same raw SQL as GetPoliticianBills with LIMIT 5
// and GetPoliticianVotes with LIMIT 10; combine into single response.
// This is a single endpoint that frontend calls on profile initial render
// to avoid 2 separate API calls.
```

**Route registration:**
```go
// Add to routes.go after Phase 55 legislative endpoints
r.Get("/politician/{id}/bills", GetPoliticianBills)
r.Get("/politician/{id}/votes", GetPoliticianVotes)
r.Get("/politician/{id}/legislative-summary", GetPoliticianLegislativeSummary)
```

### Anti-Patterns to Avoid

- **Assuming `len(items) == 250` means there's another page:** The API can return exactly 250 items AND have no next page. The stop condition is `len(items) < limit` where limit=250.
- **Using Congress.gov `house-vote` endpoint for Senate votes:** The endpoint is House-only. Attempting to fetch Senate votes via `/v3/house-vote/` returns 404 or empty data. Senate = LegiScan.
- **Fetching all bills then filtering by politician:** The efficient approach is to use the per-member sponsored-legislation endpoint. The `/v3/bill/{congress}` list endpoint would return thousands of bills — never iterate this to find sponsored bills.
- **Starting Senate vote import without checking LegiScan budget:** Full Congress import uses ~8-10K queries. The existing `legiscan_client.go` has `RemainingBudget()` and `GetBudgetStatus()` — check these before starting import and log the projected cost.
- **HTTP request timeouts during Congress.gov outages:** The client uses `http.Client{Timeout: 30s}` and `context.WithTimeout`. The import CLI must check error types and log `"Congress.gov unavailable, skipping: %v"` rather than returning a fatal error. Failed politicians should be logged for retry.
- **Blocking server startup for import:** Like all other import CLIs, the import subcommands use `os.Exit(0)` after completion. They never run as part of the server process.
- **Null vs. empty array in API responses:** All three new handlers must return `make([]T, 0)` (not `nil`) to ensure JSON encodes as `[]` not `null`. Established pattern from Phase 55 handlers.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rate limiting | Sleep/delay loops | `golang.org/x/time/rate.Limiter` | Already in go.mod; handles burst correctly; established in LegiScan client |
| Pagination | Manual offset tracking with custom struct | `fetchPaginated()` helper method on client struct | Centralizes the `len(items) < limit` stop condition — one place to fix if behavior changes |
| Bill status normalization | Large case-switch on full text | Simple `strings.Contains` string classification | latestAction.text is free text; only need 5 buckets (Introduced/In Committee/Reported/Passed/Signed) |
| LegiScan session discovery | Hardcoded session IDs | `getSessionList(state="US")` | Session IDs change per Congress; hardcoding causes silent failure when new Congress begins |
| Cosponsor deduplication | Manual uniqueness check | `clause.OnConflict{DoNothing: true}` on `legislative_bill_cosponsors` | Composite unique index `idx_cosponsor` already exists on (bill_id, politician_id) |

**Key insight:** The Congress.gov API has an 800ms-per-request rhythm at safe rate. A full Senate vote import via LegiScan uses ~8-10K of the 30K monthly budget — document this prominently in the CLI help output so operators know to check budget before running.

---

## Common Pitfalls

### Pitfall 1: Congress.gov API outages silently fail imports

**What goes wrong:** The import CLI returns a fatal error or hangs when the API is down, leaving no data imported and no useful log output.
**Why it happens:** Congress.gov had confirmed outages in August 2025 and January 2026. The API can return redirect loops, timeouts, or 5xx errors.
**How to avoid:** Wrap each politician's fetch in a per-politician error handler that appends to `result.Errors` and continues. Never `log.Fatal` on an individual politician failure. Include a `--max-errors=50` flag to abort after too many failures (suggests systemic outage).
**Warning signs:** All politicians return errors with the same error message; typically `"no such host"`, `"connection refused"`, or `"context deadline exceeded"`.

### Pitfall 2: LegiScan getMasterList returns a map, not an array

**What goes wrong:** Code tries to unmarshal `{"masterlist": [...]}` as a Go slice and gets a type error or empty result.
**Why it happens:** LegiScan's getMasterList returns `{"masterlist": {"0": {session_metadata}, "1": {bill1}, "2": {bill2}, ...}}` — a JSON object keyed by string indices.
**How to avoid:** Parse as `map[string]json.RawMessage` then range over keys, skipping key `"0"` (session metadata). Each value is a bill object with `bill_id`, `number`, `title` etc.
**Warning signs:** `json.Unmarshal` error mentioning "cannot unmarshal object into Go value of type []"; or zero bills found after parsing.

```go
// CORRECT:
var wrapper struct {
    Status     string                       `json:"status"`
    MasterList map[string]json.RawMessage   `json:"masterlist"`
}
if err := json.Unmarshal(body, &wrapper); err != nil { ... }
for key, raw := range wrapper.MasterList {
    if key == "0" { continue } // session metadata
    var bill masterListBill
    json.Unmarshal(raw, &bill)
    // process bill...
}

// WRONG:
var wrapper struct {
    MasterList []masterListBill `json:"masterlist"`
}
// ^ type error: object is not array
```

### Pitfall 3: Senate vote LegiScan budget exhaustion mid-import

**What goes wrong:** The import runs for hours and then stops with "monthly budget exhausted" after consuming half the expected votes. The database has partial data with no way to know which senators were fully imported vs. partially imported.
**Why it happens:** A full 119th Congress Senate session has ~500+ bills, each with multiple roll calls. getBill per bill = 1 query. getRollCall per roll call = 1 query. Total: easily 5,000+ queries per session.
**How to avoid:**
1. Check `legiscanClient.RemainingBudget()` before starting. Print projected cost estimate.
2. Process bills in a deterministic order (sorted by bill_id). If the import is interrupted, it can resume from where it left off (by checking existing vote records in the DB).
3. Consider using the `change_hash` field to skip unchanged bills on re-runs.
**Warning signs:** "LegiScan monthly budget exhausted" error mid-import; vote data only present for senators with early bill_ids.

### Pitfall 4: House vote endpoint double-import for same roll call

**What goes wrong:** The same roll call is imported twice (once from Congress.gov for the member vote, once from LegiScan for the cross-check), creating duplicate `legislative_votes` rows.
**Why it happens:** LegislativeVote has a composite unique index on (politician_id, bill_id, session_id, external_vote_id). If House vote is imported via Congress.gov with `external_vote_id="house-119-1-42"` AND via LegiScan with `external_vote_id="legiscan-7654321"`, both succeed (different external_vote_id values).
**How to avoid:** Keep sources cleanly separated — House votes come ONLY from Congress.gov, Senate votes come ONLY from LegiScan. Never use LegiScan for House vote data in Phase 56. (Phase 57 can use LegiScan for state data.)
**Warning signs:** Vote counts are double what expected for House members; SELECT COUNT(*) grouped by politician_id returns 2x expected counts.

### Pitfall 5: Bill external_id collision between Congress numbers

**What goes wrong:** "HR 1044" in the 118th Congress and "HR 1044" in the 119th Congress have the same bill type+number but are different bills. Using just `"{billType}-{billNumber}"` as external_id creates a false conflict.
**Why it happens:** Congress reuses bill numbers each Congress. The unique index on `legislative_bills` uses `(external_id, jurisdiction)` — if external_id doesn't include the Congress number, an upsert for 119-HR-1044 would overwrite 118-HR-1044.
**How to avoid:** Always include Congress number in external_id: `fmt.Sprintf("%d-%s-%s", congressNum, billType, billNumber)` → `"119-HR-1044"`.
**Warning signs:** Bills from previous Congress are being overwritten with data from current Congress; `SELECT COUNT(*) FROM legislative_bills` is lower than expected.

### Pitfall 6: Congress.gov sponsored-legislation response field name casing

**What goes wrong:** JSON struct tags don't match the actual response field names, resulting in empty bill arrays.
**Why it happens:** Congress.gov API uses camelCase JSON fields (`sponsoredLegislation`, `latestTitle`, `introducedDate`, `latestAction`). Go struct tags must match exactly.
**How to avoid:** Verify response field names from official API documentation. The key fields are:
```go
type congressBillItem struct {
    Congress       int    `json:"congress"`
    Type           string `json:"type"`           // "HR", "S", "HJRES", etc.
    Number         string `json:"number"`
    LatestTitle    string `json:"latestTitle"`
    IntroducedDate string `json:"introducedDate"` // "YYYY-MM-DD"
    LatestAction struct {
        ActionDate string `json:"actionDate"`
        Text       string `json:"text"`
    } `json:"latestAction"`
    URL string `json:"url"`
}

// Top-level wrapper for sponsored-legislation endpoint
type sponsoredLegislationResponse struct {
    SponsoredLegislation []congressBillItem `json:"sponsoredLegislation"`
    Pagination struct {
        Count  int    `json:"count"`
        Next   string `json:"next,omitempty"`
        Prev   string `json:"prev,omitempty"`
    } `json:"pagination"`
}
```

### Pitfall 7: House vote `voteCast` values vs. database `position` values

**What goes wrong:** Congress.gov returns `"Aye"` and `"Nay"` (not `"Yea"` and `"Nay"`). The database `position` column expects lowercase. A direct insert without mapping results in `"Aye"` stored instead of `"yea"`.
**Why it happens:** Congress.gov uses `"Aye"/"Nay"/"Present"/"Not Voting"` while the LegiScan API uses `"Yea"/"Nay"/"NV"/"Absent"`. The database schema uses lowercase normalized values.
**How to avoid:** Always map through a normalization function:
```go
func normalizeVoteCast(voteCast string) string {
    switch strings.ToLower(voteCast) {
    case "aye", "yea", "yes":
        return "yea"
    case "nay", "no":
        return "nay"
    case "present":
        return "present"
    case "not voting", "nv":
        return "not_voting"
    case "absent":
        return "absent"
    default:
        return strings.ToLower(voteCast)
    }
}
```

---

## Code Examples

### Congress.gov Sponsored Bills Fetch

```go
// Source: Congress.gov API documentation, MemberEndpoint.md
func (c *CongressClient) GetSponsoredLegislation(ctx context.Context, bioguideID string, congress int) ([]congressBillItem, error) {
    path := fmt.Sprintf("/member/%s/sponsored-legislation", bioguideID)
    params := url.Values{"congress": {strconv.Itoa(congress)}}

    var allBills []congressBillItem
    err := c.fetchPaginated(ctx, path, params, func(body []byte) (int, error) {
        var resp sponsoredLegislationResponse
        if err := json.Unmarshal(body, &resp); err != nil {
            return 0, err
        }
        allBills = append(allBills, resp.SponsoredLegislation...)
        return len(resp.SponsoredLegislation), nil
    })
    return allBills, err
}
```

### Congress.gov House Vote List Fetch

```go
// Source: Congress.gov API documentation, HouseRollCallVoteEndpoint.md
// URL: GET /v3/house-vote/{congress}/{sessionNumber}
// Response: {"houseRollCallVotes": [{"rollCallNumber": 42, "congress": 119, "sessionNumber": 1, ...}]}
func (c *CongressClient) GetHouseVoteList(ctx context.Context, congress int, session int) ([]houseVoteItem, error) {
    path := fmt.Sprintf("/house-vote/%d/%d", congress, session)
    params := url.Values{}

    var allVotes []houseVoteItem
    err := c.fetchPaginated(ctx, path, params, func(body []byte) (int, error) {
        var resp houseVoteListResponse
        if err := json.Unmarshal(body, &resp); err != nil {
            return 0, err
        }
        allVotes = append(allVotes, resp.HouseRollCallVotes...)
        return len(resp.HouseRollCallVotes), nil
    })
    return allVotes, err
}

// Member votes level: GET /v3/house-vote/{congress}/{sessionNumber}/{rollCallNumber}/votes
// Response: {"houseRollCallVoteMemberVotes": {"results": [{"bioguideId":"A000360","voteCast":"Aye",...}]}}
```

### CRS Summary Fetch

```go
// Source: Congress.gov API documentation, BillEndpoint.md / SummariesEndpoint.md
// URL: GET /v3/bill/{congress}/{billType}/{billNumber}/summaries
// Response: {"summaries": [{"text": "<html>...", "actionDate": "2025-01-15", ...}]}
func (c *CongressClient) GetBillSummary(ctx context.Context, congress int, billType, billNumber string) (string, error) {
    if err := c.limiter.Wait(ctx); err != nil {
        return "", err
    }
    path := fmt.Sprintf("/v3/bill/%d/%s/%s/summaries", congress, strings.ToLower(billType), billNumber)
    // ... standard HTTP GET + JSON parse
    // Return summaries[0].text (most recent), or "" if empty
    // Text is HTML-encoded CRS summary — strip HTML tags before storing
}
```

### Bill SQL Upsert Pattern

```go
// Source: import_committees.go pattern in same package
bill := LegislativeBill{
    SessionID:    sessionID,
    ExternalID:   fmt.Sprintf("%d-%s-%s", congressNum, bill.Type, bill.Number),
    Jurisdiction: "federal",
    Number:       fmt.Sprintf("%s %s", bill.Type, bill.Number),
    Title:        bill.LatestTitle,
    RawStatus:    bill.LatestAction.Text,
    StatusLabel:  normalizeBillStatus(bill.LatestAction.Text),
    SponsorID:    sponsorID, // nil for cosponsored bills
    URL:          bill.URL,
    Source:       "congress",
}
if !bill.IntroducedDate.IsZero() {
    bill.IntroducedAt = &introducedDate
}
db.DB.Clauses(clause.OnConflict{
    Columns:   []clause.Column{{Name: "external_id"}, {Name: "jurisdiction"}},
    DoUpdates: clause.AssignmentColumns([]string{"title", "raw_status", "status_label", "summary", "sponsor_id", "url"}),
}).Create(&bill)
```

### Vote SQL Upsert Pattern

```go
// Source: models.go LegislativeVote uniqueIndex: idx_leg_vote on (politician_id, bill_id, session_id, external_vote_id)
vote := LegislativeVote{
    PoliticianID:   polUUID,
    BillID:         &billUUID, // nullable — may be nil for procedural votes
    SessionID:      sessionID,
    ExternalVoteID: fmt.Sprintf("house-%d-%d-%d", congress, session, rollCallNum),
    VoteQuestion:   rollCall.VoteQuestion,
    Position:       normalizeVoteCast(memberVote.VoteCast),
    VoteDate:       voteDateParsed,
    Result:         normalizeVoteResult(rollCall.Result),
    YeaCount:       rollCall.YeaTotal,
    NayCount:       rollCall.NayTotal,
    Source:         "congress",
}
db.DB.Clauses(clause.OnConflict{
    Columns:   []clause.Column{{Name: "politician_id"}, {Name: "bill_id"}, {Name: "session_id"}, {Name: "external_vote_id"}},
    DoUpdates: clause.AssignmentColumns([]string{"position", "vote_question", "result"}),
}).Create(&vote)
```

### GetPoliticianBills Handler SQL

```go
// Source: pattern from GetPoliticianCommittees/GetPoliticianEndorsements in handlers.go
db.DB.Raw(`
    SELECT
        b.external_id,
        b.number,
        b.title,
        b.summary,
        b.status_label,
        b.url,
        b.source,
        TO_CHAR(b.introduced_at, 'YYYY-MM-DD') AS introduced_at,
        CASE WHEN b.sponsor_id = ? THEN true ELSE false END AS is_sponsor
    FROM essentials.legislative_bills b
    WHERE b.sponsor_id = ?
       OR b.id IN (SELECT bill_id FROM essentials.legislative_bill_cosponsors WHERE politician_id = ?)
    AND ($2 = true OR b.status_label != 'Introduced')
    ORDER BY b.introduced_at DESC NULLS LAST
    LIMIT ?
`, parsedID, parsedID, parsedID, includeAll, pageLimit).Scan(&rows)
```

### Main.go CLI Dispatch Pattern

```go
// Source: import-committees case in main.go
case "import-federal-bills":
    dryRun := false
    skipSummaries := false
    congresses := []int{119, 118} // current + previous
    for _, arg := range os.Args[2:] {
        switch {
        case arg == "--dry-run":
            dryRun = true
        case arg == "--skip-summaries":
            skipSummaries = true
        case strings.HasPrefix(arg, "--congress="):
            n, _ := strconv.Atoi(strings.TrimPrefix(arg, "--congress="))
            congresses = []int{n}
        }
    }
    congressAPIKey := os.Getenv("CONGRESS_API_KEY")
    if congressAPIKey == "" {
        log.Fatal("CONGRESS_API_KEY environment variable is required")
    }
    result, err := essentials.ImportFederalBills(essentials.ImportFederalBillsConfig{
        DryRun:          dryRun,
        CongressNumbers: congresses,
        SkipSummaries:   skipSummaries,
        CongressAPIKey:  congressAPIKey,
    })
    if err != nil {
        log.Fatal("import-federal-bills failed: ", err)
    }
    fmt.Printf("Import complete: %d bills, %d cosponsors, %d summaries, %d skipped\n",
        result.BillsUpserted, result.CosponsorsUpserted, result.SummariesFetched, result.Skipped)
    os.Exit(0)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Congress.gov API rate limit: 1,000/hr | 5,000/hr | March 2024 | Can import more aggressively; use 4,500/hr (90% headroom) |
| Senate votes via Congress.gov | Senate votes via LegiScan only | March 2026 (confirmed) | House-vote endpoint is House-only. Senate roll calls are NOT in Congress.gov API v3. |
| House-vote beta (118th Congress only) | House-vote covers 118th AND 119th Congress | Updated as of March 2026 | Both current and previous Congress available from one source |
| ProPublica Congress API | Congress.gov API v3 (authoritative) | ProPublica API is not current for 119th Congress | Must use Congress.gov directly |

**Deprecated/outdated:**
- `gopkg.in/yaml.v3`: Archived, do not use. All YAML work uses `goccy/go-yaml`.
- ProPublica Congress API: Not updated for 119th Congress. Do not use.
- Congress.gov `total` field in pagination response: Removed. Use `len(items) < limit` as stop condition.

---

## Open Questions

1. **Congress.gov API key delivery to the import CLI**
   - What we know: The existing `.env.local` contains `DATABASE_URL` and `BALLOTREADY_API_KEY`. There is no `CONGRESS_API_KEY` entry yet.
   - What's unclear: Should the Congress.gov API key use a new env var `CONGRESS_API_KEY` or be bundled with the existing BALLOTREADY key?
   - Recommendation: Add `CONGRESS_API_KEY` as a separate env var. Add it to `.env.local.example` documentation and to `apprunner.yaml` secrets list. Treat it the same as `BALLOTREADY_API_KEY`.

2. **LegiScan people_id to bioguide bridging for Senate**
   - What we know: The LegiScan `getPerson` response does NOT include `bioguide_id`. The `legislative_politician_id_map` currently only has `id_type="bioguide"` rows. Senate votes need `id_type="legiscan"` rows.
   - What's unclear: Is `getSessionPeople` the right approach, or should we match via name against existing politician records?
   - Recommendation: Use `getSessionPeople(session_id)` → get full list of US Congress senators with their `people_id`, `first_name`, `last_name`, `district` → match by name against existing bridge table's bioguide rows (JOIN on `politicians.first_name + last_name`). Insert `id_type="legiscan"` rows where match is unambiguous. This is ~2 API calls for two sessions — very budget-efficient.

3. **HTML stripping for CRS bill summaries**
   - What we know: Congress.gov CRS summaries are returned with HTML tags in the `text` field (CDATA-wrapped HTML).
   - What's unclear: Should we strip HTML before storing, or store raw HTML and let the frontend handle rendering?
   - Recommendation: Strip HTML tags before storing. The database `summary` column is `text` type with no HTML rendering expectation. A simple regex or stdlib HTML tokenizer pass is sufficient. Store plain text.

4. **Significance filter default for /bills endpoint**
   - What we know: STATE.md notes: "After first federal bill import, check what percentage are 'introduced' status only. Calibrate default filter cutoff from actual data distribution before building the UI filter."
   - What's unclear: What the actual distribution will look like before import runs.
   - Recommendation: Default to filtering out `status_label = 'Introduced'` as specified in the success criteria. Implement the query param `?all=true` to override. Log the status distribution during import so the calibration check can be done immediately after first real import run.

5. **House vote session number mapping (session 1 vs session 2)**
   - What we know: Congress.gov `house-vote` endpoint requires session number (1 or 2). Session 1 of the 119th Congress started January 2025.
   - What's unclear: For historical imports (118th Congress), session 2 ended January 2025.
   - Recommendation: Always try both sessions (1 and 2) for each Congress number. Handle 404 gracefully (session 2 of current Congress may not exist yet in 2025).

---

## Validation Architecture

> nyquist_validation is not set in .planning/config.json — skip this section.

---

## Sources

### Primary (HIGH confidence)
- `EV-Backend/internal/essentials/models.go` — confirmed LegislativeBill, LegislativeBillCosponsor, LegislativeVote, LegislativePoliticianIDMap schema; all tables AutoMigrated in setup.go
- `EV-Backend/internal/essentials/legiscan_client.go` — confirmed exact LegiScan client pattern, rate.Limiter usage, monthly counter, RemainingBudget() and GetBudgetStatus() methods
- `EV-Backend/internal/essentials/import_committees.go` — confirmed CLI import pattern with Config/Result structs, GORM clause.OnConflict upsert
- `EV-Backend/internal/essentials/handlers.go` — confirmed GetPoliticianCommittees, GetPoliticianLeadership handler patterns; DTO struct pattern; writeJSON helper
- `EV-Backend/internal/essentials/routes.go` — confirmed route registration pattern; Phase 55 endpoints already wired
- `EV-Backend/main.go` — confirmed CLI subcommand dispatch pattern with os.Args, os.Exit(0)
- `EV-Backend/go.mod` — confirmed `golang.org/x/time v0.14.0` direct dependency
- `https://github.com/LibraryOfCongress/api.congress.gov/blob/main/README.md` (WebFetch) — confirmed rate limit 5,000/hr, max 250 items/page, pagination via offset+limit, `len(items) < limit` stop condition
- `https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/MemberEndpoint.md` (WebFetch) — confirmed `/member/{bioguideId}/sponsored-legislation` and `/cosponsored-legislation` endpoints; response fields including `sponsoredLegislation[]` array
- `https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/HouseRollCallVoteEndpoint.md` (WebFetch) — confirmed `house-vote/{congress}/{session}` list level and `/votes` member level; `bioguideId`, `voteCast` fields; covers 118th AND 119th Congress
- `https://github.com/LibraryOfCongress/api.congress.gov/blob/main/Documentation/SummariesEndpoint.md` (WebFetch) — confirmed CRS summary text in CDATA with HTML; `actionDate` for ordering
- `https://github.com/LibraryOfCongress/api.congress.gov/blob/main/ChangeLog.md` (WebFetch) — confirmed API is active as of February-March 2026; scheduled updates in March and April 2026
- `https://learn.microsoft.com/en-us/connectors/legiscan/` (WebFetch) — confirmed complete LegiScan API operation list; all response schemas including RollCallResponse (votes[].{people_id, vote_id, vote_text}), MasterListResponse structure, getSessionList fields
- `.planning/STATE.md` — confirmed locked decisions: Senate votes via LegiScan only, `len(items) < limit` pagination stop condition, Congress.gov outage in January 2026, batch import mandatory

### Secondary (MEDIUM confidence)
- `https://www.govtech.com/gov-experience/congress-govs-api-has-gone-dark-impacting-data-access` (WebFetch) — confirmed Congress.gov API outage began August 23, 2025; no restoration timeline from Library of Congress
- WebSearch "Congress.gov API v3 house-vote endpoint 119th Congress" — confirmed beta House Roll Call Votes endpoint covers both 118th and 119th Congress; blog.loc.gov post from May 2025
- WebSearch "Congress.gov API rate limit 5000 per hour" — confirmed 5,000/hr rate limit increased from 1,000/hr in March 2024

### Tertiary (LOW confidence)
- LegiScan getMasterList returning a map (not array) — confirmed from Microsoft connector documentation response schema and gist review documentation; not verified against live API
- LegiScan Senate full Congress import consuming ~8-10K queries — estimate based on ~500+ bills/session × ~15-20 roll calls/bill average; not verified with actual Congress session data

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in go.mod; no new dependencies
- Congress.gov API endpoints: HIGH — verified via official GitHub documentation and ChangeLog
- House vote endpoint structure: HIGH — verified via official endpoint documentation (bioguideId, voteCast fields confirmed)
- LegiScan workflow for Senate votes: HIGH — response schemas verified via Microsoft connector documentation
- getMasterList map structure: MEDIUM — confirmed from documentation descriptions but not verified against live API
- LegiScan budget estimate for Senate import: LOW — estimate only, no verified count of Senate roll calls per Congress

**Research date:** 2026-03-02
**Valid until:** 2026-06-01 (Congress.gov API is actively maintained; LegiScan API is stable; Go libraries are stable)
