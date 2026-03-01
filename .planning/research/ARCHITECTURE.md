# Architecture Patterns: Legislative Profile Data Integration

**Domain:** Civic tech — legislative activity data (committees, votes, bills, leadership) enrichment for existing politician profiles
**Researched:** 2026-03-01
**Confidence:** HIGH — based on direct source inspection of all backend files, existing lazy-fetch and import CLI patterns, and verified API documentation for Congress.gov and Open States

---

## System Overview

The v2026.3 milestone adds a new data domain to existing politician profiles. The architecture must answer three distinct questions: where does the data come from (external APIs, static datasets, scraping), how does it get into the database (import CLI for static data, lazy-fetch goroutines for dynamic data), and how does the frontend display it (new profile sections, separate fetch calls or inline in profile response).

The milestone uses a **hybrid write model**: static data (committee assignments, leadership positions) is loaded once via CLI import and refreshed periodically; dynamic data (votes, bills) is fetched from external APIs on first profile view and cached in the database.

This is not a new module. All legislative data lives within `internal/essentials/` following the existing package structure. No new Go packages are needed.

```
┌───────────────────────────────────────────────────────────────────────┐
│                     IMPORT PIPELINE (CLI, one-time / periodic)         │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  congress-legislators YAML (GitHub raw)                                │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  import-committees subcommand (new, in main.go switch)       │     │
│  │  - Reads committees-current.yaml + committee-membership-     │     │
│  │    current.yaml from unitedstates/congress-legislators        │     │
│  │  - Upserts into essentials.legislative_committees            │     │
│  │  - Upserts into essentials.legislative_committee_memberships │     │
│  │  - Matches politician via bioguide_id on politicians table   │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  congress-legislators YAML (leadership_roles array in legislators-     │
│  current.yaml / legislators-historical.yaml)                           │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  import-leadership subcommand (new, in main.go switch)       │     │
│  │  - Reads legislators-current.yaml                            │     │
│  │  - Parses leadership_roles[] for each member                 │     │
│  │  - Upserts into essentials.legislative_leadership_roles      │     │
│  │  - Matches politician via bioguide_id                        │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  Python scraping scripts (local government — Bloomington + LA County) │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  scrape_committees.py                                        │     │
│  │  - Bloomington: bloomington.in.gov/council/committees        │     │
│  │  - LA County: bos.lacounty.gov (Board standing committees)  │     │
│  │  - Writes to essentials.legislative_committees +            │     │
│  │    essentials.legislative_committee_memberships              │     │
│  │  - Matches politician via full_name + government lookup      │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  Open States or LegiScan import (Indiana + California state)          │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  import-state-legislation subcommand (new, in main.go switch) │    │
│  │  - Fetches bills + votes per legislator via API              │     │
│  │  - Writes to essentials.legislative_bills +                  │     │
│  │    essentials.legislative_votes                              │     │
│  │  - Rate limited: 500/day free tier (Open States)            │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                LAZY-FETCH GOROUTINES (triggered on first profile view)  │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Federal politicians (bioguide_id present, district_type NATIONAL_*)  │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  fetchCongressData(politicianID, bioguideID)  goroutine      │     │
│  │  - Checks leg_data_fetched_at on politicians table           │     │
│  │  - If nil or > 7 days old: fetch from Congress.gov API       │     │
│  │    GET /v3/member/{bioguideId}/sponsored-legislation         │     │
│  │    GET /v3/member/{bioguideId}/cosponsored-legislation       │     │
│  │    (Note: votes available in Senate vote records;            │     │
│  │     House roll call votes beta available via                  │     │
│  │     /v3/house-vote endpoints as of May 2025)                 │     │
│  │  - Upserts into essentials.legislative_bills +              │     │
│  │    essentials.legislative_votes                              │     │
│  │  - Updates politicians.leg_data_fetched_at = NOW()          │     │
│  │  - Rate limit: 5,000 req/hr — safe for per-profile fetch    │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                DATABASE (Supabase / PostgreSQL)                         │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  EXISTING (modified — add leg_data_fetched_at column):                │
│  essentials.politicians                                                │
│  ┌──────────────────────────────────────────────────────────────┐     │
│  │  bioguide_id (existing)  │  leg_data_fetched_at (NEW column) │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  NEW TABLES in essentials schema:                                      │
│                                                                        │
│  essentials.legislative_sessions                                       │
│  ┌──────────────────┬───────────────┬────────────────────────────┐    │
│  │ id (uuid pk)     │ government_id │ name ("119th Congress")     │    │
│  │ start_date       │ end_date      │ jurisdiction ("federal")    │    │
│  └──────────────────┴───────────────┴────────────────────────────┘    │
│                                                                        │
│  essentials.legislative_committees                                     │
│  ┌──────────────────┬────────────────┬───────────────────────────┐    │
│  │ id (uuid pk)     │ external_id    │ name                       │    │
│  │ committee_type   │ chamber        │ parent_committee_id (fk)  │    │
│  │ jurisdiction     │ session_id(fk) │ source ("congress-leg"...) │    │
│  └──────────────────┴────────────────┴───────────────────────────┘    │
│                                                                        │
│  essentials.legislative_committee_memberships                          │
│  ┌──────────────────┬──────────────────┬──────────────────────────┐   │
│  │ id (uuid pk)     │ politician_id(fk) │ committee_id (fk)        │   │
│  │ role             │ rank             │ party ("majority"/"min.") │   │
│  │ session_id (fk)  │ source           │ (UNIQUE: pol+comm+session)│   │
│  └──────────────────┴──────────────────┴──────────────────────────┘   │
│                                                                        │
│  essentials.legislative_leadership_roles                               │
│  ┌──────────────────┬──────────────────┬──────────────────────────┐   │
│  │ id (uuid pk)     │ politician_id(fk) │ title ("Minority Leader")│   │
│  │ chamber          │ start_date        │ end_date                 │   │
│  │ (UNIQUE: pol+title+start_date)                                  │   │
│  └──────────────────┴──────────────────┴──────────────────────────┘   │
│                                                                        │
│  essentials.legislative_bills                                          │
│  ┌──────────────────┬───────────────────┬─────────────────────────┐   │
│  │ id (uuid pk)     │ external_bill_id  │ session_id (fk)          │   │
│  │ bill_number      │ title             │ summary (plain language) │   │
│  │ status           │ sponsor_pol_id(fk)│ introduced_date          │   │
│  │ last_action_date │ subject_tags[]    │ source ("congress.gov")  │   │
│  │ (UNIQUE: ext_bill_id)                                            │   │
│  └──────────────────┴───────────────────┴─────────────────────────┘   │
│                                                                        │
│  essentials.legislative_bill_cosponsors                                │
│  ┌──────────────────┬──────────────────┬──────────────────────────┐   │
│  │ bill_id (fk)     │ politician_id(fk) │ (UNIQUE: bill+pol)       │   │
│  └──────────────────┴──────────────────┴──────────────────────────┘   │
│                                                                        │
│  essentials.legislative_votes                                          │
│  ┌──────────────────┬──────────────────┬──────────────────────────┐   │
│  │ id (uuid pk)     │ politician_id(fk) │ bill_id (fk, nullable)   │   │
│  │ vote_question    │ vote_result      │ date                      │   │
│  │ session_id (fk)  │ external_vote_id │ source                    │   │
│  │ (UNIQUE: pol+ext_vote_id)                                        │   │
│  └──────────────────┴──────────────────┴──────────────────────────┘   │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                EV-BACKEND (Go / Chi / GORM)                            │
│  internal/essentials/                                                  │
│  ├── models.go      — 5 new GORM structs + leg_data_fetched_at field  │
│  ├── setup.go       — AutoMigrate for 5 new tables                    │
│  ├── handlers.go    — GetPoliticianByID triggers lazy-fetch goroutine  │
│  │                  — 5 new sub-resource handlers                      │
│  ├── routes.go      — 5 new GET endpoints under /politician/{id}/...  │
│  └── legislation/   — new sub-package: Congress.gov + Open States     │
│      ├── congress.go   — API client (rate-limit-aware)                │
│      └── openstates.go — API client (rate-limit-aware)                │
└───────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────────┐
│                FRONTEND (essentials React app + ev-ui)                  │
│                                                                        │
│  essentials/src/pages/Profile.jsx                                      │
│  ├── Existing: GET /essentials/politician/{id} (profile data)         │
│  ├── NEW sequential fetches (after main profile loads):               │
│  │     GET /essentials/politician/{id}/committees                     │
│  │     GET /essentials/politician/{id}/leadership                     │
│  │     GET /essentials/politician/{id}/bills                          │
│  │     GET /essentials/politician/{id}/votes                          │
│                                                                        │
│  ev-ui/src/PoliticianProfile.jsx                                       │
│  ├── Existing sections: bio, images, term dates, education, experience│
│  ├── NEW prop: legislativeData (committees, leadership, bills, votes) │
│  ├── NEW LegislativeActivity section renders conditionally            │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

### Existing Components (unchanged or minor modification)

| Component | Responsibility | v2026.3 Change |
|-----------|---------------|----------------|
| `essentials/models.go` | GORM models for existing data | Add 5 new structs; add `leg_data_fetched_at *time.Time` to Politician struct |
| `essentials/setup.go` | AutoMigrate all essentials tables | Add 5 new tables to AutoMigrate call |
| `essentials/handlers.go` | GetPoliticianByID returns full profile | Add goroutine trigger for fetchCongressData when bioguide_id present; add 5 new sub-resource handlers |
| `essentials/routes.go` | Route registration for all endpoints | Add 5 new routes under /politician/{id}/... |
| `main.go` switch dispatch | CLI subcommand routing | Add import-committees, import-leadership cases |
| `PoliticianProfile.jsx` (ev-ui) | Profile layout and rendering | Add LegislativeActivity section; accept new legislativeData prop |
| `Profile.jsx` (essentials) | Page component that fetches politician data | Add sequential fetches for legislative sub-resources; pass to PoliticianProfile |

### New Components (create from scratch)

| Component | File | Responsibility |
|-----------|------|---------------|
| Legislative GORM models | `EV-Backend/internal/essentials/models.go` (additions) | LegislativeSession, LegislativeCommittee, LegislativeCommitteeMembership, LegislativeLeadershipRole, LegislativeBill, LegislativeBillCosponsor, LegislativeVote structs |
| Congress.gov API client | `EV-Backend/internal/essentials/legislation/congress.go` | Fetches sponsored/cosponsored legislation and vote records by bioguide_id; respects 5,000 req/hr rate limit; handles 20-item default / 250 max pagination |
| Open States API client | `EV-Backend/internal/essentials/legislation/openstates.go` | Fetches bills + votes for state legislators by Open States person ID; respects 10 req/min / 500 req/day free tier |
| Legislature committee import | `EV-Backend/internal/committeeimport/import.go` | Parses congress-legislators YAML files; matches bioguide_id to politicians; upserts committees + memberships |
| Leadership role import | `EV-Backend/internal/leadershipimport/import.go` | Parses leadership_roles[] from legislators-current.yaml; upserts into legislative_leadership_roles |
| State committee scraper | `EV-Backend/scripts/scrape_committees.py` | Scrapes Bloomington Common Council and LA County Board committees from city/county websites |
| Committee handler | `EV-Backend/internal/essentials/handlers.go` (addition) | GET /politician/{id}/committees — returns current committee assignments with role and rank |
| Leadership handler | `EV-Backend/internal/essentials/handlers.go` (addition) | GET /politician/{id}/leadership — returns leadership roles with date ranges |
| Bills handler | `EV-Backend/internal/essentials/handlers.go` (addition) | GET /politician/{id}/bills — returns sponsored + cosponsored bills with status and summary |
| Votes handler | `EV-Backend/internal/essentials/handlers.go` (addition) | GET /politician/{id}/votes — returns voting record with bill references and dates |
| LegislativeActivity section | `ev-ui/src/PoliticianProfile.jsx` (addition) | Renders committees, leadership, bills, votes in profile card sections; conditionally hides empty sections |

---

## Data Flow

### Import CLI Flow (static data — committees, leadership)

```
Developer downloads congress-legislators YAML:
  curl -O https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committee-membership-current.yaml
  curl -O https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committees-current.yaml
  curl -O https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml
    ↓
