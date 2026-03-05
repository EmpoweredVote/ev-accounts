# Phase 55: Federal Committees & Leadership - Research

**Researched:** 2026-03-01
**Domain:** Go CLI import subcommands, congress-legislators YAML parsing, LegiScan API client, GORM upserts, Chi route handlers
**Confidence:** HIGH

---

## Summary

Phase 55 imports federal committee assignments and leadership positions from the `unitedstates/congress-legislators` YAML repository and creates a LegiScan Go API client with monthly rate limiting. It builds on Phase 54's schema foundation (all 8 `essentials.legislative_*` tables already exist, `bioguide_id` bridge rows already populated in `legislative_politician_id_map`).

The work splits naturally into three independent files: `import_committees.go` (FED-01), `import_leadership.go` + `legiscan_client.go` (FED-02 + FED-07), and API handler additions to `handlers.go` + `routes.go` (success criteria 4 and 5). The plans in Phase 55 can run two in parallel once schema is confirmed present, or be sequenced as three plans as indicated by the phase description.

The most important research finding is the **committee membership YAML structure**: `committee-membership-current.yaml` is a map keyed by `thomas_id` (the same `thomas_id` from `committees-current.yaml`), and each value is an array of member objects with `bioguide`, `rank`, `party`, and an optional `title` field (not normalized — accept any string, normalize on import). Subcommittee IDs in membership data are composed as `{parent_thomas_id}{subcommittee_thomas_id}` (e.g., parent `HSAG` + subcommittee `15` = membership key `HSAG15`). The `committees-current.yaml` file has the full committee hierarchy — each top-level committee entry has a `subcommittees` array with `thomas_id` and `name` fields.

The second important finding is **leadership_roles field location**: it is a top-level array on each legislator in `legislators-current.yaml`, NOT inside individual term entries. Each entry has `title`, `chamber`, `start`, and `end` date fields. Import only entries where `end` is absent or is in the future to populate current leadership roles.

The LegiScan API is fully documented. It uses `https://api.legiscan.com/?key=KEY&op=OPERATION&id=VALUE` pattern. For Phase 55, the only LegiScan requirement (FED-07) is to create the client with rate limiting — actual Senate vote fetching happens in Phase 56. The free tier is 30K queries/month (resets the 1st of each month). The implementation needs a persistent counter (file-based or DB-based) plus `golang.org/x/time/rate` for burst control, since the stdlib rate package only handles per-second rates, not monthly quotas.

**Primary recommendation:** Two YAML files from congress-legislators (committees-current + committee-membership-current for FED-01; legislators-current leadership_roles field for FED-02). LegiScan client in its own file with a monthly counter backed by a simple JSON file. Three new handler functions added to `handlers.go` with routes in `routes.go` — following the exact same pattern as `GetPoliticianEndorsements`.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FED-01 | Go CLI `import-committees` subcommand imports committee assignments from unitedstates/congress-legislators YAML, matching politicians via bioguide_id | `committee-membership-current.yaml` keyed by `thomas_id`; member entries have `bioguide` field; match via `legislative_politician_id_map` bridge table; upsert into `legislative_committees` + `legislative_committee_memberships` |
| FED-02 | Go CLI `import-leadership` subcommand imports leadership roles (Speaker, Majority/Minority Leader, Whip, etc.) from congress-legislators YAML | `leadership_roles` top-level array in `legislators-current.yaml`; fields: title, chamber, start, end; filter to current (no end date or end >= today); match via `bioguide` field in YAML; upsert into `legislative_leadership_roles` |
| FED-07 | LegiScan API client with rate limiting (30K queries/month) for Senate vote gap-fill | LegiScan base URL `https://api.legiscan.com/?key=KEY&op=OPERATION&id=VALUE`; state `"US"` for Congress; `getRollCall` returns `votes[]` with `people_id`, `vote_id`, `vote_text`; `getPerson` returns `people_id`, `votesmart_id`, `opensecrets_id`, `ballotpedia`; rate limit via persistent counter + `golang.org/x/time/rate` |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `github.com/goccy/go-yaml` | v1.18.0 | Parse congress-legislators YAML files | Already in go.mod (added in Phase 54); established pattern in backfill_ids.go |
| `net/http` stdlib | Go 1.24 | HTTP download of YAML files; LegiScan API calls | Already used throughout codebase |
| GORM | 1.30.0 | Upsert into legislative_committees, memberships, leadership tables | All Phase 54 tables already AutoMigrated and ready |
| `golang.org/x/time/rate` | latest (available in go.sum transitively) | Token bucket for per-second burst control on LegiScan calls | Standard Go rate limiting approach |
| `github.com/go-chi/chi/v5` | v5.2.1 | Route registration for new endpoints | Already used in routes.go |
| `github.com/google/uuid` | v1.6.0 | UUID handling in new handlers | Established pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `encoding/json` stdlib | Go 1.24 | Parse LegiScan JSON responses, persist monthly counter | No external JSON lib needed |
| `os`, `path/filepath` stdlib | Go 1.24 | Read/write persistent monthly query counter file | Simple file-based counter |
| `time` stdlib | Go 1.24 | Check leadership_roles end dates; monthly counter reset logic | Standard |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| File-based monthly counter | DB row in `essentials` schema | DB is heavier; file next to binary is simpler for CLI tool; both are acceptable |
| `golang.org/x/time/rate` | `github.com/uber-go/ratelimit` (leaky bucket) | uber-go version is leaky bucket (strict rate), x/time is token bucket (burst-friendly); token bucket is better for CLI batch imports that run infrequently |
| `gopkg.in/yaml.v3` | `goccy/go-yaml` | `gopkg.in/yaml.v3` is archived — must not be used (locked decision from Phase 54) |

