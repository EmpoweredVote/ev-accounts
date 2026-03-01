# Stack Research — v2026.3 Legislative Profile Data

**Domain:** Civic engagement platform — legislative activity data (committees, votes, bills, leadership) across federal, Indiana state, and LA County local government levels
**Researched:** 2026-03-01
**Confidence:** MEDIUM-HIGH (Congress.gov API reliability is a known risk factor; all other components HIGH)

---

## Scope

This document covers only *new or changed* stack decisions for v2026.3. The existing stack is retained as-is:

- **Go 1.24.3 + Chi v5.2.1 + GORM v1.30.0 + PostgreSQL** — backend unchanged
- **React 19 + Vite + Tailwind CSS 4** — frontends unchanged
- **Python 3.13 scraper pipeline + psycopg2 + requests + BeautifulSoup** — reused, extended
- **Supabase DB + Netlify frontends + Render backend** — infrastructure unchanged
- **All existing essentials models** — `Politician`, `PoliticianImage`, `PoliticianContact`, `Degree`, `Experience`, etc.
- **`meetings` schema** — has `Vote`/`VoteRecord` for transcript-extracted local votes; the new `legislative` schema is separate and purpose-built for structured bill/vote data from external sources

v2026.3 adds five new capabilities to the existing stack:
1. Congress.gov API v3 client (Go) — federal bills, votes, committees, leadership
2. unitedstates/congress-legislators YAML parsing (Go) — federal committee membership from static repo
3. Open States API v3 client (Python) — Indiana + California state legislative data
4. LegiScan API client (Python, optional fallback) — state vote records when Open States gaps exist
5. python-legistar-scraper (Python) — LA County Board of Supervisors and Bloomington Common Council

---

## Recommended Stack

### Federal Legislative Data: Congress.gov API v3

**Decision:** Use Congress.gov API v3 directly with a hand-rolled Go HTTP client. No third-party wrapper library exists for Go.

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Congress.gov API v3 | Current (free) | Bills, House roll call votes, committee assignments, member data | Official government source; 5,000 requests/hour; free API key via api.data.gov; added House roll call votes endpoint in May 2025 — now out of beta |
| `net/http` stdlib | Go 1.24 | HTTP client for Congress.gov API calls | No Go wrapper exists; stdlib is sufficient for REST+JSON; existing codebase pattern for all external HTTP calls |
| `encoding/json` stdlib | Go 1.24 | JSON decode Congress.gov responses | Already used throughout codebase |
| `golang.org/x/time/rate` | v0.x (indirect via `golang.org/x/sync`) | Rate limit outbound Congress.gov requests | Token bucket rate limiter; prevents hitting 5K/hour ceiling during bulk imports; already in `go.sum` transitively |

**Congress.gov API endpoint coverage for this milestone:**

| Data | Endpoint | Notes |
|------|----------|-------|
| Bill list by member | `GET /v3/member/{bioguide_id}/sponsored-legislation` | Uses existing `bioguide_id` on `Politician` model |
| Bill detail + summary | `GET /v3/bill/{congress}/{type}/{number}` with `summaries` | AI-generated summaries available since 119th Congress |
| House roll call votes | `GET /v3/house-vote/{congress}/{session}/{rollCallNumber}` | 118th Congress (2023) onward; Senate votes NOT yet in API |
| Committee list | `GET /v3/committee/{chamber}` | Returns current committees |
| Committee assignments | Parse `committees-current.yaml` from unitedstates/congress-legislators | Faster and more complete than API for membership data |

**Critical risk:** The Congress.gov API experienced an outage in early January 2026 and was restored. It remains under Library of Congress management and is subject to budget/infrastructure risk (DOGE cuts were mentioned in reporting but no confirmed funding loss). Always treat this API as potentially unavailable and design the import CLI to degrade gracefully — log failures, skip missing data, never block profile rendering.

**Senate roll call votes:** Not yet available in Congress.gov API v3 as of March 2026. For Senate votes, use the `unitedstates/congress` scraper or LegiScan as a fallback (see below).

---