./server import-committees --file committee-membership-current.yaml
    ↓
committeeimport.Run():
  1. Load all politicians WHERE bioguide_id != '' → map[bioguideID]uuid
  2. Parse YAML: for each committee ID → member list
  3. Resolve committee external_id → find or create LegislativeCommittee row
  4. For each member: resolve bioguide → politician_id
  5. Upsert LegislativeCommitteeMembership (politician_id, committee_id, role, rank, party)
     ON CONFLICT (politician_id, committee_id, session_id) DO UPDATE
  6. Print: N memberships inserted/updated, M politicians not found
    ↓
./server import-leadership --file legislators-current.yaml
    ↓
leadershipimport.Run():
  1. Load all politicians WHERE bioguide_id != '' → map[bioguideID]uuid
  2. Parse YAML: for each legislator, check leadership_roles[]
  3. For each leadership_role:
     Upsert LegislativeLeadershipRole (politician_id, title, chamber, start_date, end_date)
     ON CONFLICT (politician_id, title, start_date) DO UPDATE SET end_date = excluded.end_date
  4. Print: N leadership roles inserted/updated
```

### Lazy-Fetch Flow (dynamic data — bills, votes, federal only)

```
User opens /politician/{uuid} profile page
    ↓
GET /essentials/politician/{id}
    ↓