**Installation (no new dependencies needed for Phase 55):**
```bash
# github.com/goccy/go-yaml v1.18.0 already in go.mod
# golang.org/x/time is available transitively — promote to direct require if needed:
cd EV-Backend
go get golang.org/x/time@latest
```

---

## Architecture Patterns

### Recommended Project Structure

All new code goes in `internal/essentials/`. No new packages, no new subdirectories:

```
EV-Backend/
├── internal/essentials/
│   ├── import_committees.go     ← NEW: ImportCommittees function (FED-01)
│   ├── import_leadership.go     ← NEW: ImportLeadership function (FED-02)
│   ├── legiscan_client.go       ← NEW: LegiScanClient struct with rate limiting (FED-07)
│   ├── handlers.go              ← MODIFY: Add GetPoliticianCommittees, GetPoliticianLeadership
│   └── routes.go                ← MODIFY: Register two new routes
├── main.go                      ← MODIFY: Add import-committees and import-leadership cases
└── go.mod                       ← MODIFY: Promote golang.org/x/time to direct if needed
```

### Pattern 1: CLI Subcommand (established in backfill_ids.go and main.go)

**What:** Each import subcommand follows the same Config+Result struct pattern. `main.go` dispatches and `os.Exit(0)` after printing counts.

**Example (from existing backfill-legislative-ids case):**
```go
// Source: EV-Backend/main.go
case "import-committees":
    dryRun := false
    congressNumber := 119  // default to current
    for _, arg := range os.Args[2:] {
        if arg == "--dry-run" {
            dryRun = true
        }
        // parse --congress=119 flag
    }
    result, err := essentials.ImportCommittees(essentials.ImportCommitteesConfig{
        DryRun:         dryRun,
        CongressNumber: congressNumber,
    })
    if err != nil {
        log.Fatal("import-committees failed: ", err)
    }
    fmt.Printf("Import complete: %d committees, %d memberships, %d skipped\n",
        result.CommitteesUpserted, result.MembershipsUpserted, result.Skipped)
    os.Exit(0)
```

### Pattern 2: congress-legislators YAML Download and Parse

**What:** HTTP GET from raw.githubusercontent.com, unmarshal into minimal struct. Already established in `backfill_ids.go`.

**Key URLs:**
```go
const (
    committeesCurrentURL    = "https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committees-current.yaml"
    committeeMembershipURL  = "https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committee-membership-current.yaml"
    legislatorsCurrentURL   = "https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml"
)
```

**committees-current.yaml structure (verified via WebFetch):**
```go
type committeeYAML struct {
    ThomasID          string             `yaml:"thomas_id"`        // "HSAG", "SSAF", "JSTX"
    Name              string             `yaml:"name"`
    Type              string             `yaml:"type"`             // "house", "senate", "joint"
    HouseCommitteeID  string             `yaml:"house_committee_id"`
    SenateCommitteeID string             `yaml:"senate_committee_id"`
    Subcommittees     []subcommitteeYAML `yaml:"subcommittees"`
}

type subcommitteeYAML struct {
    ThomasID string `yaml:"thomas_id"`  // numeric string: "15", "22"
    Name     string `yaml:"name"`
}
```