### Federal Committee Membership: unitedstates/congress-legislators YAML

**Decision:** Parse `committees-current.yaml` and `committee-membership-current.yaml` directly from the GitHub repo (raw download). Do NOT call the Congress.gov API for committee membership — the YAML is more complete and requires zero API budget.

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `github.com/goccy/go-yaml` | `v1.18.0` | Parse `committees-current.yaml` and `committee-membership-current.yaml` | `gopkg.in/yaml.v3` is now archived/unmaintained (confirmed March 2025). `goccy/go-yaml` is the actively maintained replacement — passes 60+ additional YAML test cases vs go-yaml, team of active maintainers, v1.x stable |

**Do NOT use `gopkg.in/yaml.v3`.** It was archived. Use `github.com/goccy/go-yaml` instead.

**YAML download pattern for the import CLI:**

```go
// Download raw YAML from unitedstates/congress-legislators
const committeesURL = "https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committees-current.yaml"
const membershipURL  = "https://raw.githubusercontent.com/unitedstates/congress-legislators/main/committee-membership-current.yaml"

resp, err := http.Get(committeesURL)
// decode with goccy/go-yaml into []CommitteeYAML struct
```

The YAML structure has these top-level fields per committee entry:
- `thomas_id` — committee identifier (e.g., `SSFI`, `HSFA`)
- `name`, `url`, `type` (`house`/`senate`/`joint`)
- `subcommittees[]` — each with `thomas_id`, `name`

`committee-membership-current.yaml` is keyed by concatenated ID (`SSFI00` = Finance full committee, `SSFI01` = first subcommittee) with a list of legislator entries:
- `bioguide` — matches existing `politicians.bioguide_id`
- `name`, `party`, `rank`, `title` (chair/ranking member flags)

---

### State Legislative Data: Open States API v3

**Decision:** Use Open States API v3 (REST, JSON) for Indiana and California state legislative data. Access via Python scripts in the existing scraper pipeline, not from Go.

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Open States API v3 | Current (free tier) | Indiana + CA state bills, votes, committees, legislators | Only comprehensive state legislative API covering both IN and CA; free tier available; previously known as Plural Policy |
| `requests` | `2.32.5` (existing) | HTTP calls to `v3.openstates.org` | Already pinned; no new library needed |

**Base URL:** `https://v3.openstates.org/`

**Key endpoints for this milestone:**

| Data | Endpoint | Notes |
|------|----------|-------|
| Legislator lookup | `GET /people?jurisdiction=ocd-jurisdiction/country:us/state:in/government&name={name}` | Match by name to get Open States person ID |
| Bills sponsored | `GET /bills?sponsor={person_id}&jurisdiction={ocd_id}` | Returns bills with status |
| Vote records | `GET /votes?voter={person_id}&jurisdiction={ocd_id}` | Pagination required |
| Committee memberships | `GET /committees?jurisdiction={ocd_id}` then member filter | Committee data restored for IN and CA |

**API key:** Free registration at `openstates.org`. Set via `OPENSTATES_API_KEY` environment variable. Rate limits are not yet enforced on v3 (confirmed from Open States community discussions) but stay polite — use serial requests with a 0.5s delay.

**Confidence:** MEDIUM — rate limits for v3 were marked "TBD" in community discussions. Monitor for quota enforcement when it activates; for this milestone's data volume (2 states, ~200 legislators) it will not matter.

---

### State Legislative Data Fallback: LegiScan API

**Decision:** Add LegiScan as a fallback for Senate roll call votes (not in Congress.gov API) and as a secondary source when Open States has gaps. Use Python, not Go.

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| LegiScan API v1.91 | Current (free public tier) | Senate roll call votes for US Congress; Indiana + CA state rollups | 30,000 free queries/month; all 50 states + Congress covered; documentation updated March 2025; well-structured JSON responses |
| `requests` | `2.32.5` (existing) | HTTP calls to `api.legiscan.com` | Already pinned; no new library needed |