GetPoliticianByID handler (existing):
  - Fetches core profile (existing behavior unchanged)
  - Checks if bioguide_id != '' (federal politician)
  - Checks politicians.leg_data_fetched_at:
      nil OR older than 7 days → launch goroutine
      recent → skip (data already cached)
    ↓ (goroutine, does not block response)
fetchCongressData(ctx, politicianID, bioguideID):
  1. GET https://api.congress.gov/v3/member/{bioguideId}/sponsored-legislation
     ?limit=250&offset=0&api_key={CONGRESS_API_KEY}
     Paginate until count exhausted (250-item pages, pagination.next in response)
  2. GET /v3/member/{bioguideId}/cosponsored-legislation?limit=250
     Same pagination loop
  3. For each bill: upsert LegislativeBill (bill_number, title, summary, status, dates)
     ON CONFLICT (external_bill_id) DO UPDATE (status, last_action_date, summary)
  4. For sponsored bills: upsert with sponsor_pol_id = politicianID
  5. For cosponsored bills: upsert LegislativeBillCosponsor (bill_id, politician_id)
  6. (House votes beta, May 2025+) Attempt GET /v3/house-vote?member={bioguideId}
     If available: upsert LegislativeVote records
  7. UPDATE essentials.politicians SET leg_data_fetched_at = NOW() WHERE id = politicianID
    ↓ (main request already returned to client, goroutine continues in background)
First profile load: legislative sections show empty/loading state
Second profile load (after goroutine completes): legislative sections populated
```

### Profile Page Frontend Flow

```
User navigates to /politician/{id}
    ↓
Profile.jsx:
  1. fetchPolitician(id) → GET /essentials/politician/{id}
     Sets pol state, removes main loading spinner
  2. Conditionally (if pol loaded and has bioguide_id or is_elected):
     Parallel fetch batch:
       fetch(`/essentials/politician/${id}/committees`)
       fetch(`/essentials/politician/${id}/leadership`)
       fetch(`/essentials/politician/${id}/bills`)
       fetch(`/essentials/politician/${id}/votes`)
     Each sets its own loading state independently
    ↓
PoliticianProfile receives legislativeData prop:
  - committees[]    → CommitteeSection (name, role, subcommittees)
  - leadership[]    → LeadershipSection (title, chamber, dates)
  - bills[]         → BillsSection (sponsored + cosponsored tabs, bill number, title, status, summary)
  - votes[]         → VotingRecord (bill title, date, vote value, bill link)
  - Each section: hidden if empty array (no "no data" UI noise for local officials)
```

### Local Government Data Flow (Bloomington + LA County scraping)

```
Developer runs: python3 scripts/scrape_committees.py --jurisdiction bloomington
    ↓
Script fetches bloomington.in.gov/council/committees
  Parses committee names, members, chair designations
  For each committee:
    Looks up government_id for Bloomington Common Council
    Upserts LegislativeCommittee (name, jurisdiction="local", chamber="council")
    For each member:
      Finds politician_id by full_name + government lookup
      Upserts LegislativeCommitteeMembership (politician_id, committee_id, role)
    Commits per-committee (not global transaction)
    ↓
Same pattern for LA County (bos.lacounty.gov) with jurisdiction="county"
```

---

## New GORM Models

### LegislativeSession

```go
type LegislativeSession struct {
    ID           uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    GovernmentID *uuid.UUID `json:"government_id,omitempty" gorm:"type:uuid"`
    Name         string     `json:"name"`                   // "119th Congress", "2025-2026 Indiana General Assembly"
    Jurisdiction string     `json:"jurisdiction"`           // "federal", "state", "local", "county"
    StartDate    string     `json:"start_date"`
    EndDate      string     `json:"end_date"`
    IsCurrent    bool       `json:"is_current" gorm:"default:false"`
}

func (LegislativeSession) TableName() string {
    return "essentials.legislative_sessions"
}
```

### LegislativeCommittee

```go
type LegislativeCommittee struct {
    ID                uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    ExternalID        string     `json:"external_id" gorm:"uniqueIndex:idx_leg_comm_ext,where:external_id != ''"`
    Name              string     `json:"name"`
    CommitteeType     string     `json:"committee_type"` // "standing", "select", "joint", "subcommittee"
    Chamber           string     `json:"chamber"`        // "senate", "house", "council", "board"
    Jurisdiction      string     `json:"jurisdiction"`   // "federal", "state", "local", "county"
    ParentCommitteeID *uuid.UUID `json:"parent_committee_id,omitempty" gorm:"type:uuid"`
    SessionID         *uuid.UUID `json:"session_id,omitempty" gorm:"type:uuid"`
    Source            string     `json:"source"` // "congress-legislators", "scraped", "openstates"
    Memberships       []LegislativeCommitteeMembership `json:"memberships,omitempty" gorm:"foreignKey:CommitteeID"`
}