**committee-membership-current.yaml structure (verified via WebFetch):**
```
Top level: map[string][]memberYAML
Key: committee/subcommittee thomas_id (e.g. "HSAG" or "HSAG15" for subcommittee)
```
```go
// Parsed as a map: map[string][]committeeMemberYAML
type committeeMemberYAML struct {
    Name     string `yaml:"name"`     // human-readable, for debugging only
    Bioguide string `yaml:"bioguide"` // primary matching key
    Party    string `yaml:"party"`    // "majority" or "minority"
    Rank     int    `yaml:"rank"`
    Title    string `yaml:"title"`    // "Chairman", "Ranking Member", "Ex Officio" (or empty)
    Chamber  string `yaml:"chamber"`  // only for joint committees: "house" or "senate"
}
```

**Role normalization (title field is not normalized per README):**
```go
func normalizeCommitteeRole(title string) string {
    t := strings.ToLower(strings.TrimSpace(title))
    switch {
    case strings.Contains(t, "chair") && !strings.Contains(t, "vice") && !strings.Contains(t, "ranking"):
        return "chair"
    case strings.Contains(t, "ranking"):
        return "ranking_member"
    case strings.Contains(t, "vice") && strings.Contains(t, "chair"):
        return "vice_chair"
    case strings.Contains(t, "ex officio"):
        return "ex_officio"
    default:
        return "member"
    }
}
```

**legislators-current.yaml leadership_roles structure (verified via WebFetch and WebSearch):**
```go
// Add to existing legislatorYAML struct used in backfill_ids.go, OR define new struct
type legislatorWithLeadershipYAML struct {
    ID struct {
        Bioguide string `yaml:"bioguide"`
    } `yaml:"id"`
    Name struct {
        Official string `yaml:"official_full"`
    } `yaml:"name"`
    LeadershipRoles []leadershipRoleYAML `yaml:"leadership_roles"`
}

type leadershipRoleYAML struct {
    Title   string `yaml:"title"`   // "Speaker of the House", "Senate Majority Leader", etc.
    Chamber string `yaml:"chamber"` // "house" or "senate"
    Start   string `yaml:"start"`   // "YYYY-MM-DD"
    End     string `yaml:"end"`     // "YYYY-MM-DD" or empty if current
}
```

**Filter to current leadership roles:**
```go
func isCurrentLeadershipRole(role leadershipRoleYAML) bool {
    if role.End == "" {
        return true  // no end date = currently serving
    }
    end, err := time.Parse("2006-01-02", role.End)
    if err != nil {
        return false
    }
    return end.After(time.Now())
}
```

### Pattern 3: GORM Upsert for Legislative Tables

**What:** Use `clause.OnConflict` with the composite unique index defined in Phase 54 models. This is the established pattern for all other essentials models.

**Committee upsert (unique on external_id + jurisdiction):**
```go
// Source: EV-Backend/internal/essentials/models.go — LegislativeCommittee unique index
committee := LegislativeCommittee{
    ExternalID:   thomasID,          // "HSAG"
    Jurisdiction: "federal",
    Name:         name,
    Type:         committeeType,     // "committee" or "subcommittee"
    Chamber:      chamber,           // "house", "senate", "joint"
    ParentID:     parentID,          // nil for top-level, UUID for subcommittees
    IsCurrent:    true,
    Source:       "congress-legislators",
}
db.DB.Clauses(clause.OnConflict{
    Columns:   []clause.Column{{Name: "external_id"}, {Name: "jurisdiction"}},
    DoUpdates: clause.AssignmentColumns([]string{"name", "type", "chamber", "parent_id", "is_current"}),
}).Clauses(clause.Returning{Columns: []clause.Column{{Name: "id"}}}).Create(&committee)
```

**Membership upsert (unique on committee_id + politician_id + congress_number):**
```go
// Source: EV-Backend/internal/essentials/models.go — LegislativeCommitteeMembership
membership := LegislativeCommitteeMembership{
    CommitteeID:    committeeDBID,
    PoliticianID:   polID,
    CongressNumber: congressNumber,  // 119
    Role:           normalizeCommitteeRole(member.Title),
    IsCurrent:      true,
}
db.DB.Clauses(clause.OnConflict{
    Columns:   []clause.Column{{Name: "committee_id"}, {Name: "politician_id"}, {Name: "congress_number"}},
    DoUpdates: clause.AssignmentColumns([]string{"role", "is_current"}),
}).Create(&membership)
```