**LegiScan free tier:** 30,000 queries/month. This milestone imports data for ~535 federal legislators + ~200 state legislators from 2 states. A single import run will consume ~5,000-10,000 queries (well within the free tier for periodic imports).

**Key endpoints:**

| Data | Endpoint | Notes |
|------|----------|-------|
| Session list | `?op=getSessionList&state=US` | Returns session IDs for Congress |
| Person bills | `?op=getSponsoredBills&id={person_id}` | person_id from `getPerson` lookup |
| Roll call detail | `?op=getRollCall&id={roll_call_id}` | Returns full member vote breakdown |
| Bill detail | `?op=getBill&id={bill_id}` | Includes committees, text link, status |

**Person lookup:** LegiScan uses its own integer person IDs. Match federal legislators by `bioguide_id` (LegiScan includes it in person records). For state legislators, match by full name + session.

**Cost:** Free public key for ≤30K queries/month. No credit card required.

---

### Local Legislative Data: python-legistar-scraper

**Decision:** Use `python-legistar-scraper` (PyPI: `scraper-legistar`) for LA County Board of Supervisors. For Bloomington Common Council, use the City's OnBoard open data portal directly.

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `scraper-legistar` | Latest stable | LA County Board of Supervisors votes/legislation from `lacounty.legistar.com` | LA County uses Legistar (Granicus) for meeting management — confirmed at `lacounty.legistar.com`. The `opencivicdata/python-legistar-scraper` library handles Legistar's paginated HTML/JSON hybrid interface. Actively maintained by Open Civic Data project. |
| `requests` | `2.32.5` (existing) | Bloomington OnBoard API | City of Bloomington runs open-source OnBoard system (GitHub: `City-of-Bloomington/OnBoard`) with REST endpoints for votes and legislation. Use `requests` directly — no scraping library needed. |

**Bloomington Common Council:** The City of Bloomington runs a public OnBoard system. Fetch data via HTTP from their open data portal at `data.bloomington.in.gov`. Fall back to scraping council meeting minutes from `bloomington.in.gov/council/meetings/2025` if the structured API is insufficient.

**LA County Board of Supervisors:** Uses Legistar at `lacounty.legistar.com`. The `scraper-legistar` library abstracts Legistar's unusual partial-JSON-partial-HTML interface. Install:
```
scraper-legistar==<latest>
```

---

### Go Packages: New Additions to `go.mod`

Only two new Go packages are needed:

```
github.com/goccy/go-yaml v1.18.0     # YAML parsing for congress-legislators repo
golang.org/x/time v0.x               # rate.Limiter for Congress.gov API client
```

`golang.org/x/time` is already transitively in `go.sum` via `golang.org/x/sync`. Promote it to a direct dependency.

**No other new Go packages.** The Congress.gov API client is a hand-rolled struct with `net/http` + `encoding/json` — the existing pattern for all Go HTTP calls in this codebase. Do not add an HTTP client library (resty, got, etc.) — unnecessary for a single-API client.

---

### Python Packages: New Additions to `requirements.txt`

```
scraper-legistar          # LA County Legistar scraping
```

Everything else (requests, BeautifulSoup, psycopg2-binary) is already in `requirements.txt` and covers Open States + LegiScan API calls.

Do NOT add `pyopenstates` — the official Python client for Open States. It wraps v3 API with opinionated data models that will conflict with the project's direct psycopg2 write pattern. Raw `requests` calls to `v3.openstates.org` are simpler and already proven.

---

### Frontend Components: React (No New npm Packages)

**Decision:** Build voting record and legislation displays with existing Tailwind CSS 4 utility classes. No new component library needed.

The project already has:
- `ev-ui` component library with `PoliticianCard`, `PoliticianProfile`
- Tailwind CSS 4 for all styling
- Existing profile section pattern in `essentials` (education, experience, contacts)

New profile sections to build (in `ev-ui` or inline in `essentials`):