func (LegislativeCommittee) TableName() string {
    return "essentials.legislative_committees"
}
```

### LegislativeCommitteeMembership

```go
type LegislativeCommitteeMembership struct {
    ID           uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_leg_comm_membership,unique"`
    CommitteeID  uuid.UUID `json:"committee_id" gorm:"type:uuid;uniqueIndex:idx_leg_comm_membership,unique"`
    SessionID    uuid.UUID `json:"session_id" gorm:"type:uuid;uniqueIndex:idx_leg_comm_membership,unique"`
    Role         string    `json:"role"` // "chair", "vice_chair", "ranking_member", "member"
    Rank         int       `json:"rank"` // seniority rank within party (1 = chair/ranking member)
    Party        string    `json:"party"` // "majority", "minority"
    Source       string    `json:"source"`
}

func (LegislativeCommitteeMembership) TableName() string {
    return "essentials.legislative_committee_memberships"
}
```

### LegislativeLeadershipRole

```go
type LegislativeLeadershipRole struct {
    ID           uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_leg_lead,unique"`
    Title        string    `json:"title" gorm:"uniqueIndex:idx_leg_lead,unique"` // "Minority Leader", "Speaker"
    Chamber      string    `json:"chamber"`
    StartDate    string    `json:"start_date" gorm:"uniqueIndex:idx_leg_lead,unique"`
    EndDate      string    `json:"end_date"`
    Source       string    `json:"source"` // "congress-legislators"
}

func (LegislativeLeadershipRole) TableName() string {
    return "essentials.legislative_leadership_roles"
}
```

### LegislativeBill

```go
type LegislativeBill struct {
    ID              uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    ExternalBillID  string     `json:"external_bill_id" gorm:"uniqueIndex"` // "hr1234-119", "in-sb0042-2025"
    SessionID       *uuid.UUID `json:"session_id,omitempty" gorm:"type:uuid"`
    SponsorPolID    *uuid.UUID `json:"sponsor_pol_id,omitempty" gorm:"type:uuid"`
    BillNumber      string     `json:"bill_number"`   // "H.R. 1234", "S. 56"
    Title           string     `json:"title"`
    Summary         string     `json:"summary"`       // Plain-language summary (from API or generated)
    Status          string     `json:"status"`        // "introduced", "passed_house", "enacted", "failed"
    IntroducedDate  string     `json:"introduced_date"`
    LastActionDate  string     `json:"last_action_date"`
    SubjectTags     pq.StringArray `json:"subject_tags" gorm:"type:text[]"`
    Source          string     `json:"source"` // "congress.gov", "openstates", "scraped"
    Cosponsors      []LegislativeBillCosponsor `json:"cosponsors,omitempty" gorm:"foreignKey:BillID"`
}

func (LegislativeBill) TableName() string {
    return "essentials.legislative_bills"
}
```

### LegislativeBillCosponsor

```go
type LegislativeBillCosponsor struct {
    BillID       uuid.UUID `json:"bill_id" gorm:"type:uuid;primaryKey"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;primaryKey"`
}

func (LegislativeBillCosponsor) TableName() string {
    return "essentials.legislative_bill_cosponsors"
}
```

### LegislativeVote

```go
type LegislativeVote struct {
    ID             uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID   uuid.UUID  `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_leg_vote,unique"`
    ExternalVoteID string     `json:"external_vote_id" gorm:"uniqueIndex:idx_leg_vote,unique"` // Roll call ID
    BillID         *uuid.UUID `json:"bill_id,omitempty" gorm:"type:uuid"`
    SessionID      *uuid.UUID `json:"session_id,omitempty" gorm:"type:uuid"`
    VoteQuestion   string     `json:"vote_question"` // "On Passage", "On Amendment", etc.
    VoteResult     string     `json:"vote_result"`   // "Yea", "Nay", "Present", "Not Voting"
    Date           string     `json:"date"`
    Source         string     `json:"source"` // "congress.gov", "openstates"
}

func (LegislativeVote) TableName() string {
    return "essentials.legislative_votes"
}
```

---

## API Endpoint Design

Five new sub-resource endpoints under `/essentials/politician/{id}/`:

```
GET /essentials/politician/{id}/committees
  → []CommitteeMembershipOut (committee name, type, chamber, role, rank, session)
  → Sorted: current session first, then by rank within party

GET /essentials/politician/{id}/leadership
  → []LeadershipRoleOut (title, chamber, start_date, end_date)
  → Sorted: most recent start_date first

GET /essentials/politician/{id}/bills
  → { sponsored: []BillOut, cosponsored: []BillOut }
  → Default: current session only; ?session=all for full history
  → Sorted: introduced_date DESC

GET /essentials/politician/{id}/votes
  → []VoteOut (vote_question, vote_result, date, bill_number, bill_title)
  → Default: current session, limit 50; ?session=all&limit=250 for full history
  → Sorted: date DESC

GET /essentials/politician/{id}/legislative-summary
  → Combined: committees + leadership + recent bills (5) + recent votes (10)
  → One request for frontend initial render; sub-resources for full data