**Leadership upsert (unique on politician_id + session_id + chamber):**
```go
// Source: EV-Backend/internal/essentials/models.go — LegislativeLeadershipRole
role := LegislativeLeadershipRole{
    PoliticianID: polID,
    SessionID:    sessionID,    // nil if no session row created yet
    Chamber:      role.Chamber, // "house" or "senate"
    Title:        role.Title,
    IsCurrent:    true,
    Source:       "congress-legislators",
}
db.DB.Clauses(clause.OnConflict{
    Columns:   []clause.Column{{Name: "politician_id"}, {Name: "chamber"}},
    DoUpdates: clause.AssignmentColumns([]string{"title", "is_current", "start_date", "end_date"}),
}).Create(&role)
```

### Pattern 4: LegiScan Client with Rate Limiting

**What:** A struct wrapping `net/http.Client` with (a) monthly query budget enforced via a persistent counter, and (b) per-second burst control via `golang.org/x/time/rate.Limiter`. Phase 55 creates the client; Phase 56 uses it.

**LegiScan API URL format (verified via Microsoft connector documentation):**
```
https://api.legiscan.com/?key={API_KEY}&op={OPERATION}&{PARAM}={VALUE}
```

**For Congress:** state = `"US"` (confirmed via LegiScan website showing "US Congress Legislature 2025-2026")

**Rate limiting design:**
```go
// Source: pattern described in golang.org/x/time/rate docs
type LegiScanClient struct {
    apiKey     string
    httpClient *http.Client
    limiter    *rate.Limiter   // burst control: ~1 req/sec is safe
    counter    *monthlyCounter // persistent monthly budget
}

type monthlyCounter struct {
    Month    string `json:"month"`    // "2026-03"
    Queries  int    `json:"queries"`
    filepath string
}

// Monthly limit: 30,000 queries/month free tier
const legiScanMonthlyLimit = 30_000
// Burst limit: conservative 1 req/sec for CLI import workload
// At 1 req/sec, 30K queries = ~8.3 hours of continuous use — budget is the real constraint
var legiScanLimiter = rate.NewLimiter(rate.Every(time.Second), 3) // 3/sec burst, 1/sec sustained

func NewLegiScanClient(apiKey string, counterPath string) *LegiScanClient {
    return &LegiScanClient{
        apiKey:     apiKey,
        httpClient: &http.Client{Timeout: 30 * time.Second},
        limiter:    rate.NewLimiter(rate.Every(time.Second), 3),
        counter:    loadMonthlyCounter(counterPath),
    }
}
```

**Monthly counter logic:**
```go
func (c *LegiScanClient) checkAndIncrementBudget() error {
    currentMonth := time.Now().Format("2006-01")
    if c.counter.Month != currentMonth {
        // New month — reset counter
        c.counter.Month = currentMonth
        c.counter.Queries = 0
    }
    if c.counter.Queries >= legiScanMonthlyLimit {
        return fmt.Errorf("LegiScan monthly budget exhausted (%d/%d queries used for %s)",
            c.counter.Queries, legiScanMonthlyLimit, c.counter.Month)
    }
    c.counter.Queries++
    return c.counter.save() // persist to file
}
```

**Core query method:**
```go
func (c *LegiScanClient) query(ctx context.Context, op string, params map[string]string) ([]byte, error) {
    if err := c.checkAndIncrementBudget(); err != nil {
        return nil, err
    }
    if err := c.limiter.Wait(ctx); err != nil {
        return nil, err
    }
    // Build URL: https://api.legiscan.com/?key=KEY&op=OPERATION&param=value
    u, _ := url.Parse("https://api.legiscan.com/")
    q := u.Query()
    q.Set("key", c.apiKey)
    q.Set("op", op)
    for k, v := range params {
        q.Set(k, v)
    }
    u.RawQuery = q.Encode()
    resp, err := c.httpClient.Do(...)
    // ... standard error handling
}
```

**Key operations for Phase 55 (client must expose, but Phase 56 calls them):**
- `GetSessionList(state string)` — state="US" for Congress
- `GetRollCall(rollCallID int)` — returns votes[] with people_id, vote_id, vote_text
- `GetPerson(peopleID int)` — returns people_id, name, party, district, votesmart_id, opensecrets_id, ballotpedia
- `GetSessionPeople(sessionID int)` — returns all persons for a session

