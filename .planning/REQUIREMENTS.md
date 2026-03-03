# Requirements: Empowered Vote Platform

**Defined:** 2026-03-01
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v2026.3 Requirements

Requirements for Legislative Profile Data milestone. Each maps to roadmap phases.

### Schema & Infrastructure

- [x] **SCHEMA-01**: Database schema includes legislative sessions table with jurisdiction, name, date range, and is_current flag
- [x] **SCHEMA-02**: Database schema includes legislative committees table with external_id, name, type, chamber, parent committee support, and source tracking
- [x] **SCHEMA-03**: Database schema includes committee memberships join table linking politicians to committees with role (member/chair/vice-chair/ranking member) and session
- [x] **SCHEMA-04**: Database schema includes leadership roles table with politician, title, chamber, and date range
- [x] **SCHEMA-05**: Database schema includes legislative bills table with external_id, number, title, plain-language summary, status, sponsor, introduced date, subject tags, and source
- [x] **SCHEMA-06**: Database schema includes bill cosponsors join table linking politicians to bills
- [x] **SCHEMA-07**: Database schema includes legislative votes table with politician, bill (nullable), vote question, position (yea/nay/abstain/absent/not voting), date, result, and source
- [x] **SCHEMA-08**: Politician table extended with `leg_data_fetched_at` timestamp for lazy-fetch staleness gating
- [x] **SCHEMA-09**: Full data model entities from data-model.md implemented: jurisdictions, governing bodies, seats, seat tenures, and data sources tables

### Federal Data Pipeline

- [x] **FED-01**: Go CLI `import-committees` subcommand imports committee assignments from unitedstates/congress-legislators YAML, matching politicians via bioguide_id
- [x] **FED-02**: Go CLI `import-leadership` subcommand imports leadership roles (Speaker, Majority/Minority Leader, Whip, etc.) from congress-legislators YAML
- [x] **FED-03**: Congress.gov API client with rate limiting (5K req/hr) and exhaustive pagination (250-item page cap handling)
- [x] **FED-04**: Sponsored and cosponsored legislation imported for federal politicians via Congress.gov API (current + previous Congress)
- [x] **FED-05**: Voting records batch-imported for federal politicians — House via Congress.gov API, Senate via LegiScan (current + previous Congress)
- [x] **FED-06**: CRS plain-language bill summaries fetched from Congress.gov and stored alongside bill records
- [x] **FED-07**: LegiScan API client with rate limiting (30K queries/month) for Senate vote gap-fill

### State Data Pipeline

- [x] **STATE-01**: Indiana state committee assignments, bills, and votes imported via LegiScan or IGA API (current + previous session)
- [ ] **STATE-02**: California state committee assignments, bills, and votes imported via LegiScan (current + previous session)
- [x] **STATE-03**: State legislators matched to existing politician records via external IDs or name matching with dedup

### Local Data Pipeline

- [x] **LOCAL-01**: Feasibility check completed for Bloomington Common Council and LA County Board of Supervisors data availability before building scrapers
- [x] **LOCAL-02**: Bloomington Common Council committee assignments imported (from city website or manual entry)
- [x] **LOCAL-03**: LA County Board of Supervisors committee assignments imported (from county website or Legistar)
- [x] **LOCAL-04**: Bloomington legislation metadata imported from city clerk database where available
- [x] **LOCAL-05**: LA County BOS legislation/motions metadata imported from Legistar where available

### Backend API

- [x] **API-01**: GET /politician/{id}/committees returns committee assignments with roles for any government level
- [x] **API-02**: GET /politician/{id}/leadership returns leadership positions with date ranges
- [x] **API-03**: GET /politician/{id}/bills returns sponsored and cosponsored legislation with status
- [x] **API-04**: GET /politician/{id}/votes returns voting record with bill info and position
- [x] **API-05**: GET /politician/{id}/legislative-summary returns bounded overview (top committees, recent votes, recent bills) for initial profile render

### Frontend Profile Display