| Component | Pattern | Location |
|-----------|---------|----------|
| `CommitteeList` | Simple list with role badge (Member/Chair/Vice-Chair) | Inline in essentials `Profile.jsx` or ev-ui |
| `VotingRecord` | Paginated table — bill name, date, vote (Yea/Nay/Abstain), result badge | Inline in essentials `Profile.jsx` |
| `SponsoredLegislation` | Card list — bill number, title, status badge, topic tags | Inline in essentials `Profile.jsx` |
| `LeadershipRoles` | Compact list — role title, body, since date | Inline in essentials `Profile.jsx` |

**Styling pattern for vote indicators** (Yea/Nay/Abstain):
```jsx
const voteColors = {
  yea:     'bg-green-100 text-green-800',
  nay:     'bg-red-100 text-red-800',
  abstain: 'bg-gray-100 text-gray-600',
  absent:  'bg-gray-50 text-gray-400',
};
```

This is consistent with ev-coral / ev-muted-blue brand palette using Tailwind's green/red semantic colors for civic context.

**No new npm packages** for the frontend. Do not add:
- A data table library (TanStack Table, etc.) — Tailwind table utility classes are sufficient for 10-20 vote rows
- A charting library for vote breakdowns — a simple CSS bar or text summary is adequate
- Any additional UI kit — the project's pattern is Tailwind utilities, not component library additions

---

## Go Module Schema: New `internal/legislative/` Package

The legislative data needs its own Go module following the existing pattern (`internal/<feature>/models.go`, `routes.go`, `handlers.go`, `setup.go`).

**New schema:** `legislative` (new PostgreSQL schema, separate from `essentials` and `meetings`)

Core models needed:

```go
// LegislativeSession — a congressional/state session (e.g., "119th Congress", "2025 Indiana Regular Session")
type LegislativeSession struct {
    ID           uuid.UUID `gorm:"type:uuid;primaryKey"`
    Jurisdiction string    // "federal", "indiana", "california", "bloomington-in", "la-county-ca"
    Name         string    // "119th Congress", "2025 IN Regular Session"
    StartDate    time.Time
    EndDate      *time.Time
    ExternalID   string    // Congress number, Open States session ID, LegiScan session ID
}
func (LegislativeSession) TableName() string { return "legislative.sessions" }

// GoverningBody — a legislative chamber or local body
type GoverningBody struct {
    ID           uuid.UUID `gorm:"type:uuid;primaryKey"`
    Jurisdiction string
    Name         string    // "U.S. Senate", "Indiana State Senate", "Bloomington Common Council"
    Chamber      string    // "upper", "lower", "unicameral", "local"
    ExternalID   string
}
func (GoverningBody) TableName() string { return "legislative.governing_bodies" }

// Committee — a committee or subcommittee
type Committee struct {
    ID              uuid.UUID  `gorm:"type:uuid;primaryKey"`
    GoverningBodyID uuid.UUID
    ParentID        *uuid.UUID // for subcommittees
    Name            string
    ExternalID      string    // thomas_id, OCD committee ID, Legistar committee ID
    IsCurrent       bool
}
func (Committee) TableName() string { return "legislative.committees" }

// CommitteeMembership — politician on committee with role
type CommitteeMembership struct {
    ID           uuid.UUID `gorm:"type:uuid;primaryKey"`
    CommitteeID  uuid.UUID
    PoliticianID uuid.UUID // FK to essentials.politicians (app-level)
    Role         string    // "member", "chair", "vice_chair", "ranking_member", "ex_officio"
    SessionID    uuid.UUID
    IsCurrent    bool
}
func (CommitteeMembership) TableName() string { return "legislative.committee_memberships" }

// LeadershipPosition — speaker, majority leader, whip, etc.
type LeadershipPosition struct {
    ID           uuid.UUID `gorm:"type:uuid;primaryKey"`
    PoliticianID uuid.UUID
    BodyID       uuid.UUID
    Title        string    // "Speaker", "Majority Leader", "President Pro Tempore"
    StartDate    *time.Time
    EndDate      *time.Time
    SessionID    *uuid.UUID
    IsCurrent    bool
}
func (LeadershipPosition) TableName() string { return "legislative.leadership_positions" }

// Legislation — a bill, resolution, ordinance, or motion
type Legislation struct {
    ID            uuid.UUID `gorm:"type:uuid;primaryKey"`
    SessionID     uuid.UUID
    ExternalID    string    // bill number + session composite, LegiScan bill_id, Legistar matter_id
    Number        string    // "HB 1044", "SB 123", "Ordinance 2026-15"
    Title         string
    Summary       string    `gorm:"type:text"`  // plain-language summary
    Status        string    // "introduced", "committee", "floor", "passed", "failed", "signed", "vetoed"
    IntroducedAt  *time.Time
    PassedAt      *time.Time
    SignedAt      *time.Time
    TopicTags     pq.StringArray `gorm:"type:text[]"`
    Url           string
}
func (Legislation) TableName() string { return "legislative.legislation" }

// Sponsorship — politician sponsors/co-sponsors legislation
type Sponsorship struct {
    ID            uuid.UUID `gorm:"type:uuid;primaryKey"`
    LegislationID uuid.UUID
    PoliticianID  uuid.UUID
    Type          string    // "primary", "cosponsor"
}
func (Sponsorship) TableName() string { return "legislative.sponsorships" }

// RollCallVote — a recorded vote on legislation
type RollCallVote struct {
    ID            uuid.UUID `gorm:"type:uuid;primaryKey"`
    LegislationID *uuid.UUID // nullable: some votes are procedural
    SessionID     uuid.UUID
    BodyID        uuid.UUID
    ExternalID    string    // roll call number, Legistar vote ID
    Date          time.Time
    Question      string    // "Passage", "Amendment #3", "Cloture"
    Result        string    // "passed", "failed", "tabled"
    YeaCount      int
    NayCount      int
    AbstainCount  int
    AbsentCount   int
}
func (RollCallVote) TableName() string { return "legislative.roll_call_votes" }

// VoteCast — individual member's vote on a roll call
type VoteCast struct {
    ID             uuid.UUID `gorm:"type:uuid;primaryKey;uniqueIndex:idx_vote_cast"`
    RollCallVoteID uuid.UUID `gorm:"uniqueIndex:idx_vote_cast"`
    PoliticianID   uuid.UUID `gorm:"uniqueIndex:idx_vote_cast"`
    Position       string    // "yea", "nay", "abstain", "absent", "not_voting", "present"
}
func (VoteCast) TableName() string { return "legislative.votes_cast" }
```