**getRollCall votes array (verified via Microsoft connector documentation):**
```go
type LegiScanRollCall struct {
    RollCallID int    `json:"roll_call_id"`
    BillID     int    `json:"bill_id"`
    Date       string `json:"date"`
    Desc       string `json:"desc"`
    Yea        int    `json:"yea"`
    Nay        int    `json:"nay"`
    NV         int    `json:"nv"`
    Absent     int    `json:"absent"`
    Total      int    `json:"total"`
    Passed     int    `json:"passed"`
    Chamber    string `json:"chamber"`
    ChamberID  int    `json:"chamber_id"`
    Votes      []LegiScanVote `json:"votes"`
}

type LegiScanVote struct {
    PeopleID int    `json:"people_id"`
    VoteID   int    `json:"vote_id"`
    VoteText string `json:"vote_text"` // "Yea", "Nay", "NV", "Absent"
}
```

**getPerson response (verified via Microsoft connector documentation):**
```go
type LegiScanPerson struct {
    PeopleID        int    `json:"people_id"`
    StateID         int    `json:"state_id"`
    PartyID         string `json:"party_id"`
    Party           string `json:"party"`
    RoleID          int    `json:"role_id"`
    Role            string `json:"role"`
    Name            string `json:"name"`
    FirstName       string `json:"first_name"`
    LastName        string `json:"last_name"`
    Suffix          string `json:"suffix"`
    Nickname        string `json:"nickname"`
    District        string `json:"district"`
    VotesmartID     int    `json:"votesmart_id"`
    OpensecretsID   string `json:"opensecrets_id"`
    KnowwhoPID      int    `json:"knowwho_pid"`
    Ballotpedia     string `json:"ballotpedia"`
}
```

**Note:** LegiScan getPerson does NOT return a bioguide_id field. Linking LegiScan people_id to bioguide_id must be done via name matching or via the `legislative_politician_id_map` bridge table (Phase 57 adds legiscan id_type entries).

### Pattern 5: API Handler (established in GetPoliticianEndorsements)

**What:** Handler parses `{id}` UUID from URL, runs a raw SQL JOIN query, maps rows to DTO structs, calls `writeJSON`.

**Template (from existing GetPoliticianEndorsements):**
```go
func GetPoliticianCommittees(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    if id == "" {
        http.Error(w, "Missing id parameter", http.StatusBadRequest)
        return
    }
    parsedID, err := uuid.Parse(id)
    if err != nil {
        http.Error(w, "Invalid id format", http.StatusBadRequest)
        return
    }

    type committeeRow struct {
        CommitteeName  string
        Role           string
        Chamber        string
        CongressNumber int
        IsCurrent      bool
        ParentName     string
    }
    var rows []committeeRow
    if err := db.DB.Raw(`
        SELECT
            c.name AS committee_name,
            m.role,
            c.chamber,
            m.congress_number,
            m.is_current,
            p.name AS parent_name
        FROM essentials.legislative_committee_memberships m
        JOIN essentials.legislative_committees c ON c.id = m.committee_id
        LEFT JOIN essentials.legislative_committees p ON p.id = c.parent_id
        WHERE m.politician_id = ?
        ORDER BY m.is_current DESC, c.chamber, c.name
    `, parsedID).Scan(&rows).Error; err != nil {
        http.Error(w, "DB fetch error", http.StatusInternalServerError)
        return
    }

    result := make([]CommitteeAssignmentOut, 0, len(rows))
    // map rows to DTOs...
    writeJSON(w, result)
}
```

### Anti-Patterns to Avoid

- **GORM foreign key associations across schemas:** Do NOT add `foreignKey` tags pointing at `Politician` from any legislative model. Established pattern from Phase 54: use bare UUID fields only.
- **`gopkg.in/yaml.v3`:** Archived. Always use `github.com/goccy/go-yaml`.
- **Matching on name without bioguide bridge:** All politician matching for imports MUST go through `legislative_politician_id_map` bridge table. Joining directly on `politicians.full_name` for committee memberships would be unreliable and slow.
- **Not handling missing bridge rows:** Some politicians in the database may not have bridge rows yet (NATIONAL_EXEC, cabinet). Import code must gracefully log and skip unmatched bioguide IDs.
- **Over-counting monthly LegiScan budget:** The Phase 55 plan creates the client but doesn't make any API calls. LegiScan API is only used starting in Phase 56. The counter file starts at 0.
- **Hardcoding CongressNumber 119:** Accept as CLI flag with default 119, not hardcoded. Allow future re-runs for 120th Congress.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing | Custom tokenizer | `goccy/go-yaml` | Complex nesting in congress-legislators; already in go.mod |
| Rate limiting | Sleep loops | `golang.org/x/time/rate` + monthly counter | Edge cases around burst, concurrency; standard approach |
| UUID generation | Custom IDs | GORM `default:uuid_generate_v4()` | Pattern established across all essentials models |
| HTTP JSON parsing | Manual string search | `encoding/json` `Unmarshal` | Handles escaping, nesting |
| Committee hierarchy | Recursive DB queries | Self-referential `ParentID` already in `LegislativeCommittee` | Schema already handles it |