```

The `/legislative-summary` endpoint is the frontend default request. The sub-resource endpoints support deeper views ("see all votes", "see all bills").

### Route registration (routes.go additions):

```go
r.Get("/politician/{id}/committees", GetPoliticianCommittees)
r.Get("/politician/{id}/leadership", GetPoliticianLeadership)
r.Get("/politician/{id}/bills", GetPoliticianBills)
r.Get("/politician/{id}/votes", GetPoliticianVotes)
r.Get("/politician/{id}/legislative-summary", GetPoliticianLegislativeSummary)
```

---

## Integration Points

### Existing Tables Modified

| Table | Field Added | Reason |
|-------|-------------|--------|
| `essentials.politicians` | `leg_data_fetched_at *time.Time` | Lazy-fetch staleness check; nil = never fetched; set to NOW() after successful fetch |

This is the only change to existing tables. All other legislative data goes into new tables. This preserves backward compatibility of existing API responses.

### New Tables (all in `essentials` schema)

| Table | Unique Key | Populated By |
|-------|------------|--------------|
| `essentials.legislative_sessions` | natural key (jurisdiction + name) | CLI import + manual seed |
| `essentials.legislative_committees` | `external_id` (where non-empty) | CLI import + scraper |
| `essentials.legislative_committee_memberships` | `(politician_id, committee_id, session_id)` | CLI import + scraper |
| `essentials.legislative_leadership_roles` | `(politician_id, title, start_date)` | CLI import |
| `essentials.legislative_bills` | `external_bill_id` | Lazy-fetch goroutine + CLI import |
| `essentials.legislative_bill_cosponsors` | `(bill_id, politician_id)` | Lazy-fetch goroutine + CLI import |
| `essentials.legislative_votes` | `(politician_id, external_vote_id)` | Lazy-fetch goroutine + CLI import |

### Go API Internal Boundaries

| Boundary | Change | Scope |
|----------|--------|-------|
| `Politician` struct (models.go) | Add `LegDataFetchedAt *time.Time` field | 1 line |
| `GetPoliticianByID` (handlers.go) | After assembling profile: check bioguide_id + leg_data_fetched_at; launch goroutine if stale | ~15 lines |
| New sub-resource handlers (handlers.go) | GetPoliticianCommittees, GetPoliticianLeadership, GetPoliticianBills, GetPoliticianVotes, GetPoliticianLegislativeSummary | ~30 lines each |
| New routes (routes.go) | 5 route registrations | 5 lines |
| New import subcommands (main.go) | `case "import-committees":` and `case "import-leadership":` in switch | ~20 lines each case |
| New legislation sub-package | `internal/essentials/legislation/congress.go` and `openstates.go` | New package, ~150 lines each |
| setup.go | Add 7 new GORM models to AutoMigrate | 7 lines |

### Frontend Boundaries

| Component | Change | Scope |
|-----------|--------|-------|
| `essentials/src/pages/Profile.jsx` | After pol loads: fetch /legislative-summary; on "see all" actions, fetch sub-resources | ~40 lines |
| `ev-ui/src/PoliticianProfile.jsx` | Add `legislativeData` prop; add LegislativeActivity section at bottom of profile card | ~80 lines; requires ev-ui version bump + publish |

### External Services

| Service | Endpoint | Rate Limit | Key Required | Notes |
|---------|----------|------------|--------------|-------|
| Congress.gov API | `https://api.congress.gov/v3/member/{bioguideId}/sponsored-legislation` | 5,000 req/hr | Yes — free via api.congress.gov/sign-up | 250 max per page; paginate with `offset` param |
| Congress.gov API | `https://api.congress.gov/v3/member/{bioguideId}/cosponsored-legislation` | same | same | Same pagination pattern |
| Congress.gov API | `https://api.congress.gov/v3/house-vote` | same | same | Beta as of May 2025; Senate vote records available separately |
| Open States API v3 | `https://v3.openstates.org/bills` | 10/min, 500/day (free) | Yes — docs.openstates.org/api-v3 | Indiana + California state legislators |
| unitedstates/congress-legislators | GitHub raw YAML files | No rate limit | No | committees-current.yaml, committee-membership-current.yaml, legislators-current.yaml |
| Bloomington bloomington.in.gov | `/council/committees` HTML | No API; scraping | No | Public HTML; well-structured meeting page |
| LA County bos.lacounty.gov | `/board-meeting-agendas/` HTML + Granicus archive | No API; scraping | No | Board standing committees scrapeable from committee pages |
| LegiScan API | `https://api.legiscan.com/` | 30,000 req/month free | Yes — legiscan.com | Alternative to Open States for state-level; deeper bill history |

---

## Architectural Patterns

### Pattern 1: Bioguide-ID as Federal Politician Identifier

**What:** The `bioguide_id` field already exists on `essentials.politicians` (from BallotReady data for federal officials). It is the primary join key for all Congress.gov API calls and for matching congress-legislators YAML records.

**When to use:** Every federal legislative data import/fetch. Check `bioguide_id != ''` before attempting Congress.gov API calls. For politicians without bioguide_id (state, local), use Open States person ID or local identifier.

**Example:**
```go
// In fetchCongressData goroutine
if pol.BioguideID == "" {
    log.Printf("[legislation] skipping non-federal politician %s", pol.ID)
    return
}
resp, err := congressClient.GetSponsoredLegislation(ctx, pol.BioguideID)
```

**Confidence:** HIGH — bioguide_id already stored, used in API response (OfficialOut.BioguideID), and congress-legislators YAML explicitly uses it as the join key.

### Pattern 2: Staleness-Gated Lazy-Fetch (extend existing pattern)

**What:** GetPoliticianByID already uses a background goroutine for candidacy data (BallotReady Phase B). The v2026.3 lazy-fetch follows the same pattern: check a staleness timestamp on the politician record, launch a goroutine if stale, return the cached response immediately.

The staleness window for legislative data is longer than for candidacy data: 7 days is appropriate for bills/votes (Congress is not in continuous session; committee assignments change only per session). The candidacy data pattern used `ExternalGlobalID != ""` as its trigger; legislative data uses `BioguideID != ""` (federal) or Open States person ID (state).

**When to use:** Bills and votes only. Committee assignments and leadership roles are static enough to import via CLI and refresh manually per session. The goroutine approach is only worthwhile when data changes frequently enough to justify on-demand refresh.

**Key implementation detail:** The goroutine must capture context from a detached `context.Background()` (not the request context), because the request context is cancelled when `GetPoliticianByID` returns the response. The existing Phase B goroutine pattern in handlers.go uses this correctly.