This schema is intentionally source-agnostic — Congress.gov, Open States, LegiScan, Legistar, and OnBoard all write into the same tables using the import CLI.

---

## Import CLI Pattern

The existing import CLI pattern (`go run . import-stances`, `go run . import-quotes`) extends cleanly. New subcommands:

```
go run . import-federal-committees   # parse congress-legislators YAML → legislative.committees + committee_memberships
go run . import-federal-votes        # Congress.gov API → legislative.roll_call_votes + votes_cast
go run . import-federal-bills        # Congress.gov API → legislative.legislation + sponsorships
go run . import-state-data           # Open States API (Python script) → legislative.*
go run . import-local-data           # Legistar / OnBoard (Python script) → legislative.*
```

The Python scripts (Open States, LegiScan, Legistar) write directly to PostgreSQL via psycopg2 — same pattern as all existing scraper scripts. The Go CLI subcommands handle federal data.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Congress.gov API v3 (direct) | ProPublica Congress API | ProPublica shut down its Congress API — no longer available |
| Congress.gov API v3 (direct) | GovTrack bulk data | GovTrack ended its bulk data and API service (confirmed deprecated) |
| `goccy/go-yaml` v1.18.0 | `gopkg.in/yaml.v3` | `gopkg.in/yaml.v3` is archived/unmaintained as of 2025 |
| `goccy/go-yaml` v1.18.0 | `sigs.k8s.io/yaml` | Wraps archived `gopkg.in/yaml.v3` — inherits same maintenance issues |
| Open States API v3 + raw `requests` | `pyopenstates` | Official Python client wraps v3 but imposes data models that conflict with direct psycopg2 write pattern; no benefit over raw `requests` |
| LegiScan (fallback only) | LegiScan as primary | Open States is more structured for committee data; LegiScan free tier is generous but LegiScan person IDs require separate lookup vs Open States OCD IDs which are standard |
| `scraper-legistar` (PyPI) | Scraping Legistar HTML manually | `scraper-legistar` from opencivicdata is purpose-built for Legistar's unusual partial-JSON structure; reinventing it is wasted effort |
| `net/http` stdlib | `github.com/go-resty/resty` | No third-party HTTP client needed for a single-API Go client; existing codebase uses stdlib throughout |
| Tailwind CSS utilities (existing) | TanStack Table for vote lists | Vote lists have ≤20 rows in the initial scope; a full table library is overkill; existing ev-ui component pattern uses Tailwind |