**Key insight:** The congress-legislators YAML is intentionally maintained and machine-readable. Don't build custom parsing — the YAML structure is stable and goccy handles it cleanly with minimal struct definitions.

---

## Common Pitfalls

### Pitfall 1: committee-membership-current.yaml is a MAP, not an array

**What goes wrong:** Code tries to unmarshal the file as `[]struct{}` and gets an empty result or parse error.
**Why it happens:** The file is `map[thomas_id][]member` at the top level (keyed dict), unlike `committees-current.yaml` and `legislators-current.yaml` which are top-level arrays.
**How to avoid:** Parse with `map[string][]committeeMemberYAML` target type.
**Warning signs:** Empty membership result after successful parse; len(membership_map) == 0.

```go
// CORRECT:
var membershipMap map[string][]committeeMemberYAML
if err := yaml.Unmarshal(body, &membershipMap); err != nil { ... }

// WRONG:
var memberships []struct{ ... }
yaml.Unmarshal(body, &memberships) // gives empty slice
```

### Pitfall 2: Subcommittee thomas_id composition

**What goes wrong:** Subcommittee membership entries in committee-membership-current.yaml use COMPOSED keys like `"HSAG15"` (parent `"HSAG"` + subcommittee `"15"`), not just `"15"`.
**Why it happens:** `committees-current.yaml` stores subcommittee thomas_ids as simple numeric strings within the parent entry. The membership file composes them as `parent_thomas_id + subcommittee_thomas_id`.
**How to avoid:** When iterating membership map keys, check if the key matches a known parent thomas_id — if not, it's a subcommittee key. Parse subcommittees from committees-current by composing the key.
**Warning signs:** Subcommittee memberships not found because lookup uses the numeric thomas_id `"15"` instead of `"HSAG15"`.

```go
// When building the committee lookup: for each top-level committee in committees-current,
// iterate subcommittees and compose the key:
for _, parent := range committees {
    committeeByThomasID[parent.ThomasID] = parent
    for _, sub := range parent.Subcommittees {
        composedKey := parent.ThomasID + sub.ThomasID  // e.g. "HSAG15"
        subcommitteeByComposedKey[composedKey] = sub
    }
}
```

### Pitfall 3: leadership_roles field only present for leaders — not on most legislators

**What goes wrong:** Code tries to access `leadership_roles` on every legislator and gets nil/empty for all ~535 members, concluding the field doesn't exist.
**Why it happens:** The field is only populated for members who hold formal leadership positions (Speaker, Leaders, Whips, President Pro Tempore). Most entries in legislators-current.yaml have no `leadership_roles` key.
**How to avoid:** Use a pointer or check `len(leg.LeadershipRoles) > 0` before processing. Result count of 5-10 leadership records is correct (one per chamber per party).
**Warning signs:** `INSERT 0` rows on leadership import despite no errors.

### Pitfall 4: LegiScan `getPerson` has no bioguide_id

**What goes wrong:** Phase 55 creates the LegiScan client and attempts to map LegiScan `people_id` to existing politicians via `getPerson`, expecting a `bioguide_id` field in the response.
**Why it happens:** LegiScan's `PersonResponse` does not include `bioguide_id` (verified via Microsoft connector documentation).
**How to avoid:** Do NOT attempt LegiScan-to-bioguide matching in Phase 55. That ID bridge work is Phase 57 (state data). Phase 55 client just needs to work correctly — actual linking happens later.
**Warning signs:** Nil/empty string when accessing `person.BioguideID`.

### Pitfall 5: Monthly counter file path in CLI vs. server context

**What goes wrong:** Counter file saves to relative path `./legiscan_counter.json` which resolves differently when running `go run . import-committees` from different directories.
**How to avoid:** Accept counter path as a config option with a sensible default relative to the binary. Document where the file lives.
**Warning signs:** Counter resets to 0 on every run; monthly budget not enforced.

### Pitfall 6: import-leadership inserts historical roles (no `end` but ancient `start`)