**Example:**
```go
// After assembling profile in GetPoliticianByID
if pol.BioguideID != "" {
    stale := pol.LegDataFetchedAt == nil ||
        time.Since(*pol.LegDataFetchedAt) > 7*24*time.Hour
    if stale {
        go func(id uuid.UUID, bioguide string) {
            ctx := context.Background()
            if err := legislation.FetchAndCache(ctx, id, bioguide); err != nil {
                log.Printf("[legislation] fetch failed for %s: %v", bioguide, err)
            }
        }(parsedID, r0.BioguideID)
    }
}
```

**Confidence:** HIGH — based on direct inspection of existing goroutine pattern in handlers.go (candidacy fetch, Phase B).

### Pattern 3: External-ID-Keyed Upsert for Import CLI

**What:** Each new table uses an `external_bill_id`, `external_id`, or composite unique key as the ON CONFLICT target. Import CLI subcommands (import-committees, import-leadership) follow the same pattern as import-stances and import-quotes: load all entities into memory maps for fast lookup, iterate rows, resolve politician by bioguide_id or full_name, upsert with ON CONFLICT DO UPDATE.

**When to use:** All CLI import subcommands. The YAML-based imports (congress-legislators) are simpler than CSV because the YAML already has bioguide IDs as keys.

**Example (committees import):**
```go
// Load bioguide → politician_id map
var pols []struct {
    ID         uuid.UUID `gorm:"column:id"`
    BioguideID string    `gorm:"column:bioguide_id"`
}
db.DB.Raw("SELECT id, bioguide_id FROM essentials.politicians WHERE bioguide_id != ''").Scan(&pols)
byBioguide := make(map[string]uuid.UUID, len(pols))
for _, p := range pols {
    byBioguide[p.BioguideID] = p.ID
}

// For each committee member in YAML
if polID, ok := byBioguide[member.Bioguide]; ok {
    membership := LegislativeCommitteeMembership{
        PoliticianID: polID,
        CommitteeID:  committeeID,
        SessionID:    currentSessionID,
        Role:         resolveRole(member.Title),
        Rank:         member.Rank,
        Party:        member.Party,
        Source:       "congress-legislators",
    }
    db.DB.Clauses(clause.OnConflict{
        Columns:   []clause.Column{{Name: "politician_id"}, {Name: "committee_id"}, {Name: "session_id"}},
        DoUpdates: clause.AssignmentColumns([]string{"role", "rank", "party"}),
    }).Create(&membership)
}
```

**Confidence:** HIGH — follows exact pattern from stanceimport.Run() (which itself follows the same lookup-then-upsert structure).

### Pattern 4: Congress.gov Pagination Handling

**What:** Congress.gov API returns 20 items by default, maximum 250 per request. The `pagination.next` URL in the response indicates whether more pages exist. For a member with many sponsored bills (e.g., a senior senator), pagination may require 3-5 requests.

**Rate limit:** 5,000 requests per hour. At the per-profile lazy-fetch scale (one fetch per politician, triggered once every 7 days), this is not a concern. If bulk backfilling all federal officials at once, budget ~2 requests per politician (sponsored + cosponsored), with 435 House + 100 Senate = ~1,070 requests for a full backfill — well within the 5,000/hr limit.

**Example:**
```go
func (c *CongressClient) GetSponsoredLegislation(ctx context.Context, bioguideID string) ([]BillResult, error) {
    var all []BillResult
    offset := 0
    limit := 250
    for {
        url := fmt.Sprintf("%s/v3/member/%s/sponsored-legislation?limit=%d&offset=%d&api_key=%s",
            c.baseURL, bioguideID, limit, offset, c.apiKey)
        resp, err := c.httpClient.Get(url)
        // ... parse response ...
        all = append(all, page.SponsoredLegislation...)
        if page.Pagination.Next == "" { break }
        offset += limit
    }
    return all, nil
}
```

**Confidence:** MEDIUM — rate limit (5,000/hr) confirmed from official docs. Pagination structure (limit/offset, pagination.next field) confirmed from Congress R package and Postman collection. Exact response field names for house vote beta need verification against live API when implementing.

### Pattern 5: Session-Scoped Data (Default to Current Session)

**What:** The API endpoints should default to returning the current legislative session's data. The `LegislativeSession.IsCurrent` boolean identifies the active session. The `?session=all` query parameter expands to full history.

This avoids overwhelming the UI with 20+ years of vote history on first render, while making the full history discoverable.

**When to use:** All five sub-resource endpoints. The `/legislative-summary` endpoint always returns current session only (no `?session=all` option; it is optimized for card-level display).

**Example:**
```go
func GetPoliticianBills(w http.ResponseWriter, r *http.Request) {
    allSessions := r.URL.Query().Get("session") == "all"
    query := db.DB.Where("sponsor_pol_id = ?", politicianID)
    if !allSessions {
        query = query.Joins("JOIN essentials.legislative_sessions s ON s.id = legislative_bills.session_id").
            Where("s.is_current = true")
    }
    // ...
}
```

### Pattern 6: Sub-Package for External API Clients

**What:** The Congress.gov and Open States API clients belong in a sub-package (`internal/essentials/legislation/`) rather than inline in handlers.go. This follows the existing `internal/essentials/geocoding/` sub-package precedent (the Google Maps client lives there, not in handlers.go).

**When to use:** Any external API client that: (a) requires configuration (API key, base URL), (b) has meaningful retry/rate-limit logic, or (c) will be called from both the lazy-fetch goroutine and CLI import subcommands.

**Package boundary:**
```
internal/essentials/legislation/
├── congress.go    — CongressClient struct, GetSponsoredLegislation(), GetVotes()
└── openstates.go  — OpenStatesClient struct, GetBillsByPerson(), GetVotesByPerson()
```

The CLI import subcommands import from `legislation/` for live API fetching but may also bypass the API entirely (YAML files for congress-legislators). Keep the YAML parsing logic in the `committeeimport` and `leadershipimport` packages, not in `legislation/`.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Including Legislative Data in the Core Profile Response