---

## Installation

### Go — add to go.mod

```bash
cd /Users/chrisandrews/Documents/GitHub/EV-Backend
go get github.com/goccy/go-yaml@v1.18.0
go get golang.org/x/time
```

### Python — add to requirements.txt

```
scraper-legistar          # Legistar scraping for LA County BOS + potential Bloomington
```

Full updated `requirements.txt`:
```
geopandas==1.1.2
SQLAlchemy==2.0.46
psycopg2-binary==2.9.11
shapely==2.0.7
requests==2.32.5
beautifulsoup4==4.12.3
rapidfuzz==3.12.1
pdfplumber==0.11.4
playwright==1.50.0
supabase==2.28.0
scraper-legistar          # NEW — Legistar scraping for LA County BOS
```

### Environment Variables (new)

```
CONGRESS_API_KEY=<from api.data.gov — free signup>
OPENSTATES_API_KEY=<from openstates.org — free signup>
LEGISCAN_API_KEY=<from legiscan.com — free signup>
```

Add to EV-Backend `.env.local` (never commit). Add to Render environment for production.

---

## External API Summary

| API | Auth | Rate Limit | Cost | Primary Use |
|-----|------|------------|------|-------------|
| Congress.gov API v3 | API key (api.data.gov) | 5,000 req/hour | Free | Federal bills, House votes, committees |
| unitedstates/congress-legislators | None (public GitHub raw) | GitHub raw CDN limits | Free | Federal committee membership YAML |
| Open States API v3 | API key (openstates.org) | Not enforced yet (v3 beta) | Free | Indiana + CA bills, votes, committees |
| LegiScan API | API key (legiscan.com) | 30,000 req/month free | Free | Senate votes fallback; state rollup |
| LA County Legistar | None (public) | Polite scraping | Free | LA County BOS votes/legislation |
| Bloomington OnBoard | None (public) | Polite requests | Free | Bloomington Council votes |