**What goes wrong:** Old leadership records (e.g., Schumer as Minority Whip 2007-2009) get imported as current because filter logic only checks for empty `end` field.
**Why it happens:** `leadership_roles` array in congress-legislators contains FULL history for some members, not just current roles. Some entries have `end` dates, others for truly current roles have no `end`.
**How to avoid:** Filter on `end == "" OR end >= today`. Records with `end` dates in the past should be skipped for the `import-leadership` subcommand (or stored with `is_current = false` if historical tracking is desired — but the schema supports it).
**Warning signs:** Import reports 40+ leadership roles when there should be ~8 (Speaker, Majority/Minority Leader + Whips in each chamber, President Pro Tempore).

---

## Code Examples

### Import Committees — Main Flow

```go
// Source: based on backfill_ids.go pattern in EV-Backend/internal/essentials/
type ImportCommitteesConfig struct {
    DryRun         bool
    CongressNumber int  // default 119
}

type ImportCommitteesResult struct {
    CommitteesUpserted  int
    MembershipsUpserted int
    Skipped             int
    Errors              []string
}

func ImportCommittees(cfg ImportCommitteesConfig) (ImportCommitteesResult, error) {
    // 1. Download + parse committees-current.yaml
    // 2. Download + parse committee-membership-current.yaml (as map[string][]member)
    // 3. Build thomas_id -> DB committee UUID map (upsert as we go)
    // 4. For each member in membership map:
    //    a. Look up bioguide in legislative_politician_id_map to get politician UUID
    //    b. Look up committee UUID from map
    //    c. Upsert LegislativeCommitteeMembership
    // 5. Return result counts
}
```

### Import Leadership — Main Flow

```go
type ImportLeadershipConfig struct {
    DryRun bool
}

func ImportLeadership(cfg ImportLeadershipConfig) (ImportLeadershipResult, error) {
    // 1. Download + parse legislators-current.yaml
    // 2. For each legislator where len(leadership_roles) > 0:
    //    a. Find current roles (end == "" or end >= today)
    //    b. Look up politician UUID via legislative_politician_id_map (bioguide)
    //    c. Upsert LegislativeLeadershipRole
    // 3. Return result counts
}
```

### Bridge Table Lookup (required for both imports)

```go
// Source: pattern needed for import_committees.go and import_leadership.go
func lookupPoliticianByBioguide(bioguide string) (uuid.UUID, error) {
    var bridge LegislativePoliticianIDMap
    err := db.DB.Where("id_type = ? AND id_value = ?", "bioguide", bioguide).
        First(&bridge).Error
    if err != nil {
        return uuid.Nil, fmt.Errorf("no bridge row for bioguide %s: %w", bioguide, err)
    }
    return bridge.PoliticianID, nil
}
```

### GetPoliticianLeadership Handler