**What goes wrong:** Adding bills[], votes[], committees[] arrays directly to `OfficialOut` or `PoliticianProfileOut`, so the existing GET /politician/{id} response grows to include potentially thousands of vote records.

**Why it's wrong:** The existing `/politician/{id}` endpoint returns in <50ms by joining a fixed number of tables. Adding unbounded arrays (a senator may have 500+ bills, 1,000+ vote records) would make the core response slow and unpredictable. It also forces the frontend to wait for all legislative data before showing the profile.

**Do this instead:** Separate sub-resource endpoints (`/politician/{id}/bills`, `/politician/{id}/votes`) that the frontend fetches in parallel after the main profile loads. The `/legislative-summary` endpoint provides a fast, bounded slice for the initial render.

### Anti-Pattern 2: Storing Raw API Responses as JSON Blobs

**What goes wrong:** Adding a `raw_api_response jsonb` column to politicians or a single `legislative_data jsonb` table to avoid designing a proper relational schema.

**Why it's wrong:** The existing pattern for all data in this codebase is normalized GORM models with proper foreign keys, unique constraints, and AutoMigrate. JSON blobs are not queryable (no "find all politicians who voted Yea on bill X"), cannot enforce referential integrity, and make the API handler logic more complex (no GORM queries, manual JSON unmarshal at read time).

**Do this instead:** The 7-table schema above. It is the correct fit for the access patterns needed: "get all committees for politician X", "get all bills sponsored by politician X in the current session", "get vote record for politician X". These are simple indexed queries on the new tables.

### Anti-Pattern 3: Polling Congress.gov on Every Profile Request

**What goes wrong:** Calling the Congress.gov API synchronously inside GetPoliticianByID (blocking the response), or checking staleness on every request but not tracking when data was last fetched.

**Why it's wrong:** Congress.gov has a 5,000 req/hr limit. At scale, per-request API calls would exhaust the rate limit within minutes for a busy server. More importantly, it adds 500ms-2s latency to every profile page load — unacceptable.

**Do this instead:** The staleness-gated lazy-fetch pattern (Pattern 2 above). First load triggers the goroutine; goroutine updates `leg_data_fetched_at`; subsequent loads within 7 days skip the fetch entirely. The frontend shows empty/skeleton state on first load (sub-second), then populated data on refresh or next visit.

### Anti-Pattern 4: One Import Subcommand Per Data Source Per Level

**What goes wrong:** Creating `import-federal-committees`, `import-state-committees`, `import-local-committees`, `import-federal-bills`, `import-state-bills`, etc. — one CLI subcommand per data source per government level.

**Why it's wrong:** The existing CLI pattern (import-stances, import-quotes) uses a single command with a `--file` or `--source` flag to select the data source. Proliferating subcommands makes the CLI harder to document and maintain.

**Do this instead:** `import-committees --source congress-legislators --file committee-membership-current.yaml`, `import-committees --source scraped --jurisdiction bloomington`. The import package internally dispatches based on source.

### Anti-Pattern 5: Fetching Historical Data in the Lazy-Fetch Goroutine

**What goes wrong:** The Congress.gov API goroutine fetches all sponsored legislation for all time (potentially 30+ years for a senior senator), storing hundreds of bill records per politician on every profile view.

**Why it's wrong:** The database will grow rapidly. A senior senator may have 200-500 sponsored bills. Fetching all of them on first profile view takes many API calls (with 250-per-page pagination) and inserts hundreds of rows. The frontend only shows current session data by default.

**Do this instead:** Scope the lazy-fetch to the current congress (e.g., `congress=119` for the 119th Congress, 2025-2026). The import-bills CLI subcommand handles full historical backfill as a separate operation. The goroutine only fetches current session.

---

## Recommended Project Structure

```
EV-Backend/
├── internal/
│   ├── essentials/
│   │   ├── models.go           # MODIFIED — add 7 new structs; add leg_data_fetched_at to Politician
│   │   ├── setup.go            # MODIFIED — AutoMigrate 7 new models
│   │   ├── handlers.go         # MODIFIED — goroutine trigger in GetPoliticianByID
│   │   │                       #           — 5 new sub-resource handlers
│   │   ├── routes.go           # MODIFIED — 5 new route registrations
│   │   └── legislation/        # NEW SUB-PACKAGE
│   │       ├── congress.go     # Congress.gov API client
│   │       └── openstates.go   # Open States API client
│   ├── committeeimport/        # NEW PACKAGE (following stanceimport pattern)
│   │   ├── csv.go              # YAML parsing (despite name, matches package convention)
│   │   └── import.go           # Run(Config) entry point
│   └── leadershipimport/       # NEW PACKAGE
│       ├── csv.go              # YAML parsing
│       └── import.go           # Run(Config) entry point
├── main.go                     # MODIFIED — add import-committees, import-leadership cases
└── scripts/
    └── scrape_committees.py    # NEW — local government committee scraping

ev-ui/
└── src/
    ├── PoliticianProfile.jsx   # MODIFIED — add LegislativeActivity section; new legislativeData prop
    └── LegislativeActivity.jsx # NEW COMPONENT (or inline in PoliticianProfile)

essentials/
└── src/
    └── pages/
        └── Profile.jsx         # MODIFIED — add parallel fetches for legislative sub-resources
```

---

## Build Order (dependency-aware)

Dependencies: new tables must exist before imports run; imports must run before frontend can show data; frontend changes require ev-ui publish before they appear.

### Phase A: Schema Foundation (blocking for all subsequent steps)

1. Add 7 new GORM structs to `models.go` + `LegDataFetchedAt` to Politician
2. Add AutoMigrate for all 7 in `setup.go`
3. Run `go run .` locally — verify 7 new tables created in Supabase
4. Seed `legislative_sessions` manually (119th Congress, 2025 Indiana session, 2025 CA session, Bloomington 2025-2026)

**Blocking note:** All import CLI steps and lazy-fetch goroutine require tables to exist.

### Phase B: Static Data Import (parallel — federal committees, leadership; local scraping)