**Total new API cost: $0** — all free tiers sufficient for this scope.

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `pyopenstates` PyPI package | Opinionated data models conflict with psycopg2 direct write pattern; v3 wrapper adds abstraction with no benefit | Raw `requests` to `v3.openstates.org` |
| `gopkg.in/yaml.v3` | Archived, unmaintained as of 2025 | `github.com/goccy/go-yaml` v1.18.0 |
| `sigs.k8s.io/yaml` | Wraps the archived `gopkg.in/yaml.v3`; inherits maintenance issues | `github.com/goccy/go-yaml` v1.18.0 |
| ProPublica Congress API | Shut down — no longer available | Congress.gov API v3 |
| GovTrack bulk data or API | Explicitly deprecated, service ended | Congress.gov API v3 + unitedstates/congress data |
| Any Go HTTP client library (resty, got, heimdall) | One external API; stdlib `net/http` is sufficient and consistent with existing codebase | `net/http` + `encoding/json` |
| TanStack Table or any React table library | Vote tables have ≤20 rows in initial scope; full table library is disproportionate; ev-ui already handles lists | Tailwind CSS table utilities in existing `Profile.jsx` pattern |
| GraphQL client for Open States | Open States v2 GraphQL is deprecated and sunset December 2023; v3 is REST | Open States API v3 REST endpoints |
| Storing Senate roll call votes from Congress.gov | Senate votes are NOT yet available in Congress.gov API v3 | LegiScan for Senate votes, or note as "data not yet available" |
| `encoding/yaml` from stdlib | Go stdlib does not have a YAML package — only JSON/XML | `github.com/goccy/go-yaml` |
| New npm packages for frontend | Existing Tailwind + ev-ui component pattern covers all new UI needs | Extend existing `Profile.jsx` sections |

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Congress.gov API v3 — endpoints exist | HIGH | Official LoC blog post May 2025 confirming House roll call votes; ChangeLog on GitHub |
| Congress.gov API v3 — reliability | LOW | Experienced outage January 2026; Library of Congress budget at political risk; treat as unstable |
| Senate votes in Congress.gov API | HIGH (not available) | API changelog confirms only House roll call votes added; Senate not yet included |
| Open States API v3 — coverage | MEDIUM | Indiana + CA confirmed covered; rate limits "TBD" for v3; v2 GraphQL sunset December 2023 |
| LegiScan — free tier 30K/month | HIGH | Explicitly documented in API manual (Revision 20250317 v1.91) |
| `goccy/go-yaml` v1.18.0 | HIGH | Active release on GitHub, v1.x stable, Debian/Ubuntu packaged |
| `gopkg.in/yaml.v3` archived | HIGH | Multiple community discussions confirming archived status 2025 |
| `scraper-legistar` — LA County | MEDIUM | LA County confirmed on Legistar (`lacounty.legistar.com`); library maintained by Open Civic Data project; last commit activity to verify before starting |
| Bloomington OnBoard REST API | MEDIUM | City of Bloomington GitHub confirms OnBoard system exists; specific endpoint documentation not found in search — validate before building integration |

---

## Sources

- [Congress.gov API v3 — Official Library of Congress](https://www.loc.gov/apis/additional-apis/congress-dot-gov-api/) — HIGH confidence
- [Congress.gov API ChangeLog](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/ChangeLog.md) — HIGH confidence
- [Introducing House Roll Call Votes in the Congress.gov API](https://blogs.loc.gov/law/2025/05/introducing-house-roll-call-votes-in-the-congress-gov-api/) — HIGH confidence
- [Congress.gov API outage article](https://www.govtech.com/gov-experience/congress-govs-api-has-gone-dark-impacting-data-access) — HIGH confidence (January 2026 outage confirmed)
- [unitedstates/congress-legislators — GitHub](https://github.com/unitedstates/congress-legislators) — HIGH confidence
- [goccy/go-yaml — GitHub](https://github.com/goccy/go-yaml) — HIGH confidence; v1.18.0 confirmed stable
- [gopkg.in/yaml.v3 archived discussion](https://github.com/go-task/task/issues/2171) — HIGH confidence
- [Open States API v3 Documentation](https://docs.openstates.org/api-v3/) — MEDIUM confidence (rate limits TBD)
- [Open States Rate Limit Discussion](https://github.com/openstates/issues/discussions/205) — MEDIUM confidence
- [LegiScan API User Manual v1.91 (2025-03-17)](https://api.legiscan.com/dl/LegiScan_API_User_Manual.pdf) — HIGH confidence; 30K free queries confirmed
- [opencivicdata/python-legistar-scraper — GitHub](https://github.com/opencivicdata/python-legistar-scraper) — MEDIUM confidence (verify last commit date before adoption)
- [LA County Legistar portal](https://lacounty.legistar.com/) — HIGH confidence (confirmed by search results)
- [City-of-Bloomington/OnBoard — GitHub](https://github.com/City-of-Bloomington/OnBoard) — MEDIUM confidence (REST API endpoints not confirmed in search; requires direct validation)
- [golang.org/x/time/rate — pkg.go.dev](https://pkg.go.dev/golang.org/x/time/rate) — HIGH confidence (stdlib extension, stable)

---

*Stack research for: v2026.3 Legislative Profile Data — Congress.gov API, Open States, LegiScan, Legistar, congress-legislators YAML*
*Researched: 2026-03-01*