```go
// New DTO for leadership response
type LeadershipRoleOut struct {
    Title     string `json:"title"`
    Chamber   string `json:"chamber"`
    IsCurrent bool   `json:"is_current"`
    StartDate string `json:"start_date,omitempty"`
    EndDate   string `json:"end_date,omitempty"`
}

func GetPoliticianLeadership(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    parsedID, err := uuid.Parse(id)
    if err != nil {
        http.Error(w, "Invalid id format", http.StatusBadRequest)
        return
    }

    var roles []LegislativeLeadershipRole
    if err := db.DB.Where("politician_id = ?", parsedID).
        Order("is_current DESC, start_date DESC").
        Find(&roles).Error; err != nil {
        http.Error(w, "DB fetch error", http.StatusInternalServerError)
        return
    }

    result := make([]LeadershipRoleOut, 0, len(roles))
    for _, r := range roles {
        out := LeadershipRoleOut{
            Title:     r.Title,
            Chamber:   r.Chamber,
            IsCurrent: r.IsCurrent,
        }
        if r.StartDate != nil {
            out.StartDate = r.StartDate.Format("2006-01-02")
        }
        result = append(result, out)
    }
    writeJSON(w, result)
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `gopkg.in/yaml.v3` | `goccy/go-yaml` | Phase 54 (archived) | Must use goccy; do not use yaml.v3 |
| congress-legislators as supplemental only | Primary source for committees + leadership | Phase 55 | YAML is the canonical source for current-Congress committee assignments and leadership; Congress.gov API is for bills/votes (Phase 56) |
| LegiScan for state data only | LegiScan for Senate votes too | STATE.md decision | Congress.gov API v3 does NOT include Senate roll calls as of March 2026; LegiScan covers US Congress including Senate |

**Deprecated/outdated:**
- `gopkg.in/yaml.v3`: Archived, do not use. Replaced by `goccy/go-yaml`.
- Direct `politicians.bioguide_id` lookups for import matching: Use `legislative_politician_id_map` bridge table instead — it's the single source of truth for ID cross-references.

---

## Open Questions

1. **LegislativeSession for committees and leadership — should one be created?**
   - What we know: `LegislativeCommitteeMembership.SessionID` is nullable. `LegislativeLeadershipRole.SessionID` is nullable. The schema was designed to work without a session row.
   - What's unclear: Should import-committees create a `LegislativeSession` row for the 119th Congress, or leave `session_id = NULL` and rely on `congress_number` alone?
   - Recommendation: Create a single `LegislativeSession` row for "119th Congress" with `jurisdiction = "federal"`, `external_id = "119"`, `is_current = true`. Link memberships and roles to it. This enables frontend session filtering (UI-05) later without schema changes.

2. **How many active federal politicians have bridge rows after Phase 54 backfill?**
   - What we know: Phase 54 backfill downloads congress-legislators YAML and inserts bioguide bridge rows for all active NATIONAL_UPPER + NATIONAL_LOWER politicians. The database coverage is limited to the geofence area (primarily Indiana-area coverage from BallotReady).
   - What's unclear: If the database only has ~8 Indiana federal politicians (not all 535 members of Congress), then import-committees will only create ~8 membership rows, not the full 535-member committee roster.
   - Recommendation: This is expected and acceptable. The import CLI imports ALL committees and ALL membership data from the YAML — it just links to politicians we have in our DB. Unmatched bioguides are logged and skipped. Future BallotReady coverage expansion will fill in the rest automatically when bridge rows are added.

3. **`golang.org/x/time` promotion from indirect to direct in go.mod?**
   - What we know: `golang.org/x/time` is available transitively (via `golang.org/x/crypto`). May already be in go.sum.
   - Recommendation: Run `go get golang.org/x/time@latest` when adding the LegiScan client to promote it to a direct dependency with a pinned version.

---

## Sources

### Primary (HIGH confidence)
- `EV-Backend/internal/essentials/models.go` — confirmed all Phase 54 models exist and are ready; LegislativeCommittee, LegislativeCommitteeMembership, LegislativeLeadershipRole struct definitions
- `EV-Backend/internal/essentials/backfill_ids.go` — confirmed CLI import pattern, goccy/go-yaml usage, bridge table lookup pattern
- `EV-Backend/main.go` — confirmed CLI subcommand dispatch pattern
- `EV-Backend/internal/essentials/handlers.go` — confirmed GetPoliticianEndorsements handler pattern for new committee/leadership handlers
- `EV-Backend/go.mod` — confirmed goccy/go-yaml v1.18.0 already present
- `https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committees-current.yaml` (WebFetch) — verified exact YAML structure: type/thomas_id/house_committee_id/senate_committee_id/subcommittees[] fields
- `https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committee-membership-current.yaml` (WebFetch) — verified map[thomas_id][]member structure; member fields: name, bioguide, party, rank, title
- `https://learn.microsoft.com/en-us/connectors/legiscan/` (WebFetch) — verified complete LegiScan API operations, all request/response schemas including getRollCall votes[], getPerson response fields, getSessionList format

### Secondary (MEDIUM confidence)
- WebSearch "congress-legislators YAML leadership_roles field structure" — confirmed `leadership_roles` is a top-level array (not in terms), structure: title/chamber/start/end fields
- LegiScan state `"US"` for Congress — confirmed via `https://legiscan.com/US` showing "US Congress Legislature 2025-2026 | 119th Congress"
- `golang.org/x/time/rate` for token bucket in Go — confirmed standard approach via pkg.go.dev reference

### Tertiary (LOW confidence)
- LegiScan 30K/month quota details (tracking mechanism, exact reset date) — confirmed as "30K/month, resets 1st" from multiple sources but exact enforcement mechanism (key-based vs IP-based) not verified from official docs

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in go.mod or standard library
- Architecture: HIGH — all patterns established in Phase 54 and existing handlers.go
- YAML data structures: HIGH — directly verified via WebFetch of raw YAML files and README
- LegiScan API: HIGH — complete response schemas verified via Microsoft Power Platform connector documentation (authoritative, up-to-date)
- Pitfalls: HIGH — derived directly from verified data structure quirks (map vs array, key composition)

**Research date:** 2026-03-01
**Valid until:** 2026-06-01 (congress-legislators YAML is stable; LegiScan API is stable; Go libraries are stable)