Federal (can run simultaneously):
- Build `committeeimport` package
- Add `import-committees` case to `main.go`
- Download congress-legislators YAMLs
- Run `./server import-committees --file committee-membership-current.yaml`
- Build `leadershipimport` package
- Add `import-leadership` case to `main.go`
- Run `./server import-leadership --file legislators-current.yaml`

Local (parallel with federal):
- Build `scrape_committees.py` for Bloomington + LA County
- Run scraper — upserts into `legislative_committees` + `legislative_committee_memberships`

**Validation:** `SELECT COUNT(*) FROM essentials.legislative_committee_memberships` — expect ~1,000+ for federal.

### Phase C: Lazy-Fetch Goroutine (depends on Phase A only)

- Create `internal/essentials/legislation/congress.go` API client
- Create `internal/essentials/legislation/openstates.go` API client
- Add goroutine trigger to `GetPoliticianByID` in `handlers.go`
- Add `CONGRESS_API_KEY` and `OPENSTATES_API_KEY` to `.env.local` + Render env vars

**Validation:** Visit a federal politician profile; wait 5-10 seconds; check `legislative_bills` and `legislative_votes` for rows. Check `politicians.leg_data_fetched_at` is now populated.

### Phase D: Backend API Endpoints (depends on Phase A; Phase B/C data useful for testing)

- Add 5 new handlers to `handlers.go`
- Add 5 new routes to `routes.go`
- Test each endpoint with curl against known politicians (e.g., a Senator with known bills)

**Validation:** `curl https://localhost:5050/essentials/politician/{id}/committees` returns JSON.

### Phase E: Frontend (depends on Phase D deployed)

- Add `legislativeData` prop to `PoliticianProfile.jsx` in ev-ui
- Add `LegislativeActivity` section (committees, leadership, bills, votes tabs or sections)
- Bump ev-ui version, publish to GitHub npm registry
- Update ev-ui version in `essentials/package.json` and `CompassV2/package.json`
- Add parallel fetches to `Profile.jsx` in essentials app
- Test: federal politician profile shows committees, leadership, bills, votes
- Test: local politician profile shows committees only (no bill/vote sections since empty)

**Blocking dependency:** ev-ui must be published before essentials frontend can use the new component.

### Blocking Dependency Chain

```
Phase A (schema migration)
    ↓
Phase B (static imports) — independent of C/D/E
Phase C (lazy-fetch goroutine) — independent of B/D/E; needs Phase A + API keys
    ↓
Phase D (API endpoints) — needs Phase A; Phase B/C useful but not blocking
    ↓
Phase E (frontend) — needs Phase D deployed to staging/prod
```

---

## Scalability Considerations

| Concern | Current Scale | Future |
|---------|--------------|--------|
| Bills per politician | ~50-250 (current session) | ~500-2,000 (full career) — handled by session-scoped queries |
| Votes per politician | ~200-500 (current session) | ~5,000+ (full career) — same session filter |
| API rate limit (Congress.gov) | 5,000/hr — trivial at per-profile trigger scale | Batch backfill ~1,070 federal officials = ~2,140 requests; fits in 30 minutes |
| Open States free tier | 500/day — sufficient for initial IN + CA import (few hundred politicians) | May need paid tier ($100/state/yr) if expanding to additional states |
| Database growth | Small (~10K rows on initial import) | Linear with politicians added; all queries are indexed on politician_id |
| Frontend latency | /legislative-summary endpoint returns in <100ms from indexed DB | No scaling concern; data is cached |

---

## Sources

- Direct source inspection: `EV-Backend/internal/essentials/models.go` — existing GORM model conventions, TableName() pattern, existing Committee/PoliticianCommittee tables, bioguide_id field — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/handlers.go` — GetPoliticianByID pattern, existing lazy-fetch goroutine approach confirmed in Phase B candidacy data (ExternalGlobalID trigger), sub-resource endpoint patterns (GetPoliticianEndorsements, GetPoliticianStances, GetPoliticianElections) — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/routes.go` — existing route structure, sub-resource pattern already established — HIGH confidence
- Direct source inspection: `EV-Backend/internal/stanceimport/import.go` — import CLI pattern: Config struct, Run() entry point, bioguide/name lookup maps, upsert with ON CONFLICT — HIGH confidence
- Direct source inspection: `EV-Backend/main.go` — CLI switch dispatch pattern (import-stances, import-quotes cases), Init() call order — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/setup.go` — AutoMigrate pattern, schema initialization, sub-package import pattern (geocoding.NewClient()) — HIGH confidence
- Direct source inspection: `ev-ui/src/PoliticianProfile.jsx` — existing section structure, prop interface, conditional rendering — HIGH confidence
- Congress.gov API documentation (GitHub: LibraryOfCongress/api.congress.gov) — rate limit 5,000/hr confirmed; pagination (limit/offset, pagination.next); available endpoints (sponsored-legislation, cosponsored-legislation, house-vote beta May 2025) — MEDIUM confidence (endpoint details from indirect sources; verify against live API)
- unitedstates/congress-legislators README — file list (committees-current.yaml, committee-membership-current.yaml, legislators-current.yaml), committee membership schema (bioguide, rank, title, party), leadership_roles[] schema (title, chamber, start, end) — HIGH confidence (from official GitHub README)
- Open States API v3 docs — rate limits (10/min, 500/day free; 40/min, 5,000/day bronze); key endpoints for bills and legislators; Indiana and California covered — MEDIUM confidence (tier limits from GitHub discussions thread; verify current limits at signup)
- LegiScan API — 30,000 req/month free; covers all 50 states including Indiana and California — MEDIUM confidence (from search results citing LegiScan user manual)
- Bloomington Common Council website — bloomington.in.gov/council/committees confirmed as data source for local committee assignments; no public API — HIGH confidence (from direct web search result)
- LA County Board of Supervisors — bos.lacounty.gov standing committees scrapeable from public pages; Granicus video archive separate from legislative text — MEDIUM confidence (confirmed public access; specific HTML structure needs verification during implementation)

---

*Architecture research for: Legislative Profile Data Integration (v2026.3)*
*Researched: 2026-03-01*