- [x] **UI-01**: Committees & Leadership section on politician profile showing current committee assignments with roles and any leadership positions
- [x] **UI-02**: Voting Record section showing recent votes with bill title/summary, politician's position (yea/nay/etc), and overall outcome
- [x] **UI-03**: Sponsored Legislation section showing bills with number, title, status, and introduction date
- [x] **UI-04**: All legislative sections gracefully show empty states when data unavailable for a given government level
- [ ] **UI-05**: Session filter lets users toggle between current and previous session data

## Future Requirements

### Derived Metrics (deferred to future milestone)

- **METRIC-01**: Bill topic tags for state/local (federal via Congress.gov subjects ships in v2026.3)
- **METRIC-02**: Notable votes curation (editorial workflow needed)

### Cross-App Integration (carried from v1.9)

- **XAPP-01**: User's Essentials address search surfaces "my reps" first in Compass compare picker
- **XAPP-02**: Compass radar overlay displayed on Essentials politician profile pages
- **XAPP-03**: Read & Rank quotes shown on Essentials politician profiles
- **COMP-04**: User can compare themselves against 2-3 politicians simultaneously

### Additional Coverage

- **COV-01**: Additional county/region geofence and politician coverage beyond Monroe County IN + LA County CA
- **COV-02**: LA City Council voting records (no structured API currently)
- **COV-03**: Historical voting records beyond 2 sessions

## Out of Scope

| Feature | Reason |
|---------|--------|
| Real-time vote syncing | Ops complexity too high for 2-3 person team; weekly batch sufficient |
| Full bill text display | Link to Congress.gov/state sites instead; storage/rendering burden |
| Interest group ratings | Antipartisan mission — we want users forming their own views, not deferring to advocacy groups |
| Ideology score computation | Antipartisan mission — partisan spectrum labels encourage tribal thinking over issue engagement |
| Vote alignment / party-line % | Antipartisan mission — framing votes as "with/against party" reinforces partisan lens |
| AI-generated bill summaries | Separate project; use CRS federal summaries only for now |
| Bill co-sponsorship network visualization | Text list sufficient; network graph is future v2 feature |
| Vote history beyond 2 sessions | Start narrow, expand on demand; DB size concern |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCHEMA-01 | Phase 54 | Complete |
| SCHEMA-02 | Phase 54 | Complete |
| SCHEMA-03 | Phase 54 | Complete |
| SCHEMA-04 | Phase 54 | Complete |
| SCHEMA-05 | Phase 54 | Complete |
| SCHEMA-06 | Phase 54 | Complete |
| SCHEMA-07 | Phase 54 | Complete |
| SCHEMA-08 | Phase 54 | Complete |
| SCHEMA-09 | Phase 54 | Complete |
| FED-01 | Phase 55 | Complete |
| FED-02 | Phase 55 | Complete |
| FED-07 | Phase 55 | Complete |
| FED-03 | Phase 56 | Complete |
| FED-04 | Phase 56 | Complete |
| FED-05 | Phase 56 | Complete |
| FED-06 | Phase 56 | Complete |
| API-01 | Phase 56 | Complete |
| API-02 | Phase 56 | Complete |
| API-03 | Phase 56 | Complete |
| API-04 | Phase 56 | Complete |
| API-05 | Phase 56 | Complete |
| STATE-01 | Phase 57 | Complete |
| STATE-02 | Phase 57 | Pending |
| STATE-03 | Phase 57 | Complete |
| LOCAL-01 | Phase 58 | Complete |
| LOCAL-02 | Phase 58 | Complete |
| LOCAL-03 | Phase 58 | Complete |
| LOCAL-04 | Phase 58 | Complete |
| LOCAL-05 | Phase 58 | Complete |
| UI-01 | Phase 59 | Complete |
| UI-02 | Phase 59 | Complete |
| UI-03 | Phase 59 | Complete |
| UI-04 | Phase 59 | Complete |
| UI-05 | Phase 59 | Pending |

**Coverage:**
- v2026.3 requirements: 34 total
- Mapped to phases: 34
- Unmapped: 0

---
*Requirements defined: 2026-03-01*
*Last updated: 2026-03-01 after roadmap creation*
